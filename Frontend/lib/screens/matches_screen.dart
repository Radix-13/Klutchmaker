import 'package:flutter/material.dart';
import 'tournament_setup_screen.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});
  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Match> _matches = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final m = await ApiService.getMatches();
      if (mounted) setState(() => _matches = m);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _advance() async {
    setState(() => _loading = true);
    try {
      await ApiService.advanceKnockout();
      await _fetch();
      _snack('Knockout Rounds Generated!');
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _undo(int idx) async {
    try {
      final updated = await ApiService.undoEvent(idx);
      setState(() => _matches[idx] = updated);
    } catch (_) {}
  }

  Future<void> _finishMatch(int idx) async {
    try {
      final updated = await ApiService.finishMatch(idx);
      setState(() => _matches[idx] = updated);
    } catch (_) {}
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.red : AppTheme.accent,
    ));
  }

  Future<void> _openEventDialog(Match match, int teamNum) async {
    final team = teamNum == 1 ? match.team1 : match.team2;
    String? player;
    String? assister;
    String eventType = 'goal';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Record Event for ${team.name}', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: eventType,
                decoration: const InputDecoration(labelText: 'Event Type'),
                items: const [
                  DropdownMenuItem(value: 'goal', child: Text('⚽ Goal')),
                  DropdownMenuItem(value: 'yellow_card', child: Text('🟨 Yellow Card')),
                  DropdownMenuItem(value: 'red_card', child: Text('🟥 Red Card')),
                ],
                onChanged: (v) => setS(() => eventType = v!),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: team.players.any((p) => p.name == player) ? player : (player != null ? 'other' : null),
                hint: const Text('Select Player'),
                items: [
                  ...team.players.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))),
                  const DropdownMenuItem(value: 'other', child: Text('+ NEW PLAYER')),
                ],
                onChanged: (v) {
                  if (v == 'other') {
                    setS(() => player = '');
                  } else {
                    setS(() => player = v);
                  }
                },
              ),
              if (player != null && !team.players.any((p) => p.name == player)) ...[
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => setS(() => player = v),
                  decoration: const InputDecoration(labelText: 'New Player Name', hintText: 'Type name...'),
                ),
              ],
              if (eventType == 'goal') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: team.players.any((p) => p.name == assister) ? assister : (assister != null && assister!.isNotEmpty ? 'other' : ''),
                  hint: const Text('Assist (Optional)'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('No Assist')),
                    ...team.players.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))),
                    const DropdownMenuItem(value: 'other', child: Text('+ NEW PLAYER')),
                  ],
                  onChanged: (v) {
                    if (v == 'other') {
                      setS(() => assister = ' '); // Space to trigger "other" mode
                    } else {
                      setS(() => assister = v);
                    }
                  },
                ),
                if (assister != null && assister!.trim().isEmpty && assister != '') ...[
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => setS(() => assister = v),
                    decoration: const InputDecoration(labelText: 'Assistant Name', hintText: 'Type name...'),
                  ),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
          ],
        ),
      ),
    );

    if (confirmed == true && player != null && player!.isNotEmpty) {
      Match updated;
      if (eventType == 'goal') {
        updated = await ApiService.addGoal(
          matchIndex: match.index,
          team: teamNum,
          playerName: player!,
          assistName: assister,
        );
      } else {
        updated = await ApiService.addCard(
          matchIndex: match.index,
          team: teamNum,
          playerName: player!,
          cardType: eventType,
        );
      }
      setState(() => _matches[match.index] = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasGroupMatches = _matches.any((m) => m.matchType == 'group');
    bool allGroupFinished = hasGroupMatches && _matches.where((m) => m.matchType == 'group').every((m) => m.isFinished);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppTheme.accent,
        child: _matches.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  if (allGroupFinished && !_matches.any((m) => m.matchType == 'knockout' || m.matchType == 'Final'))
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      color: AppTheme.accent.withOpacity(.1),
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _advance,
                        icon: const Icon(Icons.flash_on),
                        label: const Text('GENERATE KNOCKOUT STAGE'),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _matches.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (ctx, i) => _MatchCard(
                        match: _matches[i],
                        onEvent1: () => _openEventDialog(_matches[i], 1),
                        onEvent2: () => _openEventDialog(_matches[i], 2),
                        onUndo: () => _undo(_matches[i].index),
                        onFinish: () => _finishMatch(_matches[i].index),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 80, color: AppTheme.surface2),
          const SizedBox(height: 24),
          const Text('NO ACTIVE TOURNAMENT', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => TournamentSetupScreen(
                    onTournamentCreated: () {
                      Navigator.pop(context);
                      _fetch();
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('START NEW TOURNAMENT'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onEvent1;
  final VoidCallback onEvent2;
  final VoidCallback onUndo;
  final VoidCallback onFinish;

  const _MatchCard({required this.match, required this.onEvent1, required this.onEvent2, required this.onUndo, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white.withOpacity(0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MATCH #${match.index + 1} • ${match.matchType.toUpperCase()}', 
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.accent, letterSpacing: 1)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: match.isFinished ? AppTheme.surface2.withOpacity(.3) : AppTheme.red.withOpacity(.2), 
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: match.isFinished ? AppTheme.accent.withOpacity(.3) : AppTheme.red.withOpacity(.3)),
                    ),
                    child: Text(match.isFinished ? 'FINISHED' : 'LIVE', 
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: match.isFinished ? AppTheme.accent : AppTheme.red)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _TeamInfo(name: match.team1.name, score: match.team1Score, align: CrossAxisAlignment.end)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('VS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
                      ),
                      Expanded(child: _TeamInfo(name: match.team2.name, score: match.team2Score, align: CrossAxisAlignment.start)),
                    ],
                  ),
                  if (!match.isFinished) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _MatchActionBtn(label: 'GOAL/CARD', icon: Icons.add_circle_outline, color: AppTheme.accent, onTap: onEvent1)),
                        const SizedBox(width: 12),
                        Expanded(child: _MatchActionBtn(label: 'GOAL/CARD', icon: Icons.add_circle_outline, color: AppTheme.accent2, onTap: onEvent2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _MatchActionBtn(label: 'UNDO', icon: Icons.undo, color: AppTheme.textMuted, onTap: onUndo, outline: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _MatchActionBtn(label: 'FINISH', icon: Icons.check_circle, color: AppTheme.yellow, onTap: onFinish)),
                      ],
                    ),
                  ],
                  if (match.events.isNotEmpty) ...[
                    const Divider(height: 40, color: Colors.white10),
                    ...match.events.reversed.map((e) {
                      String icon = '⚽';
                      if (e['type'] == 'yellow_card') icon = '🟨';
                      if (e['type'] == 'red_card') icon = '🟥';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  children: [
                                    TextSpan(text: e['player'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    const TextSpan(text: ' scored for '),
                                    TextSpan(text: e['team'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
                                    if (e['assist'] != null && e['assist'].toString().isNotEmpty) ...[
                                      const TextSpan(text: ' (Assist: '),
                                      TextSpan(text: e['assist'], style: const TextStyle(fontStyle: FontStyle.italic)),
                                      const TextSpan(text: ')'),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamInfo extends StatelessWidget {
  final String name;
  final int score;
  final CrossAxisAlignment align;
  const _TeamInfo({required this.name, required this.score, required this.align});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: align,
    children: [
      Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Text('$score', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1)),
    ],
  );
}

class _MatchActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outline;
  const _MatchActionBtn({required this.label, required this.icon, required this.color, required this.onTap, this.outline = false});
  @override
  Widget build(BuildContext context) {
    if (outline) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppTheme.bg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
