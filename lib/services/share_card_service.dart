import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:share_plus/share_plus.dart' as sharing;

import '../common/formatters.dart';
import '../models/personal_record.dart';
import '../models/unit_preferences.dart';
import '../models/workout_session.dart';
import 'unit_conversion_service.dart';
import 'workout_calculator.dart';

/// Outcome of handing a rendered card to the platform share surface.
class ShareResult {
  const ShareResult({required this.shared, this.error});

  final bool shared;
  final String? error;
}

/// Renders the 1080x1920 PR card and shares it.
///
/// The card is drawn locally with a canvas. No network is used. On web the
/// share package falls back to downloading the image when the Web Share API
/// cannot share files.
class ShareCardService {
  const ShareCardService();

  static const int cardWidth = 1080;
  static const int cardHeight = 1920;

  static const Color _lime = Color(0xFFB7F24C);
  static const Color _limeEnd = Color(0xFF4D8A2A);
  static const Color _ink = Color(0xFF131A04);

  /// Renders a PNG for [session]. When [record] is supplied the card uses the
  /// personal record exercise and value, otherwise it uses the best completed
  /// working set in the session.
  Future<Uint8List?> render(
    WorkoutSession session, {
    PersonalRecord? record,
    String Function(String exerciseId)? exerciseName,
    WeightUnit weightUnit = WeightUnit.kg,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    _paintBackground(canvas);
    _paintMark(canvas);

    final card = _cardData(
      session,
      record: record,
      exerciseName: exerciseName,
      weightUnit: weightUnit,
    );

    _paintText(
      canvas,
      'PERSONAL RECORD',
      offset: const Offset(80, 540),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 6,
        color: _ink,
      ),
    );
    _paintText(
      canvas,
      card.title,
      offset: const Offset(80, 610),
      maxWidth: 920,
      maxLines: 2,
      style: const TextStyle(
        fontFamily: 'Barlow Condensed',
        fontSize: 84,
        height: 1.02,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
    );
    _paintText(
      canvas,
      card.value,
      offset: const Offset(80, 830),
      maxWidth: 820,
      style: const TextStyle(
        fontFamily: 'Barlow Condensed',
        fontSize: 210,
        height: 1,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: _ink,
      ),
    );
    _paintText(
      canvas,
      card.unit,
      offset: const Offset(84, 1060),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 46,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: _ink,
      ),
    );

    if (card.delta != null) {
      _paintChip(canvas, card.delta!, top: 1180);
    }

    _paintText(
      canvas,
      card.footer,
      offset: const Offset(80, 1360),
      maxWidth: 920,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 38,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: _ink,
      ),
    );

    canvas.drawRect(
      const Rect.fromLTWH(80, 1660, 920, 2),
      Paint()..color = _ink.withValues(alpha: 0.25),
    );
    _paintText(
      canvas,
      'Move. Log. Progress.',
      offset: const Offset(80, 1690),
      style: const TextStyle(
        fontFamily: 'Barlow Condensed',
        fontSize: 52,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: _ink,
      ),
    );
    _paintText(
      canvas,
      'MOVA',
      offset: const Offset(80, 1772),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 8,
        color: _ink,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(cardWidth, cardHeight);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  /// Opens the native share sheet. On web the share package downloads the
  /// image when file sharing is unavailable.
  Future<ShareResult> share(
    Uint8List bytes, {
    ui.Rect? origin,
    String fileName = 'mova-card.png',
  }) async {
    try {
      final result = await sharing.SharePlus.instance.share(
        sharing.ShareParams(
          files: <sharing.XFile>[
            sharing.XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: fileName,
            ),
          ],
          fileNameOverrides: <String>[fileName],
          text: 'Move. Log. Progress.',
          sharePositionOrigin: origin,
          downloadFallbackEnabled: true,
        ),
      );
      return ShareResult(
        shared: result.status != sharing.ShareResultStatus.dismissed,
      );
    } catch (error) {
      return ShareResult(shared: false, error: error.toString());
    }
  }

