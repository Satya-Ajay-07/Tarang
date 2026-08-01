"""
test_waves.py — Wave CRUD and interaction tests for Tarang.

Fixtures (database, Redis mock, client) are provided by conftest.py.
"""

import pytest
from sqlalchemy.orm import Session
from app.models.models import User
from app.core.security import create_access_token
from tests.conftest import client, TestingSessionLocal


def _seed_active_user(db: Session):
    """Insert a pre-verified test user directly into the test DB."""
    user = User(
        id="test-user-uuid",
        email="test@tarang.in",
        username="testrider",
        hashed_password="hashed_placeholder_here",
        is_active=True,
        role="user",
    )
    db.add(user)
    db.commit()


def get_auth_headers():
    token = create_access_token(subject="test-user-uuid")
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def seed_user():
    """Seed a verified test user before each wave test. Explicitly requested by wave tests."""
    db = TestingSessionLocal()
    _seed_active_user(db)
    db.close()


def test_create_wave(seed_user):
    headers = get_auth_headers()
    response = client.post(
        "/api/v1/waves",
        json={"content": "Hello Tarang WaveStream!"},
        headers=headers,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["content"] == "Hello Tarang WaveStream!"
    assert data["creator_id"] == "test-user-uuid"


def test_get_wave_stream(seed_user):
    headers = get_auth_headers()
    # Create a wave first
    client.post("/api/v1/waves", json={"content": "Wave 1"}, headers=headers)

    response = client.get("/api/v1/waves", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1
    assert data[0]["content"] == "Wave 1"


def test_ripple_wave(seed_user):
    headers = get_auth_headers()
    # Create wave
    res = client.post(
        "/api/v1/waves",
        json={"content": "Wave to ripple"},
        headers=headers,
    )
    wave_id = res.json()["id"]

    # Ripple it
    ripple_res = client.post(f"/api/v1/waves/{wave_id}/ripple", headers=headers)
    assert ripple_res.status_code == 200
    assert ripple_res.json()["rippled"] is True
    assert ripple_res.json()["ripples_count"] == 1
