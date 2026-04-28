import 'player.dart';

class Team {
  final String name;
  final List<Player> players;
  final String groupName;
  final int goals;
  final int assists;
  
  // Standings
  final int points;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;

  const Team({
    required this.name,
    required this.players,
    this.groupName = '',
    this.goals = 0,
    this.assists = 0,
    this.points = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.goalDifference = 0,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        name: json['name'] as String? ?? 'Unnamed Team',
        groupName: json['group_name'] as String? ?? '',
        players: (json['players'] as List<dynamic>? ?? [])
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        goals: (json['goals'] as num?)?.toInt() ?? 0,
        assists: (json['assists'] as num?)?.toInt() ?? 0,
        points: (json['points'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        draws: (json['draws'] as num?)?.toInt() ?? 0,
        losses: (json['losses'] as num?)?.toInt() ?? 0,
        goalsFor: (json['goals_for'] as num?)?.toInt() ?? 0,
        goalsAgainst: (json['goals_against'] as num?)?.toInt() ?? 0,
        goalDifference: (json['goal_difference'] as num?)?.toInt() ?? 0,
      );
}
