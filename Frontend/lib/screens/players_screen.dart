import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/km_chip.dart';
import '../widgets/section_header.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});
  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _nameCtrl = TextEditingController();
  String _position = 'striker';
  List<Player> _players = [];
  bool _loading = false;

  static const _positions = [
    ('striker',    '⚡ Striker'),
    ('midfielder', '🎯 Midfielder'),
    ('defender',   '🛡️ Defender'),
    ('goalkeeper', '🧤 Goalkeeper'),
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final p = await ApiService.getPlayers();
      if (mounted) setState(() => _players = p);
    } catch (_) {}
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.addPlayer(name, _position);
      _nameCtrl.clear();
      await _fetch();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String name) async {
    try {
      await ApiService.removePlayer(name);
      await _fetch();
    } catch (_) {}
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: AppTheme.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppTheme.accent.withOpacity(.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Recruit Player'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_add_alt_1_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _position,
                        dropdownColor: AppTheme.surface,
                        decoration: const InputDecoration(
                          labelText: 'Field Position',
                          prefixIcon: Icon(Icons.ads_click_rounded),
                        ),
                        items: _positions
                            .map((p) => DropdownMenuItem(
                                  value: p.$1,
                                  child: Text(p.$2),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _position = v!),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _add,
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('JOIN ROSTER'),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const SectionHeader(title: 'The Squad'),
                  const SizedBox(width: 8),
                  KmChip(label: '${_players.length}', color: AppTheme.accent2),
                  const Spacer(),
                  if (_players.isNotEmpty)
                    TextButton(
                      onPressed: () => ApiService.clearAll().then((_) => _fetch()),
                      child: const Text('Reset All', style: TextStyle(color: AppTheme.red, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
          _players.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_3_outlined, size: 60, color: AppTheme.surface2),
                        const SizedBox(height: 10),
                        const Text('Pitch is empty. Recruit players!', style: TextStyle(color: AppTheme.textMuted)),
                      ],
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisExtent: 80,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _PlayerTile(
                        player: _players[i],
                        onRemove: () => _remove(_players[i].name),
                      ).animate(delay: (50 * i).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
                      childCount: _players.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final Player player;
  final VoidCallback onRemove;
  const _PlayerTile({required this.player, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.bg,
            child: Text(player.positionEmoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(player.position.toUpperCase(),
                    style: const TextStyle(color: AppTheme.accent, fontSize: 9, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
            onPressed: onRemove,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
