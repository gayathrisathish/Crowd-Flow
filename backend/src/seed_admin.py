"""
Seed script: creates an admin user.

Usage:
    cd backend
    python -m src.seed_admin --username admin --password admin123
"""
import argparse
from src.database import SessionLocal, engine, Base
from src.models import User
from src.auth import hash_password

Base.metadata.create_all(bind=engine)


def main():
    parser = argparse.ArgumentParser(description="Create an admin user")
    parser.add_argument("--username", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()

    db = SessionLocal()
    try:
        if db.query(User).filter(User.username == args.username).first():
            print(f"User '{args.username}' already exists.")
            return

        admin = User(
            username=args.username,
            password_hash=hash_password(args.password),
            role="admin",
        )
        db.add(admin)
        db.commit()
        print(f"Admin user '{args.username}' created successfully.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
