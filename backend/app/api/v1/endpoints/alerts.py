from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from app.api.deps import get_current_active_user
from app.core.database import get_db
from app.core.exceptions import NotFoundException
from app.models.models import User, WaveAlert
from app.schemas.schemas import WaveAlertResponse

router = APIRouter()

# Get recent wave alerts
@router.get("", response_model=List[WaveAlertResponse])
def get_alerts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    skip: int = 0,
    limit: int = 50
):
    alerts = db.query(WaveAlert).filter(
        WaveAlert.recipient_id == current_user.id
    ).order_by(WaveAlert.created_at.desc()).offset(skip).limit(limit).all()
    return alerts

# Mark all alerts as read
@router.post("/read")
def mark_all_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    db.query(WaveAlert).filter(
        WaveAlert.recipient_id == current_user.id,
        WaveAlert.is_read == False
    ).update({"is_read": True}, synchronize_session=False)
    db.commit()
    return {"success": True, "message": "All alerts marked as read"}

# Mark single alert as read
@router.post("/{alert_id}/read")
def mark_read(
    alert_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    alert = db.query(WaveAlert).filter(
        WaveAlert.id == alert_id,
        WaveAlert.recipient_id == current_user.id
    ).first()
    
    if not alert:
        raise NotFoundException(detail="Alert not found")
        
    alert.is_read = True
    db.commit()
    return {"success": True, "message": "Alert marked as read"}
