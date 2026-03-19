from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from src.auth import get_current_user, require_admin
from src.database import get_db
from src.models import Ticket, User
from src.schemas import TicketOut

router = APIRouter(prefix="/tickets", tags=["Tickets"])


@router.get("/me", response_model=List[TicketOut])
def my_tickets(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return db.query(Ticket).filter(Ticket.user_id == current_user.user_id).all()


@router.get("/", response_model=List[TicketOut])
def all_tickets(
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    return db.query(Ticket).all()


@router.get("/{ticket_id}", response_model=TicketOut)
def get_ticket(
    ticket_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ticket = db.query(Ticket).filter(Ticket.ticket_id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    if current_user.role != "admin" and ticket.user_id != current_user.user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    return ticket
