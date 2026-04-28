import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Team> _standings = [];
  List<Player> _leaderboard = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final s = await ApiService.getStandings();
      final l = await ApiService.getLeaderboard();
      if (mounted) {
        setState(() {
          _standings = s;
          _leaderboard = l;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            indicatorColor: AppTheme.accent,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'STANDINGS'),
              Tab(text: 'PLAYER STATS'),
            ],
          ),
        ),
        body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              children: [
                _buildStandings(),
                _buildLeaderboard(),
              ],
            ),
      ),
    );
  }

  Widget _buildStandings() {
    if (_standings.isEmpty) return _buildEmpty();
    
    // Check if we have groups
    Map<String, List<Team>> groups = {};
    for (var t in _standings) {
      String gn = t.groupName.isEmpty ? 'Tournament' : t.groupName;
      groups.putIfAbsent(gn, () => []).add(t);
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: groups.entries.map((e) => _buildGroupTable(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _buildGroupTable(String name, List<Team> teams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.accent, letterSpacing: 1.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1.5),
            },
            children: [
              _buildHeaderRow(),
              ...teams.asMap().entries.map((entry) => _buildTeamRow(entry.key + 1, entry.value)),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  TableRow _buildHeaderRow() {
    return const TableRow(
      children: [
        _TableH('TEAM'),
        _TableH('P'),
        _TableH('W'),
        _TableH('D'),
        _TableH('PTS'),
      ],
    );
  }

  TableRow _buildTeamRow(int pos, Team t) {
    return TableRow(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.03)))),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text('$pos', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              Expanded(child: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            ],
          ),
        ),
        _TableC('${t.wins + t.draws + t.losses}'),
        _TableC('${t.wins}'),
        _TableC('${t.draws}'),
        _TableC('${t.points}', bold: true),
      ],
    );
  }

  Widget _buildLeaderboard() {
    if (_leaderboard.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboard.length,
        itemBuilder: (ctx, i) {
          final p = _leaderboard[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: i < 3 ? AppTheme.accent : AppTheme.surface2, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: i < 3 ? AppTheme.bg : Colors.white70, fontSize: 12)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(p.position.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                _StatItem(label: 'GOALS', value: '${p.goals}', icon: Icons.sports_soccer),
                const SizedBox(width: 16),
                _StatItem(label: 'ASSISTS', value: '${p.assists}', icon: Icons.assistant_photo),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: AppTheme.surface2),
          SizedBox(height: 16),
          Text('NO STATS YET', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _TableH extends StatelessWidget {
  final String text;
  const _TableH(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
  );
}

class _TableC extends StatelessWidget {
  final String text;
  final bool bold;
  const _TableC(this.text, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(child: Text(text, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w900 : FontWeight.normal, color: bold ? AppTheme.accent : Colors.white70))),
  );
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.accent)),
      Text(label, style: const TextStyle(fontSize: 8, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
    ],
  );
}
