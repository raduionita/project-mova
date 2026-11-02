# AGENTS.md - Mova Flutter Mobile Fitness App

This document provides context, guidelines, and project structure information to help AI assistants understand and contribute effectively to this Dart + Flutter fitness app

---

## Project Overview

**Project Name**: Mova
**Language**: English
**Description**: Mova is a mobile fitness up build with Flutter/Dart
**Platform**: Mobile-first (iOS, Android, Web via Flutter)

---

## Technology Stack
**Flutter** - Cross-platform mobile UI framework
**Dart** - Programming language for Flutter
**Provider** - State management
**Authentication** - Google and Apple Sign-In, (NO Firebase)

---

## Rules

- Do NOT use em dash (—), ONLY hyphens (-)
- NEVER `git commit`, `git add` or `git push`
- Do NOT bundle multiple models, provides, widgets, screens, components into a single file, each in its own file.
- `shared_preferences` and `provider` for storage and state management
- D0 NOT Firebase, keep data local
- methods that return a widget should be prefixed with `_build` and placed above the `build()` method
- `build()` methods stay at the bottom of the class
- Before calling work complete: `flutter analyze` zero issues, `flutter test` green, `flutter build apk --debug` succeeds.


---

## File Structure Conventions

### Naming Conventions
- **Files**: `snake_case.dart` (e.g., `fitness_tracker.dart`)
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
import '../models/nutrition_tracker.dart';
import '../services/custom_service.dart';
```

---

## Running the App

```bash
flutter pub get
flutter run
```

---


---

## Plans & Changelog

- `CHANGELOG.md` is the changelog: one entry per shipped update, `## Update N - YYYY.MM.DD - Title`, appended at the bottom, oldest first.
- Shipped entries are append-only; fix typos only, never rewrite history.
- Open work never lives in `CHANGES.md`; it lives in `plans/`.
- `plans/` holds one file per plan, named `YYYY.MM.DD.<slug>.md`.
- A plan is only done when the matching update entry is added to `CHANGELOG.md` with its gate results.
- NEVER execute plans from this (`plans/`) folder directly - only the user can ask for them.

---

## Project Structure

```
lib/
├── main.dart
├── common/
├── models/
├── navigation/
├── providers/
├── screens/
├── services/
├── theme/
└── widgets/
assets/
├── icons/
├── images/
├── legal/
└── svgs/
test/
```
