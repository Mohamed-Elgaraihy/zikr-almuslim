import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PatternHeader extends StatelessWidget {
  const PatternHeader({super.key, required this.child, this.height = 168});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: CustomPaint(
        painter: const _StarPatternPainter(),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: child,
        ),
      ),
    );
  }
}

class _StarPatternPainter extends CustomPainter {
  const _StarPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = AppColors.greenDeep;
    canvas.drawRect(Offset.zero & size, background);

    final line = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const step = 46.0;
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        _star(canvas, Offset(x + step / 2, y + step / 2), 16, line);
      }
    }
    final wash = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x66083C2E), Color(0xCC06261E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);
  }

  void _star(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 8;
    for (var i = 0; i < points * 2; i++) {
      final spoke = i.isEven ? radius : radius * 0.42;
      final angle = (i * math.pi / points) - math.pi / 2;
      final point = Offset(
        center.dx + spoke * math.cos(angle),
        center.dy + spoke * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
