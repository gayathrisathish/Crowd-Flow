from datetime import datetime
from typing import Optional
from pydantic import BaseModel


# ── Auth ──────────────────────────────────────────
class UserRegister(BaseModel):
    username: str
    password: str
    event_id: int  # attendee picks an event at registration


class UserLogin(BaseModel):
    username: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    user_id: int
    username: str
    role: str
    registered_at: datetime

    class Config:
        from_attributes = True


# ── Events ────────────────────────────────────────
class EventCreate(BaseModel):
    name: str
    location: str
    date: datetime


class EventUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    date: Optional[datetime] = None


class EventOut(BaseModel):
    event_id: int
    name: str
    location: str
    date: datetime

    class Config:
        from_attributes = True


# ── Tickets ───────────────────────────────────────
class TicketOut(BaseModel):
    ticket_pk_id: int
    ticket_id: str
    user_id: int
    event_id: int
    status: str

    class Config:
        from_attributes = True


# ── Alerts ────────────────────────────────────────
class AlertCreate(BaseModel):
    event_id: int
    message: str
    level: str = "alert"


class AlertOut(BaseModel):
    alert_id: int
    event_id: int
    message: str
    level: str
    created_at: datetime

    class Config:
        from_attributes = True


# ── Crowd Verification ───────────────────────────
class VerifyRequest(BaseModel):
    ticket_id: str  # the unique ticket_id string


class VerificationOut(BaseModel):
    verification_id: int
    ticket_pk_id: int
    verified_at: datetime
    verifier_id: int

    class Config:
        from_attributes = True


# ── Audit Logs ────────────────────────────────────
class AuditLogOut(BaseModel):
    audit_id: int
    action: str
    user_id: Optional[int]
    timestamp: datetime
    details: Optional[str]

    class Config:
        from_attributes = True
