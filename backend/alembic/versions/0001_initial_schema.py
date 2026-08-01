"""Initial schema — all Tarang models

Revision ID: 0001_initial_schema
Revises: 
Create Date: 2026-07-31 10:00:00.000000

Creates all tables for the first deployment:
  - users
  - waves
  - ripples
  - wave_circles
  - circle_members
  - wave_riders
  - messages
  - wave_alerts
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "0001_initial_schema"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── users ────────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("username", sa.String(100), nullable=False),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("full_name", sa.String(255), nullable=True),
        sa.Column("avatar_url", sa.String(512), nullable=True),
        sa.Column("cover_url", sa.String(512), nullable=True),
        sa.Column("bio", sa.Text, nullable=True),
        sa.Column("location", sa.String(255), nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=True),
        sa.Column("updated_at", sa.DateTime, nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=True),
        sa.Column("role", sa.String(50), nullable=True),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.create_index("ix_users_username", "users", ["username"], unique=True)

    # ── wave_circles (must exist before waves references it) ─────────────────
    op.create_table(
        "wave_circles",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(100), nullable=False, unique=True),
        sa.Column("slug", sa.String(100), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("banner_url", sa.String(512), nullable=True),
        sa.Column("creator_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=True),
    )
    op.create_index("ix_wave_circles_slug", "wave_circles", ["slug"], unique=True)

    # ── waves ────────────────────────────────────────────────────────────────
    op.create_table(
        "waves",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("creator_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("content", sa.Text, nullable=True),
        sa.Column("media_url", sa.String(512), nullable=True),
        sa.Column("media_type", sa.String(50), nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=True),
        sa.Column("updated_at", sa.DateTime, nullable=True),
        sa.Column("spread_from_id", sa.String(36), sa.ForeignKey("waves.id", ondelete="SET NULL"), nullable=True),
        sa.Column("parent_wave_id", sa.String(36), sa.ForeignKey("waves.id", ondelete="CASCADE"), nullable=True),
        sa.Column("circle_id", sa.String(36), sa.ForeignKey("wave_circles.id", ondelete="SET NULL"), nullable=True),
    )
    op.create_index("ix_waves_creator_id", "waves", ["creator_id"])
    op.create_index("ix_waves_created_at", "waves", ["created_at"])
    op.create_index("ix_waves_parent_wave_id", "waves", ["parent_wave_id"])
    op.create_index("ix_waves_circle_id", "waves", ["circle_id"])

    # ── ripples ──────────────────────────────────────────────────────────────
    op.create_table(
        "ripples",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("wave_id", sa.String(36), sa.ForeignKey("waves.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", sa.DateTime, nullable=True),
        sa.UniqueConstraint("user_id", "wave_id", name="_user_wave_ripple_uc"),
    )
    op.create_index("ix_ripples_user_id", "ripples", ["user_id"])
    op.create_index("ix_ripples_wave_id", "ripples", ["wave_id"])

    # ── circle_members ───────────────────────────────────────────────────────
    op.create_table(
        "circle_members",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("circle_id", sa.String(36), sa.ForeignKey("wave_circles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("role", sa.String(50), nullable=True),
        sa.Column("joined_at", sa.DateTime, nullable=True),
        sa.UniqueConstraint("circle_id", "user_id", name="_circle_user_member_uc"),
    )
    op.create_index("ix_circle_members_circle_id", "circle_members", ["circle_id"])
    op.create_index("ix_circle_members_user_id", "circle_members", ["user_id"])

    # ── wave_riders ──────────────────────────────────────────────────────────
    op.create_table(
        "wave_riders",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("rider_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("rider_of_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", sa.DateTime, nullable=True),
        sa.UniqueConstraint("rider_id", "rider_of_id", name="_rider_rider_of_uc"),
    )
    op.create_index("ix_wave_riders_rider_id", "wave_riders", ["rider_id"])
    op.create_index("ix_wave_riders_rider_of_id", "wave_riders", ["rider_of_id"])

    # ── messages ─────────────────────────────────────────────────────────────
    op.create_table(
        "messages",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("sender_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("recipient_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("content", sa.Text, nullable=True),
        sa.Column("media_url", sa.String(512), nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=True),
        sa.Column("is_read", sa.Boolean, nullable=True),
        sa.Column("read_at", sa.DateTime, nullable=True),
    )
    op.create_index("ix_messages_sender_id", "messages", ["sender_id"])
    op.create_index("ix_messages_recipient_id", "messages", ["recipient_id"])
    op.create_index("ix_messages_created_at", "messages", ["created_at"])

    # ── wave_alerts ──────────────────────────────────────────────────────────
    op.create_table(
        "wave_alerts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("recipient_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("sender_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("wave_id", sa.String(36), sa.ForeignKey("waves.id", ondelete="SET NULL"), nullable=True),
        sa.Column("type", sa.String(50), nullable=False),
        sa.Column("content", sa.Text, nullable=True),
        sa.Column("is_read", sa.Boolean, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=True),
    )
    op.create_index("ix_wave_alerts_recipient_id", "wave_alerts", ["recipient_id"])
    op.create_index("ix_wave_alerts_created_at", "wave_alerts", ["created_at"])


def downgrade() -> None:
    op.drop_table("wave_alerts")
    op.drop_table("messages")
    op.drop_table("wave_riders")
    op.drop_table("circle_members")
    op.drop_table("ripples")
    op.drop_table("waves")
    op.drop_table("wave_circles")
    op.drop_table("users")
