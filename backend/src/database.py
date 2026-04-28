import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.exc import OperationalError
from src.config import DATABASE_URL

# Try creating a MySQL engine first (from config). If the DB is unreachable,
# fall back to a local SQLite file for development so the app can run without
# requiring Docker or a remote MySQL instance.

def _create_engine_with_fallback(url: str):
    try:
        # Try with Unix socket if connecting to localhost
        connect_args = {"connection_timeout": 10, "use_pure": True}
        if "localhost" in url:
            connect_args["unix_socket"] = "/tmp/mysql.sock"
        
        engine = create_engine(
            url,
            pool_pre_ping=True,
            pool_recycle=300,
            connect_args=connect_args,
        )
        # attempt a short-lived connection to verify availability
        conn = engine.connect()
        conn.close()
        print(f"Using primary database: {url}")
        return engine
    except Exception as e:  # catch OperationalError and others
        print(f"WARNING: Could not connect to primary DB ({url}): {e}")
        sqlite_url = "sqlite:///./crowd_flow_dev.db"
        print(f"Falling back to SQLite database at {sqlite_url}")
        engine = create_engine(sqlite_url, connect_args={"check_same_thread": False})
        return engine


engine = _create_engine_with_fallback(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
