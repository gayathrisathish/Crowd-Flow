import datetime
from sqlalchemy import (
    Column, Integer, String, DateTime, Text, ForeignKey, Enum as SAEnum, Float,
)
from sqlalchemy.orm import relationship
from src.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column("user_id", Integer, primary_key=True, autoincrement=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(SAEnum("admin", "attendee", name="user_role"), nullable=False, default="attendee")
    registered_at = Column(DateTime, default=datetime.datetime.utcnow)

    tickets = relationship("Ticket", back_populates="user")
    audit_logs = relationship("AuditLog", back_populates="user")


class Event(Base):
    __tablename__ = "events"

    id = Column("event_id", Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    location = Column(String(255), nullable=False)
    date = Column(DateTime, nullable=False)

    tickets = relationship("Ticket", back_populates="event")
    alerts = relationship("Alert", back_populates="event")


class Ticket(Base):
    __tablename__ = "tickets"

    id = Column("ticket_pk_id", Integer, primary_key=True, autoincrement=True)
    ticket_id = Column(String(100), unique=True, nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    event_id = Column(Integer, ForeignKey("events.event_id"), nullable=False)
    status = Column(
        SAEnum("active", "used", "cancelled", name="ticket_status"),
        nullable=False,
        default="active",
    )

    user = relationship("User", back_populates="tickets")
    event = relationship("Event", back_populates="tickets")
    verification = relationship("CrowdVerification", back_populates="ticket", uselist=False)


class Alert(Base):
    __tablename__ = "alerts"

    id = Column("alert_id", Integer, primary_key=True, autoincrement=True)
    event_id = Column(Integer, ForeignKey("events.event_id"), nullable=False)
    message = Column(Text, nullable=False)
    level = Column(SAEnum("alert", "safe", name="alert_level"), nullable=False, default="alert")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    event = relationship("Event", back_populates="alerts")


class CrowdVerification(Base):
    __tablename__ = "crowd_verification"

    id = Column("verification_id", Integer, primary_key=True, autoincrement=True)
    ticket_id = Column("ticket_pk_id", Integer, ForeignKey("tickets.ticket_pk_id"), nullable=False)
    verified_at = Column(DateTime, default=datetime.datetime.utcnow)
    verifier_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    ticket = relationship("Ticket", back_populates="verification")
    verifier = relationship("User")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column("audit_id", Integer, primary_key=True, autoincrement=True)
    action = Column(String(255), nullable=False)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    details = Column(Text, nullable=True)

    user = relationship("User", back_populates="audit_logs")


class CrowdPoint(Base):
    __tablename__ = "crowd_points"

    id = Column("crowd_point_id", Integer, primary_key=True, autoincrement=True)
    event_id = Column(Integer, ForeignKey("events.event_id"), nullable=False)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    event = relationship("Event")
