from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.auth import require_admin
from src.database import get_db
from src.models import Alert, User
from src.schemas import AlertCreate, AlertOut
from src.audit import log_action

router = APIRouter(prefix="/alerts", tags=["Alerts"])


@router.get("/", response_model=List[AlertOut])
def list_alerts(
    event_id: int | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(Alert)
    if event_id is not None:
        query = query.filter(Alert.event_id == event_id)
    return query.order_by(Alert.created_at.desc()).all()


@router.post("/", response_model=AlertOut, status_code=status.HTTP_201_CREATED)
def create_alert(
    body: AlertCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    if body.level not in ("alert", "safe"):
        raise HTTPException(status_code=400, detail="Level must be 'alert' or 'safe'")
    alert = Alert(event_id=body.event_id, message=body.message, level=body.level)
    db.add(alert)
    db.commit()
    db.refresh(alert)
    log_action(db, "ALERT_CREATE", admin.id, f"Alert for event {body.event_id}: {body.message}")
    return alert
