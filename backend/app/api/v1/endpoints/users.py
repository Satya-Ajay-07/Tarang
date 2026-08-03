from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import List, Optional
from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.core.exceptions import NotFoundException, BadRequestException
from app.models.models import User, Wave, WaveRider, WaveAlert
from app.schemas.schemas import UserResponse, UserUpdate, ChangePasswordRequest, DeactivateAccountRequest
from app.services.users import delete_user
from app.core.redis import get_redis
import redis

router = APIRouter()

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_active_user)):
    return current_user

@router.put("/me", response_model=UserResponse)
def update_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    # Update fields
    if user_update.full_name is not None:
        current_user.full_name = user_update.full_name
    if user_update.bio is not None:
        current_user.bio = user_update.bio
    if user_update.location is not None:
        current_user.location = user_update.location
    if user_update.avatar_url is not None:
        current_user.avatar_url = user_update.avatar_url
    if user_update.cover_url is not None:
        current_user.cover_url = user_update.cover_url
    if user_update.country is not None:
        current_user.country = user_update.country
    if user_update.phone_number is not None:
        current_user.phone_number = user_update.phone_number
    if user_update.website is not None:
        current_user.website = user_update.website
    if user_update.twitter_url is not None:
        current_user.twitter_url = user_update.twitter_url
    if user_update.github_url is not None:
        current_user.github_url = user_update.github_url
    if user_update.pinned_wave_id is not None:
        # Pinned wave id can be set to empty string or null to unpin
        current_user.pinned_wave_id = None if user_update.pinned_wave_id == "" else user_update.pinned_wave_id
        
    db.commit()
    db.refresh(current_user)
    return current_user

# Get specific profile by username
@router.get("/profile/{username}", response_model=dict)
def get_profile(
    username: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    user = db.query(User).filter(User.username == username).first()
    if not user or getattr(user, "is_deactivated", False):
        raise NotFoundException(detail="Rider profile not found")
        
    # Get stats
    wave_count = db.query(Wave).filter(Wave.creator_id == user.id, Wave.parent_wave_id == None).count()
    riders_count = db.query(WaveRider).filter(WaveRider.rider_of_id == user.id).count()
    riding_count = db.query(WaveRider).filter(WaveRider.rider_id == user.id).count()
    
    # Check if followed by current user
    is_riding = db.query(WaveRider).filter(
        WaveRider.rider_id == current_user.id,
        WaveRider.rider_of_id == user.id
    ).first() is not None

    # Calculate mutual followers
    # Users who follow "user" AND are followed by "current_user"
    followers_of_user = db.query(WaveRider.rider_id).filter(WaveRider.rider_of_id == user.id).subquery()
    mutuals = db.query(User).join(
        WaveRider, WaveRider.rider_of_id == User.id
    ).filter(
        WaveRider.rider_id == current_user.id,
        User.id.in_(followers_of_user)
    ).all()
    mutual_riders = [{"id": m.id, "username": m.username, "full_name": m.full_name, "avatar_url": m.avatar_url} for m in mutuals]

    return {
        "id": user.id,
        "username": user.username,
        "full_name": user.full_name,
        "avatar_url": user.avatar_url,
        "cover_url": user.cover_url,
        "bio": user.bio,
        "location": user.location,
        "country": user.country,
        "phone_number": user.phone_number if user.id == current_user.id else None,
        "website": user.website,
        "twitter_url": user.twitter_url,
        "github_url": user.github_url,
        "pinned_wave_id": user.pinned_wave_id,
        "created_at": user.created_at,
        "role": user.role,
        "wave_count": wave_count,
        "riders_count": riders_count,
        "riding_count": riding_count,
        "is_riding": is_riding,
        "mutual_riders": mutual_riders,
        "mutual_count": len(mutual_riders)
    }

# Follow/Unfollow (Riding Toggle)
@router.post("/ride/{user_id}")
def toggle_ride(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    if user_id == current_user.id:
        raise BadRequestException(detail="You cannot ride your own wave (follow yourself)")

    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise NotFoundException(detail="Target rider not found")

    rider_rel = db.query(WaveRider).filter(
        WaveRider.rider_id == current_user.id,
        WaveRider.rider_of_id == user_id
    ).first()

    if rider_rel:
        # Unfollow
        db.delete(rider_rel)
        db.commit()
        return {"riding": False, "message": f"You stopped riding with {target_user.username}"}
    else:
        # Follow
        new_rider = WaveRider(rider_id=current_user.id, rider_of_id=user_id)
        db.add(new_rider)
        
        # Create alert for follow event
        alert = WaveAlert(
            recipient_id=user_id,
            sender_id=current_user.id,
            type="follow",
            content=f"{current_user.username} started riding with you"
        )
        db.add(alert)
        db.commit()
        return {"riding": True, "message": f"You are now riding with {target_user.username}"}

# List followers (riders)
@router.get("/{user_id}/riders", response_model=List[UserResponse])
def get_riders(
    user_id: str,
    db: Session = Depends(get_db)
):
    riders = db.query(User).join(
        WaveRider, WaveRider.rider_id == User.id
    ).filter(WaveRider.rider_of_id == user_id).all()
    return riders

# List following (riding)
@router.get("/{user_id}/riding", response_model=List[UserResponse])
def get_riding(
    user_id: str,
    db: Session = Depends(get_db)
):
    riding = db.query(User).join(
        WaveRider, WaveRider.rider_of_id == User.id
    ).filter(WaveRider.rider_id == user_id).all()
    return riding

# Account Settings
from app.core import security
from datetime import datetime

@router.post("/change-password", status_code=status.HTTP_200_OK)
def change_password(
    req: ChangePasswordRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if not security.verify_password(req.current_password, current_user.hashed_password):
        raise BadRequestException(detail="Incorrect current password", code="PASSWORD_INCORRECT")
    
    if len(req.new_password) < 8:
        raise BadRequestException(detail="New password must be at least 8 characters long", code="PASSWORD_TOO_SHORT")

    current_user.hashed_password = security.get_password_hash(req.new_password)
    db.commit()
    return {"success": True, "message": "Password changed successfully."}

@router.post("/deactivate", status_code=status.HTTP_200_OK)
def deactivate_my_account(
    req: DeactivateAccountRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis)
):
    if not security.verify_password(req.password, current_user.hashed_password):
        raise BadRequestException(detail="Incorrect password confirmation", code="PASSWORD_INCORRECT")

    current_user.is_deactivated = True
    current_user.deactivated_at = datetime.utcnow()
    db.commit()

    # Immediately revoke all active refresh tokens in Redis
    keys = redis_client.keys(f"refresh_token:{current_user.id}:*")
    if keys:
        redis_client.delete(*keys)

    return {"success": True, "message": "Account successfully deactivated. Logging out."}

class DeleteAccountRequest(BaseModel):
    password: str

@router.delete("/me", status_code=status.HTTP_200_OK)
def delete_my_account(
    req: DeleteAccountRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis)
):
    # Verify password before deletion
    if not security.verify_password(req.password, current_user.hashed_password):
        raise BadRequestException(detail="Incorrect password confirmation", code="PASSWORD_INCORRECT")

    # Invalidate all active sessions/tokens in Redis first
    keys = redis_client.keys(f"refresh_token:{current_user.id}:*")
    if keys:
        redis_client.delete(*keys)

    # Modular deletion service method
    delete_user(db, current_user)

    return {"success": True, "message": "Account successfully deleted. Logging out."}

