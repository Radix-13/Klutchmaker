from typing import List
from .models.player import Player
from .models.team import Team
from .models.tournament import Tournament

# Global state for independent modules
players: List[Player] = []
saved_teams: List[Team] = []
active_tournament: Tournament = Tournament()
