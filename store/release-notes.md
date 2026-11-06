# Mova 1.0.0 Release Candidate

Build date: 2026.11.06
Version: `1.0.0+1`

## Artifacts

| Artifact | Path | Size | SHA-256 |
|---|---|---|---|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` | 183 MB | `0efde208f7a9ba1cf58027745b9bd69a112ec24780ff0caa9c572ef43bf9e4f4` |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` | 55 MB | `a113a682b89e07b90ce1c92ce54e30d7a507d9926487c61096b3f53db074cb18` |
| Web bundle | `build/web/main.dart.js` | 3.9 MB | `29fbb6d46b6e2b3e83e2b580c7fb3d682f123e1bc80409b07716c46e38f5e987` |

The release APK and web bundle were built without signing credentials. The Android upload keystore and Apple distribution profile remain manual blockers.

## Gate results

| Command | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | 217 files, 0 changed |
| `flutter analyze` | No issues found |
| `flutter test` | 458 tests passed in 88 files |
| `flutter test --coverage` | Passed |
| `tool/check_coverage.sh coverage/lcov.info` | Models 91.65%, services 87.54%, providers 88.59%, overall 86.05% |
| `flutter build apk --debug` | Passed |
| `flutter build apk --release` | Passed, 58.1 MB reported by Flutter |
| `flutter build web --release` | Passed |
| `adb install app-release.apk` | Installed on the Pixel 9 Pro API 34 emulator and launched cold in 1194 ms with no fatal crash |

## Device matrix

| Device class | Viewport | Result |
|---|---|---|
| Small phone | 375x667 at 2x, touch | Clean render, no console errors |
| Small Android | 360x640 at 1.0 and 1.3 font scale | Clean render, no clipping |
| Large phone | 393x852 at 3x, touch | Clean render, no clipping |
| Tablet | 800x1280 at 2x, touch | Centered 720 dp content column |
| Tablet landscape | 1280x800 at 2x, touch | Centered 720 dp content column |
| Web | 1440x900 at 1x | Centered 720 dp content column, full-width navigation |

## QA highlights

- Chrome Lighthouse scored 100 for accessibility, best practices, SEO, and agentic browsing on Today, Settings, Progress, Social, Train, Logger, and Summary.
- Warm startup LCP was 157 ms with CLS 0.00. Logger scrolling held 119.5 fps with a 12.8 ms maximum frame.
- A corrupt settings payload was dropped with a dismissible local storage warning.
- An Android emulator granted notification permission and scheduled three inexact reminders, showed blocked health guidance, opened the share chooser with a rendered card, and released KEEP_SCREEN_ON on pause.
- Streak, Today, weekly volume, and plan day rollover passed under `TZ=Europe/Bucharest` and `TZ=America/New_York`.

## Known warnings

- The disabled ruler slider widget test emits a non-fatal hit-test warning. The test passes.
- The Android build emits a `health` plugin Kotlin Gradle Plugin migration warning. The build succeeds.

## Remaining manual blockers

- Android upload keystore, store password, key alias, and key password.
- Apple Developer team, certificate, provisioning profile, and App Store Connect record.
- Google Play Console and App Store Connect submission access.
- Health data declarations for Play Console and App Review.
- Final legal review of privacy and terms.
- Final brand approval for the icon and splash.
- VoiceOver on iOS and TalkBack on Android on physical hardware, plus physical plugin confirmation.
- User-owned version control setup.
