import json
import logging
import asyncio
from typing import Dict, List, Optional
from fastapi import WebSocket
import redis.asyncio as async_redis
from app.core.config import settings

logger = logging.getLogger("tarang")

class ConnectionManager:
    def __init__(self):
        # Maps user_id -> List of active WebSockets on this specific server instance
        self.active_connections: Dict[str, List[WebSocket]] = {}
        # Maps user_id -> Redis Pub/Sub subscriber task (per-user messages)
        self.pubsub_tasks: Dict[str, asyncio.Task] = {}
        # Single node-level task that fans out global presence events
        self._presence_task: Optional[asyncio.Task] = None
        # Async Redis client (reused across calls)
        self._redis_client = None

    async def _get_async_redis(self):
        if self._redis_client is None:
            self._redis_client = async_redis.from_url(
                settings.REDIS_URL, decode_responses=True
            )
        return self._redis_client

    async def connect(self, user_id: str, websocket: WebSocket, redis_client):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)

        # Track presence in Redis with a 60-second TTL (heartbeat refreshes it)
        redis_client.setex(f"presence:{user_id}", 60, "online")

        # Publish presence update via Redis — picked up by _listen_presence_channel
        await self.broadcast_presence(user_id, "online", redis_client)

        # Start per-user message channel listener if not already running on this node
        if user_id not in self.pubsub_tasks:
            task = asyncio.create_task(self._listen_user_channel(user_id))
            self.pubsub_tasks[user_id] = task

        # Start the node-level presence fan-out listener exactly once
        if self._presence_task is None or self._presence_task.done():
            self._presence_task = asyncio.create_task(self._listen_presence_channel())

    async def disconnect(self, user_id: str, websocket: WebSocket, redis_client):
        if user_id in self.active_connections:
            if websocket in self.active_connections[user_id]:
                self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

                # Cancel per-user message listener — no local sockets remain for this user
                task = self.pubsub_tasks.pop(user_id, None)
                if task:
                    task.cancel()

                # Clear Redis presence key
                redis_client.delete(f"presence:{user_id}")
                await self.broadcast_presence(user_id, "offline", redis_client)

    async def send_personal_message(self, message: dict, user_id: str):
        """
        Publish a direct message to the user's dedicated Redis channel.
        The node that holds the recipient's WebSocket connection receives it
        through _listen_user_channel and delivers it locally.
        """
        try:
            async_client = await self._get_async_redis()
            await async_client.publish(f"tarang:user:{user_id}", json.dumps(message))
        except Exception as e:
            logger.error(f"Failed to publish WS message for user {user_id}: {e}")

    async def _listen_user_channel(self, user_id: str):
        """
        Per-user background task — subscribes to tarang:user:{user_id} and delivers
        any published messages to the user's locally active WebSocket connections.
        """
        async_client = await self._get_async_redis()
        pubsub = async_client.pubsub()
        channel = f"tarang:user:{user_id}"
        await pubsub.subscribe(channel)

        try:
            async for message in pubsub.listen():
                if message["type"] == "message":
                    data = json.loads(message["data"])
                    for connection in list(self.active_connections.get(user_id, [])):
                        try:
                            await connection.send_json(data)
                        except Exception as e:
                            logger.warning(f"WS send failed for {user_id}: {e}")
        except asyncio.CancelledError:
            await pubsub.unsubscribe(channel)
            await pubsub.close()
        except Exception as e:
            logger.error(f"User channel listener error for {user_id}: {e}")
            await pubsub.unsubscribe(channel)
            await pubsub.close()

    async def broadcast_presence(self, user_id: str, status: str, redis_client):
        """
        Publish a presence event to the global tarang:presence Redis channel.
        _listen_presence_channel (running once per node) picks this up and fans
        it out locally — no direct push to sockets here, avoiding double-delivery.
        """
        payload = json.dumps({"type": "presence", "user_id": user_id, "status": status})
        try:
            async_client = await self._get_async_redis()
            await async_client.publish("tarang:presence", payload)
        except Exception as e:
            logger.warning(f"Failed to publish presence event: {e}")

    async def _listen_presence_channel(self):
        """
        Single node-level background task. Subscribes to tarang:presence and
        forwards each event to ALL locally connected WebSockets on this node.
        Runs exactly once per server instance (started on first user connect).
        """
        async_client = await self._get_async_redis()
        pubsub = async_client.pubsub()
        await pubsub.subscribe("tarang:presence")

        try:
            async for message in pubsub.listen():
                if message["type"] == "message":
                    data = json.loads(message["data"])
                    for uid in list(self.active_connections.keys()):
                        for connection in list(self.active_connections.get(uid, [])):
                            try:
                                await connection.send_json(data)
                            except Exception:
                                pass
        except asyncio.CancelledError:
            await pubsub.unsubscribe("tarang:presence")
            await pubsub.close()
        except Exception as e:
            logger.error(f"Presence channel listener error: {e}")
            await pubsub.unsubscribe("tarang:presence")
            await pubsub.close()

manager = ConnectionManager()
