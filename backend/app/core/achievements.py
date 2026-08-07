"""
achievements.py
──────────────
Central achievement engine for Tarang.

Usage inside any endpoint:
    from app.core.achievements import check_and_award_achievements
    newly_unlocked = check_and_award_achievements(user, db, trigger="wave_created")

The returned list contains dicts for every achievement unlocked for the
FIRST time during this call – the caller can pass them back to the client
in the response header / body so the frontend can show a celebration toast.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any

from sqlalchemy import func
from sqlalchemy.orm import Session

logger = logging.getLogger("tarang.achievements")

# ── Achievement Catalogue ──────────────────────────────────────────────────────
# Each entry is static metadata; unlock *logic* lives in TRIGGERS below.
ACHIEVEMENT_CATALOGUE: List[Dict[str, Any]] = [
    {
        "id": "first_wave",
        "name": "First Wave",
        "icon": "🌊",
        "description": "Posted your very first wave into the ocean.",
        "category": "creator",
    },
    {
        "id": "50_waves",
        "name": "Wave Maker",
        "icon": "✍️",
        "description": "Posted 50 waves — a true voice of the ocean.",
        "category": "creator",
    },
    {
        "id": "first_ripple",
        "name": "First Ripple",
        "icon": "❤️",
        "description": "Sent your first ripple of appreciation.",
        "category": "social",
    },
    {
        "id": "100_ripples_received",
        "name": "Ripple Magnet",
        "icon": "💯",
        "description": "Your waves have been rippled 100 times.",
        "category": "influence",
    },
    {
        "id": "100_followers",
        "name": "Community Builder",
        "icon": "👥",
        "description": "100 riders are now following your wave.",
        "category": "influence",
    },
    {
        "id": "7_day_streak",
        "name": "7 Day Streak",
        "icon": "🔥",
        "description": "Stayed active and posted waves 7 days in a row.",
        "category": "dedication",
    },
    {
        "id": "early_rider",
        "name": "Early Rider",
        "icon": "🚀",
        "description": "Joined Tarang in the first 30 days of launch.",
        "category": "special",
    },
    {
        "id": "trend_starter",
        "name": "Trend Starter",
        "icon": "📢",
        "description": "Created a hashtag that became trending.",
        "category": "influence",
    },
    {
        "id": "community_builder",
        "name": "Super Connector",
        "icon": "🏆",
        "description": "Following 50+ riders and followed by 50+ riders.",
        "category": "social",
    },
]

# Quick look-up: id → metadata
ACHIEVEMENT_MAP: Dict[str, Dict[str, Any]] = {a["id"]: a for a in ACHIEVEMENT_CATALOGUE}

# ── Trigger Tags ───────────────────────────────────────────────────────────────
# Which achievements to re-check after a given action.  This avoids
# running all N checks on every single endpoint call.
TRIGGER_MAP: Dict[str, List[str]] = {
    "wave_created":   ["first_wave", "50_waves", "7_day_streak", "trend_starter"],
    "ripple_given":   ["first_ripple"],
    "ripple_received": ["100_ripples_received"],
    "rider_gained":   ["100_followers", "community_builder"],
    "rider_followed": ["community_builder"],
    "user_registered": ["early_rider"],
    # Universal — run everything (e.g. on profile load to back-fill)
    "all":            [a["id"] for a in ACHIEVEMENT_CATALOGUE],
}

# ── Platform launch date (for early_rider) ────────────────────────────────────
PLATFORM_LAUNCH_DATE = datetime(2026, 7, 1, tzinfo=timezone.utc)


# ── Condition checkers ─────────────────────────────────────────────────────────

def _check(achievement_id: str, user: Any, db: Session) -> bool:
    """Return True if the user meets the unlock condition for this achievement."""
    from app.models.models import Wave, Ripple, WaveRider, WaveHashtag, Hashtag, WaveAlert
    from app.models.models import UserAchievement

    uid = user.id

    if achievement_id == "first_wave":
        return db.query(Wave).filter(
            Wave.creator_id == uid, Wave.parent_wave_id == None  # noqa: E711
        ).count() >= 1

    if achievement_id == "50_waves":
        return db.query(Wave).filter(
            Wave.creator_id == uid, Wave.parent_wave_id == None  # noqa: E711
        ).count() >= 50

    if achievement_id == "first_ripple":
        return db.query(Ripple).filter(Ripple.user_id == uid).count() >= 1

    if achievement_id == "100_ripples_received":
        # Count ripples on waves the user created
        total = (
            db.query(func.count(Ripple.id))
            .join(Wave, Ripple.wave_id == Wave.id)
            .filter(Wave.creator_id == uid)
            .scalar() or 0
        )
        return total >= 100

    if achievement_id == "100_followers":
        count = db.query(WaveRider).filter(WaveRider.rider_of_id == uid).count()
        return count >= 100

    if achievement_id == "7_day_streak":
        # Check if the user has at least one wave on each of the past 7 calendar days
        today = datetime.now(timezone.utc).date()
        streak = True
        for delta in range(7):
            day = today - timedelta(days=delta)
            day_start = datetime(day.year, day.month, day.day, tzinfo=timezone.utc)
            day_end = day_start + timedelta(days=1)
            has_wave = db.query(Wave).filter(
                Wave.creator_id == uid,
                Wave.created_at >= day_start,
                Wave.created_at < day_end,
                Wave.parent_wave_id == None,  # noqa: E711
            ).first() is not None
            if not has_wave:
                streak = False
                break
        return streak

    if achievement_id == "early_rider":
        created = user.created_at
        if created is not None:
            if created.tzinfo is None:
                created = created.replace(tzinfo=timezone.utc)
            return created <= PLATFORM_LAUNCH_DATE + timedelta(days=30)
        return False

    if achievement_id == "trend_starter":
        # Has at least one hashtag used in 5+ different waves (proxy for "trending")
        result = (
            db.query(WaveHashtag.hashtag_id, func.count(WaveHashtag.wave_id).label("cnt"))
            .join(Wave, Wave.id == WaveHashtag.wave_id)
            .filter(Wave.creator_id == uid)
            .group_by(WaveHashtag.hashtag_id)
            .having(func.count(WaveHashtag.wave_id) >= 5)
            .first()
        )
        return result is not None

    if achievement_id == "community_builder":
        following = db.query(WaveRider).filter(WaveRider.rider_id == uid).count()
        followers = db.query(WaveRider).filter(WaveRider.rider_of_id == uid).count()
        return following >= 50 and followers >= 50

    return False


# ── Main engine ───────────────────────────────────────────────────────────────

def check_and_award_achievements(
    user: Any,
    db: Session,
    trigger: str = "all",
) -> List[Dict[str, Any]]:
    """
    Check relevant achievements for ``user`` and persist any newly earned ones.

    Returns a list of achievement dicts for every achievement unlocked for
    the FIRST time in this call (may be empty).
    """
    from app.models.models import UserAchievement

    achievement_ids = TRIGGER_MAP.get(trigger, TRIGGER_MAP["all"])

    # Load already-earned IDs in one query
    earned_ids: set = {
        row.achievement_id
        for row in db.query(UserAchievement.achievement_id)
        .filter(UserAchievement.user_id == user.id)
        .all()
    }

    newly_unlocked: List[Dict[str, Any]] = []

    for ach_id in achievement_ids:
        if ach_id in earned_ids:
            continue  # Already unlocked — skip
        if ach_id not in ACHIEVEMENT_MAP:
            continue  # Unknown achievement — skip

        try:
            if _check(ach_id, user, db):
                ua = UserAchievement(user_id=user.id, achievement_id=ach_id)
                db.add(ua)
                db.flush()  # Assign ID without full commit so caller can roll back
                meta = dict(ACHIEVEMENT_MAP[ach_id])
                meta["unlocked_at"] = ua.unlocked_at.isoformat() if ua.unlocked_at else None
                newly_unlocked.append(meta)
                logger.info("Achievement unlocked: user=%s achievement=%s", user.username, ach_id)
        except Exception as exc:
            logger.warning("Achievement check failed: %s – %s", ach_id, exc)

    if newly_unlocked:
        db.commit()

    return newly_unlocked


def get_user_achievements(user_id: str, db: Session) -> List[Dict[str, Any]]:
    """
    Return ALL achievements in the catalogue annotated with unlock status
    for the given user.  Locked achievements have ``unlocked_at`` = None.
    """
    from app.models.models import UserAchievement

    earned = {
        row.achievement_id: row.unlocked_at
        for row in db.query(UserAchievement)
        .filter(UserAchievement.user_id == user_id)
        .all()
    }

    result = []
    for meta in ACHIEVEMENT_CATALOGUE:
        entry = dict(meta)
        ua_ts = earned.get(meta["id"])
        entry["unlocked"] = meta["id"] in earned
        entry["unlocked_at"] = ua_ts.isoformat() if ua_ts else None
        result.append(entry)

    return result
