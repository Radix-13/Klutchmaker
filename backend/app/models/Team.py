from typing import List
from .player import Player

class Team:
    def __init__(self, name: str):
        self.name = name
        self.players: List[Player] = []
        self.group_name: str = "" # Associated group

        self.goals = 0
        self.assists = 0
        
        # Standings fields
        self.points = 0
        self.wins = 0
        self.draws = 0
        self.losses = 0
        self.goals_for = 0
        self.goals_against = 0

    def add_player(self, player: Player):
        self.players.append(player)

    def remove_player(self, player: Player):
        self.players.remove(player)

    def team_size(self):
        return len(self.players)

    def team_goals(self):
        return sum(p.goals for p in self.players)

    def team_assists(self):
        return sum(p.assists for p in self.players)
        
    def goal_difference(self):
        return self.goals_for - self.goals_against
        
    def add_match_result(self, gf: int, ga: int):
        self.goals_for += gf
        self.goals_against += ga
        if gf > ga:
            self.wins += 1
            self.points += 3
        elif gf == ga:
            self.draws += 1
            self.points += 1
        else:
            self.losses += 1