import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Geometry of the Mova logo mark, the reversed M from the splash artwork.
///
/// The points are traced from `assets/images/splash_logo.png` (1024x1024) so
/// the same silhouette is drawn at every size instead of typed as a letter.
class MovaMarkPath {
  const MovaMarkPath._();

  /// Artboard size of the mark, stroke included.
  static const double sourceWidth = 312;
  static const double sourceHeight = 288;

  /// Stroke weight as drawn on the 1024 artboard.
  static const double sourceStroke = 53;

  static const double aspectRatio = sourceWidth / sourceHeight;

  static const Offset _sourceCenter = Offset(511.5, 506);

  static const List<Offset> _points = <Offset>[
    Offset(382, 388.5),
    Offset(382, 623.5),
    Offset(511, 484.5),
    Offset(641, 623.5),
    Offset(641, 388.5),
  ];

  /// Fits the mark into [rect], preserving the artboard aspect ratio.
  static Path pathIn(Rect rect) {
    final scale = rect.height / sourceHeight;
    Offset map(Offset point) => rect.center + (point - _sourceCenter) * scale;

    final first = map(_points.first);
    final path = Path()..moveTo(first.dx, first.dy);
    for (final point in _points.skip(1)) {
      final mapped = map(point);
      path.lineTo(mapped.dx, mapped.dy);
    }
    return path;
  }

  /// Strokes the mark into [rect] with round caps and joins.
  static void paint(Canvas canvas, Rect rect, Color color) {
    canvas.drawPath(
      pathIn(rect),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sourceStroke * rect.height / sourceHeight
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }
}

/// The Mova logo mark on its own, sized by [height].
class MovaMark extends StatelessWidget {
  const MovaMark({
    super.key,
    this.height = 44,
    this.color = AppColors.limeInk,
    this.semanticLabel,
  });

  final double height;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: height * MovaMarkPath.aspectRatio,
      height: height,
      child: CustomPaint(painter: _MovaMarkPainter(color)),
    );
    final label = semanticLabel;
    if (label == null) {
      return mark;
    }
    return Semantics(image: true, label: label, child: mark);
  }
}

class _MovaMarkPainter extends CustomPainter {
  const _MovaMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    MovaMarkPath.paint(canvas, Offset.zero & size, color);
  }

  @override
  bool shouldRepaint(_MovaMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
