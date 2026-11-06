import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _displayFonts = <String>[
  'assets/fonts/BarlowCondensed-Bold.ttf',
  'assets/fonts/BarlowCondensed-ExtraBold.ttf',
];

const _bodyFonts = <String>[
  'assets/fonts/Inter-Regular.ttf',
  'assets/fonts/Inter-Medium.ttf',
  'assets/fonts/Inter-SemiBold.ttf',
  'assets/fonts/Inter-Bold.ttf',
  'assets/fonts/Inter-ExtraBold.ttf',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled display and body fonts load', () async {
    final displayLoader = FontLoader('Barlow Condensed');
    for (final asset in _displayFonts) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
      displayLoader.addFont(Future<ByteData>.value(data));
    }
    await displayLoader.load();

    final bodyLoader = FontLoader('Inter');
    for (final asset in _bodyFonts) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
      bodyLoader.addFont(Future<ByteData>.value(data));
    }
    await bodyLoader.load();
  });
}
