from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from src.auth import require_admin
from src.database import get_db
from src.models import Ticket, CrowdVerification, User
from src.schemas import VerifyRequest, VerificationOut
from src.audit import log_action

router = APIRouter(prefix="/verify", tags=["Crowd Verification"])


@router.post("/", response_model=VerificationOut, status_code=201)
def verify_ticket(
    body: VerifyRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    ticket = db.query(Ticket).filter(Ticket.ticket_id == body.ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    if ticket.status != "active":
        raise HTTPException(status_code=404, detail="Ticket is not verified")

    existing = db.query(CrowdVerification).filter(CrowdVerification.ticket_pk_id == ticket.ticket_pk_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Ticket already verified")

    ticket.status = "used"
    verification = CrowdVerification(ticket_pk_id=ticket.ticket_pk_id, verifier_id=admin.user_id)
    db.add(verification)
    db.commit()
    db.refresh(verification)

    log_action(db, "TICKET_VERIFY", admin.user_id, f"Verified ticket {body.ticket_id}")
    return verification
