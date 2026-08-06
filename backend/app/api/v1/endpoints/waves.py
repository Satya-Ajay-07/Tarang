from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session, joinedload, selectinload
from sqlalchemy import func
from typing import List, Optional
import time
import redis
import json
import logging
from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.core.redis import get_redis
from datetime import datetime, timedelta
from app.core.exceptions import NotFoundException, BadRequestException, ForbiddenException
from app.models.models import User, Wave, Ripple, WaveAlert, WaveRider, Poll, PollOption, PollVote, Bookmark
from app.schemas.schemas import WaveCreate, WaveResponse, WaveUpdate, PollResponse, PollOptionResponse

logger = logging.getLogger("tarang")
router = APIRouter()

# Helper to enrich wave database models into WaveResponse schemas
# Helper to enrich wave database models into WaveResponse schemas in bulk
def enrich_waves_bulk(waves: List[Wave], db: Session, current_user: User, recursive: bool = True) -> List[WaveResponse]:
    if not waves:
        return []

    # 1. Fetch spread_from waves in one query (if recursive is True)
    parent_map = {}
    if recursive:
        parent_ids = list(set([w.spread_from_id for w in waves if w.spread_from_id]))
        if parent_ids:
            parent_waves = db.query(Wave).options(
                joinedload(Wave.creator),
                joinedload(Wave.poll),
                selectinload(Wave.hashtags)
            ).filter(Wave.id.in_(parent_ids)).all()
            
            # Enrich parent waves once (with recursive=False to avoid nested recursion)
            enriched_parents = enrich_waves_bulk(parent_waves, db, current_user, recursive=False)
            parent_map = {pw.id: pw for pw in enriched_parents}

    # 2. Collect all wave IDs (main + parent waves)
    all_wave_ids = list(set([w.id for w in waves] + list(parent_map.keys())))

    # 3. Fetch counts in batches
    ripples_counts = db.query(Ripple.wave_id, func.count(Ripple.user_id)).filter(Ripple.wave_id.in_(all_wave_ids)).group_by(Ripple.wave_id).all()
    ripples_map = {w_id: count for w_id, count in ripples_counts}

    joins_counts = db.query(Wave.parent_wave_id, func.count(Wave.id)).filter(Wave.parent_wave_id.in_(all_wave_ids)).group_by(Wave.parent_wave_id).all()
    joins_map = {w_id: count for w_id, count in joins_counts}

    spreads_counts = db.query(Wave.spread_from_id, func.count(Wave.id)).filter(Wave.spread_from_id.in_(all_wave_ids)).group_by(Wave.spread_from_id).all()
    spreads_map = {w_id: count for w_id, count in spreads_counts}

    # 4. Fetch user-specific statuses in batches
    rippled_by_me_raw = db.query(Ripple.wave_id).filter(Ripple.wave_id.in_(all_wave_ids), Ripple.user_id == current_user.id).all()
    rippled_set = {r[0] for r in rippled_by_me_raw}

    spread_by_me_raw = db.query(Wave.spread_from_id).filter(Wave.spread_from_id.in_(all_wave_ids), Wave.creator_id == current_user.id).all()
    spread_set = {s[0] for s in spread_by_me_raw}

    bookmarked_raw = db.query(Bookmark.wave_id).filter(Bookmark.wave_id.in_(all_wave_ids), Bookmark.user_id == current_user.id).all()
    bookmarked_set = {b[0] for b in bookmarked_raw}

    # 5. Fetch polls & votes in batches
    poll_ids = [w.poll.id for w in waves if w.poll]
    for pw in parent_map.values():
        if pw.poll:
            poll_ids.append(pw.poll.id)
            
    poll_ids = list(set(poll_ids))

    options_map = {}
    votes_count_map = {}
    my_vote_map = {}

    if poll_ids:
        options = db.query(PollOption).filter(PollOption.poll_id.in_(poll_ids)).all()
        for opt in options:
            options_map.setdefault(opt.poll_id, []).append(opt)

        votes_counts = db.query(PollVote.option_id, func.count(PollVote.user_id)).filter(PollVote.poll_id.in_(poll_ids)).group_by(PollVote.option_id).all()
        votes_count_map = {opt_id: count for opt_id, count in votes_counts}

        my_votes = db.query(PollVote.poll_id, PollVote.option_id).filter(PollVote.poll_id.in_(poll_ids), PollVote.user_id == current_user.id).all()
        my_vote_map = {poll_id: opt_id for poll_id, opt_id in my_votes}

    # 6. Map to WaveResponse list
    enriched_waves = []
    for wave in waves:
        # Resolve spread wave
        spread_from_response = parent_map.get(wave.spread_from_id) if wave.spread_from_id else None

        # Resolve poll
        poll_response = None
        if wave.poll:
            db_options = options_map.get(wave.poll.id, [])
            my_vote_option_id = my_vote_map.get(wave.poll.id)
            
            options_enriched = []
            total_votes = 0
            for opt in db_options:
                opt_votes = votes_count_map.get(opt.id, 0)
                total_votes += opt_votes
                options_enriched.append(PollOptionResponse(
                    id=opt.id,
                    poll_id=opt.poll_id,
                    text=opt.text,
                    votes_count=opt_votes,
                    voted_by_me=(my_vote_option_id == opt.id) if my_vote_option_id else False
                ))
            
            poll_response = PollResponse(
                id=wave.poll.id,
                question=wave.poll.question,
                expires_at=wave.poll.expires_at,
                options=options_enriched,
                total_votes=total_votes,
                has_voted=my_vote_option_id is not None,
                voted_option_id=my_vote_option_id
            )

        is_edited = False
        if wave.updated_at and wave.created_at:
            t1 = wave.updated_at.replace(tzinfo=None)
            t2 = wave.created_at.replace(tzinfo=None)
            if (t1 - t2).total_seconds() > 1.0:
                is_edited = True

        enriched_waves.append(WaveResponse(
            id=wave.id,
            content=wave.content,
            media_url=wave.media_url,
            media_type=wave.media_type,
            creator_id=wave.creator_id,
            creator=wave.creator,
            created_at=wave.created_at,
            parent_wave_id=wave.parent_wave_id,
            spread_from_id=wave.spread_from_id,
            spread_from=spread_from_response,
            circle_id=wave.circle_id,
            ripples_count=ripples_map.get(wave.id, 0),
            joins_count=joins_map.get(wave.id, 0),
            spreads_count=spreads_map.get(wave.id, 0),
            rippled_by_me=wave.id in rippled_set,
            spread_by_me=wave.id in spread_set,
            bookmarked_by_me=wave.id in bookmarked_set,
            poll=poll_response,
            updated_at=wave.updated_at,
            is_edited=is_edited
        ))

    return enriched_waves

