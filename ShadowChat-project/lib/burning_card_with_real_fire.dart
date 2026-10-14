import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class BurningCardWithRealFire extends StatelessWidget {
  const BurningCardWithRealFire({
    super.key,
    required this.child,
    required this.controller,
  });

  final Widget child;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, childWidget) {
        final progress = controller.value.clamp(0.0, 1.0);
        return CustomPaint(
          foregroundPainter: RealFirePainter(progress),
          child: ClipPath(
            clipper: _BurningCardClipper(progress),
            child: Opacity(
              opacity: (1.0 - progress * 1.2).clamp(0.0, 1.0),
              child: childWidget,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class RealFirePainter extends CustomPainter {
  const RealFirePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1 || size.isEmpty) return;

    final currentX = size.width * (1 - progress);
    final glowRect = Rect.fromLTWH(currentX - 20, 0, 40, size.height);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(currentX - 20, 0),
          Offset(currentX + 20, 0),
          [
            Colors.transparent,
            Colors.deepOrange.withValues(alpha: 0.8),
            Colors.red.withValues(alpha: 0.9),
            Colors.transparent,
          ],
          [0, 0.35, 0.65, 1],
        ),
    );

    final flamePath = Path()..moveTo(currentX, size.height);
    for (var y = size.height; y >= 0; y -= 15) {
      final wave = math.sin((y + progress * 50) * 0.2) * 10;
      flamePath.lineTo(currentX + wave, y);
    }
    flamePath
      ..lineTo(currentX + 30, 0)
      ..lineTo(currentX + 30, size.height)
      ..close();
    canvas.drawPath(
      flamePath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(currentX, 0),
          Offset(currentX + 30, 0),
          [
            Colors.yellow,
            Colors.deepOrange,
            Colors.red.shade900,
            Colors.transparent,
          ],
          [0, 0.35, 0.75, 1],
        ),
    );

    final sparkPaint = Paint()..color = Colors.amberAccent;
    for (var index = 0; index < 8; index++) {
      final phase = index * 2.4;
      final offsetX = currentX + math.sin(phase + progress * 13) * 20;
      final offsetY = (size.height * ((index * 0.37 + progress * 0.22) % 1));
      final radius = 1.5 + (math.sin(phase + progress * 9) + 1) * 1.5;
      canvas.drawCircle(Offset(offsetX, offsetY), radius, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RealFirePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BurningCardClipper extends CustomClipper<Path> {
  const _BurningCardClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final remainingWidth = size.width * (1 - progress);
    return Path()..addRect(Rect.fromLTWH(0, 0, remainingWidth, size.height));
  }

  @override
  bool shouldReclip(covariant _BurningCardClipper oldClipper) =>
      oldClipper.progress != progress;
}
