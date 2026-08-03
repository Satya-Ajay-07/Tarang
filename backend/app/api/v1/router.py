from fastapi import APIRouter
from app.api.v1.endpoints import auth, users, waves, alerts, messages, circles, explore, media, hashtags

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(waves.router, prefix="/waves", tags=["waves"])
api_router.include_router(alerts.router, prefix="/alerts", tags=["alerts"])
api_router.include_router(messages.router, prefix="/messages", tags=["messages"])
api_router.include_router(circles.router, prefix="/circles", tags=["circles"])
api_router.include_router(explore.router, prefix="/explore", tags=["explore"])
api_router.include_router(media.router, prefix="/media", tags=["media"])
api_router.include_router(hashtags.router, prefix="/hashtags", tags=["hashtags"])


