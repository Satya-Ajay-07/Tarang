"""Reconcile polls unique constraint and wave parent index

Revision ID: 0003_reconcile_schema
Revises: 0002_add_polls
Create Date: 2026-08-01 10:00:00.000000

Reconciles two minor schema drifts detected by `alembic check`:
  1. polls.wave_id: ix_polls_wave_id should be UNIQUE (polls.wave_id is a 1:1
     relationship — each poll belongs to exactly one wave). The migration
     removes the plain index and replaces it with a unique index to match the
     SQLAlchemy model's unique=True on the poll.wave_id FK column.
  2. waves.parent_wave_id: the ix_waves_parent_wave_id index was present in the
     initial migration but Alembic now detects it as missing, possibly due to a
     DB-level quirk. Re-create it to stay in sync.
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0003_reconcile_schema"
down_revision: Union[str, None] = "0002_add_polls"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()

    # 1. polls.wave_id — ensure the index is UNIQUE
    #    Drop the old plain index (if it exists), then create a UNIQUE one.
    conn.execute(sa.text("DROP INDEX IF EXISTS ix_polls_wave_id"))
    conn.execute(sa.text(
        "CREATE UNIQUE INDEX IF NOT EXISTS ix_polls_wave_id ON polls (wave_id)"
    ))

    # 2. waves.parent_wave_id — ensure the plain index exists
    conn.execute(sa.text(
        "CREATE INDEX IF NOT EXISTS ix_waves_parent_wave_id ON waves (parent_wave_id)"
    ))


def downgrade() -> None:
    conn = op.get_bind()
    conn.execute(sa.text("DROP INDEX IF EXISTS ix_waves_parent_wave_id"))
    conn.execute(sa.text("DROP INDEX IF EXISTS ix_polls_wave_id"))
    conn.execute(sa.text("CREATE INDEX IF NOT EXISTS ix_polls_wave_id ON polls (wave_id)"))
