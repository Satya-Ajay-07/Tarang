"""
test_account_state.py — Tests for the separated account state fields:

  is_active       => email verification status only
  is_deactivated  => temporary deactivation
  is_deleted      => permanent deletion

Ensures no ambiguity between states and that all flows behave independently.
"""
import re
import json
import pytest
from tests.conftest import client, TestingSessionLocal
from app.models.models import User


# ─── helpers ────────────────────────────────────────────────────────────────

def _register(email, username, password="password123", full_name="Test User"):
    return client.post("/api/v1/auth/register", json={
        "email": email, "username": username,
        "password": password, "full_name": full_name
    })


def _verify(capsys):
    captured = capsys.readouterr()
    match = re.search(r"token=([0-9a-f\-]+)", captured.out)
    assert match is not None, f"Verification token not in stdout:\n{captured.out}"
    client.post(f"/api/v1/auth/verify-email?token={match.group(1)}")


def _login(username_or_email, password="password123"):
    return client.post("/api/v1/auth/login", json={
        "username_or_email": username_or_email, "password": password
    })


def _delete_account(token, password="password123"):
    """Use client.request for DELETE with JSON body — TestClient.delete() doesn't support json kwarg."""
    return client.request(
        "DELETE",
        "/api/v1/users/me",
        json={"password": password},
        headers={"Authorization": f"Bearer {token}"}
    )


def _error_code(resp):
    """Extract error code from Tarang's nested error response."""
    return resp.json()["error"]["code"]


# ─── tests ──────────────────────────────────────────────────────────────────

def test_register_new_user(capsys):
    """Normal registration creates an unverified (is_active=False) user."""
    resp = _register("new@tarang.in", "newuser")
    assert resp.status_code == 201
    data = resp.json()
    assert data["email"] == "new@tarang.in"

    db = TestingSessionLocal()
    user = db.query(User).filter(User.email == "new@tarang.in").first()
    assert user is not None
    assert user.is_active is False          # Unverified
    assert user.is_deleted is False
    assert user.is_deactivated is False
    db.close()


def test_register_duplicate_active_user(capsys):
    """Registering with an email/username that is already in use returns EMAIL_ALREADY_EXISTS."""
    _register("dup@tarang.in", "dupuser")
    _verify(capsys)
    _login("dupuser")

    resp = _register("dup@tarang.in", "dupuser")
    assert resp.status_code == 400
    assert _error_code(resp) == "EMAIL_ALREADY_EXISTS"


def test_register_after_deletion_succeeds(capsys):
    """Re-registration with a deleted account's credentials must succeed (fresh account)."""
    _register("recycled@tarang.in", "recycleduser")
    _verify(capsys)
    login_resp = _login("recycleduser")
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]

    del_resp = _delete_account(token)
    assert del_resp.status_code == 200

    # Verify flag was set without touching is_active
    db = TestingSessionLocal()
    user = db.query(User).filter(User.email == "recycled@tarang.in").first()
    assert user is not None
    assert user.is_deleted is True
    assert user.deleted_at is not None
    # is_active should NOT have been changed by deletion
    assert user.is_active is True
    db.close()

    # Re-register with the same credentials — should succeed
    resp = _register("recycled@tarang.in", "recycleduser", full_name="Recycled Again")
    assert resp.status_code == 201

    # Should be a completely new user row (old one purged)
    db = TestingSessionLocal()
    users = db.query(User).filter(User.email == "recycled@tarang.in").all()
    assert len(users) == 1
    assert users[0].is_deleted is False
    db.close()


def test_login_deleted_account_blocked(capsys):
    """Deleted accounts cannot log in."""
    _register("deleted@tarang.in", "deleteduser")
    _verify(capsys)
    login_resp = _login("deleteduser")
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]

    _delete_account(token)

    resp = _login("deleteduser")
    assert resp.status_code == 401
    assert _error_code(resp) == "ACCOUNT_DELETED"


def test_login_unverified_user(capsys):
    """Unverified users get EMAIL_NOT_VERIFIED — not ACCOUNT_DELETED or LOGIN_FAILED."""
    _register("unverified@tarang.in", "unverifieduser")
    # Do NOT call _verify()

    resp = _login("unverifieduser")
    assert resp.status_code == 401
    assert _error_code(resp) == "EMAIL_NOT_VERIFIED"


def test_email_verification_does_not_modify_deletion_flag(capsys):
    """Verifying email must only set is_active; is_deleted/is_deactivated must remain untouched."""
    _register("verifystate@tarang.in", "verifystateuser")

    # Before verification
    db = TestingSessionLocal()
    user = db.query(User).filter(User.email == "verifystate@tarang.in").first()
    assert user.is_active is False
    assert user.is_deleted is False
    db.close()

    _verify(capsys)

    # After verification
    db = TestingSessionLocal()
    user = db.query(User).filter(User.email == "verifystate@tarang.in").first()
    assert user.is_active is True
    assert user.is_deleted is False
    assert user.is_deactivated is False
    db.close()


def test_forgot_password_blocked_for_deleted_accounts(capsys):
    """Deleted accounts must receive ACCOUNT_DELETED when requesting a password reset."""
    _register("delpwd@tarang.in", "delpwduser")
    _verify(capsys)
    login_resp = _login("delpwduser")
    token = login_resp.json()["access_token"]

    _delete_account(token)

    resp = client.post("/api/v1/auth/forgot-password",
        params={"email": "delpwd@tarang.in"}
    )
    assert resp.status_code == 400
    assert _error_code(resp) == "ACCOUNT_DELETED"


def test_deleted_profile_hidden(capsys):
    """Deleted accounts must not be discoverable via profile lookup."""
    _register("hiddenprofile@tarang.in", "hiddenprofileuser")
    _verify(capsys)
    login_resp = _login("hiddenprofileuser")
    token = login_resp.json()["access_token"]

    _delete_account(token)

    # Register a fresh user to query with
    _register("seeker@tarang.in", "seekeruser")
    _verify(capsys)
    seeker_login = _login("seekeruser")
    seeker_token = seeker_login.json()["access_token"]

    resp = client.get("/api/v1/users/profile/hiddenprofileuser",
        headers={"Authorization": f"Bearer {seeker_token}"}
    )
    assert resp.status_code == 404


def test_state_fields_are_independent():
    """
    Three state fields are mutually independent:
      is_active     — email verified
      is_deactivated — temporarily deactivated
      is_deleted    — permanently deleted

    This test confirms the User model contains all three distinct columns.
    """
    from datetime import datetime
    db = TestingSessionLocal()
    u = User(
        id="test-state-uuid",
        email="statetest@tarang.in",
        username="statetestuser",
        hashed_password="x",
        is_active=False,
        is_deactivated=True,
        deactivated_at=datetime.utcnow(),
        is_deleted=True,
        deleted_at=datetime.utcnow()
    )
    db.add(u)
    db.commit()
    db.refresh(u)

    assert u.is_active is False
    assert u.is_deactivated is True
    assert u.is_deleted is True
    assert u.deactivated_at is not None
    assert u.deleted_at is not None

    db.delete(u)
    db.commit()
    db.close()
