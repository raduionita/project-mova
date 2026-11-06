import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  final storage = await StorageService.create();
  runApp(MovaApp(storage: storage));
}

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final barlow = await rootBundle.loadString(
      'assets/legal/OFL-BarlowCondensed.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['Barlow Condensed'], barlow);
    final inter = await rootBundle.loadString('assets/legal/OFL-Inter.txt');
    yield LicenseEntryWithLineBreaks(<String>['Inter'], inter);
  });
}
