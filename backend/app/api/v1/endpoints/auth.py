from datetime import timedelta
import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Response, Request, status, Cookie
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.redis import get_redis
from app.core.config import settings
from app.core import security
from app.core.exceptions import BadRequestException, UnauthorizedException, NotFoundException, EmailDeliveryException
from app.models.models import User
from app.schemas.schemas import UserCreate, UserLogin, UserResponse, Token, RegisterResponse
from app.services.email import email_service
from fastapi.responses import JSONResponse, RedirectResponse
import redis
import logging

logger = logging.getLogger("app.api.auth")

router = APIRouter()

# Simple Redis rate limiter helper for auth endpoints
def rate_limit_auth(request: Request, client_ip: str, redis_client: redis.Redis, limit: int = 5, window_seconds: int = 60):
    import sys
    if "pytest" in sys.modules or settings.ENV == "test":
        return
    key = f"rate_limit:auth:{client_ip}"
    current = redis_client.get(key)
    if current and int(current) >= limit:
        raise BadRequestException(detail="Too many authentication attempts. Please try again later.", code="RATE_LIMIT_EXCEEDED")
    
    pipe = redis_client.pipeline()
    pipe.incr(key)
    pipe.expire(key, window_seconds)
    pipe.execute()

@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
def register(user_in: UserCreate, request: Request, db: Session = Depends(get_db), redis_client: redis.Redis = Depends(get_redis)):
    # Rate limiting
    client_ip = request.client.host if request.client else "unknown"
    rate_limit_auth(request, client_ip, redis_client, limit=10, window_seconds=60)

    # Check unique constraints
    user_exists = db.query(User).filter((User.email == user_in.email) | (User.username == user_in.username)).first()
    if user_exists:
        raise BadRequestException(detail="Username or email already registered", code="REGISTRATION_FAILED")
    
    # Hash password and create user
    hashed_password = security.get_password_hash(user_in.password)
    db_user = User(
        email=user_in.email,
        username=user_in.username,
        full_name=user_in.full_name,
        hashed_password=hashed_password,
        country=user_in.country,
        phone_number=user_in.phone_number,
        role="user",
        is_active=False  # Inactive until email is verified
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # Generate email verification token
    verification_token = str(uuid.uuid4())
    # Store token in Redis for 24 hours
    redis_client.setex(f"email_verify:{verification_token}", 86400, db_user.id)
    
    warning = None
    try:
        from app.core.mail import send_verification_email
        success = send_verification_email(db_user.email, db_user.username, verification_token)
        if not success:
            warning = "Account created successfully, but verification email could not be delivered at this time."
    except Exception as e:
        logger.error(f"Error sending verification email during registration: {str(e)}")
        warning = "Account created successfully, but verification email could not be delivered at this time."

    user_response = UserResponse.model_validate(db_user)
    return RegisterResponse(
        success=True,
        user=user_response,
        warning=warning,
        # Flattened fields for backwards compatibility with existing tests
        id=db_user.id,
        email=db_user.email,
        username=db_user.username,
        full_name=db_user.full_name,
        country=db_user.country,
        avatar_url=db_user.avatar_url,
        cover_url=db_user.cover_url,
        bio=db_user.bio,
        location=db_user.location,
        created_at=db_user.created_at,
        role=db_user.role,
        phone_number=db_user.phone_number,
        website=db_user.website,
        twitter_url=db_user.twitter_url,
        github_url=db_user.github_url,
        pinned_wave_id=db_user.pinned_wave_id
    )

@router.post("/login")
def login(
    user_in: UserLogin,
    request: Request,
    db: Session =Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis)
):

    client_ip = request.client.host if request.client else "unknown"
    rate_limit_auth(request, client_ip, redis_client, limit=10, window_seconds=60)

    user = db.query(User).filter(
        (User.username == user_in.username_or_email) |
        (User.email == user_in.username_or_email)
    ).first()

    if not user or not security.verify_password(user_in.password, user.hashed_password):
        raise UnauthorizedException(
            detail="Invalid username/email or password",
            code="LOGIN_FAILED"
        )

    # Check if user account is deactivated
    if getattr(user, "is_deactivated", False):
        from datetime import datetime
        now = datetime.utcnow()
        deactivated_time = user.deactivated_at or user.created_at
        elapsed = now - deactivated_time
        days_passed = elapsed.total_seconds() / 86400.0
        
        if days_passed < 7.0:
            days_remaining = round(7.0 - days_passed, 1)
            if days_remaining <= 0:
                days_remaining = 0.1
            raise UnauthorizedException(
                detail="Your account is taking a break. You can log in again after 7 days to automatically reactivate your account.",
                code="ACCOUNT_DEACTIVATED_COOL_DOWN",
                extra={"days_remaining": days_remaining}
            )
        else:
            # Reactivate
            user.is_deactivated = False
            user.deactivated_at = None
            db.commit()

    if not user.is_active:
        raise UnauthorizedException(
            detail="Please verify your email first.",
            code="EMAIL_NOT_VERIFIED"
        )

    access_token = security.create_access_token(user.id)
    refresh_token = security.create_refresh_token(user.id)

    redis_client.setex(
        f"refresh_token:{user.id}:{refresh_token}",
        7 * 24 * 60 * 60,
        "active"
    )

    response = JSONResponse(
        content={
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer"
        }
    )

    response.set_cookie(
        key="refresh_token",
        value=refresh_token,
        httponly=True,
        secure=True,
        samesite="none",
        path="/",
        max_age=7 * 24 * 60 * 60,
    )

    return response

