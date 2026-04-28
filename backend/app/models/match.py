from typing import List, Optional
from .team import Team
from .player import Player

class Match:
    def __init__(self, team1: Team, team2: Team, match_type: str = "group", next_match_index: Optional[int] = None):
        self.team1 = team1
        self.team2 = team2

        self.team1_score = 0
        self.team2_score = 0

        self.is_finished = False
        
        self.match_type = match_type
        self.next_match_index = next_match_index

        # store events for stats
        # List of dicts: {"type": "goal"|"yellow_card"|"red_card", "player": Player, "team": Team, "assist": Player | None}
        self.events = []

    def add_goal(self, player: Player, team: Team, assist: Optional[Player] = None):
        self.events.append({
            "type": "goal",
            "player": player,
            "team": team,
            "assist": assist
        })

        if team == self.team1:
            self.team1_score += 1
        else:
            self.team2_score += 1

        player.add_goal()
        if assist:
            assist.add_assist()
            
    def add_card(self, player: Player, team: Team, card_type: str):
        if card_type not in ["yellow_card", "red_card"]:
            raise ValueError("Invalid card type")
            
        self.events.append({
            "type": card_type,
            "player": player,
            "team": team,
            "assist": None
        })
        
        if card_type == "yellow_card":
            player.add_yellow_card()
        else:
            player.add_red_card()

    def undo_last_event(self):
        if not self.events:
            return None
        
        last_event = self.events.pop()
        player = last_event["player"]
        team = last_event["team"]
        assist = last_event["assist"]
        event_type = last_event.get("type", "goal")

        if event_type == "goal":
            if team == self.team1:
                self.team1_score = max(0, self.team1_score - 1)
            else:
                self.team2_score = max(0, self.team2_score - 1)

            # Reverse stats
            player.goals = max(0, player.goals - 1)
            if assist:
                assist.assists = max(0, assist.assists - 1)
        elif event_type == "yellow_card":
            player.yellow_cards = max(0, player.yellow_cards - 1)
        elif event_type == "red_card":
            player.red_cards = max(0, player.red_cards - 1)
        
        return last_event

    def finish_match(self):
        self.is_finished = True
        # For group/league matches, update team stats
        if self.match_type in ["group", "league"]:
            self.team1.add_match_result(self.team1_score, self.team2_score)
            self.team2.add_match_result(self.team2_score, self.team1_score)