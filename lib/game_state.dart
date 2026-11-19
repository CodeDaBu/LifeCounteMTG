import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'layouts.dart';

const playerColors = <Color>[
  Color(0xFFFFC400), // yellow
  Color(0xFFFF0048), // red
  Color(0xFFF799FA), // pink
  Color(0xFF4452FF), // blue
  Color(0xFF00D26A), // green
  Color(0xFF00C2FF), // cyan
];

class Player {
  Player({required this.life, required this.color});

  int life;
  Color color;

  /// Sum of recent changes, shown briefly above the life total.
  int recentDelta = 0;
  Timer? _deltaTimer;

  void dispose() => _deltaTimer?.cancel();
}

class GameState extends ChangeNotifier {
  GameState({Random? random}) : _random = random ?? Random() {
    _resetPlayers();
  }

  final Random _random;

  int startingLife = 40;
  bool keepAwake = true;
  GameLayout layout = defaultLayout;
  List<Player> players = [];

  /// Non-null while the "high roll" screen is shown.
  List<int>? highRollValues;
  bool isRolling = false;
  Timer? _rollTimer;

  void _resetPlayers() {
    for (final p in players) {
      p.dispose();
    }
    players = List.generate(
      layout.playerCount,
      (i) => Player(
        life: startingLife,
        color: playerColors[i % playerColors.length],
      ),
    );
  }

  void restart() {
    closeHighRoll(notify: false);
    _resetPlayers();
    notifyListeners();
  }

  void setLayout(GameLayout newLayout) {
    layout = newLayout;
    restart();
  }

  void setStartingLife(int value) {
    startingLife = value;
    restart();
  }

  void setKeepAwake(bool value) {
    keepAwake = value;
    notifyListeners();
  }

  void changeLife(int playerIndex, int amount) {
    final p = players[playerIndex];
    p.life += amount;
    p.recentDelta += amount;
    p._deltaTimer?.cancel();
    p._deltaTimer = Timer(const Duration(seconds: 2), () {
      p.recentDelta = 0;
      notifyListeners();
    });
    notifyListeners();
  }

  /// [count] distinct d20 results, so there is always a single winner.
  List<int> rollDistinct(int count) {
    final pool = List.generate(20, (i) => i + 1)..shuffle(_random);
    return pool.take(count).toList();
  }

  void startHighRoll() {
    _rollTimer?.cancel();
    isRolling = true;
    highRollValues = rollDistinct(players.length);
    notifyListeners();
    var ticks = 0;
    _rollTimer = Timer.periodic(const Duration(milliseconds: 70), (t) {
      ticks++;
      highRollValues = rollDistinct(players.length);
      if (ticks >= 14) {
        t.cancel();
        isRolling = false;
      }
      notifyListeners();
    });
  }

  int? get highRollWinner {
    final values = highRollValues;
    if (values == null || isRolling) return null;
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }

  void closeHighRoll({bool notify = true}) {
    _rollTimer?.cancel();
    highRollValues = null;
    isRolling = false;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    for (final p in players) {
      p.dispose();
    }
    super.dispose();
  }
}
