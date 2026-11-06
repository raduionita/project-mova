# Mova 1.0.0 Release Candidate

Build date: 2026.11.06
Version: `1.0.0+1`

## Artifacts

| Artifact | Path | Size | SHA-256 |
|---|---|---|---|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` | 160 MB | `bd8b14e205baa07507e0eaee155dbf7e2626ba458451b546d8227abbfd46eed1` |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` | 55 MB | `3a8fef6211c5808d8a841dee39a4a674e86a8fbc57c631025a32016061693252` |
| Web bundle | `build/web/main.dart.js` | 3.9 MB | `a3aebe6232a9de35aad933df47a6c0efba8d24ccbfdf2823c140c72b1e29e010` |

The release APK and web bundle were built without signing credentials. The Android upload keystore and Apple distribution profile remain manual blockers.

## Gate results

| Command | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | 217 files, 0 changed |
| `flutter analyze` | No issues found |
| `flutter test` | 459 tests passed in 88 files |
| `flutter test --coverage` | Passed |
| `tool/check_coverage.sh coverage/lcov.info` | Models 91.65%, services 87.54%, providers 88.59%, overall 86.06% |
| `flutter build apk --debug` | Passed |
| `flutter build apk --release` | Passed, 58.1 MB reported by Flutter |
| `flutter build web --release` | Passed |
| Chrome mobile smoke | Pixel 9 Pro emulation at 412x915; onboarding, workout, summary, Progress, Social, Train browse, Settings, legal screens, 5,000 manual steps, and reload persistence passed; no console errors or warnings |
| `adb install app-release.apk` | Installed the rebuilt APK (SHA-256 `3a8fef62...3252`) on the Pixel 9 Pro API 34 emulator; after clearing local data it launched cold in 916 ms to the welcome screen with no fatal crash |

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
- Chrome mobile smoke found that Today did not show the saved streak. TRN-22 added the `1 day streak` tag to the Today header and a widget test; the rebuilt web bundle was re-smoked and the tag rendered.
- The same mobile smoke passed a 5,000-step manual entry and a reload that preserved the workout, streak, steps, and the kilogram unit choice.
- The rebuilt release APK was installed on the Pixel 9 Pro API 34 emulator and, after clearing local data, launched cold in 916 ms to the welcome screen with no fatal crash.

## Known warnings

- The disabled ruler slider widget test emits a non-fatal hit-test warning. The test passes.
- The Android build emits a `health` plugin Kotlin Gradle Plugin migration warning. The build succeeds.

## Remaining release preparation

The remaining manual blockers are tracked in `plans/2026.11.07.pre-release.md`:

- Android upload keystore, store password, key alias, and key password.
- Apple Developer team, certificate, provisioning profile, and App Store Connect record.
- Google Play Console and App Store Connect submission access.
- Health data declarations for Play Console and App Review.
- Final legal review of privacy and terms.
- Final brand approval for the icon and splash.
- VoiceOver on iOS and TalkBack on Android on physical hardware, plus physical plugin confirmation.
- User-owned version control setup.
