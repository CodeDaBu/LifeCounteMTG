import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Roll a coin or any standard die. Tap the big die to roll again.
class DiceSheet extends StatefulWidget {
  const DiceSheet({super.key});

  @override
  State<DiceSheet> createState() => _DiceSheetState();
}

class _DiceSheetState extends State<DiceSheet> {
  static const _dice = [2, 4, 6, 8, 10, 12, 20];

  final _rng = Random();
  int _sides = 20;
  int? _result;
  bool _rolling = false;
  Timer? _timer;

  void _roll(int sides) {
    _timer?.cancel();
    setState(() {
      _sides = sides;
      _rolling = true;
    });
    var ticks = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      ticks++;
      setState(() => _result = _rng.nextInt(sides) + 1);
      if (ticks >= 12) {
        t.cancel();
        setState(() => _rolling = false);
        HapticFeedback.mediumImpact();
      }
    });
  }

  String get _resultText {
    final r = _result;
    if (r == null) return '?';
    if (_sides == 2) return r == 1 ? 'HEADS' : 'TAILS';
    return '$r';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('DICE', style: labelStyle(36, color: Colors.white)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _roll(_sides),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: _rolling ? const Color(0xFFFF9F1C) : Colors.white,
                borderRadius: BorderRadius.circular(36),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FittedBox(
                  child: Text(
                    _resultText,
                    style: _sides == 2 && _result != null
                        ? labelStyle(64)
                        : numberStyle(96, Colors.black),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in _dice)
                GestureDetector(
                  onTap: () => _roll(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: s == _sides ? accentGreen : Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(s == 2 ? 'COIN' : 'D$s', style: labelStyle(26)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap the die to roll again',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
