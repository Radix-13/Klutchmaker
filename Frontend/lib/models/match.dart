import 'team.dart';

class Match {
  final int index;
  final Team team1;
  final Team team2;
  final int team1Score;
  final int team2Score;
  final bool isFinished;
  final String matchType;
  final int? nextMatchIndex;
  final List<Map<String, dynamic>> events;

  const Match({
    required this.index,
    required this.team1,
    required this.team2,
    this.team1Score = 0,
    this.team2Score = 0,
    this.isFinished = false,
    this.matchType = 'group',
    this.nextMatchIndex,
    this.events = const [],
  });

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        index: (json['index'] as num).toInt(),
        team1: Team.fromJson(json['team1'] as Map<String, dynamic>),
        team2: Team.fromJson(json['team2'] as Map<String, dynamic>),
        team1Score: (json['team1_score'] as num?)?.toInt() ?? 0,
        team2Score: (json['team2_score'] as num?)?.toInt() ?? 0,
        isFinished: json['is_finished'] as bool? ?? false,
        matchType: json['match_type'] as String? ?? 'group',
        nextMatchIndex: (json['next_match_index'] as num?)?.toInt(),
        events: (json['events'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}
