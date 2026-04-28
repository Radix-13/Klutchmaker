import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TournamentSetupScreen extends StatefulWidget {
  final VoidCallback onTournamentCreated;
  const TournamentSetupScreen({super.key, required this.onTournamentCreated});

  @override
  State<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends State<TournamentSetupScreen> {
  int _step = 0;
  String _type = 'league';
  int _teamCount = 4;
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _groupControllers = [];
  bool _manualGroups = false;
  bool _shuffle = false;
  bool _loading = false;

  void _nextStep() {
    if (_step == 1) {
      _nameControllers.clear();
      _groupControllers.clear();
      for (int i = 0; i < _teamCount; i++) {
        _nameControllers.add(TextEditingController(text: 'Team ${i + 1}'));
        // Default group assignment logic (4 per group)
        int groupIndex = i ~/ 4;
        _groupControllers.add(TextEditingController(text: 'Group ${String.fromCharCode(65 + groupIndex)}'));
      }
    }
    setState(() => _step++);
  }

  void _prevStep() {
    setState(() => _step--);
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      List<Team> teams = [];
      for (int i = 0; i < _nameControllers.length; i++) {
        String gn = _type == 'group_knockout' ? _groupControllers[i].text.trim() : "";
        teams.add(Team(name: _nameControllers[i].text.trim(), players: [], groupName: gn));
      }

      if (_shuffle) {
        teams.shuffle();
      }

      await ApiService.setupTournament(_type, teams: teams);
      await ApiService.createSchedule();
      
      _snack('Tournament Created!');
      widget.onTournamentCreated();
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.red : AppTheme.accent,
    ));
  }

  @override
  void dispose() {
    for (var c in _nameControllers) c.dispose();
    for (var c in _groupControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Setup', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _step > 0 ? _prevStep : () => Navigator.pop(context)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressIndicator(),
                const SizedBox(height: 32),
                Expanded(child: _buildStepContent()),
                const SizedBox(height: 16),
                _buildNavigationButtons(),
              ],
            ),
          ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(4, (index) {
        bool active = index <= _step;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: active ? AppTheme.accent : AppTheme.surface,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _stepFormat();
      case 1: return _stepCount();
      case 2: return _stepNames();
      case 3: return _stepFinal();
      default: return const SizedBox();
    }
  }

  Widget _stepFormat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 1', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.accent)),
        const Text('Choose Tournament Format', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        _formatCard('league', 'League', 'Everyone plays everyone. Most points wins.', Icons.format_list_numbered),
        const SizedBox(height: 12),
        _formatCard('knockout', 'Knockout', 'Single elimination bracket. Winner stays.', Icons.account_tree),
        const SizedBox(height: 12),
        _formatCard('group_knockout', 'World Cup Style', 'Groups followed by knockout rounds.', Icons.groups),
      ],
    );
  }

  Widget _formatCard(String value, String title, String desc, IconData icon) {
    bool selected = _type == value;
    return InkWell(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.accent : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppTheme.accent : AppTheme.textMuted, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: selected ? AppTheme.accent : Colors.white)),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppTheme.accent),
          ],
        ),
      ),
    );
  }

  Widget _stepCount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 2', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.accent)),
        const Text('Number of Teams', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(Icons.remove, () {
                if (_teamCount > 2) setState(() => _teamCount--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text('$_teamCount', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
              ),
              _circleButton(Icons.add, () {
                if (_teamCount < 32) setState(() => _teamCount++);
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('Minimum 2, Maximum 32', style: TextStyle(color: AppTheme.textMuted))),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.surface, width: 2)),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _stepNames() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP 3', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.accent)),
                Text('Team Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
            if (_type == 'group_knockout')
              Row(
                children: [
                  const Text('Manual Groups', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _manualGroups,
                      onChanged: (v) => setState(() => _manualGroups = v),
                      activeColor: AppTheme.accent,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _nameControllers.length,
            itemBuilder: (ctx, i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameControllers[i],
                        decoration: InputDecoration(
                          labelText: 'Team ${i + 1}',
                          prefixIcon: const Icon(Icons.shield, size: 18),
                        ),
                      ),
                    ),
                    if (_type == 'group_knockout' && _manualGroups) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _groupControllers[i],
                          decoration: const InputDecoration(
                            labelText: 'Group',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _stepFinal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 4', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.accent)),
        const Text('Finalize Setup', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _summaryRow('Format', _type.toUpperCase()),
              const Divider(height: 32, color: Colors.white10),
              _summaryRow('Teams', '$_teamCount'),
              const Divider(height: 32, color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shuffle Teams', style: TextStyle(color: AppTheme.textMuted)),
                  Switch(
                    value: _shuffle,
                    onChanged: (v) => setState(() => _shuffle = v),
                    activeColor: AppTheme.accent,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('This will reset any active tournament and create new fixtures.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _loading ? null : _prevStep,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
              child: const Text('BACK'),
            ),
          ),
        if (_step > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _loading ? null : (_step < 3 ? _nextStep : _create),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 56)),
            child: Text(_step < 3 ? 'CONTINUE' : 'FINALIZE'),
          ),
        ),
      ],
    );
  }
}
