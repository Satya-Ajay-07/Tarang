from sqlalchemy.orm import Session
from app.models.models import User

def delete_user(db: Session, user: User) -> None:
    """
    Modular deletion service method to isolate account deletion behavior.
    Currently implements the existing soft-delete (setting is_active = False).
    Future deletion strategies (hard delete, anonymization, archival)
    can be plugged here without modifying API routes.
    """
    user.is_active = False
    db.commit()
