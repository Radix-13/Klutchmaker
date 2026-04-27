import random
from typing import List
from ..models.player import Player
from ..models.team import Team

class TeamService:

    def create_balanced_teams(self, players: List[Player]):
        random.shuffle(players)

        team1 = Team("Team A")
        team2 = Team("Team B")

        toggle = True

        for player in players:
            if toggle:
                team1.add_player(player)
            else:
                team2.add_player(player)
            toggle = not toggle

        return team1, team2