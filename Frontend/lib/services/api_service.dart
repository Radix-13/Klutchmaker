import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/player.dart';
import '../models/team.dart';
import '../models/match.dart';

class ApiService {
  static const String _base = 'http://localhost:8000/api';

  static Future<bool> checkHealth() async {
    try {
      // Use any existing endpoint to check health, or use tournament/setup if it responds to GET
      // For now, let's just check players
      final res = await http
          .get(Uri.parse('$_base/players'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Players ──────────────────────────────────────────────────
  static Future<List<Player>> getPlayers() async {
    final res = await http.get(Uri.parse('$_base/players/'));
    _assertOk(res);
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Player.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> addPlayer(String name, String position) async {
    final res = await http.post(
      Uri.parse('$_base/players/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'position': position}),
    );
    _assertOk(res);
  }

  static Future<void> removePlayer(String name) async {
    final res = await http.delete(Uri.parse('$_base/players/$name'));
    _assertOk(res);
  }

  static Future<void> clearAll() async {
    final res = await http.delete(Uri.parse('$_base/players/'));
    _assertOk(res);
  }

  // ── Team Builder ─────────────────────────────────────────────
  static Future<List<Team>> createTeamsAuto() async {
    final res = await http.post(Uri.parse('$_base/teams/auto-balance'));
    _assertOk(res);
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Team>> createTeamsManual({
    required String team1Name,
    required List<String> team1Players,
    required String team2Name,
    required List<String> team2Players,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/teams/manual'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'team1_name': team1Name,
        'team1_players': team1Players,
        'team2_name': team2Name,
        'team2_players': team2Players,
      }),
    );
    _assertOk(res);
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Team>> getSavedTeams() async {
    final res = await http.get(Uri.parse('$_base/teams/'));
    _assertOk(res);
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Tournament ───────────────────────────────────────────────
  static Future<void> setupTournament(String type, {List<Team>? teams, List<String>? teamNames}) async {
    final body = {
      'type': type,
      if (teams != null)
        'teams': teams.map((t) => {
          'name': t.name,
          'players': t.players.map((p) => p.name).toList(),
          'group_name': t.groupName,
        }).toList(),
      if (teamNames != null) 'team_names': teamNames,
    };

    final res = await http.post(
      Uri.parse('$_base/tournament/setup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _assertOk(res);
  }

  static Future<List<Match>> createSchedule() async {
    final res = await http.post(Uri.parse('$_base/tournament/create-schedule'));
    _assertOk(res);
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Match.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Match>> advanceKnockout() async {
    final res = await http.post(Uri.parse('$_base/tournament/advance-knockout'));
    _assertOk(res);
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Match.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Match>> getMatches() async {
    final res = await http.get(Uri.parse('$_base/tournament/matches'));
    _assertOk(res);
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Match.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Match> addGoal({
    required int matchIndex,
    required int team,
    required String playerName,
    String? assistName,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/tournament/matches/goal'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_index': matchIndex,
        'team': team,
        'player_name': playerName,
        if (assistName != null && assistName.isNotEmpty)
          'assist_name': assistName,
      }),
    );
    _assertOk(res);
    return Match.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Match> addCard({
    required int matchIndex,
    required int team,
    required String playerName,
    required String cardType,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/tournament/matches/card'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_index': matchIndex,
        'team': team,
        'player_name': playerName,
        'card_type': cardType,
      }),
    );
    _assertOk(res);
    return Match.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Match> undoEvent(int matchIndex) async {
    final res = await http.post(
      Uri.parse('$_base/tournament/matches/undo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'match_index': matchIndex}),
    );
    _assertOk(res);
    return Match.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Match> finishMatch(int matchIndex) async {
    final res = await http.post(
      Uri.parse('$_base/tournament/matches/finish'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'match_index': matchIndex}),
    );
    _assertOk(res);
    return Match.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Stats ────────────────────────────────────────────────────
  static Future<List<Player>> getLeaderboard() async {
    final res = await http.get(Uri.parse('$_base/tournament/stats/leaderboard'));
    _assertOk(res);
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Player.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Team>> getStandings() async {
    final res = await http.get(Uri.parse('$_base/tournament/stats/standings'));
    _assertOk(res);
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
  }

  static void _assertOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'API error ${res.statusCode}';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        msg = body['detail']?.toString() ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
