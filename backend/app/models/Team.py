from typing import List
from .player import Player

class Team:
    def __init__(self, name: str):
        self.name = name
        self.players: List[Player] = []

        self.goals = 0
        self.assists = 0

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