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

/// Colors offered by the "Background" option.
const backgroundChoices = <Color>[
  ...playerColors,
  Color(0xFFFF7A00), // orange
  Color(0xFF9B5CFF), // purple
  Color(0xFF8BE04E), // lime
  Color(0xFF00B3A4), // teal
  Color(0xFFB0805A), // brown
  Color(0xFFE6E6E6), // light grey
];

/// Extra counters a player can track besides life.
/// Each is drawn either as an [icon] or as a short text [glyph], with an
/// optional small [badge] (e.g. TAX 1 / TAX 2).
enum CounterType {
  poison('POISON', glyph: 'Φ', lethal: 10),
  commanderTax('TAX 1', glyph: 'TAX', badge: '1'),
  commanderTax2('TAX 2', glyph: 'TAX', badge: '2'),
  storm('STORM', icon: Icons.thunderstorm_rounded),
  experience('EXPERIENCE', glyph: 'XP'),
  energy('ENERGY', icon: Icons.bolt_rounded),
  rad('RAD', icon: Icons.blur_circular_rounded),
  tickets('TICKETS', icon: Icons.confirmation_number_rounded),
  manaWhite('WHITE', icon: Icons.wb_sunny_rounded, tint: Color(0xFFF8E08E)),
  manaBlue('BLUE', icon: Icons.water_drop_rounded, tint: Color(0xFF14C8FF)),
  manaBlack('BLACK', icon: Icons.dark_mode_rounded, tint: Color(0xFF9B5CFF)),
  manaRed('RED',
      icon: Icons.local_fire_department_rounded, tint: Color(0xFFFF2D55)),
  manaGreen('GREEN', icon: Icons.eco_rounded, tint: Color(0xFF1EE07F)),
  manaColorless('COLORLESS',
      icon: Icons.change_history_rounded, tint: Color(0xFFB8C4D6));

  const CounterType(
    this.label, {
    this.icon,
    this.glyph,
    this.badge,
    this.tint,
    this.lethal,
  });

  final String label;
  final IconData? icon;
  final String? glyph;
  final String? badge;

  /// Background color for the mana pool buttons.
  final Color? tint;

  /// Value at which the player is out (poison: 10), or null.
  final int? lethal;

  /// Shown as +/- steppers in the drawer instead of in the grid.
  static const steppers = [poison, commanderTax, commanderTax2];

  /// Shown in the drawer's icon grid.
  static const gridTop = [storm, experience, energy, rad, tickets];
  static const gridBottom = [
    manaWhite,
    manaBlue,
    manaBlack,
    manaRed,
    manaGreen,
    manaColorless,
  ];
}

/// Commander damage from one commander is lethal at this amount.
const commanderLethal = 21;

class Player {
  Player({required this.life, required this.color, required this.name});

  int life;
  Color color;
  String name;

  /// Sum of recent changes, shown briefly above the life total.
  int recentDelta = 0;
  Timer? _deltaTimer;

  /// Counters in the order they were added. Shown on the panel.
  final Map<CounterType, int> counters = {};

  /// Commander damage taken, keyed by [commanderKey].
  final Map<int, int> commanderDamage = {};

  /// Has two commanders (partner), so others track damage from each.
  bool hasPartner = false;

  /// Marked out by hand with "Kill".
  bool killed = false;

  /// Kept in the game by "Unkill" even though a loss condition is met.
  bool revived = false;

  int counter(CounterType type) => counters[type] ?? 0;

  int damageFrom(int sourceIndex, int slot) =>
      commanderDamage[commanderKey(sourceIndex, slot)] ?? 0;

  bool get meetsLossCondition =>
      life <= 0 ||
      counters.entries
          .any((e) => e.key.lethal != null && e.value >= e.key.lethal!) ||
      commanderDamage.values.any((d) => d >= commanderLethal);

  bool get isOut => killed || (!revived && meetsLossCondition);

  void dispose() => _deltaTimer?.cancel();
}

int commanderKey(int sourceIndex, int slot) => sourceIndex * 2 + slot;

class HistoryEntry {
  HistoryEntry({
    required this.playerIndex,
    required this.from,
    required this.to,
    required this.time,
  });

  final int playerIndex;
  final int from;
  final int to;
  final DateTime time;
}

class GameState extends ChangeNotifier {
  GameState({Random? random}) : _random = random ?? Random() {
    _resetPlayers();
  }

  final Random _random;

  int startingLife = 40;
  bool keepAwake = true;

  /// Commander damage also takes life away (the official rule).
  bool commanderDamageReducesLife = true;

  GameLayout layout = defaultLayout;
  List<Player> players = [];

