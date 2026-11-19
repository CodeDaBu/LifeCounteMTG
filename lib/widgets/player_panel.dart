import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_state.dart';
import '../theme.dart';

/// One player's tile. Tap the left half for -1, right half for +1.
/// Hold for -10 / +10 (repeats while held).
class PlayerPanel extends StatefulWidget {
  const PlayerPanel({
    super.key,
    required this.player,
    required this.quarterTurns,
    required this.onChange,
    this.highRoll,
    this.highRollFaded = false,
  });

  final Player player;
  final int quarterTurns;
  final ValueChanged<int> onChange;

  /// When set, the panel shows this die result instead of the life total.
  final int? highRoll;
  final bool highRollFaded;

  @override
  State<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<PlayerPanel> {
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

  @override
  Widget build(BuildContext context) {
    final rolling = widget.highRoll != null;
    return RotatedBox(
      quarterTurns: widget.quarterTurns,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          color: rolling ? const Color(0xFF26262A) : widget.player.color,
          child: rolling ? _highRollContent() : _lifeContent(),
        ),
      ),
    );
  }

  Widget _highRollContent() {
    return LayoutBuilder(builder: (context, c) {
      final size = min(c.maxHeight * 0.5, c.maxWidth * 0.35);
      final color = widget.highRollFaded
          ? Colors.white.withValues(alpha: 0.45)
          : Colors.white;
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('${widget.highRoll}', style: numberStyle(size, color)),
        ),
      );
    });
  }

  Widget _lifeContent() {
    return LayoutBuilder(builder: (context, c) {
      final size = min(c.maxHeight * 0.42, c.maxWidth * 0.32);
      const ink = Colors.black;
      final faint = Colors.black.withValues(alpha: 0.28);
      final delta = widget.player.recentDelta;
      final deltaText = delta > 0 ? '+$delta' : '$delta';

      return Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              Expanded(child: _half(-1)),
              Expanded(child: _half(1)),
            ],
          ),
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        opacity: delta == 0 ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          deltaText,
                          style: numberStyle(
                              size * 0.3, ink.withValues(alpha: 0.6)),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_rounded,
                              size: size * 0.35, color: faint),
                          SizedBox(width: size * 0.15),
                          Text('${widget.player.life}',
                              style: numberStyle(size, ink)),
                          SizedBox(width: size * 0.15),
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
        ],
      );
    });
  }

  Widget _half(int sign) {
    return GestureDetector(
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
        color: _flashSide == sign
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0),
      ),
    );
  }
}
