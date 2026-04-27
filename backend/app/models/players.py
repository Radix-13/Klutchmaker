class Player:
    def __init__(self, name: str, position: str):
        self.name = name
        self.position = position  # striker, midfielder, defender, etc.

        self.goals = 0
        self.assists = 0
        self.matches_played = 0

    def add_goal(self):
        self.goals += 1

    def add_assist(self):
        self.assists += 1

    def play_match(self):
        self.matches_played += 1