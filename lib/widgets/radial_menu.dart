import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

class RadialMenuItem {
  const RadialMenuItem(this.label, this.color, this.onTap);

  final String label;
  final Color color;
  final VoidCallback onTap;
}

/// Pill buttons arranged in a ring around the screen center, each turned
/// along the ring so players on every side can read one of them.
/// Fill the screen with it; empty areas let taps through.
class RadialMenu extends StatelessWidget {
  const RadialMenu({super.key, required this.items, this.radius = 140});

  final List<RadialMenuItem> items;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => LayoutBuilder(
        // Shrink the whole ring on narrow screens so no button is cut off.
        builder: (context, c) => Transform.scale(
          scale: min(1.0, (c.biggest.shortestSide - 16) / (radius * 2 + 110)),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < items.length; i++) _item(i, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, double t) {
    final angle = -2 * pi / 3 + i * 2 * pi / items.length;
    final r = radius * t;
    final item = items[i];
    return Transform.translate(
      offset: Offset(cos(angle) * r, sin(angle) * r),
      child: Transform.rotate(
        angle: angle + pi / 2,
        child: Opacity(
          opacity: t.clamp(0.0, 1.0).toDouble(),
          child: Material(
            color: item.color,
            shape: const StadiumBorder(),
            elevation: 6,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: item.onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Text(item.label, style: labelStyle(26)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
