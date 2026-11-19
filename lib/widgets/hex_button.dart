import 'dart:math';

import 'package:flutter/material.dart';

/// The center hexagon that opens the menu (menu icon) or closes things (X).
class HexButton extends StatelessWidget {
  const HexButton({
    super.key,
    required this.open,
    required this.onTap,
    this.size = 76,
  });

  final bool open;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _HexPainter(open: open),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  RotationTransition(turns: anim, child: child),
              child: Icon(
                open ? Icons.close_rounded : Icons.menu_rounded,
                key: ValueKey(open),
                color: open ? Colors.black : Colors.white,
                size: size * 0.42,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter({required this.open});

  final bool open;

  static const _sheen = [
    Color(0xFFFFB8F5),
    Color(0xFFB8E8FF),
    Color(0xFFB8FFE0),
    Color(0xFFE0C8FF),
    Color(0xFFFFB8F5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = roundedHexagon(rect.deflate(4), 10);
    final gradient = const SweepGradient(colors: _sheen).createShader(rect);

    canvas.drawShadow(path, Colors.black, 6, false);
    if (open) {
      canvas.drawPath(path, Paint()..shader = gradient);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.black,
      );
    } else {
      canvas.drawPath(path, Paint()..color = Colors.black);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..shader = gradient,
      );
    }
  }

  @override
  bool shouldRepaint(_HexPainter old) => old.open != open;
}

/// Pointy-top hexagon with rounded corners, fitted inside [rect].
Path roundedHexagon(Rect rect, double radius) {
  final c = rect.center;
  final r = rect.shortestSide / 2;
  final pts = List.generate(6, (i) {
    final a = -pi / 2 + i * pi / 3;
    return c + Offset(cos(a), sin(a)) * r;
  });
  final path = Path();
  for (var i = 0; i < 6; i++) {
    final p = pts[i];
    final prev = pts[(i + 5) % 6];
    final next = pts[(i + 1) % 6];
    final a = p + (prev - p) / (prev - p).distance * radius;
    final b = p + (next - p) / (next - p).distance * radius;
    if (i == 0) {
      path.moveTo(a.dx, a.dy);
    } else {
      path.lineTo(a.dx, a.dy);
    }
    path.quadraticBezierTo(p.dx, p.dy, b.dx, b.dy);
  }
  return path..close();
}
