import 'package:flutter/material.dart';

import '../game_state.dart';
import '../theme.dart';

/// Draws a counter's symbol: an icon or short text, with an optional badge.
class CounterGlyph extends StatelessWidget {
  const CounterGlyph({
    super.key,
    required this.type,
    required this.size,
    required this.color,
  });

  final CounterType type;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Widget symbol = type.icon != null
        ? Icon(type.icon, size: size, color: color)
        : Text(
            type.glyph!,
            style: type.glyph == 'Φ'
                ? numberStyle(size * 0.95, color)
                : labelStyle(size * (type.glyph!.length > 2 ? 0.75 : 0.95),
                    color: color),
          );
    final badge = type.badge;
    if (badge == null) return symbol;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        symbol,
        Positioned(
          right: -size * 0.15,
          bottom: -size * 0.2,
          child: Container(
            width: size * 0.45,
            height: size * 0.45,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              badge,
              style: labelStyle(size * 0.38,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
