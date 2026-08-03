from datetime import datetime
from sqlalchemy.orm import Session
from app.models.models import User

def delete_user(db: Session, user: User) -> None:
    """
    Marks the account as permanently deleted using the dedicated is_deleted flag.
    is_active is NOT modified here — it represents email verification state only.
    Future deletion strategies (hard delete, anonymisation, data export before deletion)
    can be plugged here without modifying API routes.
    """
    # pyrefly: ignore [bad-assignment]
    user.is_deleted = True
    # pyrefly: ignore [bad-assignment, deprecated]
    user.deleted_at = datetime.utcnow()
    db.commit()
