from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
import redis
import json
from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.core.redis import get_redis
from datetime import datetime, timedelta
from app.core.exceptions import NotFoundException, BadRequestException, ForbiddenException
from app.models.models import User, Wave, Ripple, WaveAlert, WaveRider, Poll, PollOption, PollVote, Bookmark
from app.schemas.schemas import WaveCreate, WaveResponse, WaveUpdate, PollResponse, PollOptionResponse

router = APIRouter()

# Helper to enrich wave database models into WaveResponse schemas
def enrich_wave(wave: Wave, db: Session, current_user: User) -> WaveResponse:
    # Ripple status
    rippled_by_me = db.query(Ripple).filter(
        Ripple.user_id == current_user.id,
        Ripple.wave_id == wave.id
    ).first() is not None
    
    # Counts
    ripples_count = db.query(Ripple).filter(Ripple.wave_id == wave.id).count()
    joins_count = db.query(Wave).filter(Wave.parent_wave_id == wave.id).count()
    spreads_count = db.query(Wave).filter(Wave.spread_from_id == wave.id).count()
    
    # Spread status
    spread_by_me = db.query(Wave).filter(
        Wave.creator_id == current_user.id,
        Wave.spread_from_id == wave.id
    ).first() is not None

    # Bookmark status
    bookmarked_by_me = db.query(Bookmark).filter(
        Bookmark.user_id == current_user.id,
        Bookmark.wave_id == wave.id
    ).first() is not None

    # Spread Wave resolution
    spread_from = None
    if wave.spread_from_id:
        parent = db.query(Wave).filter(Wave.id == wave.spread_from_id).first()
        if parent:
            spread_from = enrich_wave(parent, db, current_user)

    # Poll enrichment
    poll_response = None
    if wave.poll:
        # Fetch options
        db_options = db.query(PollOption).filter(PollOption.poll_id == wave.poll.id).all()
        
        # Check current user's vote
        my_vote = db.query(PollVote).filter(
            PollVote.poll_id == wave.poll.id,
            PollVote.user_id == current_user.id
        ).first()
        
        options_enriched = []
        total_votes = 0
        
        for opt in db_options:
            opt_votes = db.query(PollVote).filter(PollVote.option_id == opt.id).count()
            total_votes += opt_votes
            
            options_enriched.append(PollOptionResponse(
                id=opt.id,
                poll_id=opt.poll_id,
                text=opt.text,
                votes_count=opt_votes,
                voted_by_me=(my_vote.option_id == opt.id) if my_vote else False
            ))
            
        poll_response = PollResponse(
            id=wave.poll.id,
            question=wave.poll.question,
            expires_at=wave.poll.expires_at,
            options=options_enriched,
            total_votes=total_votes,
            has_voted=my_vote is not None,
            voted_option_id=my_vote.option_id if my_vote else None
        )

    return WaveResponse(
        id=wave.id,
        content=wave.content,
        media_url=wave.media_url,
        media_type=wave.media_type,
        creator_id=wave.creator_id,
        creator=wave.creator,
        created_at=wave.created_at,
        parent_wave_id=wave.parent_wave_id,
        spread_from_id=wave.spread_from_id,
        spread_from=spread_from,
        circle_id=wave.circle_id,
        ripples_count=ripples_count,
        joins_count=joins_count,
        spreads_count=spreads_count,
        rippled_by_me=rippled_by_me,
        spread_by_me=spread_by_me,
        bookmarked_by_me=bookmarked_by_me,
        poll=poll_response
    )

