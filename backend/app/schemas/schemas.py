from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime

# --- Token Schemas ---
class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenPayload(BaseModel):
    sub: Optional[str] = None
    type: Optional[str] = None

# --- User Schemas ---
class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    full_name: Optional[str] = None
    country: Optional[str] = None

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    phone_number: Optional[str] = None

class UserLogin(BaseModel):
    username_or_email: str
    password: str

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    bio: Optional[str] = None
    location: Optional[str] = None
    avatar_url: Optional[str] = None
    cover_url: Optional[str] = None
    country: Optional[str] = None
    phone_number: Optional[str] = None

class UserResponse(UserBase):
    id: str
    avatar_url: Optional[str] = None
    cover_url: Optional[str] = None
    bio: Optional[str] = None
    location: Optional[str] = None
    created_at: datetime
    role: str
    phone_number: Optional[str] = None  # Expose phone number securely if retrieved by self

    class Config:
        from_attributes = True


# --- Poll Schemas ---
class PollOptionCreate(BaseModel):
    text: str = Field(..., max_length=100)

class PollOptionResponse(BaseModel):
    id: str
    poll_id: str
    text: str
    votes_count: int = 0
    voted_by_me: bool = False

    class Config:
        from_attributes = True

class PollCreate(BaseModel):
    question: str = Field(..., max_length=255)
    options: List[PollOptionCreate] = Field(..., min_length=2, max_length=6)
    expires_in_hours: int = Field(24, ge=1, le=168)

class PollResponse(BaseModel):
    id: str
    question: str
    expires_at: datetime
    options: List[PollOptionResponse]
    total_votes: int = 0
    has_voted: bool = False
    voted_option_id: Optional[str] = None

    class Config:
        from_attributes = True

# --- Wave Schemas ---
class WaveBase(BaseModel):
    content: Optional[str] = None
    media_url: Optional[str] = None
    media_type: Optional[str] = None # "image", "video"

class WaveCreate(WaveBase):
    parent_wave_id: Optional[str] = None
    circle_id: Optional[str] = None
    poll: Optional[PollCreate] = None

class WaveUpdate(BaseModel):
    content: Optional[str] = None
    media_url: Optional[str] = None
    media_type: Optional[str] = None # "image", "video"

class WaveSpread(BaseModel):
    spread_from_id: str

class WaveResponse(WaveBase):
    id: str
    creator_id: str
    creator: UserResponse
    created_at: datetime
    parent_wave_id: Optional[str] = None
    spread_from_id: Optional[str] = None
    spread_from: Optional['WaveResponse'] = None
    circle_id: Optional[str] = None
    ripples_count: int = 0
    joins_count: int = 0
    spreads_count: int = 0
    rippled_by_me: bool = False
    poll: Optional[PollResponse] = None

    class Config:
        from_attributes = True

# --- Wave Circle Schemas ---
class WaveCircleBase(BaseModel):
    name: str
    description: Optional[str] = None

class WaveCircleCreate(WaveCircleBase):
    pass

class WaveCircleResponse(WaveCircleBase):
    id: str
    slug: str
    banner_url: Optional[str] = None
    creator_id: Optional[str] = None
    created_at: datetime
    members_count: int = 0
    joined_by_me: bool = False

    class Config:
        from_attributes = True

# --- Message Schemas ---
class MessageBase(BaseModel):
    content: Optional[str] = None
    media_url: Optional[str] = None

class MessageCreate(MessageBase):
    recipient_id: str

class MessageResponse(MessageBase):
    id: str
    sender_id: str
    recipient_id: str
    created_at: datetime
    is_read: bool
    read_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# --- Wave Alert Schemas ---
class WaveAlertResponse(BaseModel):
    id: str
    recipient_id: str
    sender: Optional[UserResponse] = None
    wave_id: Optional[str] = None
    type: str  # "ripple", "join", "spread", "follow"
    content: Optional[str] = None
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True
