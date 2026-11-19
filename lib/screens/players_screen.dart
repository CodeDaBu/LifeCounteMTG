import 'package:flutter/material.dart';

import '../game_state.dart';
import '../layouts.dart';
import '../theme.dart';

/// Pick the number of players, then a table layout.
class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key, required this.game});

  final GameState game;

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  late int _count = widget.game.layout.playerCount;

  @override
  Widget build(BuildContext context) {
    final layouts = layoutsByCount[_count]!;
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentPink,
        shape: const CircleBorder(),
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('PLAYERS', style: labelStyle(40, color: Colors.white)),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final n in layoutsByCount.keys) _countTile(n),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 0.58,
                children: [for (final l in layouts) _preview(l)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countTile(int n) {
    final selected = n == _count;
    return GestureDetector(
      onTap: () => setState(() => _count = n),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 80,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? accentGreen : Colors.transparent,
            width: 5,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text('$n', style: labelStyle(38)),
        ),
      ),
    );
  }

  Widget _preview(GameLayout layout) {
    final selected = identical(layout, widget.game.layout);
    return GestureDetector(
      onTap: () {
        widget.game.setLayout(layout);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? accentGreen : Colors.white12,
            width: 5,
          ),
        ),
        child: Column(
          children: [
            for (final row in layout.rows)
              Expanded(
                child: Row(
                  children: [
                    for (final turns in row)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: RotatedBox(
                            quarterTurns: turns,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: FittedBox(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Text(
                                    '${widget.game.startingLife}',
                                    style: numberStyle(26, Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