  /// Life changes, oldest first.
  final List<HistoryEntry> history = [];

  /// Player holding the monarch / initiative, if any.
  int? monarch;
  int? initiative;

  /// Non-null while the "high roll" screen is shown.
  List<int>? highRollValues;
  bool isRolling = false;
  Timer? _rollTimer;

  void _resetPlayers() {
    final oldNames = [for (final p in players) p.name];
    final oldColors = [for (final p in players) p.color];
    for (final p in players) {
      p.dispose();
    }
    players = List.generate(
      layout.playerCount,
      (i) => Player(
        life: startingLife,
        // Keep names and colors the players picked across restarts.
        color: i < oldColors.length
            ? oldColors[i]
            : playerColors[i % playerColors.length],
        name: i < oldNames.length ? oldNames[i] : 'PLAYER ${i + 1}',
      ),
    );
    history.clear();
    monarch = null;
    initiative = null;
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

  void setCommanderDamageReducesLife(bool value) {
    commanderDamageReducesLife = value;
    notifyListeners();
  }

  void changeLife(int playerIndex, int amount) {
    if (amount == 0) return;
    final p = players[playerIndex];
    p.life += amount;
    p.recentDelta += amount;
    _afterChange(p);
    p._deltaTimer?.cancel();
    p._deltaTimer = Timer(const Duration(seconds: 2), () {
      _commitHistory(playerIndex);
      notifyListeners();
    });
    notifyListeners();
  }

  /// Writes the pending life change into the history.
  void _commitHistory(int playerIndex) {
    final p = players[playerIndex];
    if (p.recentDelta != 0) {
      history.add(HistoryEntry(
        playerIndex: playerIndex,
        from: p.life - p.recentDelta,
        to: p.life,
        time: DateTime.now(),
      ));
    }
    p.recentDelta = 0;
  }

  /// Add a counter to the panel (starts at 0, or stays as it is).
  void addCounter(int playerIndex, CounterType type) {
    players[playerIndex].counters.putIfAbsent(type, () => 0);
    notifyListeners();
  }

  /// Counters that reach 0 disappear from the panel.
  void changeCounter(int playerIndex, CounterType type, int amount) {
    final p = players[playerIndex];
    final value = max(0, p.counter(type) + amount);
    if (value == 0) {
      p.counters.remove(type);
    } else {
      p.counters[type] = value;
    }
    _afterChange(p);
    notifyListeners();
  }

  /// Hide counters that are back at 0.
  void removeEmptyCounters(int playerIndex) {
    players[playerIndex].counters.removeWhere((_, v) => v == 0);
    notifyListeners();
  }

  void changeCommanderDamage(
      int targetIndex, int sourceIndex, int slot, int amount) {
    final p = players[targetIndex];
    final key = commanderKey(sourceIndex, slot);
    final before = p.commanderDamage[key] ?? 0;
    final after = max(0, before + amount);
    if (after == before) return;
    if (after == 0) {
      p.commanderDamage.remove(key);
    } else {
      p.commanderDamage[key] = after;
    }
    if (commanderDamageReducesLife) {
      changeLife(targetIndex, before - after);
    } else {
      _afterChange(p);
      notifyListeners();
    }
  }

  /// Once a player no longer meets a loss condition, "Unkill" is used up.
  void _afterChange(Player p) {
    if (!p.meetsLossCondition) p.revived = false;
  }

  void toggleKill(int playerIndex) {
    final p = players[playerIndex];
    if (p.isOut) {
      p.killed = false;
      p.revived = p.meetsLossCondition;
    } else {
      p.killed = true;
      p.revived = false;
    }
    notifyListeners();
  }

  void togglePartner(int playerIndex) {
    final p = players[playerIndex];
    p.hasPartner = !p.hasPartner;
    if (!p.hasPartner) {
      // Drop damage dealt by the second commander.
      for (final other in players) {
        other.commanderDamage.remove(commanderKey(playerIndex, 1));
      }
    }
    notifyListeners();
  }

  void setColor(int playerIndex, Color color) {
    players[playerIndex].color = color;
    notifyListeners();
  }

  void setName(int playerIndex, String name) {
    final trimmed = name.trim();
    players[playerIndex].name =
        trimmed.isEmpty ? 'PLAYER ${playerIndex + 1}' : trimmed.toUpperCase();
    notifyListeners();
  }

  void toggleMonarch(int playerIndex) {
    monarch = monarch == playerIndex ? null : playerIndex;
    notifyListeners();
  }

  void toggleInitiative(int playerIndex) {
    initiative = initiative == playerIndex ? null : playerIndex;
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
