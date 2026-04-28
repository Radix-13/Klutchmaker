from fastapi import APIRouter, HTTPException
from typing import List
from pydantic import BaseModel
from ..models.team import Team
from ..services.team_service import TeamService
from .. import state

router = APIRouter(tags=["Team Builder"])
team_service = TeamService()

class ManualTeamsIn(BaseModel):
    team1_name: str
    team1_players: List[str]
    team2_name: str
    team2_players: List[str]

def _player_dict(p):
    return {
        "name": p.name,
        "position": p.position,
        "goals": p.goals,
        "assists": p.assists,
        "matches_played": p.matches_played,
        "yellow_cards": p.yellow_cards,
        "red_cards": p.red_cards
    }

def _team_dict(t: Team):
    return {
        "name": t.name,
        "players": [_player_dict(p) for p in t.players],
        "group_name": t.group_name,
        "goals": t.team_goals(),
        "assists": t.team_assists(),
        "points": t.points,
        "wins": t.wins,
        "draws": t.draws,
        "losses": t.losses,
        "goals_for": t.goals_for,
        "goals_against": t.goals_against,
        "goal_difference": t.goal_difference()
    }

@router.get("/")
def get_saved_teams():
    return [_team_dict(t) for t in state.saved_teams]

@router.post("/auto-balance")
def create_balanced_teams():
    if len(state.players) < 2:
        raise HTTPException(status_code=400, detail="Need at least 2 players")
    t1, t2 = team_service.create_balanced_teams(list(state.players))
    # We don't automatically add to tournament. We just return them or save them to state.
    state.saved_teams = [t1, t2]
    return [_team_dict(t1), _team_dict(t2)]

@router.post("/manual")
def create_teams_manual(data: ManualTeamsIn):
    t1 = Team(data.team1_name)
    t2 = Team(data.team2_name)
    player_map = {p.name.lower(): p for p in state.players}
    
    for name in data.team1_players:
        p = player_map.get(name.lower())
        if p: t1.add_player(p)
    for name in data.team2_players:
        p = player_map.get(name.lower())
        if p: t2.add_player(p)
        
    if not t1.players or not t2.players:
        raise HTTPException(status_code=400, detail="Teams cannot be empty")
        
    state.saved_teams = [t1, t2]
    return [_team_dict(t1), _team_dict(t2)]

@router.delete("/")
def clear_saved_teams():
    state.saved_teams.clear()
    return {"message": "Saved teams cleared"}
