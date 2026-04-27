from typing import List
from .team import Team
from .player import Player

class Match:
    def __init__(self, team1: Team, team2: Team):
        self.team1 = team1
        self.team2 = team2

        self.team1_score = 0
        self.team2_score = 0

        self.is_finished = False

        # store events for stats
        self.goals = []   # (player, team)
        self.assists = [] # (player, team)

    def add_goal(self, player: Player, team: Team):
        self.goals.append(player)

        if team == self.team1:
            self.team1_score += 1
        else:
            self.team2_score += 1

        player.add_goal()

    def add_assist(self, player: Player):
        self.assists.append(player)
        player.add_assist()

    def finish_match(self):
        self.is_finished = True