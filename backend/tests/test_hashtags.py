import re
import pytest
from tests.conftest import client, TestingSessionLocal
from app.models.models import User, Wave, Hashtag

def test_hashtag_flow(capsys):
    # Register and login user
    username = "tagrider"
    email = "tag@tarang.in"
    password = "testpassword"

    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "username": username,
            "password": password,
            "full_name": "Tag Rider"
        }
    )
    assert register_response.status_code == 201

    captured = capsys.readouterr()
    match = re.search(r"token=([0-9a-f\-]+)", captured.out)
    assert match is not None
    verify_token = match.group(1)
    client.post(f"/api/v1/auth/verify-email?token={verify_token}")

    login_resp = client.post(
        "/api/v1/auth/login",
        json={"username_or_email": username, "password": password}
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create a wave with hashtags (including duplicate case variant)
    wave_resp = client.post(
        "/api/v1/waves",
        json={
            "content": "Riding the big #Wave in the #Ocean! #ocean"
        },
        headers=headers
    )
    assert wave_resp.status_code == 201

    # Create another wave with #Ocean
    wave_resp2 = client.post(
        "/api/v1/waves",
        json={
            "content": "Another cool day in the #Ocean"
        },
        headers=headers
    )
    assert wave_resp2.status_code == 201

    # 1. Test Get Trending Hashtags
    trend_resp = client.get("/api/v1/hashtags/trending", headers=headers)
    assert trend_resp.status_code == 200
    trends = trend_resp.json()
    
    # "ocean" should have 2 counts, "wave" should have 1 count
    assert len(trends) == 2
    assert trends[0]["tag"] == "ocean"
    assert trends[0]["count"] == 2
    assert trends[1]["tag"] == "wave"
    assert trends[1]["count"] == 1

    # 2. Test Search Hashtags
    search_resp = client.get("/api/v1/hashtags/search?q=oc", headers=headers)
    assert search_resp.status_code == 200
    search_results = search_resp.json()
    assert len(search_results) == 1
    assert search_results[0]["tag"] == "ocean"

    # 3. Test Get Waves by Hashtag
    waves_by_tag_resp = client.get("/api/v1/hashtags/ocean/waves", headers=headers)
    assert waves_by_tag_resp.status_code == 200
    waves_by_tag = waves_by_tag_resp.json()
    assert len(waves_by_tag) == 2
    assert "Ocean" in waves_by_tag[0]["content"]

    # 4. Test Edit Wave Hashtag Updates
    wave_id = wave_resp.json()["id"]
    edit_resp = client.put(
        f"/api/v1/waves/{wave_id}",
        json={"content": "Changing hashtags: #Ocean is nice but #Sky is better!"},
        headers=headers
    )
    assert edit_resp.status_code == 200

    # Trending hashtags: "wave" should be gone/0-count (or just not trending if count=0 depending on JOIN)
    # "ocean" still count=2 (from both waves), "sky" count=1
    trend_resp2 = client.get("/api/v1/hashtags/trending", headers=headers)
    assert trend_resp2.status_code == 200
    trends2 = trend_resp2.json()
    tags_in_trends = [t["tag"] for t in trends2]
    assert "sky" in tags_in_trends
    assert "wave" not in tags_in_trends