@router.post("/refresh", response_model=Token)
def refresh_token(
    request: Request,
    redis_client: redis.Redis = Depends(get_redis),
    db: Session = Depends(get_db),
):
    print("=" * 60)
    print("REFRESH ENDPOINT CALLED")

    refresh_token = None

    print("=" * 60)
    print("ALL HEADERS")

    for k, v in request.headers.items():
        print(k, ":", v)

    print("=" * 60)

    auth = request.headers.get("authorization")
    print("Authorization Header:", auth)

    if auth and auth.startswith("Bearer "):
        refresh_token = auth.split(" ")[1]

    print("Refresh Token:", refresh_token)

    if not refresh_token:
        raise UnauthorizedException(
            detail="Refresh token missing",
            code="REFRESH_TOKEN_MISSING"
        )

    payload = security.decode_token(refresh_token)
    print("Decoded Payload:", payload)

    if not payload or payload.get("type") != "refresh":
        raise UnauthorizedException(
            detail="Invalid refresh token",
            code="REFRESH_TOKEN_INVALID"
        )

    user_id = payload["sub"]

    token_status = redis_client.get(
        f"refresh_token:{user_id}:{refresh_token}"
    )

    print("Redis Status:", token_status)

    if not token_status:
        raise UnauthorizedException(
            detail="Refresh token revoked",
            code="REFRESH_TOKEN_REVOKED"
        )

    user = db.query(User).filter(User.id == user_id).first()

    new_access = security.create_access_token(user.id)
    new_refresh = security.create_refresh_token(user.id)

    redis_client.delete(
        f"refresh_token:{user.id}:{refresh_token}"
    )

    redis_client.setex(
        f"refresh_token:{user.id}:{new_refresh}",
        7 * 86400,
        "active"
    )

    print("Refresh Successful")

    return Token(
        access_token=new_access,
        refresh_token=new_refresh
    )
@router.post("/logout")
def logout(response: Response, request: Request, refresh_token: Optional[str] = Cookie(None), redis_client: redis.Redis = Depends(get_redis)):
    if refresh_token:
        payload = security.decode_token(refresh_token)
        if payload:
            user_id = payload.get("sub")
            if user_id:
                redis_client.delete(f"refresh_token:{user_id}:{refresh_token}")
                
    response.delete_cookie(
    key="refresh_token",
    path="/",
    secure=True,
    samesite="none",
    )
    return {"success": True, "message": "Successfully logged out"}

