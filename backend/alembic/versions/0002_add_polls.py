"""Add polls schemas

Revision ID: 0002_add_polls
Revises: 0001_initial_schema
Create Date: 2026-07-31 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "0002_add_polls"
down_revision: Union[str, None] = "0001_initial_schema"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create polls table
    op.create_table(
        "polls",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("wave_id", sa.String(36), sa.ForeignKey("waves.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("question", sa.String(255), nullable=False),
        sa.Column("expires_at", sa.DateTime, nullable=False),
    )
    op.create_index("ix_polls_wave_id", "polls", ["wave_id"])

    # Create poll_options table
    op.create_table(
        "poll_options",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("poll_id", sa.String(36), sa.ForeignKey("polls.id", ondelete="CASCADE"), nullable=False),
        sa.Column("text", sa.String(100), nullable=False),
    )
    op.create_index("ix_poll_options_poll_id", "poll_options", ["poll_id"])

    # Create poll_votes table
    op.create_table(
        "poll_votes",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("poll_id", sa.String(36), sa.ForeignKey("polls.id", ondelete="CASCADE"), nullable=False),
        sa.Column("option_id", sa.String(36), sa.ForeignKey("poll_options.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", sa.DateTime, nullable=True),
        sa.UniqueConstraint("poll_id", "user_id", name="_poll_user_vote_uc"),
    )
    op.create_index("ix_poll_votes_poll_id", "poll_votes", ["poll_id"])
    op.create_index("ix_poll_votes_option_id", "poll_votes", ["option_id"])
    op.create_index("ix_poll_votes_user_id", "poll_votes", ["user_id"])


def downgrade() -> None:
    op.drop_table("poll_votes")
    op.drop_table("poll_options")
    op.drop_table("polls")
