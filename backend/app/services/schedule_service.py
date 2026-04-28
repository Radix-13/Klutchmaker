from typing import List, Optional
from ..models.team import Team
from ..models.match import Match
import math

class ScheduleService:

    def create_matches_from_groups(self, groups: List[List[Team]], match_type="group") -> List[Match]:
        """Creates round-robin matches for a given list of groups."""
        matches = []
        for group in groups:
            for i in range(len(group)):
                for j in range(i + 1, len(group)):
                    match = Match(group[i], group[j], match_type=match_type)
                    matches.append(match)
        return matches

    def generate_league(self, teams: List[Team]) -> List[Match]:
        """Round robin for all teams in a single group."""
        return self.create_matches_from_groups([teams], match_type="league")

    def generate_knockout(self, teams: List[Team]) -> List[Match]:
        """Generates a bracket. If teams is not a power of 2, adds byes (None)."""
        if len(teams) < 2:
            raise ValueError("Need at least 2 teams for a knockout.")

        # Pad to power of 2
        power = 1
        while power < len(teams):
            power *= 2
        
        # We need to create matches. For a simple bracket, we'll just pair them up.
        # A full bracket structure requires knowing which match winner goes where.
        
        matches = []
        
        # We'll create placeholders for rounds.
        # Round 1 (Quarter finals, etc.)
        current_round_teams = teams.copy()
        
        # If not power of 2, some teams get a bye.
        byes_needed = power - len(teams)
        for _ in range(byes_needed):
            current_round_teams.append(Team("BYE")) # Placeholder
            
        # To make it simple, we just generate the first round matches.
        # The backend will handle advancing winners.
        # Let's generate the whole tree.
        # Total matches = power - 1
        
        # We will create matches backwards from the final.
        # Final is match index (power - 2) if 0-indexed.
        # e.g., 8 teams -> 7 matches (idx 0 to 6). Final is 6.
        # Semi-finals are 4 and 5.
        # Quarter-finals are 0, 1, 2, 3.
        
        # Let's do a top-down approach for indexing.
        # Final: id 0.
        # Semis: id 1, 2 (feed into 0)
        # Quarters: id 3, 4, 5, 6 (feed into 1 and 2)
        
        # Actually, bottom-up is easier for initial population.
        # Round 1 matches: 0 to (power/2 - 1)
        # Round 2 matches: (power/2) to (power/2 + power/4 - 1)
        
        num_matches = power - 1
        matches = [None] * num_matches
        
        # Fill first round
        first_round_matches = power // 2
        team_idx = 0
        for i in range(first_round_matches):
            t1 = current_round_teams[team_idx]
            t2 = current_round_teams[team_idx + 1]
            team_idx += 2
            
            # If t2 is BYE, t1 auto-advances. But let's just create the match.
            matches[i] = Match(t1, t2, match_type="knockout")
            
        # Fill subsequent rounds
        current_match_idx = first_round_matches
        prev_round_start = 0
        prev_round_count = first_round_matches
        
        while prev_round_count > 1:
            next_round_count = prev_round_count // 2
            for i in range(next_round_count):
                # Placeholder teams
                m = Match(Team("TBD"), Team("TBD"), match_type="knockout")
                matches[current_match_idx + i] = m
                
                # Link previous matches to this one
                matches[prev_round_start + i * 2].next_match_index = current_match_idx + i
                matches[prev_round_start + i * 2 + 1].next_match_index = current_match_idx + i
                
            prev_round_start = current_match_idx
            prev_round_count = next_round_count
            current_match_idx += next_round_count
            
        # Set match types nicely (optional but good for UI)
        if len(matches) > 0: matches[-1].match_type = "Final"
        if len(matches) > 2: 
            matches[-2].match_type = "Semi-Final"
            matches[-3].match_type = "Semi-Final"
            
        # Auto-finish BYE matches
        for i in range(first_round_matches):
            if matches[i].team2.name == "BYE":
                matches[i].team1_score = 1
                matches[i].is_finished = True
                
        return matches

    def generate_group_knockout(self, groups_map: dict) -> List[Match]:
        """Generates round-robin for each group. Knockout is generated later when groups finish."""
        # For simplicity in this phase, we just generate the group matches.
        # The user can trigger knockout generation manually or we do it when all group matches finish.
        groups_list = list(groups_map.values())
        return self.create_matches_from_groups(groups_list, match_type="group")
