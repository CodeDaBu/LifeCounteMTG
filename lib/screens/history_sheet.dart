import 'package:flutter/material.dart';

import '../game_state.dart';
import '../theme.dart';

/// Life changes this game, newest first.
class HistorySheet extends StatelessWidget {
  const HistorySheet({super.key, required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final entries = game.history.reversed.toList();
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text('HISTORY', style: labelStyle(36, color: Colors.white)),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No life changes yet.',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => _row(entries[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(HistoryEntry e) {
    final player = game.players[e.playerIndex];
    final diff = e.to - e.from;
    final t = e.time;
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration:
                BoxDecoration(color: player.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Text(player.name, style: labelStyle(22, color: Colors.white70)),
          ),
          Text('${e.from} → ${e.to}', style: numberStyle(18, Colors.white)),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              diff > 0 ? '+$diff' : '$diff',
              textAlign: TextAlign.right,
              style: numberStyle(
                  18, diff > 0 ? accentGreen : const Color(0xFFFF5C7A)),
            ),
          ),
          const SizedBox(width: 12),
          Text(time,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}
