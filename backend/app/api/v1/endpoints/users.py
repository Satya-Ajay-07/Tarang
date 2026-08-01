from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import List, Optional
from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.core.exceptions import NotFoundException, BadRequestException
from app.models.models import User, Wave, WaveRider, WaveAlert
from app.schemas.schemas import UserResponse, UserUpdate

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
    if not user:
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
        "created_at": user.created_at,
        "role": user.role,
        "wave_count": wave_count,
        "riders_count": riders_count,
        "riding_count": riding_count,
        "is_riding": is_riding
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

# Account Settings - Delete Account (Soft Delete)
class DeleteAccountRequest(BaseModel):
    password: str

from app.core import security

@router.delete("/me", status_code=status.HTTP_200_OK)
def delete_my_account(
    req: DeleteAccountRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    # Verify password before deletion
    if not security.verify_password(req.password, current_user.hashed_password):
        raise BadRequestException(detail="Incorrect password confirmation", code="PASSWORD_INCORRECT")

    # Soft delete: mark is_active=False
    current_user.is_active = False
    db.commit()

    return {"success": True, "message": "Account successfully deactivated. Logging out."}