@router.post("/forgot-password")
def forgot_password(email: str, request: Request, db: Session = Depends(get_db), redis_client: redis.Redis = Depends(get_redis)):
    # Rate limiting
    client_ip = request.client.host if request.client else "unknown"
    rate_limit_auth(request, client_ip, redis_client, limit=5, window_seconds=60)

    user = db.query(User).filter(User.email == email).first()
    if not user:
        # Prevent user enumeration by returning success regardless
        return {"success": True, "message": "Password reset instructions sent if email exists."}

    # Generate reset token
    reset_token = str(uuid.uuid4())
    # Save token in redis with 2 hours expiry
    redis_client.setex(f"password_reset:{reset_token}", 7200, user.id)

    # Send password reset email
    success = email_service.send_password_reset_email(user.email, user.username, reset_token)
    if not success:
        raise EmailDeliveryException(detail="Failed to send password reset email. Please try again later.")

    return {"success": True, "message": "Password reset instructions sent if email exists."}

@router.post("/reset-password")
def reset_password(token: str, new_password: str, db: Session = Depends(get_db), redis_client: redis.Redis = Depends(get_redis)):
    user_id = redis_client.get(f"password_reset:{token}")
    if not user_id:
        raise BadRequestException(detail="Invalid or expired reset token", code="RESET_TOKEN_INVALID")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException(detail="User not found")

    # Update password
    user.hashed_password = security.get_password_hash(new_password)
    db.commit()

    # Revoke reset token
    redis_client.delete(f"password_reset:{token}")
    
    # Revoke all active refresh sessions to force relogin
    # Scan all user refresh tokens and delete
    for key in redis_client.scan_iter(f"refresh_token:{user.id}:*"):
        redis_client.delete(key)

    return {"success": True, "message": "Password updated successfully"}

from pydantic import EmailStr, BaseModel

class ResendVerificationRequest(BaseModel):
    email: EmailStr

@router.post("/resend-verification")
def resend_verification(
    req: ResendVerificationRequest,
    request: Request,
    db: Session = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis)
):
    # Rate limiting
    client_ip = request.client.host if request.client else "unknown"
    rate_limit_auth(request, client_ip, redis_client, limit=5, window_seconds=60)

    user = db.query(User).filter(User.email == req.email).first()
    if not user:
        # Prevent user enumeration by returning success regardless
        return {"success": True, "message": "Verification link sent if email exists."}

    if user.is_active:
        raise BadRequestException(
            detail="This email is already verified. Please log in.",
            code="EMAIL_ALREADY_VERIFIED"
        )

    cooldown_key = f"resend_verify_cooldown:{user.email}"
    if redis_client.exists(cooldown_key):
        raise BadRequestException(
            detail="Please wait 60 seconds before requesting another verification email.",
            code="RESEND_COOLDOWN"
        )

    # Generate new email verification token
    verification_token = str(uuid.uuid4())
    # Store token in Redis for 24 hours
    redis_client.setex(f"email_verify:{verification_token}", 86400, user.id)
    
    # Set cooldown for 60 seconds
    redis_client.setex(cooldown_key, 60, "active")

    from app.core.mail import send_verification_email
    success = send_verification_email(user.email, user.username, verification_token)
    if not success:
        raise EmailDeliveryException(detail="Failed to send verification email. Please try again later.")

    return {"success": True, "message": "Verification link sent successfully."}

@router.post("/verify-email")
def verify_email(token: str, db: Session = Depends(get_db), redis_client: redis.Redis = Depends(get_redis)):
    user_id = redis_client.get(f"email_verify:{token}")
    if not user_id:
        raise BadRequestException(
            detail="The verification link is invalid or has expired. Please request a new one.",
            code="VERIFY_TOKEN_INVALID"
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException(detail="User not found")

    if user.is_active:
        redis_client.delete(f"email_verify:{token}")
        return {"success": True, "message": "Email verified successfully"}

    user.is_active = True
    db.commit()

    # Revoke verification token
    redis_client.delete(f"email_verify:{token}")

    # Automatically send welcome email
    try:
        email_service.send_welcome_email(user.email, user.username)
    except Exception as e:
        logger.error(f"Failed to send welcome email to {user.email}: {str(e)}")

    return {"success": True, "message": "Email verified successfully"}
