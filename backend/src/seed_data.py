import datetime
from sqlalchemy import text
from src.database import SessionLocal, engine
from src.models import User, Event, Ticket, Alert, AuditLog, CrowdVerification
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password):
    # bcrypt only supports up to 72 chars
    return pwd_context.hash(password[:72])

def seed():
    db = SessionLocal()
    try:
        # 1. Users
        users = [
            User(username="admin", password_hash=hash_password("admin123"), role="admin"),
            User(username="user1", password_hash=hash_password("user123"), role="attendee"),
            User(username="user2", password_hash=hash_password("user123"), role="attendee"),
            User(username="user3", password_hash=hash_password("user123"), role="attendee"),
            User(username="user4", password_hash=hash_password("password123"), role="attendee"),
            User(username="user5", password_hash=hash_password("password123"), role="attendee"),
            User(username="user6", password_hash=hash_password("password123"), role="attendee"),
            User(username="user7", password_hash=hash_password("user123"), role="attendee"),
            User(username="user8", password_hash=hash_password("user123"), role="attendee"),
            User(username="user9", password_hash=hash_password("user123"), role="attendee"),
        ]
        db.add_all(users)
        db.commit()

        # 2. Events
        events = [
            Event(name="Rock Concert", location="Stadium A", date=datetime.datetime(2026, 5, 20, 19, 0)),
            Event(name="Tech Conference", location="Expo Center", date=datetime.datetime(2026, 6, 15, 9, 0)),
            Event(name="Football Match", location="Arena B", date=datetime.datetime(2026, 7, 10, 18, 0)),
            Event(name="Jazz Festival", location="Park C", date=datetime.datetime(2026, 8, 5, 17, 0)),
            Event(name="Startup Meetup", location="Hotel D", date=datetime.datetime(2026, 9, 1, 10, 0)),
        ]
        db.add_all(events)
        db.commit()

        # 3. Tickets
        tickets = []
        for i in range(20):
            tickets.append(Ticket(
                ticket_id=f"TKT{i+1:04d}",
                user_id=(i % 10) + 1,
                event_id=(i % 5) + 1,
                status="used" if i % 3 == 0 else "active"
            ))
        db.add_all(tickets)
        db.commit()

        # 4. Alerts
        alerts = [
            Alert(event_id=1, message="Crowd density high near entrance.", level="alert"),
            Alert(event_id=2, message="Capacity at 90%.", level="alert"),
            Alert(event_id=3, message="Medical emergency reported.", level="alert"),
            Alert(event_id=4, message="Weather warning issued.", level="alert"),
            Alert(event_id=5, message="VIP arrival at venue.", level="alert"),
            Alert(event_id=1, message="All clear.", level="safe"),
            Alert(event_id=2, message="Crowd dispersing.", level="safe"),
            Alert(event_id=3, message="Security check complete.", level="safe"),
            Alert(event_id=4, message="Event delayed.", level="alert"),
            Alert(event_id=5, message="Lost child found.", level="safe"),
        ]
        db.add_all(alerts)
        db.commit()

        # 5. Audit Logs
        logs = []
        for i in range(1, 11):
            logs.append(AuditLog(user_id=i, action="login", timestamp=datetime.datetime.now()))
        for i in range(1, 6):
            logs.append(AuditLog(user_id=i, action="ticket_scan", timestamp=datetime.datetime.now()))
        db.add_all(logs)
        db.commit()

        # 6. Crowd Points (lat/lng readings)
        from src.models import CrowdPoint
        crowd_points = []
        for i in range(10):
            crowd_points.append(CrowdPoint(
                event_id=(i % 5) + 1,
                lat=37.77 + (i * 0.01),
                lng=-122.41 + (i * 0.01),
                created_at=datetime.datetime.now() - datetime.timedelta(minutes=i*10)
            ))
        db.add_all(crowd_points)
        db.commit()

        # 7. Crowd Verifications
        from src.models import CrowdVerification
        for i in range(10):
            db.add(CrowdVerification(
                ticket_pk_id=((i % 20) + 1),
                verified_at=datetime.datetime.now() - datetime.timedelta(minutes=i*7),
                verifier_id=((i+1) % 10) + 1
            ))
        db.commit()

        # 8. VIEWS
        try:
            db.execute(text("DROP VIEW IF EXISTS event_occupancy_view"))
            db.execute(text("""
                CREATE VIEW event_occupancy_view AS
                SELECT e.event_id, e.name, COUNT(t.ticket_pk_id) AS ticket_count
                FROM events e
                LEFT JOIN tickets t ON e.event_id = t.event_id
                GROUP BY e.event_id
            """))
        except Exception as ve:
            print("Skipping event_occupancy_view creation:", ve)
        try:
            db.execute(text("DROP VIEW IF EXISTS user_ticket_summary"))
            db.execute(text("""
                CREATE VIEW user_ticket_summary AS
                SELECT u.user_id, u.username, COUNT(t.ticket_pk_id) AS ticket_count
                FROM users u
                LEFT JOIN tickets t ON u.user_id = t.user_id
                GROUP BY u.user_id
            """))
        except Exception as ve:
            print("Skipping user_ticket_summary creation:", ve)

        # 9. TRIGGERS
        try:
            db.execute(text("DROP TRIGGER IF EXISTS after_ticket_scan"))
            db.execute(text("""
                CREATE TRIGGER after_ticket_scan
                AFTER UPDATE ON tickets
                FOR EACH ROW
                BEGIN
                    IF NEW.status = 'used' AND OLD.status != 'used' THEN
                        INSERT INTO audit_logs (user_id, action, timestamp)
                        VALUES (NEW.user_id, 'ticket_scanned', NOW());
                    END IF;
                END
            """))
        except Exception as te:
            print("Skipping after_ticket_scan trigger:", te)
        # after_verification trigger removed: crowd_points table does not have a density column

        # 10. STORED PROCEDURE with CURSOR
        try:
            db.execute(text("DROP PROCEDURE IF EXISTS flag_over_capacity"))
            db.execute(text("""
                CREATE PROCEDURE flag_over_capacity()
                BEGIN
                    DECLARE done INT DEFAULT FALSE;
                    DECLARE eid INT;
                    DECLARE tcount INT;
                    DECLARE cap INT DEFAULT 100; -- Assume capacity 100 for demo
                    DECLARE cur CURSOR FOR SELECT e.event_id, COUNT(t.ticket_pk_id) FROM events e LEFT JOIN tickets t ON e.event_id = t.event_id GROUP BY e.event_id;
                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
                    OPEN cur;
                    read_loop: LOOP
                        FETCH cur INTO eid, tcount;
                        IF done THEN
                            LEAVE read_loop;
                        END IF;
                        IF tcount > cap * 0.8 THEN
                            INSERT INTO alerts (event_id, message, level, created_at)
                            VALUES (eid, 'Event over 80% capacity', 'alert', NOW());
                        END IF;
                    END LOOP;
                    CLOSE cur;
                END
            """))
        except Exception as pe:
            print("Skipping flag_over_capacity procedure:", pe)

        # 11. Complex Queries
        print("Sample JOIN query:")
        res = db.execute(text("""
            SELECT u.username, e.name AS event, t.status
            FROM users u
            JOIN tickets t ON u.user_id = t.user_id
            JOIN events e ON t.event_id = e.event_id
            WHERE t.status = 'used'
        """))
        for row in res.fetchall():
            print(row)

        print("Sample UNION query:")
        res = db.execute(text("""
            SELECT username FROM users WHERE user_id <= 5
            UNION
            SELECT username FROM users WHERE user_id > 5
        """))
        for row in res.fetchall():
            print(row)

        print("Sample subquery:")
        res = db.execute(text("""
            SELECT e.name FROM events e
            WHERE e.event_id IN (SELECT event_id FROM tickets WHERE status = 'used')
        """))
        for row in res.fetchall():
            print(row)

        print("All seed data and SQL objects created successfully.")

    except Exception as e:
        print("Error during seeding:", e)
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed()