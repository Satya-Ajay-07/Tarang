from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from sqlalchemy.orm import Session
from app.core import security
from app.core.database import get_db
from app.core.redis import get_redis_client
from app.services.connection import manager
from app.models.models import User, Message
import json
import logging

router = APIRouter()
logger = logging.getLogger("tarang")

@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(...),
    db: Session = Depends(get_db)
):
    # Verify JWT Token
    payload = security.decode_token(token)
    if not payload or payload.get("type") != "access":
        await websocket.close(code=4003)  # Forbidden
        return

    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        await websocket.close(code=4003)
        return

    # NOTE: FastAPI's generator-based `Depends(get_redis)` cannot be injected
    # directly into WebSocket endpoints (the generator lifecycle is not managed
    # by the WS handler scope). We call get_redis_client() explicitly and close
    # the connection in the finally block to maintain the same resource pattern.
    redis_client = get_redis_client()

    await manager.connect(user_id, websocket, redis_client)

    try:
        while True:
            data = await websocket.receive_text()
            message_data = json.loads(data)

            event_type = message_data.get("type")

            if event_type == "ping":
                # Refresh presence TTL on heartbeat
                redis_client.setex(f"presence:{user_id}", 60, "online")
                await websocket.send_json({"type": "pong"})

            elif event_type == "typing":
                recipient_id = message_data.get("recipient_id")
                is_typing = message_data.get("typing", False)
                if recipient_id:
                    await manager.send_personal_message(
                        {
                            "type": "typing",
                            "sender_id": user_id,
                            "typing": is_typing,
                        },
                        recipient_id,
                    )

            elif event_type == "read":
                message_id = message_data.get("message_id")
                msg = (
                    db.query(Message)
                    .filter(Message.id == message_id, Message.recipient_id == user_id)
                    .first()
                )
                if msg:
                    msg.is_read = True
                    db.commit()
                    await manager.send_personal_message(
                        {
                            "type": "read",
                            "message_id": message_id,
                            "recipient_id": user_id,
                        },
                        msg.sender_id,
                    )

    except WebSocketDisconnect:
        await manager.disconnect(user_id, websocket, redis_client)
    except Exception as e:
        logger.error(f"WebSocket error for user {user_id}: {e}")
        await manager.disconnect(user_id, websocket, redis_client)
    finally:
        redis_client.close()

