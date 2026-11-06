import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/services/haptics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = HapticsService();
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('set completion uses a light impact', () async {
    await service.setCompleted();

    expect(calls, hasLength(1));
    expect(calls.single.arguments, 'HapticFeedbackType.lightImpact');
  });

  test('rest completion and personal records use a medium impact', () async {
    await service.restFinished();
    await service.personalRecord();

    expect(calls, hasLength(2));
    expect(
      calls.map((call) => call.arguments),
      everyElement('HapticFeedbackType.mediumImpact'),
    );
  });

  test('reduced motion suppresses every haptic', () async {
    await service.setCompleted(reduceMotion: true);
    await service.restFinished(reduceMotion: true);
    await service.personalRecord(reduceMotion: true);

    expect(calls, isEmpty);
  });
}
