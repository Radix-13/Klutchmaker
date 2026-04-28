from typing import List, Optional
from .team import Team
from .match import Match

class Tournament:
    def __init__(self, t_type: str = "league"):
        # "league", "knockout", "group_knockout"
        self.type = t_type
        self.status = "setup" # setup, active, finished
        self.teams: List[Team] = []
        self.matches: List[Match] = []
        
    def start(self):
        if len(self.teams) < 2:
            raise ValueError("Need at least 2 teams to start.")
        if not self.matches:
            raise ValueError("Matches must be scheduled before starting.")
        self.status = "active"
        
    def get_standings(self):
        # Sort by Points (desc), then Goal Difference (desc), then Goals For (desc)
        return sorted(self.teams, key=lambda t: (t.points, t.goal_difference(), t.goals_for), reverse=True)

    def get_standings_by_group(self):
        groups = {}
        for t in self.teams:
            gn = t.group_name or "Group A"
            if gn not in groups: groups[gn] = []
            groups[gn].append(t)
        
        results = {}
        for gn, teams in groups.items():
            results[gn] = sorted(teams, key=lambda t: (t.points, t.goal_difference(), t.goals_for), reverse=True)
        return results