def enrich_wave(wave: Wave, db: Session, current_user: User) -> WaveResponse:
    res = enrich_waves_bulk([wave], db, current_user)
    return res[0]

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

    if not wave_in.content and not wave_in.media_url and not wave_in.spread_from_id:
        raise BadRequestException(detail="Wave must have either text content, media, or be a spread.")

    # Verify parent wave if exists (Join Wave)
    if wave_in.parent_wave_id:
        parent = db.query(Wave).filter(Wave.id == wave_in.parent_wave_id).first()
        if not parent or not getattr(parent, "is_active", True):
            raise NotFoundException(detail="Parent wave not found")

    target_spread_from_id = None
    if wave_in.spread_from_id:
        original = db.query(Wave).filter(Wave.id == wave_in.spread_from_id).first()
        if not original or not getattr(original, "is_active", True):
            raise BadRequestException(detail="Original Wave is no longer available.", code="ORIGINAL_WAVE_DELETED")
        
        # Rule: No nested Quote Spreads! Always reference root.
        if original.spread_from_id:
            root_original = db.query(Wave).filter(Wave.id == original.spread_from_id).first()
            if root_original and getattr(root_original, "is_active", True):
                target_spread_from_id = root_original.id
            else:
                raise BadRequestException(detail="Original Wave is no longer available.", code="ORIGINAL_WAVE_DELETED")
        else:
            target_spread_from_id = original.id

    new_wave = Wave(
        creator_id=current_user.id,
        content=wave_in.content,
        media_url=wave_in.media_url,
        media_type=wave_in.media_type,
        parent_wave_id=wave_in.parent_wave_id,
        circle_id=wave_in.circle_id,
        spread_from_id=target_spread_from_id
    )
    db.add(new_wave)
    db.flush() # get new_wave.id before commit to link the poll

    # Handle automatic hashtag extraction
    if new_wave.content:
        import re
        from app.models.models import Hashtag
        tags = re.findall(r"#(\w+)", new_wave.content)
        unique_tags = list(set(tag.lower() for tag in tags))
        for tag in unique_tags:
            hashtag = db.query(Hashtag).filter(Hashtag.tag == tag).first()
            if not hashtag:
                hashtag = Hashtag(tag=tag)
                db.add(hashtag)
                db.flush()
            new_wave.hashtags.append(hashtag)

        # Handle automatic mention extraction and notification alert
        mentioned_usernames = re.findall(r"@(\w+)", new_wave.content)
        unique_mentions = list(set(u.lower() for u in mentioned_usernames))
        for username_lower in unique_mentions:
            mentioned_user = db.query(User).filter(func.lower(User.username) == username_lower).first()
            if mentioned_user and mentioned_user.id != current_user.id:
                alert = WaveAlert(
                    recipient_id=mentioned_user.id,
                    sender_id=current_user.id,
                    wave_id=new_wave.id,
                    type="mention",
                    content=f"{current_user.username} mentioned you in a Wave"
                )
                db.add(alert)

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
    if wave_in.parent_wave_id:
        # Re-query parent after commit to ensure it's within the current session
        parent = db.query(Wave).filter(Wave.id == wave_in.parent_wave_id).first()
        if parent and parent.creator_id != current_user.id:
            alert = WaveAlert(
                recipient_id=parent.creator_id,
                sender_id=current_user.id,
                wave_id=new_wave.id,
                type="join",
                content=f"{current_user.username} joined your Wave"
            )
            db.add(alert)
            db.commit()

    # If it is a Quote Spread, notify the root original creator
    if target_spread_from_id:
        root_wave = db.query(Wave).filter(Wave.id == target_spread_from_id).first()
        if root_wave and root_wave.creator_id != current_user.id:
            preview = ""
            if wave_in.content:
                truncated = wave_in.content[:60]
                if len(wave_in.content) > 60:
                    truncated += "..."
                preview = f' "{truncated}"'
            alert = WaveAlert(
                recipient_id=root_wave.creator_id,
                sender_id=current_user.id,
                wave_id=new_wave.id,
                type="spread",
                content=f"{current_user.username} spread your Wave.{preview}"
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
    start_total = time.perf_counter()

    query = db.query(Wave).options(
        joinedload(Wave.creator),
        joinedload(Wave.poll),
        selectinload(Wave.hashtags)
    ).filter(Wave.parent_wave_id == None)

    # Load followings/riding IDs for scoring boost
    riding_ids = [r[0] for r in db.query(WaveRider.rider_of_id).filter(WaveRider.rider_id == current_user.id).all()]
    riding_ids.append(current_user.id) # Include own

    if stream_type == "riding":
        query = query.filter(Wave.creator_id.in_(riding_ids))

    start_db = time.perf_counter()
    # Fetch larger candidate pool of waves to rank
    waves = query.order_by(Wave.created_at.desc()).limit(150).all()
    db_time = (time.perf_counter() - start_db) * 1000

    start_enrich = time.perf_counter()
    enriched = enrich_waves_bulk(waves, db, current_user)
    
    # Calculate scores for each enriched wave response
    scored_waves = []
    for w in enriched:
        # Time age in hours
        age_in_hours = (datetime.utcnow() - w.created_at.replace(tzinfo=None)).total_seconds() / 3600.0
        
        # Interactions sum (signals: ripples, joins, spreads, bookmarks)
        interaction_score = (w.ripples_count * 1.5) + (w.joins_count * 2.0) + (w.spreads_count * 2.5)
        if w.bookmarked_by_me:
            interaction_score += 3.0
            
        # Following relationship boost
        following_boost = 3.0 if w.creator_id in riding_ids else 0.0
        
        # Time decay denominator formula
        time_decay = 1.0 / ((age_in_hours + 2.0) ** 1.8)
        
        # Compute final trending score
        score = (1.0 + interaction_score + following_boost) * time_decay
        scored_waves.append((w, score))
        
    # Sort waves list by score descending
    scored_waves.sort(key=lambda x: x[1], reverse=True)
    
    # Apply pagination offset slices
    paged_waves = [sw[0] for sw in scored_waves[skip:skip+limit]]
    enrich_time = (time.perf_counter() - start_enrich) * 1000

    total_time = (time.perf_counter() - start_total) * 1000
    logger.info(
        "get_wave_stream scored performance: db_time=%.2fms, enrichment_time=%.2fms, total_time=%.2fms",
        db_time,
        enrich_time,
        total_time
    )
    return paged_waves

# Rising Waves (Trending)
@router.get("/rising", response_model=List[WaveResponse])
def get_rising_waves(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    redis_client: redis.Redis = Depends(get_redis),
    limit: int = 10
):
    start_total = time.perf_counter()
    cache_key = "cache:waves:rising_ids"
    cached_ids = redis_client.get(cache_key)
    
    if cached_ids:
        # Cache hit: parse list of wave IDs
        wave_ids = json.loads(cached_ids)
        # Fetch waves in that order
        start_db = time.perf_counter()
        waves = db.query(Wave).options(
            joinedload(Wave.creator),
            joinedload(Wave.poll),
            selectinload(Wave.hashtags)
        ).filter(Wave.id.in_(wave_ids)).all()
        db_time = (time.perf_counter() - start_db) * 1000

        # Sort waves to match original cached ordering
        wave_map = {w.id: w for w in waves}
        sorted_waves = [wave_map[wid] for wid in wave_ids if wid in wave_map]
        
        start_enrich = time.perf_counter()
        enriched = enrich_waves_bulk(sorted_waves, db, current_user)
        enrich_time = (time.perf_counter() - start_enrich) * 1000
    else:
        # Cache miss: query database
        start_db = time.perf_counter()
        raw_waves = db.query(Wave).options(
            joinedload(Wave.creator),
            joinedload(Wave.poll),
            selectinload(Wave.hashtags)
        ).filter(Wave.parent_wave_id == None).order_by(Wave.created_at.desc()).limit(30).all()
        db_time = (time.perf_counter() - start_db) * 1000

        # Enrich and sort
        start_enrich = time.perf_counter()
        enriched_temp = enrich_waves_bulk(raw_waves, db, current_user)
        enriched_temp.sort(key=lambda x: (x.ripples_count + x.joins_count + x.spreads_count), reverse=True)
        enriched = enriched_temp[:limit]
        enrich_time = (time.perf_counter() - start_enrich) * 1000
        
        # Save IDs to redis
        wave_ids = [tw.id for tw in enriched]
        redis_client.setex(cache_key, 60, json.dumps(wave_ids))

    total_time = (time.perf_counter() - start_total) * 1000
    logger.info(
        "get_rising_waves performance: db_time=%.2fms, enrichment_time=%.2fms, total_time=%.2fms",
        db_time,
        enrich_time,
        total_time
    )
    return enriched[:limit]

@router.get("/bookmarks", response_model=List[WaveResponse])
def get_bookmarks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    start_total = time.perf_counter()
    start_db = time.perf_counter()
    bookmarks = db.query(Bookmark).filter(Bookmark.user_id == current_user.id).order_by(Bookmark.created_at.desc()).all()
    wave_ids = [b.wave_id for b in bookmarks]
    waves = db.query(Wave).options(
        joinedload(Wave.creator),
        joinedload(Wave.poll),
        selectinload(Wave.hashtags)
    ).filter(Wave.id.in_(wave_ids)).all()
    db_time = (time.perf_counter() - start_db) * 1000

    # Preserve order
    wave_map = {w.id: w for w in waves}
    ordered_waves = [wave_map[wid] for wid in wave_ids if wid in wave_map]
    
    start_enrich = time.perf_counter()
    enriched = enrich_waves_bulk(ordered_waves, db, current_user)
    enrich_time = (time.perf_counter() - start_enrich) * 1000

    total_time = (time.perf_counter() - start_total) * 1000
    logger.info(
        "get_bookmarks performance: db_time=%.2fms, enrichment_time=%.2fms, total_time=%.2fms",
        db_time,
        enrich_time,
        total_time
    )
    return enriched

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
    start_total = time.perf_counter()
    start_db = time.perf_counter()
    joins = db.query(Wave).options(
        joinedload(Wave.creator),
        joinedload(Wave.poll),
        selectinload(Wave.hashtags)
    ).filter(Wave.parent_wave_id == wave_id).order_by(Wave.created_at.asc()).offset(skip).limit(limit).all()
    db_time = (time.perf_counter() - start_db) * 1000

    start_enrich = time.perf_counter()
    enriched = enrich_waves_bulk(joins, db, current_user)
    enrich_time = (time.perf_counter() - start_enrich) * 1000

    total_time = (time.perf_counter() - start_total) * 1000
    logger.info(
        "get_wave_joins performance: db_time=%.2fms, enrichment_time=%.2fms, total_time=%.2fms",
        db_time,
        enrich_time,
        total_time
    )
    return enriched

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
        # Update hashtags
        wave.hashtags.clear()
        import re
        from app.models.models import Hashtag
        tags = re.findall(r"#(\w+)", wave.content)
        unique_tags = list(set(tag.lower() for tag in tags))
        for tag in unique_tags:
            hashtag = db.query(Hashtag).filter(Hashtag.tag == tag).first()
            if not hashtag:
                hashtag = Hashtag(tag=tag)
                db.add(hashtag)
                db.flush()
            wave.hashtags.append(hashtag)

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
    logger.info("Wave report: user=%s wave=%s reason=%s", current_user.username, wave_id, reason)
    return {"message": "Wave reported successfully", "wave_id": wave_id, "reason": reason}

