import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Text, Table, Index, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base
# Helper function to generate UUIDs
def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=True)
    avatar_url = Column(String(512), nullable=True)
    cover_url = Column(String(512), nullable=True)
    bio = Column(Text, nullable=True)
    location = Column(String(255), nullable=True)
    country = Column(String(100), nullable=True)
    phone_number = Column(String(50), nullable=True)
    website = Column(String(255), nullable=True)
    twitter_url = Column(String(255), nullable=True)
    github_url = Column(String(255), nullable=True)
    pinned_wave_id = Column(String(36), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)   # Email verification status ONLY
    role = Column(String(50), default="user")
    is_deactivated = Column(Boolean, default=False, nullable=False)  # Temporary deactivation
    deactivated_at = Column(DateTime, nullable=True)
    is_deleted = Column(Boolean, default=False, nullable=False)      # Permanent deletion
    deleted_at = Column(DateTime, nullable=True)

    # Relationships
    waves = relationship("Wave", back_populates="creator", foreign_keys="Wave.creator_id")
    ripples = relationship("Ripple", back_populates="user")
    alerts_received = relationship("WaveAlert", back_populates="recipient", foreign_keys="WaveAlert.recipient_id")
    alerts_sent = relationship("WaveAlert", back_populates="sender", foreign_keys="WaveAlert.sender_id")

class Wave(Base):
    __tablename__ = "waves"
    

    id = Column(String(36), primary_key=True, default=generate_uuid)
    creator_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    content = Column(Text, nullable=True)
    media_url = Column(String(512), nullable=True)
    media_type = Column(String(50), nullable=True)  # "image", "video"
    created_at = Column(
    DateTime(timezone=True),
    default=lambda: datetime.now(timezone.utc),
    index=True
    )
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Spread Wave (Repost) support
    spread_from_id = Column(String(36),ForeignKey("waves.id", ondelete="CASCADE"),nullable=True,index=True)
    # Join Wave (Reply/Comment) support — column MUST be declared before relationships
    parent_wave_id = Column(String(36), ForeignKey("waves.id", ondelete="CASCADE"), nullable=True)

    # Wave Circle post support
    circle_id = Column(String(36), ForeignKey("wave_circles.id", ondelete="SET NULL"), nullable=True, index=True)

    # Relationships
    creator = relationship("User", back_populates="waves", foreign_keys=[creator_id])

    # Self-referential: a wave can be a reply to another wave (adjacency list)
    parent_wave = relationship(
        "Wave",
        foreign_keys=[parent_wave_id],
        back_populates="joins",
        remote_side=[id],
    )
    joins = relationship(
        "Wave",
        foreign_keys=[parent_wave_id],
        back_populates="parent_wave",
        cascade="all, delete-orphan"

    )

    # Self-referential: a wave can be a repost (spread) of another wave
    spread_from = relationship(
    "Wave",
    foreign_keys=[spread_from_id],
    remote_side=[id],
    back_populates="spreads",
    overlaps="joins,parent_wave",
    )

    spreads = relationship(
        "Wave",
        foreign_keys=[spread_from_id],
        back_populates="spread_from",
        cascade="all, delete-orphan"
    )

    ripples = relationship("Ripple", back_populates="wave", cascade="all, delete-orphan")
    circle = relationship("WaveCircle", back_populates="waves")
    poll = relationship("Poll", back_populates="wave", uselist=False, cascade="all, delete-orphan")
    hashtags = relationship("Hashtag", secondary="wave_hashtags", back_populates="waves")


