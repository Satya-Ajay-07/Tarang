"""
Shared pytest fixtures for the Tarang backend test suite.

A single complete MockRedis implementation is defined here so that both
test_auth.py and test_waves.py share the same mock, preventing dependency
override conflicts when both test modules are collected in the same session.
"""

import pytest
import fnmatch
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

from app.main import app
from app.core.database import Base, get_db
from app.core.redis import get_redis


# ── Shared in-memory SQLite database ─────────────────────────────────────────

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_shared.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})

# Enable FK support in SQLite so self-referential FKs (Wave.parent_wave_id)
# are correctly created by Base.metadata.create_all()
from sqlalchemy import event as sa_event

@sa_event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()

TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


# ── Complete MockRedis ────────────────────────────────────────────────────────

class MockRedis:
    """Full-featured in-memory Redis mock supporting all methods used by Tarang."""

    def __init__(self):
        self.store: dict = {}

    # ── Basic key ops ─────────────────────────────────────────────────────────

    def get(self, key):
        return self.store.get(key)

    def set(self, key, value, *args, **kwargs):
        self.store[key] = value
        return True

    def setex(self, key, time, value):
        self.store[key] = value
        return True

    def keys(self, pattern):
        return [key for key in self.store.keys() if fnmatch.fnmatch(key, pattern)]

    def delete(self, *keys):
        count = 0
        for key in keys:
            if key in self.store:
                del self.store[key]
                count += 1
        return count

    def exists(self, key):
        return 1 if key in self.store else 0

    # ── Counters ──────────────────────────────────────────────────────────────

    def incr(self, key):
        val = int(self.store.get(key, 0)) + 1
        self.store[key] = str(val)
        return val

    def expire(self, key, time):
        return True  # TTL not simulated in-memory

    # ── Pipeline (returns self so chained calls work) ─────────────────────────

    def pipeline(self):
        return self

    def execute(self):
        return []

    # ── Scan ─────────────────────────────────────────────────────────────────

    def scan_iter(self, match=None):
        for key in list(self.store.keys()):
            if match is None or fnmatch.fnmatch(key, match):
                yield key

    # ── Pub/Sub (no-op stubs so WebSocket code doesn't crash) ─────────────────

    def publish(self, channel, message):
        return 0

    def pubsub(self):
        return MockPubSub()

    # ── Lifecycle ─────────────────────────────────────────────────────────────

    def close(self):
        pass


class MockPubSub:
    """Minimal no-op PubSub stub."""
    def subscribe(self, *args, **kwargs):
        pass
    def listen(self):
        return iter([])
    def close(self):
        pass


# Module-level singleton — shared across both test modules in a single session
mock_redis_client = MockRedis()


# ── Dependency overrides ──────────────────────────────────────────────────────

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


def override_get_redis():
    try:
        yield mock_redis_client
    finally:
        pass


app.dependency_overrides[get_db] = override_get_db
app.dependency_overrides[get_redis] = override_get_redis

client = TestClient(app)


# ── Autouse fixture ───────────────────────────────────────────────────────────

@pytest.fixture(autouse=True)
def reset_state():
    """Ensure each test starts with a clean database and clean Redis store."""
    Base.metadata.create_all(bind=engine)
    mock_redis_client.store.clear()
    yield
    Base.metadata.drop_all(bind=engine)
