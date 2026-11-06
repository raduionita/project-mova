# Changelog

<!-- Format: YYYY.MM.DD TASK-ID Description. Completed work only. Append at the bottom. -->
2026.11.05 FND-01 Add Phase 1 dependencies and bundle Barlow Condensed and Inter fonts
2026.11.05 FND-02 Add design tokens, dark theme, and nine base widgets with tests
2026.11.05 FND-03 Add immutable models and JSON round-trip tests
2026.11.05 FND-04 Add local storage service with corrupt and future-schema handling
2026.11.05 FND-05 Add an 82-exercise seed library with loader tests
2026.11.05 FND-06 Add deterministic plan generator with split, goal, and fallback tests
2026.11.05 FND-07 Add unit conversion, ID, clock, formatter, date key, and result helpers
2026.11.05 FND-08 Add ten providers, AppCoordinator, and provider wiring with tests
2026.11.05 FND-09 Add phase-aware tab registry, app shell, and bottom navigation bar
2026.11.05 FND-12 Add onboarding flow order, step progress, and shared onboarding scaffold
2026.11.05 FND-11 Add welcome screen with new-user and saved-draft entry points
2026.11.05 FND-13 Add segmented control, choice card, wheel picker, ruler slider, and multi-select widgets
2026.11.05 FND-14 Add unit selection screen with persisted weight, distance, and body units
2026.11.05 FND-15 Add gender selection screen with required choice cards
2026.11.05 FND-16 Add birth date screen with wheels, age limits, and leap-year clamping
2026.11.05 FND-17 Add weight screen with unit-aware ruler and zeroing skip
2026.11.05 FND-18 Add height screen with vertical roller and unit-aware display
2026.11.05 FND-19 Add goals screen with ordered multi-select and primary goal
2026.11.05 FND-20 Add experience screen with four single-select levels
2026.11.05 FND-21 Add schedule screen with day count and weekday validation
2026.11.05 FND-22 Add notifications step with persisted reminder choice and fallback paths
2026.11.05 FND-23 Add plan preview with generated week, schedule editing, and coordinator confirm
2026.11.05 FND-24 Add read-only Today screen with planned, rest, and no-plan states
2026.11.05 FND-10 Add splash and startup gate with active, paused, draft, and profile routing
2026.11.05 FND-25 Add end-to-end onboarding flow and draft resume tests
2026.11.05 FND-26 Replace stock counter app and test with the Mova entry point
2026.11.05 FND-27 Add local verification script for format, analyze, tests, and build
2026.11.05 FND-28 Add storage schema migration harness
2026.11.06 TRN-01 Add Train exercise library with row details and active-session add
2026.11.06 TRN-02 Add Train search and combinable muscle filters
2026.11.06 TRN-03 Add exercise details with tags, instructions, and previous best
2026.11.06 TRN-04 Add routine list and detail with delete confirmation
2026.11.06 TRN-21 Add shared exercise picker with browse, session, and routine actions
2026.11.06 TRN-05 Add routine builder with picker add, reorder, set and rep editing, save, and discard guard
2026.11.06 TRN-06 Add session creation from plan, routine, empty, and walk with ordered exercises
2026.11.06 TRN-07 Add live logger set table with previous values, editing, completion, warm-ups, and add/remove sets
2026.11.06 TRN-08 Add shared numeric input sheet with validation and kg/lb weight handling
2026.11.06 TRN-09 Add rest countdown banner with skip, auto start, and timestamp recovery
2026.11.06 TRN-10 Verify active session recovery with exact logged state
2026.11.06 TRN-11 Add workout interruption sheet with pause and confirmed discard
2026.11.06 TRN-12 Add workout calculator for volume, completed sets, duration, and estimated 1RM
2026.11.06 TRN-13 Add post-workout summary with time, volume, sets, and PR card
2026.11.06 TRN-14 Add personal record detection with previous-best tracking
2026.11.06 TRN-15 Persist finished workouts with PRs and clear the active session
2026.11.06 TRN-16 Verify the core workout loop with widget and unit tests
2026.11.06 TRN-17 Add session keep-awake, resume clock refresh, and midnight rollover
2026.11.06 TRN-18 Add set, rest, and PR haptics with reduced-motion support
2026.11.06 TRN-19 Cover navigation guards for active sessions and unsaved edits
2026.11.06 TRN-20 Wire Today start, quick action, and resume states
2026.11.06 PRG-01 Add month-grouped workout history with empty state
2026.11.06 PRG-02 Add workout history detail with exercises, sets, notes, and date
2026.11.06 PRG-03 Add workout deletion with confirmation and PR, streak, and score recomputation
2026.11.06 PRG-04 Add Progress dashboard with lifetime totals, PR wall, history shortcut, and empty state
2026.11.06 PRG-05 Add seven-day volume bars with dim empty days and text summary
2026.11.06 PRG-06 Add streak and PR aggregation across gaps, today, and yesterday
2026.11.06 PRG-07 Add beta strength score with thresholds, explanation sheet, and no ranking
2026.11.06 PRG-08 Add plan overview sheet with day moves and history-preserving regeneration
2026.11.06 PRG-09 Add progress aggregation, deletion, score, and screen tests
2026.11.06 PRG-10 Add body weight sheet from the score CTA with score refresh
2026.11.06 SOC-01 Add Social feed with sample and own post cards
2026.11.06 SOC-02 Seed three labeled sample posts with persistent dismissal
2026.11.06 SOC-03 Add persistent local kudos toggle
2026.11.06 SOC-04 Publish one own post per completed workout and remove it on delete
2026.11.06 SOC-05 Add 1080x1920 share card renderer
2026.11.06 SOC-06 Add share card sheet and share entry points
2026.11.06 SOC-07 Hide own posts when workout sharing is off
2026.11.06 SOC-08 Add Social feed, kudos, own post, and share card tests
2026.11.06 SET-01 Add Me profile screen with identity, lifetime totals, and settings entry points
2026.11.06 SET-02 Add full-screen profile edit for name, experience, goals, body, and birth date
2026.11.06 SET-03 Add weight, distance, and body unit preferences with display conversion
2026.11.06 SET-04 Add local workout reminder scheduling, cancellation, and settings rescheduling
2026.11.06 SET-05 Add fail-soft Apple Health and Health Connect step service
2026.11.06 SET-06 Add manual steps fallback with source labeling
2026.11.06 SET-07 Add health integration settings for connected, disconnected, and unavailable states
2026.11.06 SET-08 Add privacy settings and reset local data confirmation
2026.11.06 SET-09 Add point-of-use notification and health permission guidance
2026.11.06 SET-10 Audit empty states across lists, charts, and sheets
2026.11.06 SET-11 Audit accessibility labels, touch targets, and 1.3x text scale
2026.11.06 SET-12 Add Mova app icon, splash, and web branding
2026.11.06 SET-13 Add Android release SDK, permissions, desugaring, queries, backup, and signing config
2026.11.06 SET-14 Add iOS health strings, entitlement, portrait lock, and notification delegate
2026.11.06 SET-15 Add legal documents, store listing draft, and font licenses
2026.11.06 SET-16 Add Phase 5 screen, service, provider, and reset test coverage gate
2026.11.06 SET-17 Pass format, analyze, tests, coverage, debug and release APK, and web release gates
2026.11.06 SET-18 Disable Android backup and document local privacy and iOS backup behavior
2026.11.06 SET-19 Add legal document and open-source licenses screens
2026.11.06 QA-01 Run acceptance scenarios A through P on web, automated suites, and Android emulator
2026.11.06 QA-01 Seed social sample posts during startup before any own workout post
2026.11.06 QA-02 Verify phone, tablet, landscape, and web layouts and center wide content at 720 dp
2026.11.06 QA-03 Pass Lighthouse accessibility, merged settings switch labels, and 1.3x text audit
2026.11.06 QA-04 Verify warm startup at 157 ms LCP and logger scroll above 60 fps
2026.11.06 QA-05 Add dismissible storage warning and verify corrupt payload, reset, and clock integrity
2026.11.06 QA-06 Build 1.0.0+1 debug and release APK and web release with checksums
2026.11.06 QA-07 Smoke test notifications, health guidance, share, and wakelock on Android emulator
2026.11.06 QA-08 Verify streak, Today, and volume rollover under two DST time zones
