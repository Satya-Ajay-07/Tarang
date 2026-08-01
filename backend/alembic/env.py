"""Alembic environment configuration for Tarang.

This file drives all migration operations. The database URL is read from
the ``DATABASE_URL`` environment variable (via pydantic-settings) so that
credentials are never hard-coded.

NOTE ON configparser INTERPOLATION
------------------------------------
Alembic's alembic.ini is parsed by Python's configparser, which treats
the % character as the start of an interpolation sequence (%(...)s).
Calling config.set_main_option("sqlalchemy.url", url) when the URL
contains percent-encoded characters (e.g. %40 for @) or passwords with
$$ will raise:
    ValueError: invalid interpolation syntax in '...' at position N

The fix is to NOT go through configparser at all: we pass the URL
directly to engine_from_config via its `url` override kwarg and to
context.configure in offline mode.
"""

import os
import sys
from logging.config import fileConfig

from sqlalchemy import engine_from_config, create_engine, pool
from alembic import context

# ---------------------------------------------------------------------------
# Make the app package importable when running alembic from the backend/ dir.
# ---------------------------------------------------------------------------
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings  # noqa: E402
from app.core.database import Base    # noqa: E402

# Import all models so that Base.metadata is fully populated before
# autogenerate inspects it.
import app.models.models  # noqa: F401, E402

# ---------------------------------------------------------------------------
# Alembic Config object (gives access to values within alembic.ini).
# We intentionally do NOT call config.set_main_option("sqlalchemy.url", ...)
# here because configparser's interpolation will crash on URLs that contain
# percent-encoded characters or passwords with special symbols.
# ---------------------------------------------------------------------------
config = context.config

# Interpret the config file for Python logging.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

# The database URL, taken directly from pydantic-settings (bypasses configparser).
DATABASE_URL = settings.DATABASE_URL


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    Configures the context with just a URL (no Engine). Emits SQL directly
    to script output. Passes the URL straight to context.configure so that
    configparser is never involved.
    """
    context.configure(
        url=DATABASE_URL,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode.

    Creates an Engine directly from the URL string (bypassing configparser)
    and associates a connection with the context.
    """
    connectable = create_engine(DATABASE_URL, poolclass=pool.NullPool)

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
