from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
import math
from datetime import datetime, timedelta, timezone
from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.models.models import User, Wave, Hashtag, WaveHashtag, Ripple
from app.schemas.schemas import WaveResponse
from app.api.v1.endpoints.waves import enrich_wave

router = APIRouter()

def _trending_category(score: float, created_hours: float) -> str:
    """Classify a trending topic into a category based on score and recency."""
    if created_hours < 6 and score > 5:
        return "trending_now"
    elif created_hours < 48 and score > 2:
        return "rising"
    else:
        return "popular_this_week"

@router.get("/trending")
def get_trending_hashtags(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    limit: int = Query(15, ge=1, le=50)
):
    """
    Return trending hashtags scored by: wave count + ripple count, with Hacker News-style
    time decay penalising older topics. Each result includes category classification.
    """
    now = datetime.now(timezone.utc)
    window = now - timedelta(days=7)

    # Subquery: per-hashtag wave IDs in the last 7 days
    recent_wave_counts = (
        db.query(
            WaveHashtag.hashtag_id,
            func.count(WaveHashtag.wave_id).label("wave_count")
        )
        .join(Wave, Wave.id == WaveHashtag.wave_id)
        .filter(Wave.created_at >= window)
        .group_by(WaveHashtag.hashtag_id)
        .subquery()
    )

    results = (
        db.query(
            Hashtag.tag,
            func.coalesce(recent_wave_counts.c.wave_count, 0).label("wave_count"),
        )
        .outerjoin(recent_wave_counts, Hashtag.id == recent_wave_counts.c.hashtag_id)
        .filter(func.coalesce(recent_wave_counts.c.wave_count, 0) > 0)
        .order_by(func.coalesce(recent_wave_counts.c.wave_count, 0).desc())
        .limit(limit * 3)  # Over-fetch so we can re-sort after scoring
        .all()
    )

    # Enrich with ripple counts and apply time decay scoring
    scored = []
    for r in results:
        tag_str = r.tag
        wave_count = r.wave_count or 0

        # Fetch ripple sum for waves with this hashtag in the window
        ripple_sum = (
            db.query(func.count(Ripple.id))
            .join(Wave, Ripple.wave_id == Wave.id)
            .join(WaveHashtag, WaveHashtag.wave_id == Wave.id)
            .join(Hashtag, Hashtag.id == WaveHashtag.hashtag_id)
            .filter(Hashtag.tag == tag_str, Wave.created_at >= window)
            .scalar() or 0
        )

        # Weighted engagement score
        engagement = wave_count * 1.0 + ripple_sum * 1.5

        # Hacker News gravity: score / (hours_since_oldest_wave + 2)^1.5
        # Use oldest wave creation as the age anchor
        oldest_wave = (
            db.query(func.min(Wave.created_at))
            .join(WaveHashtag, WaveHashtag.wave_id == Wave.id)
            .join(Hashtag, Hashtag.id == WaveHashtag.hashtag_id)
            .filter(Hashtag.tag == tag_str, Wave.created_at >= window)
            .scalar()
        )
        if oldest_wave:
            # Make timezone-aware if naive
            if oldest_wave.tzinfo is None:
                oldest_wave = oldest_wave.replace(tzinfo=timezone.utc)
            age_hours = max((now - oldest_wave).total_seconds() / 3600, 0.5)
        else:
            age_hours = 24

        trending_score = engagement / math.pow(age_hours + 2, 1.5)
        category = _trending_category(trending_score, age_hours)

        scored.append({
            "tag": tag_str,
            "count": wave_count,
            "ripples": ripple_sum,
            "score": round(trending_score, 4),
            "category": category,
        })

    # Sort by computed trending score
    scored.sort(key=lambda x: x["score"], reverse=True)
    return scored[:limit]

@router.get("/search")
def search_hashtags(
    q: str = Query(..., min_length=1),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    limit: int = Query(10, ge=1, le=50)
):
    query_str = q.lower().lstrip("#")
    results = (
        db.query(Hashtag.tag, func.count(WaveHashtag.wave_id).label("count"))
        .outerjoin(WaveHashtag, Hashtag.id == WaveHashtag.hashtag_id)
        .filter(Hashtag.tag.ilike(f"%{query_str}%"))
        .group_by(Hashtag.id, Hashtag.tag)
        .order_by(func.count(WaveHashtag.wave_id).desc())
        .limit(limit)
        .all()
    )
    return [{"tag": r.tag, "count": r.count} for r in results]

@router.get("/{tag}/waves", response_model=List[WaveResponse])
def get_waves_by_hashtag(
    tag: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    normalized_tag = tag.lower().lstrip("#")
    hashtag = db.query(Hashtag).filter(Hashtag.tag == normalized_tag).first()
    if not hashtag:
        return []

    waves = (
        db.query(Wave)
        .join(WaveHashtag, Wave.id == WaveHashtag.wave_id)
        .filter(WaveHashtag.hashtag_id == hashtag.id)
        .order_by(Wave.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [enrich_wave(w, db, current_user) for w in waves]
