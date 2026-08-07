"""
achievements endpoint
─────────────────────
GET /achievements/catalogue   — full list of all achievement definitions
GET /achievements/me          — current user's earned + locked achievements
GET /achievements/{username}  — another user's public achievements
POST /achievements/check      — manually trigger a full achievement re-check for current user
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.core.achievements import (
    ACHIEVEMENT_CATALOGUE,
    check_and_award_achievements,
    get_user_achievements,
)
from app.models.models import User

router = APIRouter()


@router.get("/catalogue")
def get_catalogue():
    """Return the full static catalogue of all achievements."""
    return ACHIEVEMENT_CATALOGUE


@router.get("/me")
def get_my_achievements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Return all achievements for the current user, annotated with unlock status."""
    return get_user_achievements(current_user.id, db)


@router.get("/{username}")
def get_user_achievements_by_username(
    username: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Return achievements for any public user profile."""
    target = db.query(User).filter(User.username == username).first()
    if not target or target.is_deleted or target.is_deactivated:
        return []
    return get_user_achievements(target.id, db)


@router.post("/check")
def trigger_achievement_check(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Manually run the full achievement check for the current user.
    Returns newly unlocked achievements (if any).
    Useful on first login / profile open to back-fill historical achievements.
    """
    newly_unlocked = check_and_award_achievements(current_user, db, trigger="all")
    return {
        "newly_unlocked": newly_unlocked,
        "count": len(newly_unlocked),
    }
