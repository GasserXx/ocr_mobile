import 'package:flutter/material.dart';
import 'dart:ui';


class DottedBorder extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double strokeWidth;
  final Color color;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;

  const DottedBorder({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(2),
    this.strokeWidth = 1,
    this.color = Colors.black,
    this.dashPattern = const [3, 1],
    this.borderType = BorderType.Rect,
    this.radius = const Radius.circular(0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedCustomPaint(
        strokeWidth: strokeWidth,
        color: color,
        dashPattern: dashPattern,
        borderType: borderType,
        radius: radius,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DottedCustomPaint extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;

  _DottedCustomPaint({
    required this.strokeWidth,
    required this.color,
    required this.dashPattern,
    required this.borderType,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    if (borderType == BorderType.RRect) {
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          radius,
        ),
      );
    } else {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final Path dashPath = Path();
    double distance = 0.0;
    bool draw = true;
    int dashIndex = 0;

    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final double len = dashPattern[dashIndex];
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
        dashIndex = (dashIndex + 1) % dashPattern.length;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DottedCustomPaint oldDelegate) => false;
}

enum BorderType { Rect, RRect }