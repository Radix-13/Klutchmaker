from fastapi import APIRouter, HTTPException
from typing import List, Optional, Dict
from pydantic import BaseModel

from ..models.player import Player
from ..models.team import Team
from ..models.match import Match
from ..models.tournament import Tournament
from ..services.schedule_service import ScheduleService
from .. import state

router = APIRouter(tags=["Tournament"])
schedule_service = ScheduleService()

# ── Pydantic schemas ───────────────────────────────────────────────
class TournamentSetupIn(BaseModel):
    type: str # league, knockout, group_knockout
    team_names: Optional[List[str]] = None
    teams: Optional[List[Dict]] = None 

class GoalIn(BaseModel):
    match_index: int
    team: int        # 1 or 2
    player_name: str
    assist_name: Optional[str] = None
    
class CardIn(BaseModel):
    match_index: int
    team: int
    player_name: str
    card_type: str # yellow_card, red_card

class MatchFinishIn(BaseModel):
    match_index: int

# ── Helpers ─────────────────────────────────────────────────────────
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

def _match_dict(idx: int, m: Match):
    return {
        "index": idx,
        "team1": _team_dict(m.team1) if m.team1.name != "TBD" else {"name": "TBD", "players": []},
        "team2": _team_dict(m.team2) if m.team2.name != "TBD" else {"name": "TBD", "players": []},
        "team1_score": m.team1_score,
        "team2_score": m.team2_score,
        "is_finished": m.is_finished,
        "match_type": m.match_type,
        "next_match_index": m.next_match_index,
        "events": [
            {
                "type": e.get("type", "goal"),
                "player": e["player"].name,
                "team": e["team"].name,
                "assist": e["assist"].name if e.get("assist") else None
            } for e in m.events
        ]
    }

# ── Endpoints ──────────────────────────────────────────────────────
@router.post("/setup")
def setup_tournament(data: TournamentSetupIn):
    # Reset tournament
    state.active_tournament = Tournament(t_type=data.type)
    
    # Priority 1: Simple Team Names
    if data.team_names:
        for name in data.team_names:
            state.active_tournament.teams.append(Team(name))
            
    # Priority 2: Full Team Objects (Legacy/Team Builder integration)
    elif data.teams:
        for t_data in data.teams:
            team = Team(t_data["name"])
            team.group_name = t_data.get("group_name", "")
            player_map = {p.name.lower(): p for p in state.players}
            for p_name in t_data.get("players", []):
                p = player_map.get(p_name.lower())
                if p: team.add_player(p)
            state.active_tournament.teams.append(team)
            
    return {"message": f"Tournament type set to {data.type}", "team_count": len(state.active_tournament.teams)}

@router.post("/create-schedule")
def create_schedule():
    tourney = state.active_tournament
    if len(tourney.teams) < 2:
        raise HTTPException(status_code=400, detail="Initialize tournament with teams first")
        
    t_type = tourney.type
    if t_type == "league":
        tourney.matches = schedule_service.generate_league(tourney.teams)
    elif t_type == "knockout":
        tourney.matches = schedule_service.generate_knockout(tourney.teams)
    elif t_type == "group_knockout":
        groups_map = {}
        for t in tourney.teams:
            gn = t.group_name if t.group_name else "Group A"
            if gn not in groups_map: groups_map[gn] = []
            groups_map[gn].append(t)
        tourney.matches = schedule_service.generate_group_knockout(groups_map)
    else:
        tourney.matches = schedule_service.generate_league(tourney.teams)
        
    tourney.start()
    return [_match_dict(i, m) for i, m in enumerate(tourney.matches)]

@router.get("/matches")
def get_matches():
    return [_match_dict(i, m) for i, m in enumerate(state.active_tournament.matches)]

@router.post("/matches/goal")
def add_goal(data: GoalIn):
    tourney = state.active_tournament
    if data.match_index >= len(tourney.matches):
        raise HTTPException(status_code=404, detail="Match not found")
    match = tourney.matches[data.match_index]
    if match.is_finished:
        raise HTTPException(status_code=400, detail="Match already finished")
    team = match.team1 if data.team == 1 else match.team2
    
    # Dynamic player lookup/creation
    players_in_team = {p.name.lower(): p for p in team.players}
    player = players_in_team.get(data.player_name.lower())
    
    if not player:
        # Create player on the fly for decoupled tournaments
        player = Player(name=data.player_name, position="Player")
        team.add_player(player)
        # Also add to global state so they show in leaderboard
        state.players.append(player)
        
    assist_player = None
    if data.assist_name:
        assist_player = players_in_team.get(data.assist_name.lower())
        if not assist_player and data.assist_name.strip():
            assist_player = Player(name=data.assist_name, position="Player")
            team.add_player(assist_player)
            state.players.append(assist_player)

    match.add_goal(player, team, assist_player)
    return _match_dict(data.match_index, match)

