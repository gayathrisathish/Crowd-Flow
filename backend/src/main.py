from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.database import engine, Base
import src.models  # noqa: F401  — ensure models are registered with Base
from src.routers import (
    auth_router,
    events_router,
    tickets_router,
    alerts_router,
    verification_router,
    audit_router,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        Base.metadata.create_all(bind=engine)
        print("Database tables created successfully.")
    except Exception as e:
        print(f"WARNING: Could not connect to database: {e}")
        print("Server will start, but DB-dependent routes will fail until the DB is reachable.")
    yield


app = FastAPI(
    title="Crowd-Flow API",
    description="Event ticketing and crowd verification system",
    version="1.0.0",
    lifespan=lifespan,
)

import os

CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:5173").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(events_router.router)
app.include_router(tickets_router.router)
app.include_router(alerts_router.router)
app.include_router(verification_router.router)
app.include_router(audit_router.router)


@app.get("/", tags=["Health"])
def health_check():
    return {"status": "ok", "service": "Crowd-Flow API"}
