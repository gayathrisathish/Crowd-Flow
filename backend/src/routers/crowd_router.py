import math
import random
from collections import defaultdict
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.database import get_db
from src.auth import get_current_user
from src.models import CrowdPoint, Event, Alert, User

router = APIRouter(prefix="/crowd", tags=["Crowd"])

# Chennai default center
DEFAULT_CENTER = {"lat": 13.0827, "lng": 80.2707}
CROWD_THRESHOLD = 25

# Fixed hotspot zones for clustering
HOTSPOTS = [
    {"lat": 13.0840, "lng": 80.2105, "name": "Zone A"},
    {"lat": 13.0875, "lng": 80.2200, "name": "Zone B"},
    {"lat": 13.0785, "lng": 80.2135, "name": "Zone C"},
]


def _dist(lat1, lng1, lat2, lng2):
    return math.sqrt((lat1 - lat2) ** 2 + (lng1 - lng2) ** 2)


def _cluster_points(points: list[dict]) -> list[dict]:
    """Assign each point to the nearest hotspot zone, then aggregate."""
    if not points:
        return []

    zone_members = defaultdict(list)
    for p in points:
        # Find nearest hotspot
        nearest_idx = min(
            range(len(HOTSPOTS)),
            key=lambda i: _dist(p["lat"], p["lng"], HOTSPOTS[i]["lat"], HOTSPOTS[i]["lng"]),
        )
        zone_members[nearest_idx].append(p)

    clusters = []
    for idx, members in zone_members.items():
        avg_lat = sum(m["lat"] for m in members) / len(members)
        avg_lng = sum(m["lng"] for m in members) / len(members)
        size = len(members)
        exceeds = size >= CROWD_THRESHOLD
        clusters.append({
            "id": idx,
            "lat": round(avg_lat, 4),
            "lng": round(avg_lng, 4),
            "size": size,
            "exceeds_threshold": exceeds,
            "status": "CROWDED" if exceeds else "NORMAL",
        })

    return sorted(clusters, key=lambda c: c["id"])


@router.get("/{event_id}")
def get_crowd_data(event_id: int, db: Session = Depends(get_db),
                   _user: User = Depends(get_current_user)):
    points = db.query(CrowdPoint).filter(CrowdPoint.event_id == event_id).all()
    point_list = [{"id": p.crowd_point_id, "lat": p.lat, "lng": p.lng} for p in points]
    clusters = _cluster_points(point_list)
    high_density = sum(1 for c in clusters if c["exceeds_threshold"])
    return {
        "points": point_list,
        "clusters": clusters,
        "total_users": len(point_list),
        "active_clusters": len(clusters),
        "high_density": high_density,
        "threshold": CROWD_THRESHOLD,
    }


@router.post("/{event_id}/simulate")
def simulate_crowd(event_id: int, db: Session = Depends(get_db),
                   _user: User = Depends(get_current_user)):
    """Add +20 people at random positions around the event area."""
    new_points = []
    for _ in range(20):
        # 85% chance to cluster near a hotspot, 15% random spread
        if random.random() < 0.85:
            h = random.choice(HOTSPOTS)
            lat = h["lat"] + random.gauss(0, 0.002)
            lng = h["lng"] + random.gauss(0, 0.002)
        else:
            lat = DEFAULT_CENTER["lat"] + random.uniform(-0.015, 0.015)
            lng = DEFAULT_CENTER["lng"] + random.uniform(-0.015, 0.015)

        pt = CrowdPoint(event_id=event_id, lat=round(lat, 6), lng=round(lng, 6))
        db.add(pt)
        new_points.append(pt)

    db.commit()

    # Check for threshold breaches and auto-create alerts
    all_points = db.query(CrowdPoint).filter(CrowdPoint.event_id == event_id).all()
    all_point_list = [{"id": p.crowd_point_id, "lat": p.lat, "lng": p.lng} for p in all_points]
    clusters = _cluster_points(all_point_list)
    for c in clusters:
        if c["exceeds_threshold"]:
            alert = Alert(
                event_id=event_id,
                message=f"Cluster {c['id']+1} is CROWDED — {c['size']} people detected (threshold: {CROWD_THRESHOLD})",
                level="alert",
            )
            db.add(alert)
    db.commit()

    # Return updated state
    return get_crowd_data(event_id, db, _user)


@router.delete("/{event_id}/reset")
def reset_crowd(event_id: int, db: Session = Depends(get_db),
                _user: User = Depends(get_current_user)):
    """Clear all crowd data for an event."""
    db.query(CrowdPoint).filter(CrowdPoint.event_id == event_id).delete()
    db.commit()
    return {"message": "Crowd data reset", "event_id": event_id}
