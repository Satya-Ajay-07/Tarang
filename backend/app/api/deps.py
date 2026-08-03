from fastapi import Depends, Header
from sqlalchemy.orm import Session
from app.core import security
from app.core.database import get_db
from app.core.exceptions import UnauthorizedException, ForbiddenException
from app.models.models import User

def get_token_from_header(authorization: str = Header(None)) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise UnauthorizedException(detail="Missing authorization header or invalid format", code="UNAUTHORIZED")
    return authorization.split(" ")[1]

def get_current_user(token: str = Depends(get_token_from_header), db: Session = Depends(get_db)) -> User:
    payload = security.decode_token(token)
    if not payload or payload.get("type") != "access":
        raise UnauthorizedException(detail="Could not validate credentials", code="TOKEN_INVALID")
    
    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedException(detail="Token missing user information", code="TOKEN_INVALID")
        
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise UnauthorizedException(detail="User not found", code="USER_NOT_FOUND")
        
    return user

def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    if not current_user.is_active:
        raise UnauthorizedException(detail="Inactive user", code="USER_INACTIVE")
    if getattr(current_user, "is_deactivated", False):
        raise UnauthorizedException(detail="Account is deactivated", code="USER_DEACTIVATED")
    return current_user

class RoleChecker:
    def __init__(self, allowed_roles: list[str]):
        self.allowed_roles = allowed_roles

    def __call__(self, user: User = Depends(get_current_active_user)) -> User:
        if user.role not in self.allowed_roles:
            raise ForbiddenException(detail="Operation not permitted for this role", code="INSUFFICIENT_PERMISSIONS")
        return user
