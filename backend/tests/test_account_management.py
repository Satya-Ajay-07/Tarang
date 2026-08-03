import re
import pytest
from datetime import datetime, timedelta
from tests.conftest import client, TestingSessionLocal
from app.models.models import User

def test_account_management_flow(capsys):
    db = TestingSessionLocal()
    
    # 1. Register a user
    username = "accmanager"
    email = "acc@tarang.in"
    password = "testpassword"
    
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "username": username,
            "password": password,
            "full_name": "Account Manager"
        }
    )
    assert register_response.status_code == 201
    
    # Verify email
    captured = capsys.readouterr()
    match = re.search(r"token=([0-9a-f\-]+)", captured.out)
    assert match is not None
    verify_token = match.group(1)
    verify_response = client.post(f"/api/v1/auth/verify-email?token={verify_token}")
    assert verify_response.status_code == 200

    # Login to get tokens
    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "username_or_email": username,
            "password": password
        }
    )
    assert login_response.status_code == 200
    login_data = login_response.json()
    token = login_data["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Test Change Password
    # Incorrect current password
    cp_resp = client.post(
        "/api/v1/users/change-password",
        json={"current_password": "wrongpassword", "new_password": "newpassword123"},
        headers=headers
    )
    assert cp_resp.status_code == 400
    assert cp_resp.json()["error"]["code"] == "PASSWORD_INCORRECT"

    # Too short password
    cp_resp = client.post(
        "/api/v1/users/change-password",
        json={"current_password": password, "new_password": "short"},
        headers=headers
    )
    assert cp_resp.status_code == 400
    assert cp_resp.json()["error"]["code"] == "PASSWORD_TOO_SHORT"

    # Correct current password change
    cp_resp = client.post(
        "/api/v1/users/change-password",
        json={"current_password": password, "new_password": "newpassword123"},
        headers=headers
    )
    assert cp_resp.status_code == 200
    password = "newpassword123"

    # 3. Test Deactivate Account
    # Incorrect password confirmation
    deact_resp = client.post(
        "/api/v1/users/deactivate",
        json={"password": "wrongpassword"},
        headers=headers
    )
    assert deact_resp.status_code == 400
    assert deact_resp.json()["error"]["code"] == "PASSWORD_INCORRECT"

    # Correct deactivation
    deact_resp = client.post(
        "/api/v1/users/deactivate",
        json={"password": password},
        headers=headers
    )
    assert deact_resp.status_code == 200
    
    # Try to access protected route with same token (should be rejected since is_deactivated=True)
    me_resp = client.get("/api/v1/users/me", headers=headers)
    assert me_resp.status_code == 401
    assert me_resp.json()["error"]["code"] == "USER_DEACTIVATED"

    # Try to login immediately (should trigger deactivation cooldown)
    login_cooldown_resp = client.post(
        "/api/v1/auth/login",
        json={
            "username_or_email": username,
            "password": password
        }
    )
    assert login_cooldown_resp.status_code == 401
    cooldown_data = login_cooldown_resp.json()
    assert cooldown_data["error"]["code"] == "ACCOUNT_DEACTIVATED_COOL_DOWN"
    assert "days_remaining" in cooldown_data["error"]
    assert cooldown_data["error"]["days_remaining"] > 0

    # 4. Simulate passage of 8 days in DB
    user_db = db.query(User).filter(User.username == username).first()
    assert user_db is not None
    user_db.deactivated_at = datetime.utcnow() - timedelta(days=8)
    db.commit()

    # Log in again (reactivates successfully)
    login_reactivate_resp = client.post(
        "/api/v1/auth/login",
        json={
            "username_or_email": username,
            "password": password
        }
    )
    assert login_reactivate_resp.status_code == 200
    reactivate_data = login_reactivate_resp.json()
    new_token = reactivate_data["access_token"]
    new_headers = {"Authorization": f"Bearer {new_token}"}

    # Verify is_deactivated is cleared in DB
    db.refresh(user_db)
    assert user_db.is_deactivated is False
    assert user_db.deactivated_at is None

    # Verify we can access profile search/details
    me_resp = client.get("/api/v1/users/me", headers=new_headers)
    assert me_resp.status_code == 200

    # 5. Test Delete Account
    del_resp = client.request(
        "DELETE",
        "/api/v1/users/me",
        json={"password": password},
        headers=new_headers
    )
    assert del_resp.status_code == 200
    
    # In soft-delete service, user.is_active is False
    db.refresh(user_db)
    assert user_db.is_active is False

    db.close()
