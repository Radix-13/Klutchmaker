class Player {
  final String name;
  final String position;
  final int goals;
  final int assists;
  final int matchesPlayed;
  final int yellowCards;
  final int redCards;

  const Player({
    required this.name,
    required this.position,
    this.goals = 0,
    this.assists = 0,
    this.matchesPlayed = 0,
    this.yellowCards = 0,
    this.redCards = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        name: json['name'] as String? ?? 'Unknown',
        position: json['position'] as String? ?? 'striker',
        goals: (json['goals'] as num?)?.toInt() ?? 0,
        assists: (json['assists'] as num?)?.toInt() ?? 0,
        matchesPlayed: (json['matches_played'] as num?)?.toInt() ?? 0,
        yellowCards: (json['yellow_cards'] as num?)?.toInt() ?? 0,
        redCards: (json['red_cards'] as num?)?.toInt() ?? 0,
      );

  String get positionEmoji {
    switch (position.toLowerCase()) {
      case 'striker':
        return '⚡';
      case 'midfielder':
        return '🎯';
      case 'defender':
        return '🛡️';
      case 'goalkeeper':
        return '🧤';
      default:
        return '🏃';
    }
  }
}
