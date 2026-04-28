from fastapi import APIRouter, HTTPException
from typing import List
from pydantic import BaseModel
from ..models.player import Player
from .. import state

router = APIRouter(tags=["Players"])

class PlayerIn(BaseModel):
    name: str
    position: str

def _player_dict(p: Player):
    return {
        "name": p.name,
        "position": p.position,
        "goals": p.goals,
        "assists": p.assists,
        "matches_played": p.matches_played,
        "yellow_cards": p.yellow_cards,
        "red_cards": p.red_cards
    }

@router.get("/")
def get_players():
    return [_player_dict(p) for p in state.players]

@router.post("/")
def add_player(player: PlayerIn):
    if any(p.name.lower() == player.name.lower() for p in state.players):
        raise HTTPException(status_code=400, detail="Player already exists")
    p = Player(player.name, player.position)
    state.players.append(p)
    return {"message": f"Player '{player.name}' added", "player": _player_dict(p)}

@router.delete("/{name}")
def remove_player(name: str):
    before = len(state.players)
    state.players = [p for p in state.players if p.name.lower() != name.lower()]
    if len(state.players) == before:
        raise HTTPException(status_code=404, detail="Player not found")
    return {"message": f"Player '{name}' removed"}

@router.delete("/")
def clear_all_players():
    state.players.clear()
    return {"message": "All players cleared"}
