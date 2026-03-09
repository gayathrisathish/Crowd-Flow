from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.auth import require_admin
from src.database import get_db
from src.models import AuditLog, User
from src.schemas import AuditLogOut

router = APIRouter(prefix="/audit", tags=["Audit Logs"])


@router.get("/", response_model=List[AuditLogOut])
def list_audit_logs(
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    return db.query(AuditLog).order_by(AuditLog.timestamp.desc()).all()
