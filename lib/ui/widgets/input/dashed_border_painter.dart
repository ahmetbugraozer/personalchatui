import 'package:flutter/material.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    Path dashPath(Path source, double dash, double gap) {
      final metrics = source.computeMetrics();
      final dashed = Path();
      for (final m in metrics) {
        double distance = 0.0;
        while (distance < m.length) {
          final len = (distance + dash).clamp(0, m.length) as double;
          dashed.addPath(m.extractPath(distance, len), Offset.zero);
          distance = len + gap;
        }
      }
      return dashed;
    }

    final r = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth),
      const Radius.circular(12),
    );
    final outline = Path()..addRRect(r);
    final dashed = dashPath(outline, dash, gap);
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap;
  }
}
