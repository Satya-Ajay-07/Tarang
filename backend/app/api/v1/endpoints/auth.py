from datetime import timedelta
import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Response, Request, status, Cookie
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.redis import get_redis
from app.core.config import settings
from app.core import security
from app.core.exceptions import BadRequestException, UnauthorizedException, NotFoundException
from app.models.models import User
from app.schemas.schemas import UserCreate, UserLogin, UserResponse, Token
from fastapi.responses import JSONResponse, RedirectResponse
import redis

router = APIRouter()

# Simple Redis rate limiter helper for auth endpoints
def rate_limit_auth(request: Request, client_ip: str, redis_client: redis.Redis, limit: int = 5, window_seconds: int = 60):
    key = f"rate_limit:auth:{client_ip}"
    current = redis_client.get(key)
    if current and int(current) >= limit:
        raise BadRequestException(detail="Too many authentication attempts. Please try again later.", code="RATE_LIMIT_EXCEEDED")
    
    pipe = redis_client.pipeline()
    pipe.incr(key)
    pipe.expire(key, window_seconds)
    pipe.execute()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
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
    
    from app.core.mail import send_verification_email
    send_verification_email(db_user.email, db_user.username, verification_token)

    return db_user

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

    # Log simulated mail send
    print(f"[MAIL MOCK] Password Reset link for {user.email}: http://localhost:3000/reset-password?token={reset_token}")

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

@router.post("/verify-email")
def verify_email(token: str, db: Session = Depends(get_db), redis_client: redis.Redis = Depends(get_redis)):
    user_id = redis_client.get(f"email_verify:{token}")
    if not user_id:
        raise BadRequestException(detail="Invalid or expired verification token", code="VERIFY_TOKEN_INVALID")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException(detail="User not found")

    user.is_active = True
    db.commit()

    # Revoke verification token
    redis_client.delete(f"email_verify:{token}")

    return {"success": True, "message": "Email verified successfully"}
