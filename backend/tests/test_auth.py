"""
test_auth.py — Authentication flow tests for Tarang.

Fixtures (database, Redis mock, client) are provided by conftest.py.
The test client and dependency overrides are set up in conftest.
"""

import re
import pytest


# Import the client that conftest set up (same module instance as conftest, safe)
# We do NOT import mock_redis_client here to avoid the double-import problem
# (pytest imports conftest.py as 'conftest', but 'from tests.conftest import x'
#  imports it again as 'tests.conftest', creating two separate module instances).
# Instead, we capture the verification token from the MAIL MOCK stdout output.
from tests.conftest import client


def test_register(capsys):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "test@tarang.in",
            "username": "testrider",
            "password": "securepassword",
            "full_name": "Test Rider"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@tarang.in"
    assert data["username"] == "testrider"
    assert "id" in data


def test_login(capsys):
    # Register user
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "login@tarang.in",
            "username": "loginrider",
            "password": "loginpassword",
            "full_name": "Login Rider"
        }
    )
    assert register_response.status_code == 201

    # Extract the verification token from the MAIL MOCK stdout output.
    # This sidesteps the Redis module double-import problem entirely.
    captured = capsys.readouterr()
    match = re.search(r"token=([0-9a-f\-]+)", captured.out)
    assert match is not None, f"Could not find token in MAIL MOCK output:\n{captured.out}"
    verify_token = match.group(1)

    # Verify email
    verify_response = client.post(f"/api/v1/auth/verify-email?token={verify_token}")
    assert verify_response.status_code == 200

    # Login
    response = client.post(
        "/api/v1/auth/login",
        json={
            "username_or_email": "loginrider",
            "password": "loginpassword"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
