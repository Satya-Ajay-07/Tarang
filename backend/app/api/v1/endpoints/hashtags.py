from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.models.models import User, Wave, Hashtag, WaveHashtag
from app.schemas.schemas import WaveResponse
from app.api.v1.endpoints.waves import enrich_wave

router = APIRouter()

@router.get("/trending")
def get_trending_hashtags(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    limit: int = Query(10, ge=1, le=50)
):
    results = (
        db.query(Hashtag.tag, func.count(WaveHashtag.wave_id).label("count"))
        .join(WaveHashtag, Hashtag.id == WaveHashtag.hashtag_id)
        .group_by(Hashtag.id, Hashtag.tag)
        .order_by(func.count(WaveHashtag.wave_id).desc())
        .limit(limit)
        .all()
    )
    return [{"tag": r.tag, "count": r.count} for r in results]

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
