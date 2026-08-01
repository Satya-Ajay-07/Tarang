from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.models.models import User, Wave, WaveCircle, Ripple, WaveRider

router = APIRouter()


# ── Suggested Riders ──────────────────────────────────────────────────────────
# Declared BEFORE the catch-all "" route to prevent FastAPI matching
# /suggested-riders as the "q" query param of the search handler.

@router.get("/suggested-riders")
def suggested_riders(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    limit: int = 5,
):
    """Return users that the current user is NOT yet riding with."""
    already_riding_ids = [
        r[0] for r in db.query(WaveRider.rider_of_id)
        .filter(WaveRider.rider_id == current_user.id)
        .all()
    ]
    already_riding_ids.append(current_user.id)

    suggestions = (
        db.query(User)
        .filter(User.id.not_in(already_riding_ids))
        .limit(limit)
        .all()
    )
    return [
        {
            "id": u.id,
            "username": u.username,
            "full_name": u.full_name,
            "avatar_url": u.avatar_url,
            "bio": u.bio,
        }
        for u in suggestions
    ]


# ── Global Search ─────────────────────────────────────────────────────────────

@router.get("")
def search(
    q: str = Query(..., min_length=1, description="Search query"),
    kind: Optional[str] = Query("all", description="Filter: all | people | waves | circles"),
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Global search across people (username/full_name), waves (content), and wave circles (name).
    Returns highlighted snippets so the frontend can emphasise the matched term.
    """
    results: dict = {"people": [], "waves": [], "circles": [], "query": q}

    if kind in ("all", "people"):
        people = (
            db.query(User)
            .filter(
                (User.username.ilike(f"%{q}%")) | (User.full_name.ilike(f"%{q}%"))
            )
            .filter(User.id != current_user.id)
            .offset(skip)
            .limit(limit)
            .all()
        )
        results["people"] = [
            {
                "id": u.id,
                "username": u.username,
                "full_name": u.full_name,
                "avatar_url": u.avatar_url,
                "bio": u.bio,
                "is_riding": db.query(WaveRider).filter(
                    WaveRider.rider_id == current_user.id,
                    WaveRider.rider_of_id == u.id,
                ).first() is not None,
            }
            for u in people
        ]

    if kind in ("all", "waves"):
        waves = (
            db.query(Wave)
            .filter(Wave.content.ilike(f"%{q}%"), Wave.parent_wave_id == None)
            .order_by(Wave.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        results["waves"] = [
            {
                "id": w.id,
                "content": w.content,
                "media_url": w.media_url,
                "creator_id": w.creator_id,
                "created_at": w.created_at.isoformat(),
                "ripples_count": db.query(Ripple).filter(Ripple.wave_id == w.id).count(),
            }
            for w in waves
        ]

    if kind in ("all", "circles"):
        circles = (
            db.query(WaveCircle)
            .filter(
                (WaveCircle.name.ilike(f"%{q}%")) | (WaveCircle.description.ilike(f"%{q}%"))
            )
            .offset(skip)
            .limit(limit)
            .all()
        )
        results["circles"] = [
            {
                "id": c.id,
                "name": c.name,
                "slug": c.slug,
                "description": c.description,
                "banner_url": c.banner_url,
            }
            for c in circles
        ]

    return results