# Create Wave (Post / Comment / Join)
@router.post("", response_model=WaveResponse, status_code=status.HTTP_201_CREATED)
def create_wave(
    wave_in: WaveCreate,
    db: Session = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis),
    current_user: User = Depends(get_current_active_user)
):
    # Rate Limiting: max 5 waves per 60 seconds per user
    rate_key = f"rate_limit:waves:{current_user.id}"
    current = redis_client.get(rate_key)
    if current and int(current) >= 5:
        raise BadRequestException(detail="You are creating waves too quickly. Please wait a minute.", code="RATE_LIMIT_EXCEEDED")
    
    pipe = redis_client.pipeline()
    pipe.incr(rate_key)
    pipe.expire(rate_key, 60)
    pipe.execute()

    if not wave_in.content and not wave_in.media_url:
        raise BadRequestException(detail="Wave must have either text content or media.")

    # Verify parent wave if exists (Join Wave)
    if wave_in.parent_wave_id:
        parent = db.query(Wave).filter(Wave.id == wave_in.parent_wave_id).first()
        if not parent:
            raise NotFoundException(detail="Parent wave not found")

    new_wave = Wave(
        creator_id=current_user.id,
        content=wave_in.content,
        media_url=wave_in.media_url,
        media_type=wave_in.media_type,
        parent_wave_id=wave_in.parent_wave_id,
        circle_id=wave_in.circle_id
    )
    db.add(new_wave)
    db.flush() # get new_wave.id before commit to link the poll

    # Handle Poll attachment
    if wave_in.poll:
        expires_at = datetime.utcnow() + timedelta(hours=wave_in.poll.expires_in_hours)
        db_poll = Poll(
            wave_id=new_wave.id,
            question=wave_in.poll.question,
            expires_at=expires_at
        )
        db.add(db_poll)
        db.flush() # get db_poll.id for options

        for opt_in in wave_in.poll.options:
            db_option = PollOption(
                poll_id=db_poll.id,
                text=opt_in.text
            )
            db.add(db_option)
            
    db.commit()
    db.refresh(new_wave)

    # If it is a Join Wave, notify the parent creator
    if wave_in.parent_wave_id and parent.creator_id != current_user.id:
        alert = WaveAlert(
            recipient_id=parent.creator_id,
            sender_id=current_user.id,
            wave_id=new_wave.id,
            type="join",
            content=f"{current_user.username} joined your Wave"
        )
        db.add(alert)
        db.commit()

    return enrich_wave(new_wave, db, current_user)

# Ocean / Wave Stream (Home Feed)
@router.get("", response_model=List[WaveResponse])
def get_wave_stream(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    skip: int = 0,
    limit: int = 20,
    stream_type: str = Query("all", description="'all' for global, 'riding' for followings")
):
    query = db.query(Wave).filter(Wave.parent_wave_id == None)

    if stream_type == "riding":
        # Filter by people user rides with (follows)
        riding_ids = db.query(WaveRider.rider_of_id).filter(WaveRider.rider_id == current_user.id).all()
        riding_ids = [r[0] for r in riding_ids]
        riding_ids.append(current_user.id) # Include own waves
        query = query.filter(Wave.creator_id.in_(riding_ids))

    waves = query.order_by(Wave.created_at.desc()).offset(skip).limit(limit).all()
    return [enrich_wave(w, db, current_user) for w in waves]

# Rising Waves (Trending)
@router.get("/rising", response_model=List[WaveResponse])
def get_rising_waves(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    redis_client: redis.Redis = Depends(get_redis),
    limit: int = 10
):
    cache_key = "cache:waves:rising_ids"
    cached_ids = redis_client.get(cache_key)
    
    if cached_ids:
        # Cache hit: parse list of wave IDs
        wave_ids = json.loads(cached_ids)
        # Fetch waves in that order
        waves = db.query(Wave).filter(Wave.id.in_(wave_ids)).all()
        # Sort waves to match original cached ordering
        wave_map = {w.id: w for w in waves}
        sorted_waves = [wave_map[wid] for wid in wave_ids if wid in wave_map]
    else:
        # Cache miss: query database
        raw_waves = db.query(Wave).filter(Wave.parent_wave_id == None).order_by(Wave.created_at.desc()).limit(30).all()
        # Enrich and sort
        enriched_temp = [enrich_wave(w, db, current_user) for w in raw_waves]
        enriched_temp.sort(key=lambda x: (x.ripples_count + x.joins_count + x.spreads_count), reverse=True)
        top_waves = enriched_temp[:limit]
        
        # Save IDs to redis
        wave_ids = [tw.id for tw in top_waves]
        redis_client.setex(cache_key, 60, json.dumps(wave_ids))
        return top_waves

    return [enrich_wave(w, db, current_user) for w in sorted_waves][:limit]

