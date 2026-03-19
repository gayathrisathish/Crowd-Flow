"""Seed 100 new attendees with tickets and crowd map positions."""
import sys, os, uuid, random, csv
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from src.database import SessionLocal, engine, Base
from src.models import User, Ticket, Event, CrowdPoint
from src.auth import hash_password
import src.models  # ensure all models registered
from passlib.context import CryptContext

# Fast bcrypt for seeding
fast_pwd = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=4)

Base.metadata.create_all(bind=engine)
db = SessionLocal()

# Hotspot zones matching crowd_router.py
HOTSPOTS = [
    (13.0840, 80.2105),
    (13.0875, 80.2200),
    (13.0785, 80.2135),
]

FIRST_NAMES = [
    "aiden","bella","caleb","diya","elijah","fatima","gavin","hana","isaac","jade",
    "kai","lena","mason","nadia","omar","piper","quinn","riya","soren","tara",
    "uriel","vera","wyatt","xena","yusuf","zara","arjun","bianca","carlos","daphne",
    "emilio","freya","gustavo","helene","ivan","jaya","kiran","lucia","mateo","nora",
    "oliver","priti","rafael","sara","theo","uma","victor","wendy","xavier","yasmin",
    "zane","amara","ben","cora","derek","elena","felix","gita","hugo","iris",
    "joel","kavya","leon","mila","nico","orla","paul","rosa","seth","tanvi",
    "uday","vikas","walt","xander","yara","zoe","akash","bina","cyrus","divya",
    "eric","faye","hari","ines","jay","kara","luke","maya","neil","opal",
    "pete","rina","suraj","tanya","usha","vinay","wren","yash","zena","anika",
]

LAST_NAMES = [
    "kumar","shah","johnson","williams","brown","jones","garcia","miller","davis","rodriguez",
    "martinez","hernandez","lopez","gonzalez","wilson","anderson","thomas","taylor","moore","jackson",
    "martin","lee","perez","thompson","white","harris","sanchez","clark","ramirez","lewis",
    "robinson","walker","young","allen","king","wright","scott","torres","nguyen","hill",
    "flores","green","adams","nelson","baker","hall","rivera","campbell","mitchell","carter",
]

events = db.query(Event).all()
if not events:
    print("No events found. Run seed_events.py first.")
    db.close()
    sys.exit(1)

event_ids = [e.event_id for e in events]
created = []

for i in range(100):
    first = FIRST_NAMES[i]
    last = random.choice(LAST_NAMES)
    username = f"{first}_{last}_{i+1}"
    password = f"{first}@2026"

    existing = db.query(User).filter(User.username == username).first()
    if existing:
        print(f"  Skip existing: {username}")
        continue

    user = User(
        username=username,
        password_hash=fast_pwd.hash(password[:72]),
        role="attendee",
    )
    db.add(user)
    db.flush()

    event_id = random.choice(event_ids)
    tid = str(uuid.uuid4())
    ticket = Ticket(ticket_id=tid, user_id=user.user_id, event_id=event_id, status="active")
    db.add(ticket)

    # Add a crowd point on that event's map near a random hotspot
    hotspot = random.choice(HOTSPOTS)
    lat = round(hotspot[0] + random.gauss(0, 0.002), 6)
    lng = round(hotspot[1] + random.gauss(0, 0.002), 6)
    cp = CrowdPoint(event_id=event_id, lat=lat, lng=lng)
    db.add(cp)

    created.append({
        "username": username,
        "password": password,
        "event_id": event_id,
        "ticket_id": tid,
    })
    print(f"  [{i+1}/100] {username} -> event {event_id}")

db.commit()
db.close()

# Write CSV
csv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "new_users_100.csv")
with open(csv_path, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["username", "password", "event_id", "ticket_id"])
    w.writeheader()
    w.writerows(created)

print(f"\nDone! {len(created)} users created. CSV saved to new_users_100.csv")
