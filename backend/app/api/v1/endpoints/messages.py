from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc
from typing import List
from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.core.exceptions import NotFoundException, BadRequestException
from app.core.redis import get_redis
from app.services.connection import manager
from app.models.models import User, Message
from app.schemas.schemas import MessageCreate, MessageResponse
import redis

router = APIRouter()

# Get message history with a specific user
@router.get("/{recipient_id}", response_model=List[MessageResponse])
def get_message_history(
    recipient_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    # Check if recipient exists
    recipient = db.query(User).filter(User.id == recipient_id).first()
    if not recipient:
        raise NotFoundException(detail="Recipient not found")

    messages = db.query(Message).filter(
        or_(
            and_(Message.sender_id == current_user.id, Message.recipient_id == recipient_id),
            and_(Message.sender_id == recipient_id, Message.recipient_id == current_user.id)
        )
    ).order_by(Message.created_at.asc()).all()
    
    return messages

# Send a new message
@router.post("", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    msg_in: MessageCreate,
    db: Session = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis),
    current_user: User = Depends(get_current_active_user)
):
    # Rate Limiting: max 20 messages per 60 seconds per user
    rate_key = f"rate_limit:messages:{current_user.id}"
    current = redis_client.get(rate_key)
    if current and int(current) >= 20:
        raise BadRequestException(detail="You are sending messages too quickly. Please slow down.", code="RATE_LIMIT_EXCEEDED")
    
    pipe = redis_client.pipeline()
    pipe.incr(rate_key)
    pipe.expire(rate_key, 60)
    pipe.execute()

    recipient = db.query(User).filter(User.id == msg_in.recipient_id).first()
    if not recipient:
        raise NotFoundException(detail="Recipient not found")

    new_msg = Message(
        sender_id=current_user.id,
        recipient_id=msg_in.recipient_id,
        content=msg_in.content,
        media_url=msg_in.media_url
    )
    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)

    # Broadcast message through active WebSocket connection
    payload = {
        "type": "message",
        "message": {
            "id": new_msg.id,
            "sender_id": new_msg.sender_id,
            "recipient_id": new_msg.recipient_id,
            "content": new_msg.content,
            "media_url": new_msg.media_url,
            "created_at": new_msg.created_at.isoformat(),
            "is_read": new_msg.is_read
        }
    }
    await manager.send_personal_message(payload, msg_in.recipient_id)

    return new_msg

# Get list of active conversations
@router.get("/conversations/list", response_model=List[dict])
def get_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    redis_client: redis.Redis = Depends(get_redis)
):
    # Retrieve unique chat partners
    sent_partners = db.query(Message.recipient_id).filter(Message.sender_id == current_user.id).distinct()
    recv_partners = db.query(Message.sender_id).filter(Message.recipient_id == current_user.id).distinct()
    
    partner_ids = set([p[0] for p in sent_partners.all()] + [p[0] for p in recv_partners.all()])
    
    conversations = []
    for pid in partner_ids:
        partner = db.query(User).filter(User.id == pid).first()
        if not partner:
            continue
            
        # Get last message
        last_msg = db.query(Message).filter(
            or_(
                and_(Message.sender_id == current_user.id, Message.recipient_id == pid),
                and_(Message.sender_id == pid, Message.recipient_id == current_user.id)
            )
        ).order_by(Message.created_at.desc()).first()
        
        # Check active status in Redis
        is_online = redis_client.get(f"presence:{pid}") == "online"
        
        conversations.append({
            "partner_id": partner.id,
            "username": partner.username,
            "full_name": partner.full_name,
            "avatar_url": partner.avatar_url,
            "last_message": last_msg.content if last_msg else "",
            "last_message_time": last_msg.created_at if last_msg else partner.created_at,
            "unread_count": db.query(Message).filter(
                Message.sender_id == pid,
                Message.recipient_id == current_user.id,
                Message.is_read == False
            ).count(),
            "is_online": is_online
        })
        
    # Sort conversations by last message timestamp
    conversations.sort(key=lambda x: x["last_message_time"], reverse=True)
    return conversations