  void _paintBackground(Canvas canvas) {
    const bounds = Rect.fromLTWH(0, 0, cardWidth * 1.0, cardHeight * 1.0);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          <Color>[_lime, _limeEnd],
        ),
    );
  }

  void _paintMark(Canvas canvas) {
    const mark = Rect.fromLTWH(80, 96, 132, 132);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mark, const Radius.circular(38)),
      Paint()..color = _ink,
    );
    _paintText(
      canvas,
      'M',
      offset: const Offset(122, 118),
      style: const TextStyle(
        fontFamily: 'Barlow Condensed',
        fontSize: 104,
        fontWeight: FontWeight.w800,
        color: _lime,
      ),
    );
    _paintText(
      canvas,
      'MOVA',
      offset: const Offset(242, 148),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: 10,
        color: _ink,
      ),
    );
  }

  void _paintChip(Canvas canvas, String label, {required double top}) {
    const left = 80.0;
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    const horizontal = 28.0;
    const vertical = 16.0;
    final rect = Rect.fromLTWH(
      left,
      top,
      painter.width + horizontal * 2,
      painter.height + vertical * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      Paint()..color = _ink.withValues(alpha: 0.14),
    );
    painter.paint(canvas, Offset(left + horizontal, top + vertical));
    painter.dispose();
  }

  void _paintText(
    Canvas canvas,
    String text, {
    required Offset offset,
    required TextStyle style,
    double maxWidth = 920,
    int maxLines = 1,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
    painter.dispose();
  }

  _CardData _cardData(
    WorkoutSession session, {
    required PersonalRecord? record,
    required String Function(String exerciseId)? exerciseName,
    required WeightUnit weightUnit,
  }) {
    const units = UnitConversionService();
    final date = session.completedAt ?? session.startedAt;

    if (record != null) {
      final delta = record.bestE1rmKg - record.previousBestKg;
      return _CardData(
        title: _resolveName(exerciseName, record.exerciseId),
        value: _number(record.bestE1rmKg, weightUnit),
        unit: units.weightLabel(weightUnit),
        delta: record.previousBestKg > 0
            ? '${delta >= 0 ? '+' : ''}'
                  '${units.displayWeight(delta, weightUnit)} vs last best'
            : null,
        footer: formatDetailDate(date),
      );
    }

    _BestSet? best;
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        if (!set.completed || set.isWarmup || set.weightKg <= 0) {
          continue;
        }
        final estimated = WorkoutCalculator.estimatedOneRepMax(
          set.weightKg,
          set.reps,
        );
        if (best == null || estimated > best.estimated) {
          best = _BestSet(
            exerciseId: exercise.exerciseId,
            weightKg: set.weightKg,
            reps: set.reps,
            estimated: estimated,
          );
        }
      }
    }

    if (best == null) {
      return _CardData(
        title: session.name.isEmpty ? 'Workout' : session.name,
        value: formatVolume(
          WorkoutCalculator.volumeKg(session.exercises),
          unit: weightUnit,
        ).split(' ').first,
        unit: '${units.weightLabel(weightUnit)} volume',
        footer: formatDetailDate(date),
      );
    }

    return _CardData(
      title: _resolveName(exerciseName, best.exerciseId),
      value: _number(best.estimated, weightUnit),
      unit: '${units.weightLabel(weightUnit)} e1RM',
      footer:
          '${formatDetailDate(date)} · '
          '${units.displayWeight(best.weightKg, weightUnit)} × ${best.reps}',
    );
  }

  String _resolveName(
    String Function(String exerciseId)? exerciseName,
    String exerciseId,
  ) {
    final resolved = exerciseName?.call(exerciseId);
    if (resolved == null || resolved.trim().isEmpty) {
      return _titleCase(exerciseId.replaceAll('-', ' '));
    }
    return resolved;
  }

  String _number(double kilograms, WeightUnit unit) {
    const units = UnitConversionService();
    final value = unit == WeightUnit.kg ? kilograms : units.kgToLb(kilograms);
    final rounded = value.toStringAsFixed(1);
    return rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _CardData {
  const _CardData({
    required this.title,
    required this.value,
    required this.unit,
    required this.footer,
    this.delta,
  });

  final String title;
  final String value;
  final String unit;
  final String footer;
  final String? delta;
}

class _BestSet {
  const _BestSet({
    required this.exerciseId,
    required this.weightKg,
    required this.reps,
    required this.estimated,
  });

  final String exerciseId;
  final double weightKg;
  final int reps;
  final double estimated;
}
