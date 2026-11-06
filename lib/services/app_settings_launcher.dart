import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the platform app settings page so a user can change a denied
/// permission. Fails soft on web and unsupported platforms.
class AppSettingsLauncher {
  const AppSettingsLauncher();

  Future<bool> open() async {
    if (kIsWeb) {
      return false;
    }
    final uri = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => Uri.parse('app-settings:'),
      TargetPlatform.android => Uri.parse('package:com.qvonyx.mova'),
      _ => null,
    };
    if (uri == null) {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