@router.post("/matches/card")
def add_card(data: CardIn):
    tourney = state.active_tournament
    if data.match_index >= len(tourney.matches):
        raise HTTPException(status_code=404, detail="Match not found")
    match = tourney.matches[data.match_index]
    if match.is_finished:
        raise HTTPException(status_code=400, detail="Match already finished")
    team = match.team1 if data.team == 1 else match.team2
    
    # Dynamic player lookup/creation
    players_in_team = {p.name.lower(): p for p in team.players}
    player = players_in_team.get(data.player_name.lower())
    
    if not player:
        player = Player(name=data.player_name, position="Player")
        team.add_player(player)
        state.players.append(player)
        
    match.add_card(player, team, data.card_type)
    return _match_dict(data.match_index, match)

@router.post("/matches/undo")
def undo_event(data: Dict[str, int]):
    idx = data.get("match_index")
    tourney = state.active_tournament
    if idx is None or idx >= len(tourney.matches):
        raise HTTPException(status_code=404, detail="Match not found")
    match = tourney.matches[idx]
    if match.is_finished:
        raise HTTPException(status_code=400, detail="Cannot undo finished match")
    match.undo_last_event()
    return _match_dict(idx, match)

@router.post("/matches/finish")
def finish_match(data: MatchFinishIn):
    tourney = state.active_tournament
    if data.match_index >= len(tourney.matches):
        raise HTTPException(status_code=404, detail="Match not found")
    match = tourney.matches[data.match_index]
    match.finish_match()
    
    for p in match.team1.players + match.team2.players:
        p.play_match()
        
    # Knockout Progression logic...
    if match.next_match_index is not None and match.next_match_index < len(tourney.matches):
        next_match = tourney.matches[match.next_match_index]
        winner = match.team1 if match.team1_score > match.team2_score else match.team2
        
        # In case of a draw in knockout (where a winner is needed),
        # we'll assume the user wants the first team to advance if they didn't provide a penalty score,
        # but better to let them decide or check scores. 
        # For now, if it's a draw, the winner logic might be ambiguous.
        # Let's ensure a winner exists.
        if match.team1_score == match.team2_score and match.match_type != "group" and match.match_type != "league":
             # Placeholder: maybe team1 advances by default or we wait for user?
             # For now, let's just pick team1 to avoid "stucking".
             winner = match.team1 

        if next_match.team1.name == "TBD":
            next_match.team1 = winner
        elif next_match.team2.name == "TBD":
            next_match.team2 = winner
            
    return _match_dict(data.match_index, match)

@router.post("/advance-knockout")
def advance_to_knockout():
    tourney = state.active_tournament
    if tourney.type != "group_knockout":
        raise HTTPException(status_code=400, detail="Only applicable to Group + Knockout format")
    
    # Get top teams from each group
    group_standings = tourney.get_standings_by_group()
    top_teams = []
    # Sort groups by name (Group A, Group B...)
    for gn in sorted(group_standings.keys()):
        teams = group_standings[gn]
        if len(teams) >= 2:
            top_teams.append(teams[0]) # 1st
            top_teams.append(teams[1]) # 2nd
        elif len(teams) >= 1:
            top_teams.append(teams[0])
            
    if len(top_teams) < 2:
        raise HTTPException(status_code=400, detail="Not enough teams qualified for knockout")
        
    knockout_matches = schedule_service.generate_knockout(top_teams)
    # Append knockout matches to existing list
    start_idx = len(tourney.matches)
    for i, m in enumerate(knockout_matches):
        # Update indices if needed (ScheduleService might need to know the offset)
        if m.next_match_index is not None:
            m.next_match_index += start_idx
        tourney.matches.append(m)
        
    return [_match_dict(i + start_idx, m) for i, m in enumerate(knockout_matches)]

@router.get("/stats/standings")
def standings():
    st = state.active_tournament.get_standings()
    return [_team_dict(t) for t in st]

@router.get("/stats/leaderboard")
def leaderboard():
    # Show stats for all players in the system
    sorted_players = sorted(state.players, key=lambda p: (p.goals, p.assists, p.matches_played), reverse=True)
    return [_player_dict(p) for p in sorted_players]