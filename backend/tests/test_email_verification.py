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

def test_reregister_deleted_user(capsys):
    db = TestingSessionLocal()
    
    # 1. Register a user
    username = "deletedrider"
    email = "deleted@tarang.in"
    password = "testpassword"
    
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "username": username,
            "password": password,
            "full_name": "Deleted Rider"
        }
    )
    assert register_response.status_code == 201
    user_id_1 = register_response.json()["user"]["id"]
    
    # 2. Verify email so user becomes active
    captured = capsys.readouterr()
    match = re.search(r"token=([0-9a-f\-]+)", captured.out)
    assert match is not None
    verify_token_1 = match.group(1)
    
    verify_resp = client.post(f"/api/v1/auth/verify-email?token={verify_token_1}")
    assert verify_resp.status_code == 200
    
    # 3. Mark the user as deleted (new dedicated field — is_active remains True)
    user_db = db.query(User).filter(User.email == email).first()
    assert user_db is not None
    user_db.is_deleted = True
    db.commit()
    
    # 4. Attempt to re-register with the same email
    new_username = "newrider"
    register_response_2 = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "username": new_username,
            "password": "newpassword123",
            "full_name": "New Fresh Rider"
        }
    )
    assert register_response_2.status_code == 201
    
    data_2 = register_response_2.json()
    user_id_2 = data_2["user"]["id"]
    
    # Assert that a completely new user ID is generated
    assert user_id_1 != user_id_2
    
    # Check that old user is completely gone
    old_user_query = db.query(User).filter(User.id == user_id_1).first()
    assert old_user_query is None
    
    # Verify the new user email is captured from output
    captured_2 = capsys.readouterr()
    match_2 = re.search(r"token=([0-9a-f\-]+)", captured_2.out)
    assert match_2 is not None
    verify_token_2 = match_2.group(1)
    
    # Verify new user email
    verify_resp_2 = client.post(f"/api/v1/auth/verify-email?token={verify_token_2}")
    assert verify_resp_2.status_code == 200
    
    # Assert login with new user works
    login_resp = client.post(
        "/api/v1/auth/login",
        json={
            "username_or_email": new_username,
            "password": "newpassword123"
        }
    )
    assert login_resp.status_code == 200
    assert "access_token" in login_resp.json()
    
    # Ensure active user cannot register again
    register_fail = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "username": "anothername",
            "password": "password123",
            "full_name": "Failing Rider"
        }
    )
    assert register_fail.status_code == 400
    assert register_fail.json()["error"]["code"] == "EMAIL_ALREADY_EXISTS"
    
    db.close()
