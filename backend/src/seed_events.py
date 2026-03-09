"""Seed sample events for demo."""
import datetime
from src.database import SessionLocal
from src.models import Event

events_data = [
    {"name": "Tech Summit 2025", "location": "Convention Center, Hall A", "date": datetime.datetime(2025, 8, 15, 9, 0)},
    {"name": "Music Festival", "location": "Central Park Amphitheater", "date": datetime.datetime(2025, 9, 20, 16, 0)},
    {"name": "AI & ML Conference", "location": "Innovation Hub, Room 301", "date": datetime.datetime(2025, 10, 5, 10, 0)},
]

def main():
    db = SessionLocal()
    try:
        for data in events_data:
            existing = db.query(Event).filter(Event.name == data["name"]).first()
            if existing:
                print(f"Event '{data['name']}' already exists, skipping.")
                continue
            db.add(Event(**data))
            print(f"Created event: {data['name']}")
        db.commit()
        print("Done.")
    finally:
        db.close()

if __name__ == "__main__":
    main()
