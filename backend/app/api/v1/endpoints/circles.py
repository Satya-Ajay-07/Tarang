import re
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List, Optional
from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.core.exceptions import NotFoundException, BadRequestException, ForbiddenException
from pydantic import BaseModel
from app.models.models import User, WaveCircle, CircleMember, Wave, WaveAlert
from app.schemas.schemas import WaveCircleCreate, WaveCircleResponse

router = APIRouter()


def make_slug(name: str) -> str:
    """Convert a circle name into a URL-safe slug."""
    slug = re.sub(r"[^\w\s-]", "", name.lower())
    slug = re.sub(r"[\s_-]+", "-", slug).strip("-")
    return slug


def enrich_circle(circle: WaveCircle, db: Session, current_user: User) -> WaveCircleResponse:
    members_count = db.query(CircleMember).filter(CircleMember.circle_id == circle.id).count()
    joined_by_me = db.query(CircleMember).filter(
        CircleMember.circle_id == circle.id,
        CircleMember.user_id == current_user.id
    ).first() is not None

    return WaveCircleResponse(
        id=circle.id,
        name=circle.name,
        slug=circle.slug,
        description=circle.description,
        banner_url=circle.banner_url,
        creator_id=circle.creator_id,
        created_at=circle.created_at,
        members_count=members_count,
        joined_by_me=joined_by_me,
        is_public=bool(circle.is_public),
    )


# List all Wave Circles
@router.get("", response_model=List[WaveCircleResponse])
def list_circles(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    search: Optional[str] = None,
    skip: int = 0,
    limit: int = 20,
):
    query = db.query(WaveCircle)
    if search:
        query = query.filter(WaveCircle.name.ilike(f"%{search}%"))
    # Hide private circles unless current_user is a member
    private_member_ids = db.query(CircleMember.circle_id).filter(CircleMember.user_id == current_user.id).subquery()
    query = query.filter((WaveCircle.is_public == True) | (WaveCircle.id.in_(private_member_ids)))
    
    circles = query.order_by(WaveCircle.created_at.desc()).offset(skip).limit(limit).all()
    return [enrich_circle(c, db, current_user) for c in circles]


# Get circles I have joined
@router.get("/mine", response_model=List[WaveCircleResponse])
def my_circles(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    circles = (
        db.query(WaveCircle)
        .join(CircleMember, CircleMember.circle_id == WaveCircle.id)
        .filter(CircleMember.user_id == current_user.id)
        .all()
    )
    return [enrich_circle(c, db, current_user) for c in circles]


# Create a new Wave Circle
@router.post("", response_model=WaveCircleResponse, status_code=status.HTTP_201_CREATED)
def create_circle(
    circle_in: WaveCircleCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    slug = make_slug(circle_in.name)
    existing = db.query(WaveCircle).filter(WaveCircle.slug == slug).first()
    if existing:
        raise BadRequestException(detail="A Wave Circle with this name already exists.", code="CIRCLE_EXISTS")

    circle = WaveCircle(
        name=circle_in.name,
        slug=slug,
        description=circle_in.description,
        is_public=circle_in.is_public if circle_in.is_public is not None else True,
        creator_id=current_user.id,
    )
    db.add(circle)
    db.flush()  # get circle.id before commit

    # Creator auto-joins as creator role
    member = CircleMember(circle_id=circle.id, user_id=current_user.id, role="creator")
    db.add(member)
    db.commit()
    db.refresh(circle)
    return enrich_circle(circle, db, current_user)


# Get a single Wave Circle by slug
@router.get("/{slug}", response_model=WaveCircleResponse)
def get_circle(
    slug: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    circle = db.query(WaveCircle).filter(WaveCircle.slug == slug).first()
    if not circle:
        raise NotFoundException(detail="Wave Circle not found")
    return enrich_circle(circle, db, current_user)


# Join or leave a Wave Circle
@router.post("/{slug}/join")
def toggle_join_circle(
    slug: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    circle = db.query(WaveCircle).filter(WaveCircle.slug == slug).first()
    if not circle:
        raise NotFoundException(detail="Wave Circle not found")

    membership = db.query(CircleMember).filter(
        CircleMember.circle_id == circle.id,
        CircleMember.user_id == current_user.id,
    ).first()

    if membership:
        if membership.role == "creator":
            raise ForbiddenException(detail="Circle creator cannot leave their own circle.")
        db.delete(membership)
        db.commit()
        return {"joined": False, "message": f"You left {circle.name}"}
    else:
        new_member = CircleMember(circle_id=circle.id, user_id=current_user.id, role="member")
        db.add(new_member)
        db.commit()
        return {"joined": True, "message": f"You joined {circle.name}"}


# Get waves posted to a specific circle
@router.get("/{slug}/waves", response_model=List[dict])
def get_circle_waves(
    slug: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    skip: int = 0,
    limit: int = 20,
):
    circle = db.query(WaveCircle).filter(WaveCircle.slug == slug).first()
    if not circle:
        raise NotFoundException(detail="Wave Circle not found")

    waves = (
        db.query(Wave)
        .filter(Wave.circle_id == circle.id, Wave.parent_wave_id == None)
        .order_by(Wave.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    # Return minimal wave info — full enrichment handled frontend side
    return [
        {
            "id": w.id,
            "content": w.content,
            "media_url": w.media_url,
            "media_type": w.media_type,
            "creator_id": w.creator_id,
            "created_at": w.created_at.isoformat(),
        }
        for w in waves
    ]


# ─── Member listing ───────────────────────────────────────────────────────────

@router.get("/{slug}/members", response_model=List[dict])
def list_circle_members(
    slug: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    skip: int = 0,
    limit: int = 50,
):
    """List members of a Wave Circle with their roles."""
    circle = db.query(WaveCircle).filter(WaveCircle.slug == slug).first()
    if not circle:
        raise NotFoundException(detail="Wave Circle not found")

    memberships = (
        db.query(CircleMember)
        .filter(CircleMember.circle_id == circle.id)
        .offset(skip)
        .limit(limit)
        .all()
    )

    result = []
    for m in memberships:
        user = db.query(User).filter(User.id == m.user_id).first()
        if user:
            result.append({
                "user_id": user.id,
                "username": user.username,
                "full_name": user.full_name,
                "avatar_url": user.avatar_url,
                "role": m.role,
                "joined_at": m.joined_at.isoformat() if hasattr(m, "joined_at") and m.joined_at else None,
            })
    return result


# ─── Moderator management ─────────────────────────────────────────────────────

@router.post("/{slug}/moderators/{user_id}", status_code=200)
def promote_to_moderator(
    slug: str,
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Promote a circle member to moderator.
    Only the circle creator can perform this action.
    """
    circle = db.query(WaveCircle).filter(WaveCircle.slug == slug).first()
    if not circle:
        raise NotFoundException(detail="Wave Circle not found")

    # Only the creator may manage moderators
    if circle.creator_id != current_user.id:
        raise ForbiddenException(detail="Only the circle creator can promote moderators.")

    target_membership = db.query(CircleMember).filter(
        CircleMember.circle_id == circle.id,
        CircleMember.user_id == user_id,
    ).first()

    if not target_membership:
        raise NotFoundException(detail="User is not a member of this circle.")

    if target_membership.role in ("creator", "moderator"):
        raise BadRequestException(
            detail=f"User already has role '{target_membership.role}'.",
            code="ALREADY_MODERATOR",
        )

    target_membership.role = "moderator"
    db.commit()

    target_user = db.query(User).filter(User.id == user_id).first()
    return {
        "message": f"@{target_user.username if target_user else user_id} is now a moderator.",
        "user_id": user_id,
        "role": "moderator",
    }


@router.delete("/{slug}/moderators/{user_id}", status_code=200)
def demote_moderator(
    slug: str,
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Demote a circle moderator back to regular member.
    Only the circle creator can perform this action.
    """
    circle = db.query(WaveCircle).filter(WaveCircle.slug == slug).first()
    if not circle:
        raise NotFoundException(detail="Wave Circle not found")

    if circle.creator_id != current_user.id:
        raise ForbiddenException(detail="Only the circle creator can demote moderators.")

    target_membership = db.query(CircleMember).filter(
        CircleMember.circle_id == circle.id,
        CircleMember.user_id == user_id,
    ).first()

    if not target_membership:
        raise NotFoundException(detail="User is not a member of this circle.")

    if target_membership.role == "creator":
        raise ForbiddenException(detail="Cannot demote the circle creator.")

    if target_membership.role != "moderator":
        raise BadRequestException(
            detail="User is not a moderator.",
            code="NOT_A_MODERATOR",
        )

    target_membership.role = "member"
    db.commit()

    target_user = db.query(User).filter(User.id == user_id).first()
    return {
        "message": f"@{target_user.username if target_user else user_id} has been demoted to member.",
        "user_id": user_id,
        "role": "member",
    }

# Update circle settings
class WaveCircleUpdate(BaseModel):
    description: Optional[str] = None
    banner_url: Optional[str] = None
    is_public: Optional[bool] = None

from pydantic import BaseModel

@router.put("/{slug}", response_model=WaveCircleResponse)
def update_circle(
    slug: str,
    circle_update: WaveCircleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    circle = db.query(WaveCircle).filter(WaveCircle.slug == slug).first()
    if not circle:
        raise NotFoundException(detail="Wave Circle not found")
        
    # Check permissions (creator or moderator can edit settings)
    user_member = db.query(CircleMember).filter(
        CircleMember.circle_id == circle.id,
        CircleMember.user_id == current_user.id
    ).first()
    if not user_member or user_member.role not in ("creator", "moderator"):
        raise ForbiddenException(detail="Only creators and moderators can update circle settings.")

    if circle_update.description is not None:
        circle.description = circle_update.description
    if circle_update.banner_url is not None:
        circle.banner_url = circle_update.banner_url
    if circle_update.is_public is not None:
        circle.is_public = circle_update.is_public

    db.commit()
    db.refresh(circle)
    return enrich_circle(circle, db, current_user)

# Invite or add member
@router.post("/{slug}/members/{user_id}", status_code=200)
def invite_member(
    slug: str,
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    circle = db.query(WaveCircle).filter(WaveCircle.slug == slug).first()
    if not circle:
        raise NotFoundException(detail="Wave Circle not found")

    # Invite permission check (member, moderator, or creator can invite)
    user_member = db.query(CircleMember).filter(
        CircleMember.circle_id == circle.id,
        CircleMember.user_id == current_user.id
    ).first()
    if not user_member:
        raise ForbiddenException(detail="Only circle members can invite others.")

    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise NotFoundException(detail="Target user not found")

    existing_membership = db.query(CircleMember).filter(
        CircleMember.circle_id == circle.id,
        CircleMember.user_id == user_id
    ).first()
    if existing_membership:
        return {"message": "User is already a member of this circle.", "joined": True}

    new_member = CircleMember(circle_id=circle.id, user_id=user_id, role="member")
    db.add(new_member)
    db.commit()
    return {"message": f"Added @{target_user.username} to circle.", "joined": True}

# Remove member
@router.delete("/{slug}/members/{user_id}", status_code=200)
def remove_member(
    slug: str,
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    circle = db.query(WaveCircle).filter(WaveCircle.slug == slug).first()
    if not circle:
        raise NotFoundException(detail="Wave Circle not found")

    # Check permission (creator/moderator can kick; user can leave via POST /{slug}/join)
    user_member = db.query(CircleMember).filter(
        CircleMember.circle_id == circle.id,
        CircleMember.user_id == current_user.id
    ).first()
    if not user_member or user_member.role not in ("creator", "moderator"):
        raise ForbiddenException(detail="Only creators and moderators can remove members.")

    target_membership = db.query(CircleMember).filter(
        CircleMember.circle_id == circle.id,
        CircleMember.user_id == user_id
    ).first()
    if not target_membership:
        raise NotFoundException(detail="User is not a member of this circle.")

    if target_membership.role == "creator":
        raise ForbiddenException(detail="Cannot remove the circle creator.")

    db.delete(target_membership)
    db.commit()
    return {"message": "Member removed from circle successfully."}