# Get single wave details
@router.get("/{wave_id}", response_model=WaveResponse)
def get_wave(
    wave_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    wave = db.query(Wave).filter(Wave.id == wave_id).first()
    if not wave:
        raise NotFoundException(detail="Wave not found")
    return enrich_wave(wave, db, current_user)

# Join Waves (Comments) listing for a specific Wave
@router.get("/{wave_id}/joins", response_model=List[WaveResponse])
def get_wave_joins(
    wave_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    skip: int = 0,
    limit: int = 50
):
    joins = db.query(Wave).filter(Wave.parent_wave_id == wave_id).order_by(Wave.created_at.asc()).offset(skip).limit(limit).all()
    return [enrich_wave(j, db, current_user) for j in joins]

# Ripple / Un-ripple wave (Like toggle)
@router.post("/{wave_id}/ripple")
def toggle_ripple(
    wave_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    wave = db.query(Wave).filter(Wave.id == wave_id).first()
    if not wave:
        raise NotFoundException(detail="Wave not found")

    ripple = db.query(Ripple).filter(
        Ripple.user_id == current_user.id,
        Ripple.wave_id == wave_id
    ).first()

    if ripple:
        db.delete(ripple)
        db.commit()
        return {"rippled": False, "ripples_count": db.query(Ripple).filter(Ripple.wave_id == wave_id).count()}
    else:
        new_ripple = Ripple(user_id=current_user.id, wave_id=wave_id)
        db.add(new_ripple)
        
        # Create alert if owner is not sender
        if wave.creator_id != current_user.id:
            alert = WaveAlert(
                recipient_id=wave.creator_id,
                sender_id=current_user.id,
                wave_id=wave.id,
                type="ripple",
                content=f"{current_user.username} rippled your Wave"
            )
            db.add(alert)
        db.commit()
        return {"rippled": True, "ripples_count": db.query(Ripple).filter(Ripple.wave_id == wave_id).count()}

# Spread Wave (Repost / Retweet)
@router.post("/{wave_id}/spread")
def spread_wave(
    wave_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    wave = db.query(Wave).filter(Wave.id == wave_id).first()
    if not wave:
        raise NotFoundException(detail="Wave not found")

    # Prevent duplicating spread
    # Check if user already spread this wave
    existing_spread = db.query(Wave).filter(
        Wave.creator_id == current_user.id,
        Wave.spread_from_id == wave_id
    ).first()

    # Undo spread
    if existing_spread:
        db.delete(existing_spread)
        db.commit()
        # Refresh the parent wave object inside Session to get updated count
        db.refresh(wave)
        enriched = enrich_wave(wave, db, current_user)
        # We can add an extra flag so the frontend knows it was removed
        return {
            "spread": False,
            "wave": enriched
        }

    spread = Wave(
        creator_id=current_user.id,
        spread_from_id=wave_id
    )
    db.add(spread)

    # Create alert for wave spread
    if wave.creator_id != current_user.id:
        alert = WaveAlert(
            recipient_id=wave.creator_id,
            sender_id=current_user.id,
            wave_id=wave.id,
            type="spread",
            content=f"{current_user.username} spread your Wave"
        )
        db.add(alert)
        
    db.commit()
    db.refresh(wave)
    enriched = enrich_wave(wave, db, current_user)
    return {
        "spread": True,
        "wave": enriched
    }

# Update Wave
@router.put("/{wave_id}", response_model=WaveResponse)
def update_wave(
    wave_id: str,
    wave_update: WaveUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    wave = db.query(Wave).filter(Wave.id == wave_id).first()
    if not wave:
        raise NotFoundException(detail="Wave not found")
        
    if wave.creator_id != current_user.id:
        raise ForbiddenException(detail="You are not authorized to update this Wave")

    if wave_update.content is not None:
        wave.content = wave_update.content
    if wave_update.media_url is not None:
        wave.media_url = wave_update.media_url
    if wave_update.media_type is not None:
        wave.media_type = wave_update.media_type

    db.commit()
    db.refresh(wave)
    return enrich_wave(wave, db, current_user)

# Delete Wave
@router.delete("/{wave_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_wave(
    wave_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    wave = db.query(Wave).filter(Wave.id == wave_id).first()
    if not wave:
        raise NotFoundException(detail="Wave not found")

    if wave.creator_id != current_user.id:
        raise ForbiddenException(detail="You are not authorized to delete this Wave")

    db.delete(wave)
    db.commit()
    return None

# Vote in a poll option
@router.post("/{wave_id}/poll/vote/{option_id}", response_model=WaveResponse)
def vote_poll(
    wave_id: str,
    option_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    wave = db.query(Wave).filter(Wave.id == wave_id).first()
    if not wave:
        raise NotFoundException(detail="Wave not found")
        
    if not wave.poll:
        raise BadRequestException(detail="This Wave does not have a poll")
        
    if wave.poll.expires_at < datetime.utcnow():
        raise BadRequestException(detail="This poll has expired")

    # Verify option belongs to the poll
    option = db.query(PollOption).filter(
        PollOption.id == option_id,
        PollOption.poll_id == wave.poll.id
    ).first()
    if not option:
        raise NotFoundException(detail="Poll option not found")

    # Check for existing vote
    existing_vote = db.query(PollVote).filter(
        PollVote.poll_id == wave.poll.id,
        PollVote.user_id == current_user.id
    ).first()
    if existing_vote:
        raise BadRequestException(detail="You have already voted in this poll")

    # Cast vote
    vote = PollVote(
        poll_id=wave.poll.id,
        option_id=option_id,
        user_id=current_user.id
    )
    db.add(vote)
    db.commit()
    db.refresh(wave)
    return enrich_wave(wave, db, current_user)

# Report Wave
@router.post("/{wave_id}/report")
def report_wave(
    wave_id: str,
    payload: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    wave = db.query(Wave).filter(Wave.id == wave_id).first()
    if not wave:
        raise NotFoundException(detail="Wave not found")
    
    reason = payload.get("reason", "Other")
    print(f"[Tarang Report] User {current_user.username} reported Wave {wave_id} for: {reason}")
    return {"message": "Wave reported successfully", "wave_id": wave_id, "reason": reason}

# Retrieve bookmarked waves
@router.get("/bookmarks", response_model=List[WaveResponse])
def get_bookmarks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    bookmarks = db.query(Bookmark).filter(Bookmark.user_id == current_user.id).order_by(Bookmark.created_at.desc()).all()
    wave_ids = [b.wave_id for b in bookmarks]
    waves = db.query(Wave).filter(Wave.id.in_(wave_ids)).all()
    # Preserve order
    wave_map = {w.id: w for w in waves}
    ordered_waves = [wave_map[wid] for wid in wave_ids if wid in wave_map]
    return [enrich_wave(w, db, current_user) for w in ordered_waves]

# Add a bookmark
@router.post("/{wave_id}/bookmark")
def add_bookmark(
    wave_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    wave = db.query(Wave).filter(Wave.id == wave_id).first()
    if not wave:
        raise NotFoundException(detail="Wave not found")
        
    existing_bookmark = db.query(Bookmark).filter(
        Bookmark.user_id == current_user.id,
        Bookmark.wave_id == wave_id
    ).first()
    if existing_bookmark:
        return {"message": "Wave already bookmarked", "bookmarked": True}
        
    new_bookmark = Bookmark(user_id=current_user.id, wave_id=wave_id)
    db.add(new_bookmark)
    db.commit()
    return {"message": "Wave bookmarked successfully", "bookmarked": True}

# Delete a bookmark
@router.delete("/{wave_id}/bookmark")
def delete_bookmark(
    wave_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    bookmark = db.query(Bookmark).filter(
        Bookmark.user_id == current_user.id,
        Bookmark.wave_id == wave_id
    ).first()
    if not bookmark:
        raise NotFoundException(detail="Bookmark not found")
        
    db.delete(bookmark)
    db.commit()
    return {"message": "Bookmark removed successfully", "bookmarked": False}


