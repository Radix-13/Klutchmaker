import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/km_chip.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});
  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  List<Player> _allPlayers = [];
  List<Team> _savedTeams = [];
  bool _loading = false;
  
  final Set<String> _teamASelection = {};
  final Set<String> _teamBSelection = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final p = await ApiService.getPlayers();
      final t = await ApiService.getSavedTeams();
      if (mounted) setState(() { _allPlayers = p; _savedTeams = t; });
    } catch (_) {}
  }

  Future<void> _autoGenerate() async {
    setState(() => _loading = true);
    try {
      final t = await ApiService.createTeamsAuto();
      setState(() => _savedTeams = t);
      _snack('Balanced teams generated and saved!');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manualSubmit() async {
    if (_teamASelection.isEmpty || _teamBSelection.isEmpty) {
      _snack('Both teams must have players', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final t = await ApiService.createTeamsManual(
        team1Name: 'Team Alpha',
        team1Players: _teamASelection.toList(),
        team2Name: 'Team Beta',
        team2Players: _teamBSelection.toList(),
      );
      setState(() => _savedTeams = t);
      _snack('Manual teams created and saved!');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.red : AppTheme.accent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Team Builder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          bottom: const TabBar(
            indicatorColor: AppTheme.accent,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            tabs: [
              Tab(text: 'AUTO BUILD'),
              Tab(text: 'MANUAL SELECT'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAutoTab(),
            _buildManualTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.auto_fix_high_rounded, size: 50, color: AppTheme.accent),
                const SizedBox(height: 12),
                const Text('Random Balanced Distribution', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 6),
                const Text('Uses our algorithm to split the squad fairly.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _autoGenerate,
                  child: const Text('GENERATE TEAMS'),
                ),
              ],
            ),
          ),
        ),
        if (_savedTeams.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _TeamPreview(team: _savedTeams[0], color: AppTheme.accent)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.surface2)),
                  ),
                  Expanded(child: _TeamPreview(team: _savedTeams[1], color: AppTheme.accent2)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManualTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ManualStats('ALPHA', _teamASelection.length, AppTheme.accent),
              const SizedBox(width: 20),
              _ManualStats('BETA', _teamBSelection.length, AppTheme.accent2),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _allPlayers.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (ctx, i) {
              final p = _allPlayers[i];
              final inA = _teamASelection.contains(p.name);
              final inB = _teamBSelection.contains(p.name);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: (inA || inB) ? AppTheme.surface2.withOpacity(.3) : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: inA ? AppTheme.accent : inB ? AppTheme.accent2 : Colors.transparent),
                ),
                child: ListTile(
                  leading: Text(p.positionEmoji),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SelectBtn(label: 'A', selected: inA, color: AppTheme.accent, onTap: () => setState(() {
                        if (inA) _teamASelection.remove(p.name);
                        else { _teamASelection.add(p.name); _teamBSelection.remove(p.name); }
                      })),
                      const SizedBox(width: 8),
                      _SelectBtn(label: 'B', selected: inB, color: AppTheme.accent2, onTap: () => setState(() {
                        if (inB) _teamBSelection.remove(p.name);
                        else { _teamBSelection.add(p.name); _teamASelection.remove(p.name); }
                      })),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _loading ? null : _manualSubmit,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text('CONFIRM SELECTIONS'),
          ),
        ),
      ],
    );
  }
}

class _TeamPreview extends StatelessWidget {
  final Team team;
  final Color color;
  const _TeamPreview({required this.team, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Column(
        children: [
          Text(team.name.split(' ').last, style: TextStyle(fontWeight: FontWeight.w900, color: color)),
          const Divider(),
          ...team.players.take(5).map((p) => Text(p.name, style: const TextStyle(fontSize: 11), maxLines: 1)),
          if (team.players.length > 5) Text('+', style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _ManualStats extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _ManualStats(this.label, this.count, this.color);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
      Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
    ],
  );
}

class _SelectBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _SelectBtn({required this.label, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: selected ? AppTheme.bg : color))),
    ),
  );
}
