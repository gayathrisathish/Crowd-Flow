import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.auth import hash_password, verify_password, create_access_token, get_current_user
from src.database import get_db
from src.models import User, Ticket, Event
from src.schemas import UserRegister, UserLogin, Token, UserOut
from src.audit import log_action

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(body: UserRegister, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == body.username).first():
        raise HTTPException(status_code=400, detail="Username already taken")

    event = db.query(Event).filter(Event.id == body.event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    user = User(
        username=body.username,
        password_hash=hash_password(body.password),
        role="attendee",
    )
    db.add(user)
    db.flush()

    ticket = Ticket(
        ticket_id=str(uuid.uuid4()),
        user_id=user.id,
        event_id=body.event_id,
        status="active",
    )
    db.add(ticket)
    db.commit()
    db.refresh(user)

    log_action(db, "USER_REGISTER", user.id, f"Attendee registered for event {body.event_id}")
    return user


@router.post("/login", response_model=Token)
def login(body: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == body.username).first()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    token = create_access_token({"sub": user.id, "role": user.role})
    log_action(db, "USER_LOGIN", user.id)
    return {"access_token": token}


@router.get("/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)):
    return current_user
