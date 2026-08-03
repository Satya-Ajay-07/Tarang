import re
import pytest
from tests.conftest import client, TestingSessionLocal
from app.models.models import User

def test_email_verification_flow(capsys):
    db = TestingSessionLocal()

    username = "verifyrider"
    email = "verify@tarang.in"
    password = "testpassword"

    # 1. Register a user (starts as inactive)
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "username": username,
            "password": password,
            "full_name": "Verify Rider"
        }
    )
    assert register_response.status_code == 201

    # Grab the original verification token
    captured = capsys.readouterr()
    match = re.search(r"token=([0-9a-f\-]+)", captured.out)
    assert match is not None
    verify_token_1 = match.group(1)

    # 2. Resend verification email
    resend_resp = client.post(
        "/api/v1/auth/resend-verification",
        json={"email": email}
    )
    print("RESEND_RESP:", resend_resp.json())
    assert resend_resp.status_code == 200
    
    # Grab the new verification token
    captured2 = capsys.readouterr()
    match2 = re.search(r"token=([0-9a-f\-]+)", captured2.out)
    assert match2 is not None
    verify_token_2 = match2.group(1)
    assert verify_token_1 != verify_token_2

    # 3. Test Cooldown
    resend_cooldown_resp = client.post(
        "/api/v1/auth/resend-verification",
        json={"email": email}
    )
    assert resend_cooldown_resp.status_code == 400
    assert resend_cooldown_resp.json()["error"]["code"] == "RESEND_COOLDOWN"

    # 4. Verify user with expired/invalid token (should return VERIFY_TOKEN_INVALID)
    verify_expired_resp = client.post("/api/v1/auth/verify-email?token=invalidtokenuuid")
    assert verify_expired_resp.status_code == 400
    assert verify_expired_resp.json()["error"]["code"] == "VERIFY_TOKEN_INVALID"

    # 5. Verify user with the valid token
    verify_resp = client.post(f"/api/v1/auth/verify-email?token={verify_token_2}")
    assert verify_resp.status_code == 200

    # Ensure user is now active in database
    user_db = db.query(User).filter(User.username == username).first()
    assert user_db is not None
    assert user_db.is_active is True

    # 6. Attempting to resend to already active user should return EMAIL_ALREADY_VERIFIED
    resend_active_resp = client.post(
        "/api/v1/auth/resend-verification",
        json={"email": email}
    )
    assert resend_active_resp.status_code == 400
    assert resend_active_resp.json()["error"]["code"] == "EMAIL_ALREADY_VERIFIED"

    db.close()
