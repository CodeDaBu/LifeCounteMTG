import 'package:flutter/material.dart';

import '../game_state.dart';
import '../theme.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key, required this.game});

  final GameState game;

  static const _lifeOptions = [20, 25, 30, 40, 50];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text('SETTINGS', style: labelStyle(36, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Text('STARTING LIFE',
                style: labelStyle(22, color: Colors.white70)),
            const SizedBox(height: 4),
            const Text(
              'Changing this restarts the game.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final v in _lifeOptions)
                  _chip('$v', v == game.startingLife,
                      () => game.setStartingLife(v)),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: accentGreen,
              title: Text('KEEP SCREEN AWAKE',
                  style: labelStyle(22, color: Colors.white70)),
              value: game.keepAwake,
              onChanged: game.setKeepAwake,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accentGreen : Colors.white,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(label, style: labelStyle(28)),
      ),
    );
  }
}
