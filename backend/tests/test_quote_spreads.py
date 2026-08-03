import re
import pytest
from tests.conftest import client, TestingSessionLocal
from app.models.models import User, Wave, WaveAlert

def test_quote_spread_flow(capsys):
    # 1. Register and login two users: creator & spreader
    # Creator
    client.post("/api/v1/auth/register", json={
        "email": "creator@tarang.in", "username": "creator", "password": "password123", "full_name": "Creator User"
    })
    captured = capsys.readouterr()
    verify_token1 = re.search(r"token=([0-9a-f\-]+)", captured.out).group(1)
    client.post(f"/api/v1/auth/verify-email?token={verify_token1}")
    
    login_creator = client.post("/api/v1/auth/login", json={"username_or_email": "creator", "password": "password123"})
    creator_headers = {"Authorization": f"Bearer {login_creator.json()['access_token']}"}

    # Spreader
    client.post("/api/v1/auth/register", json={
        "email": "spreader@tarang.in", "username": "spreader", "password": "password123", "full_name": "Spreader User"
    })
    captured = capsys.readouterr()
    verify_token2 = re.search(r"token=([0-9a-f\-]+)", captured.out).group(1)
    client.post(f"/api/v1/auth/verify-email?token={verify_token2}")
    
    login_spreader = client.post("/api/v1/auth/login", json={"username_or_email": "spreader", "password": "password123"})
    spreader_headers = {"Authorization": f"Bearer {login_spreader.json()['access_token']}"}

    # Third User (for nested test)
    client.post("/api/v1/auth/register", json={
        "email": "third@tarang.in", "username": "third", "password": "password123", "full_name": "Third User"
    })
    captured = capsys.readouterr()
    verify_token3 = re.search(r"token=([0-9a-f\-]+)", captured.out).group(1)
    client.post(f"/api/v1/auth/verify-email?token={verify_token3}")
    
    login_third = client.post("/api/v1/auth/login", json={"username_or_email": "third", "password": "password123"})
    third_headers = {"Authorization": f"Bearer {login_third.json()['access_token']}"}

    # 2. Creator posts a Wave
    wave_resp = client.post("/api/v1/waves", json={"content": "Root Wave content"}, headers=creator_headers)
    assert wave_resp.status_code == 201
    root_wave_id = wave_resp.json()["id"]

    # 3. Spreader creates a Quote Spread (Spread + Thoughts) of the root Wave
    quote_resp = client.post(
        "/api/v1/waves",
        json={"content": "Spreader's thoughts on the root wave.", "spread_from_id": root_wave_id},
        headers=spreader_headers
    )
    assert quote_resp.status_code == 201
    quote_wave_id = quote_resp.json()["id"]
    assert quote_resp.json()["spread_from_id"] == root_wave_id
    assert quote_resp.json()["spread_from"]["content"] == "Root Wave content"

    # Verify notification preview
    db = TestingSessionLocal()
    alert = db.query(WaveAlert).filter(WaveAlert.recipient_id == wave_resp.json()["creator_id"]).first()
    assert alert is not None
    assert "spread your Wave." in alert.content
    assert "Spreader's thoughts" in alert.content
    db.close()

    # 4. Third user quotes the Spreader's Quote Spread (Nested Test)
    # The system must resolve the original root Wave instead of quoting the quote spread nestedly.
    nested_quote_resp = client.post(
        "/api/v1/waves",
        json={"content": "Third's thoughts on Spreader's thoughts.", "spread_from_id": quote_wave_id},
        headers=third_headers
    )
    assert nested_quote_resp.status_code == 201
    assert nested_quote_resp.json()["spread_from_id"] == root_wave_id  # Resolved to root wave!

    # 5. Test independent Bookmarks
    # Bookmark Quote Spread
    bookmark_resp = client.post(f"/api/v1/waves/{quote_wave_id}/bookmark", headers=spreader_headers)
    assert bookmark_resp.status_code == 200

    # Get bookmarks list - only the bookmarked quote spread should have bookmarked_by_me = True
    # The root wave itself should NOT be bookmarked
    root_get_resp = client.get(f"/api/v1/waves/{root_wave_id}", headers=spreader_headers)
    assert root_get_resp.json()["bookmarked_by_me"] is False