class Ripple(Base):
    __tablename__ = "ripples"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    wave_id = Column(String(36), ForeignKey("waves.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="ripples")
    wave = relationship("Wave", back_populates="ripples")

    __table_args__ = (
        UniqueConstraint('user_id', 'wave_id', name='_user_wave_ripple_uc'),
    )

class WaveCircle(Base):
    __tablename__ = "wave_circles"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String(100), unique=True, nullable=False)
    slug = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    banner_url = Column(String(512), nullable=True)
    is_public = Column(Boolean, default=True)
    creator_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    waves = relationship("Wave", back_populates="circle")
    members = relationship("CircleMember", back_populates="circle", cascade="all, delete-orphan")

class CircleMember(Base):
    __tablename__ = "circle_members"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    circle_id = Column(String(36), ForeignKey("wave_circles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    role = Column(String(50), default="member")  # "creator", "moderator", "member"
    joined_at = Column(DateTime, default=datetime.utcnow)

    circle = relationship("WaveCircle", back_populates="members")
    user = relationship("User")

    __table_args__ = (
        UniqueConstraint('circle_id', 'user_id', name='_circle_user_member_uc'),
    )

class WaveRider(Base):
    __tablename__ = "wave_riders"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    rider_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)  # Follower
    rider_of_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True) # Followed
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint('rider_id', 'rider_of_id', name='_rider_rider_of_uc'),
    )

class Message(Base):
    __tablename__ = "messages"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    sender_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    recipient_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    content = Column(Text, nullable=True)
    media_url = Column(String(512), nullable=True)
    created_at = Column(
    DateTime(timezone=True),
    default=lambda: datetime.now(timezone.utc),
    index=True
    )
    is_read = Column(Boolean, default=False)
    read_at = Column(DateTime, nullable=True)

class WaveAlert(Base):
    __tablename__ = "wave_alerts"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    recipient_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    sender_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    wave_id = Column(String(36), ForeignKey("waves.id", ondelete="SET NULL"), nullable=True)
    type = Column(String(50), nullable=False)  # "ripple", "join", "spread", "follow"
    content = Column(Text, nullable=True)
    is_read = Column(Boolean, default=False)
    created_at = Column(
    DateTime(timezone=True),
    default=lambda: datetime.now(timezone.utc),
    index=True
    )

    recipient = relationship("User", back_populates="alerts_received", foreign_keys=[recipient_id])
    sender = relationship("User", back_populates="alerts_sent", foreign_keys=[sender_id])
    wave = relationship("Wave")

class Poll(Base):
    __tablename__ = "polls"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    wave_id = Column(String(36), ForeignKey("waves.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)
    question = Column(String(255), nullable=False)
    expires_at = Column(DateTime, nullable=False)

    wave = relationship("Wave", back_populates="poll")
    options = relationship("PollOption", back_populates="poll", cascade="all, delete-orphan")
    votes = relationship("PollVote", back_populates="poll", cascade="all, delete-orphan")

class PollOption(Base):
    __tablename__ = "poll_options"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    poll_id = Column(String(36), ForeignKey("polls.id", ondelete="CASCADE"), nullable=False, index=True)
    text = Column(String(100), nullable=False)

    poll = relationship("Poll", back_populates="options")
    votes = relationship("PollVote", back_populates="option", cascade="all, delete-orphan")

class PollVote(Base):
    __tablename__ = "poll_votes"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    poll_id = Column(String(36), ForeignKey("polls.id", ondelete="CASCADE"), nullable=False, index=True)
    option_id = Column(String(36), ForeignKey("poll_options.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    poll = relationship("Poll", back_populates="votes")
    option = relationship("PollOption", back_populates="votes")
    user = relationship("User")

    __table_args__ = (
        UniqueConstraint('poll_id', 'user_id', name='_poll_user_vote_uc'),
    )

class Bookmark(Base):
    __tablename__ = "bookmarks"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    wave_id = Column(String(36), ForeignKey("waves.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint('user_id', 'wave_id', name='_user_wave_bookmark_uc'),
    )

class Hashtag(Base):
    __tablename__ = "hashtags"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    tag = Column(String(100), unique=True, nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    waves = relationship("Wave", secondary="wave_hashtags", back_populates="hashtags")

class WaveHashtag(Base):
    __tablename__ = "wave_hashtags"

    wave_id = Column(String(36), ForeignKey("waves.id", ondelete="CASCADE"), primary_key=True)
    hashtag_id = Column(String(36), ForeignKey("hashtags.id", ondelete="CASCADE"), primary_key=True)

