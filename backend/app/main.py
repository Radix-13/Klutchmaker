from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .api import players, teams, tournament

app = FastAPI(
    title="KlutchMaker API",
    description="Sports tournament and match scheduling system with live stats",
    version="1.0.0"
)

# Allow the Frontend to talk to the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(players.router, prefix="/api/players")
app.include_router(teams.router, prefix="/api/teams")
app.include_router(tournament.router, prefix="/api/tournament")