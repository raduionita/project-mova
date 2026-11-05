# AGENTS.md - Mova Flutter Mobile Fitness App

This document provides context, guidelines, and project structure information to help AI assistants understand and contribute effectively to this Dart + Flutter fitness app.

---

## Project Overview

**Project Name**: Mova
**Language**: English
**Description**: Mova is a mobile fitness app built with Flutter/Dart
**Platform**: Mobile-first (iOS, Android, Web via Flutter)
**Platform priority**: Android and iOS are primary. Web must build and pass a manual smoke test, but full parity is not required.

---

## Technology Stack

**Flutter** - Cross-platform mobile UI framework
**Dart** - Programming language for Flutter
**Provider** - State management
**Authentication** - Local guest profile in v1; Google and Apple Sign-In post-MVP, no Firebase

---

## Development Environment

- macOS is the supported development OS.
- Use macOS tools: `grep`, `find`, `shasum`, `open`, `xcrun`, `xcodebuild`, `flutter`, and `dart`.
- Do not call Windows tools or use win32 paths.
- `rg` is preferred when available; fall back to `grep` and `find`.
- iOS builds require Xcode. Web smoke tests use Chrome on macOS.

---

## Rules

- Do NOT use em dashes, ONLY hyphens (-)
- NEVER `git commit`, `git add` or `git push`
- Do NOT bundle multiple models, providers, widgets, screens, components into a single file, each in its own file.
- `shared_preferences` and `provider` for storage and state management
- DO NOT use Firebase, keep data local
- methods that return a widget should be prefixed with `_build` and placed above the `build()` method
- `build()` methods stay at the bottom of the class
- Before calling work complete: `flutter analyze` zero issues, `flutter test` green, `flutter build apk --debug` succeeds.
- Release work also requires `flutter build web --release` and a manual smoke test in Chrome on macOS.

---

## Plan Reading Protocol

Applies to this plan and every future plan in `plans/`.

1. Read this file, the plan header, the Active task block, and the plan map.
2. Open the first phase whose gate is not `✅ DONE`.
3. Continue the first `🔄 WIP` task. If none is active, start the first `⬜ TODO` task.
4. Mark the task `🔄 WIP` before editing code. Update the Active task block before stopping.
5. Read only the current phase, the current task row, and the definitions named by that task. Do not load a long plan in full.
6. Use `rg` or `find` to jump to named sections. Short file names are acceptable pointers.
7. At phase gate time, read the full phase, the gate commands, and the required QA scenarios.
8. Never execute a plan from `plans/` unless the user explicitly requests it.

### Plan status

- `⬜ TODO` - not started.
- `🔄 WIP` - in progress.
- `✅ DONE` - acceptance demonstrated and evidence recorded.

---

## File Structure Conventions

### Naming Conventions
- **Files**: `snake_case.dart` (e.g., `workout_session.dart`)
- **Classes**: `PascalCase` (e.g., `FitnessTracker`)
- **Functions/Variables**: `camelCase` (e.g., `calculateSomething()`)
- **Constants**: `kPascalCase` (e.g., `kDefaultValue`)
- **Private members**: Leading underscore (e.g., `_internalValue`)

### Import Organization
```dart
// Dart imports
import 'dart:async';
import 'dart:convert';

// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:provider/provider.dart';

// Relative imports
import '../models/user_profile.dart';
import '../services/storage_service.dart';
```

---

## Running the App

```bash
flutter pub get
flutter run
```

Web smoke test:

```bash
flutter run -d chrome
```

---

## Plans & Changelog

- `CHANGELOG.md` is the changelog: one compact line per completed item, `YYYY.MM.DD TASK-ID Description`, appended at the bottom.
- Record completed work only. Do not add planning, unstarted, or partial work.
- Shipped entries are append-only; fix typos only, never rewrite history.
- Open work lives in `plans/`, never in `CHANGELOG.md`.
- `plans/` holds one file per plan, named `YYYY.MM.DD.<slug>.md`.
- `plans/YYYY.MM.DD.<slug>.md` is the only plan source. Do not keep a secondary plan copy.
- A plan is done when its completed work is recorded in `CHANGELOG.md`.
- NEVER execute plans from `plans/` directly - only the user can ask for them.

---

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── app_coordinator.dart
├── common/
├── models/
├── navigation/
├── providers/
├── screens/
├── services/
├── theme/
└── widgets/
assets/
├── data/
├── fonts/
├── icons/
├── images/
├── legal/
└── svgs/
store/
tool/
test/
```
