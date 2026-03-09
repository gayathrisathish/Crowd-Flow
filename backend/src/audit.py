from sqlalchemy.orm import Session
from src.models import AuditLog


def log_action(db: Session, action: str, user_id: int | None, details: str | None = None):
    entry = AuditLog(action=action, user_id=user_id, details=details)
    db.add(entry)
    db.commit()
