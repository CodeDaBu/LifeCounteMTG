import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_state.dart';
import '../theme.dart';
import 'counter_glyph.dart';

enum _View { life, commander, colors }

/// One player's tile.
///
/// - Tap the left half for -1, the right half for +1; hold for -10 / +10.
/// - Swipe up (or tap the bar at the bottom) to open the drawer:
///   background, kill, partners, name | poison & tax steppers |
///   counter grid (storm, XP, energy, rad, tickets, commander damage,
///   monarch, initiative, mana pool).
/// - Counters in use show as chips bottom-left; tap one for a small
///   -/+ editor over the life total.
class PlayerPanel extends StatefulWidget {
  const PlayerPanel({
    super.key,
    required this.game,
    required this.index,
    required this.quarterTurns,
  });

  final GameState game;
  final int index;
  final int quarterTurns;

  @override
  State<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<PlayerPanel> {
  _View _view = _View.life;
  bool _drawerOpen = false;

  /// Counter shown in the small popup editor, if any.
  CounterType? _editing;

  GameState get game => widget.game;
  int get index => widget.index;
  Player get player => game.players[index];

  void _openDrawer() => setState(() {
        _drawerOpen = true;
        _closeEditor();
      });

  void _closeDrawer() => setState(() => _drawerOpen = false);

  void _show(_View view) {
    setState(() {
      _drawerOpen = false;
      _editing = null;
      _view = view;
    });
  }

  void _edit(CounterType type) {
    game.addCounter(index, type);
    setState(() {
      _drawerOpen = false;
      _view = _View.life;
      _editing = type;
    });
  }

  void _closeEditor() {
    if (_editing == null) return;
    _editing = null;
    game.removeEmptyCounters(index);
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -150 && !_drawerOpen) _openDrawer();
    if (v > 150 && _drawerOpen) _closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final rolls = game.highRollValues;
    return RotatedBox(
      quarterTurns: widget.quarterTurns,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          color: rolls != null ? const Color(0xFF26262A) : player.color,
          child: rolls != null
              ? _highRollView(rolls[index])
              : GestureDetector(
                  onVerticalDragEnd: _onVerticalDragEnd,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _currentView(),
                      IgnorePointer(
                        ignoring: !_drawerOpen,
                        child: AnimatedSlide(
                          offset:
                              _drawerOpen ? Offset.zero : const Offset(0, 1),
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          child: _drawer(),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _currentView() {
    switch (_view) {
      case _View.life:
        return _lifeView();
      case _View.commander:
        return _commanderView();
      case _View.colors:
        return _colorsView();
    }
  }

  // ---------------------------------------------------------------- life

  Widget _lifeView() {
    final p = player;
    final ink = inkOn(p.color);
    return LayoutBuilder(builder: (context, c) {
      final size = min(c.maxHeight * 0.42, c.maxWidth * 0.32);
      final chipHeight = (c.maxHeight * 0.13).clamp(20.0, 34.0);
      final faint = ink.withValues(alpha: 0.28);
      final delta = p.recentDelta;
      final chips = _chips(chipHeight, ink);
      final editing = _editing;

      return Stack(
        fit: StackFit.expand,
        children: [
          TapHalves(
            onChange: (amount) => game.changeLife(index, amount),
          ),
          if (!p.isOut)
            IgnorePointer(
              child: Padding(
                // Keep clear of the name on top and the chips below.
                padding: EdgeInsets.fromLTRB(8, chipHeight * 1.5, 8,
                    chips.isEmpty ? 14 : chipHeight + 30),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedOpacity(
                          opacity: delta == 0 ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            delta > 0 ? '+$delta' : '$delta',
                            style: numberStyle(
                                size * 0.3, ink.withValues(alpha: 0.6)),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.remove_rounded,
                                size: size * 0.35, color: faint),
                            SizedBox(width: size * 0.4),
                            Text('${p.life}', style: numberStyle(size, ink)),
                            SizedBox(width: size * 0.4),
                            Icon(Icons.add_rounded,
                                size: size * 0.35, color: faint),
                          ],
                        ),
                        SizedBox(height: size * 0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Name and status icons along the top edge.
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (game.monarch == index)
                    _statusIcon(
                        Icons.workspace_premium_rounded, chipHeight, ink),
                  if (game.initiative == index)
                    _statusIcon(Icons.fort, chipHeight, ink),
                  // Only names the players typed in; the default
                  // "PLAYER n" would sit under the center button.
                  if (p.name != 'PLAYER ${index + 1}')
                    Flexible(
                      child: Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle(chipHeight * 0.75,
                            color: ink.withValues(alpha: 0.55)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (p.isOut)
            IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.heart_broken_rounded,
                              color: Colors.white, size: size * 0.7),
                          const SizedBox(height: 4),
                          Text('OUT · ${p.life}',
                              style: labelStyle(size * 0.3,
                                  color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (editing != null) ...[
            // Tap anywhere outside the popup to close it.
            GestureDetector(
              key: const ValueKey('editor-barrier'),
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(_closeEditor),
            ),
            Center(child: _editor(editing, size)),
          ],
          if (chips.isNotEmpty)
            Positioned(
              left: 10,
              right: 10,
              // Sit just above the drawer handle.
              bottom: 26,
              height: chipHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(mainAxisSize: MainAxisSize.min, children: chips),
                ),
              ),
            ),
          _handle(),
        ],
      );
    });
  }

  Widget _statusIcon(IconData icon, double size, Color ink) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(icon, size: size * 0.85, color: ink),
      );

  Color get _dark => Color.lerp(player.color, Colors.black, 0.62)!;

  List<Widget> _chips(double height, Color ink) {
    final p = player;
    return [
      for (final e in p.counters.entries)
        _Chip(
          key: ValueKey('chip-${e.key.name}'),
          height: height,
          color:
              _editing == e.key ? _dark : Colors.black.withValues(alpha: 0.16),
          ink: _editing == e.key ? Colors.white : ink,
          leading: CounterGlyph(
            type: e.key,
            size: height * 0.55,
            color: _editing == e.key ? Colors.white : ink,
          ),
          value: e.value,
          onTap: () => setState(() {
            if (_editing == e.key) {
              _closeEditor();
            } else {
              _closeEditor();
              _editing = e.key;
            }
          }),
        ),
      for (var j = 0; j < game.players.length; j++)
        for (var slot = 0; slot < 2; slot++)
          if (p.damageFrom(j, slot) > 0)
            _Chip(
              key: ValueKey('cmdr-$j-$slot'),
              height: height,
              color: Colors.black.withValues(alpha: 0.16),
              ink: ink,
              leading: _ColorDot(
                color: game.players[j].color,
                size: height * 0.55,
                label: game.players[j].hasPartner ? '${slot + 1}' : null,
              ),
              value: p.damageFrom(j, slot),
              onTap: () => _show(_View.commander),
            ),
    ];
  }

  /// Small dark box over the life total: - value + with the counter symbol.
  Widget _editor(CounterType type, double size) {
    final value = player.counter(type);
    final lethal = type.lethal != null && value >= type.lethal!;
    return Container(
      key: const ValueKey('counter-editor'),
      width: size * 2.4,
      height: size * 1.3,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Counters are small numbers: tap and hold both step by 1.
          TapHalves(
            keyPrefix: 'edit-',
            onChange: (amount) => game.changeCounter(index, type, amount.sign),
          ),
          IgnorePointer(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.15),
              child: Row(
                children: [
                  Icon(Icons.remove_rounded,
                      color: Colors.white, size: size * 0.3),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$value',
                            style: numberStyle(
                                size * 0.6,
                                lethal
                                    ? const Color(0xFFFF5C7A)
                                    : Colors.white),
                          ),
                          SizedBox(height: size * 0.06),
                          CounterGlyph(
                              type: type,
                              size: size * 0.3,
                              color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.add_rounded,
                      color: Colors.white, size: size * 0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _handle() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          key: const ValueKey('drawer-handle'),
          behavior: HitTestBehavior.opaque,
          onTap: _openDrawer,
          child: SizedBox(
            width: 110,
            height: 30,
            child: Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: inkOn(player.color).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backButton(Color ink) => Positioned(
        top: 4,
        left: 4,
        child: IconButton(
          key: const ValueKey('panel-back'),
          onPressed: () => _show(_View.life),
          icon: Icon(Icons.arrow_back_rounded, color: ink),
          tooltip: 'Back',
        ),
      );

  // ----------------------------------------------------- commander damage

  Widget _commanderView() {
    final ink = inkOn(player.color);
    final sources = <(int, int)>[
      for (var j = 0; j < game.players.length; j++)
        if (j != index)
          for (var slot = 0;
              slot < (game.players[j].hasPartner ? 2 : 1);
              slot++)
            (j, slot),
    ];
    // The header goes along the panel's bottom edge: the top edge can sit
    // under the center button.
    final header = SizedBox(
      height: 44,
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('panel-back'),
            onPressed: () => _show(_View.life),
            icon: Icon(Icons.arrow_back_rounded, color: ink),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('COMMANDER DAMAGE TAKEN',
                  style: labelStyle(22, color: ink)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.12),
      child: Column(
        children: [
          Expanded(
            child: sources.isEmpty
                ? Center(
                    child:
                        Text('NO OPPONENTS', style: labelStyle(22, color: ink)),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                    child: Row(
                      children: [
                        for (final (j, slot) in sources)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _CommanderTile(
                                color: game.players[j].color,
                                label: game.players[j].hasPartner
                                    ? '${game.players[j].name} ${slot + 1}'
                                    : game.players[j].name,
                                value: player.damageFrom(j, slot),
                                onChange: (amount) =>
                                    game.changeCommanderDamage(
                                        index, j, slot, amount.sign),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          header,
        ],
      ),
    );
  }

  // ------------------------------------------------------------ colors

  Widget _colorsView() {
    final ink = inkOn(player.color);
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(52, 12, 52, 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 6 * 54,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final color in backgroundChoices)
                      GestureDetector(
                        onTap: () {
                          game.setColor(index, color);
                          _show(_View.life);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  color == player.color ? ink : Colors.black26,
                              width: color == player.color ? 4 : 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _backButton(ink),
      ],
    );
  }

  // ------------------------------------------------------------ drawer

  Widget _drawer() {
    final p = player;
    final left = <Widget>[
      _DrawerItem(
        label: 'BACKGROUND',
        swatch: p.color,
        onTap: () => _show(_View.colors),
      ),
      _DrawerItem(
        label: p.isOut ? 'UNKILL' : 'KILL',
        icon: p.isOut ? Icons.favorite_rounded : Icons.heart_broken_rounded,
        onTap: () {
          game.toggleKill(index);
          _closeDrawer();
        },
      ),
      _DrawerItem(
        label: 'PARTNERS',
        icon: Icons.people_alt_rounded,
        active: p.hasPartner,
        onTap: () {
          game.togglePartner(index);
          _closeDrawer();
        },
      ),
      _DrawerItem(
        label: 'NAME',
        icon: Icons.badge_rounded,
        onTap: () {
          _closeDrawer();
          _rename();
        },
      ),
    ];

    final steppers = <Widget>[
      for (final type in CounterType.steppers)
        _Stepper(
          type: type,
          value: p.counter(type),
          onChange: (amount) => game.changeCounter(index, type, amount),
        ),
    ];

    Widget gridButton({
      required String key,
      required VoidCallback onTap,
      required Widget child,
      Color? fill,
      bool active = false,
    }) {
      return GestureDetector(
        key: ValueKey(key),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.all(5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill ?? const Color(0xFF1F1E25),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? accentGreen : const Color(0xFF1F1E25),
              width: active ? 3 : 4,
            ),
          ),
          child: child,
        ),
      );
    }

    Widget counterButton(CounterType type) => gridButton(
          key: 'grid-${type.name}',
          onTap: () => _edit(type),
          fill: type.tint,
          active: p.counters.containsKey(type),
          child: CounterGlyph(
            type: type,
            size: 24,
            color: type.tint != null ? const Color(0xFF1F1E25) : Colors.white,
          ),
        );

    final grid = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (final type in CounterType.gridTop) counterButton(type),
          gridButton(
            key: 'grid-commander',
            onTap: () => _show(_View.commander),
            child:
                const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
          ),
          gridButton(
            key: 'grid-monarch',
            active: game.monarch == index,
            onTap: () {
              game.toggleMonarch(index);
              _closeDrawer();
            },
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 24),
          ),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (final type in CounterType.gridBottom) counterButton(type),
          gridButton(
            key: 'grid-initiative',
            active: game.initiative == index,
            onTap: () {
              game.toggleInitiative(index);
              _closeDrawer();
            },
            child: const Icon(Icons.fort, color: Colors.white, size: 24),
          ),
        ]),
      ],
    );

    Widget divider() => Container(
          width: 4,
          height: 90,
          margin: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1E25),
            borderRadius: BorderRadius.circular(2),
          ),
        );

    return GestureDetector(
      // Taps on empty drawer space must not reach the life halves below.
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Column(
        children: [
          // The panel shrinks to this colored strip while the drawer is open.
          GestureDetector(
            key: const ValueKey('drawer-close'),
            behavior: HitTestBehavior.opaque,
            onTap: _closeDrawer,
            child: Container(
              height: 30,
              width: double.infinity,
              color: p.color,
              alignment: Alignment.center,
              child: Container(
                width: 120,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: drawerColor,
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    height: c.maxHeight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ...left,
                            divider(),
                            ...steppers,
                            divider(),
                            grid,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: player.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: sheetColor,
        title: Text('PLAYER NAME', style: labelStyle(28, color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: labelStyle(20, color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('SAVE', style: labelStyle(20, color: accentGreen)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) game.setName(index, name);
  }

  // ---------------------------------------------------------- high roll

  Widget _highRollView(int value) {
    final winner = game.highRollWinner;
    final faded = winner != null && winner != index;
    return LayoutBuilder(builder: (context, c) {
      final size = min(c.maxHeight * 0.5, c.maxWidth * 0.35);
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$value',
            style: numberStyle(size,
                faded ? Colors.white.withValues(alpha: 0.45) : Colors.white),
          ),
        ),
      );
    });
  }
}

/// Left half = minus, right half = plus. Tap = 1, hold = 10 (repeating).
class TapHalves extends StatefulWidget {
  const TapHalves({super.key, required this.onChange, this.keyPrefix = ''});

  final ValueChanged<int> onChange;

  /// Prefix for the halves' keys ('minus' / 'plus'), for tests.
  final String keyPrefix;

  @override
  State<TapHalves> createState() => _TapHalvesState();
}

class _TapHalvesState extends State<TapHalves> {
  int _flashSide = 0;
  Timer? _flashTimer;
  Timer? _repeatTimer;

  void _apply(int amount, int side) {
    HapticFeedback.selectionClick();
    widget.onChange(amount);
    setState(() => _flashSide = side);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _flashSide = 0);
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _repeatTimer?.cancel();
    super.dispose();
  }

  Widget _half(int sign) {
    return GestureDetector(
      key: ValueKey('${widget.keyPrefix}${sign < 0 ? 'minus' : 'plus'}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _apply(sign, sign),
      onLongPressStart: (_) {
        _apply(sign * 10, sign);
        _repeatTimer?.cancel();
        _repeatTimer = Timer.periodic(
          const Duration(milliseconds: 600),
          (_) => _apply(sign * 10, sign),
        );
      },
      onLongPressEnd: (_) => _repeatTimer?.cancel(),
      onLongPressCancel: () => _repeatTimer?.cancel(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: Colors.white.withValues(alpha: _flashSide == sign ? 0.25 : 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _half(-1)),
        Expanded(child: _half(1)),
      ],
    );
  }
}

/// Drawer stepper: + on top, value and symbol in a box, - below.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.type,
    required this.value,
    required this.onChange,
  });

  final CounterType type;
  final int value;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    Widget button(int amount, IconData icon) => GestureDetector(
          key: ValueKey('step-${type.name}-${amount > 0 ? 'plus' : 'minus'}'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onChange(amount);
          },
          child: SizedBox(
            width: 56,
            height: 30,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(1, Icons.add_rounded),
          Container(
            width: 48,
            height: 96,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('$value', style: labelStyle(34, color: Colors.white)),
                CounterGlyph(type: type, size: 26, color: Colors.white),
              ],
            ),
          ),
          button(-1, Icons.remove_rounded),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.height,
    required this.color,
    required this.ink,
    required this.leading,
    required this.value,
    required this.onTap,
  });

  final double height;
  final Color color;
  final Color ink;
  final Widget leading;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(right: 6),
        padding: EdgeInsets.symmetric(horizontal: height * 0.35),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            SizedBox(width: height * 0.25),
            Text('$value', style: labelStyle(height * 0.65, color: ink)),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.size, this.label});

  final Color color;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: label == null
          ? null
          : Text(label!, style: labelStyle(size * 0.7, color: inkOn(color))),
    );
  }
}

class _CommanderTile extends StatelessWidget {
  const _CommanderTile({
    required this.color,
    required this.label,
    required this.value,
    required this.onChange,
  });

  final Color color;
  final String label;
  final int value;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final ink = inkOn(color);
    final lethal = value >= commanderLethal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: color,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TapHalves(onChange: onChange),
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label,
                          style: labelStyle(16,
                              color: ink.withValues(alpha: 0.7))),
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$value',
                            style: numberStyle(48, lethal ? Colors.white : ink),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.swatch,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? swatch;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('drawer-$label'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: swatch != null ? 72 : 56,
              height: 56,
              decoration: swatch != null
                  ? BoxDecoration(
                      color: swatch,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black26, width: 2),
                    )
                  : BoxDecoration(
                      color: active ? accentGreen : const Color(0xFF1F1E25),
                      shape: BoxShape.circle,
                    ),
              child: icon == null
                  ? null
                  : Icon(icon,
                      size: 30, color: active ? Colors.black : Colors.white),
            ),
            const SizedBox(height: 8),
            Text(label, style: labelStyle(20, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
