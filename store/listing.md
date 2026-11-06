# Mova store listing draft

Draft copy for Google Play and the App Store. Replace bracketed placeholders before submission.

## Identity

- App name: Mova
- Subtitle: Train, log, progress
- Category: Health and Fitness
- Content rating: Everyone
- Price: Free
- In-app purchases: None
- Ads: None
- Account required: No
- Network required: No

## Short description, 80 characters

Local-first strength training, workout logging, steps, and progress.

## Full description

Mova is a focused strength training app that keeps your data on your device.

Pick a plan that matches your schedule, open Today to see the next session, and log every set with previous values in view. Mova calculates volume, tracks personal records, and shows a strength score, weekly volume, streak, and lifetime totals as you train.

Features:

- Plans for 2 to 6 training days with build muscle, get stronger, lose weight, and stay healthy goals.
- A 60 plus exercise library with search, muscle filters, and equipment filters.
- Live workout logging with warm-up sets, rest timers, pause and resume, and crash-safe recovery.
- Workout history, personal records, streak, strength score, and weekly volume.
- Daily steps with manual entry or optional Apple Health and Health Connect read access.
- Local workout reminders on the days and time you choose.
- A local Social tab with sample posts, your own workout posts, and kudos.
- Weight, distance, and height units that switch across the whole app.
- Full export-free privacy: no account, no cloud sync, no analytics, no ads.

Mova is not medical advice. Train within your limits and consult a professional when needed.

## Keywords

strength training, workout log, gym tracker, fitness plan, progressive overload, personal records, steps

## Screenshot plan

Capture on a 6.1 inch phone in portrait with realistic sample data.

1. Today with a planned session, streak, and steps card.
2. Live logger with previous values, completed sets, and rest timer.
3. Summary with duration, volume, sets, and a new PR.
4. Progress with strength score, weekly volume bars, and the PR wall.
5. Train with search and muscle filters.
6. Me with profile stats and Settings entry.
7. Settings with units, reminders, health, privacy, and reset.

Optional tablet and web captures: Today, Progress, and Train at a wide layout.

## Support and legal URLs

- Support URL: [replace with public support page]
- Privacy policy URL: [replace with public privacy page]
- Terms URL: [replace with public terms page]
- Marketing URL: [replace with public landing page]

The in-app copies live in `assets/legal/privacy.md`, `assets/legal/terms.md`, and `assets/legal/help.md`. Keep the public copies in sync with the app.

## Contact

- Support email: [replace with support email]
- Developer name: [replace with developer or studio name]

## Google Play data safety

Answer the questionnaire from the shipped behavior:

- Does your app collect or share any of the required user data types? No.
- Is all user data encrypted in transit? Not applicable, because no data leaves the device.
- Does your app provide a way for users to request data deletion? Yes, Settings has Reset local data. There is no server copy.
- Data types accessed on device: health and fitness, specifically step count, only with permission.
- Data types stored on device: profile details, fitness activity, workout history, and app preferences.
- Data shared with third parties: None.
- Analytics: None.
- Advertising or tracking: None.
- Account creation: None.

Declare the health permission in the Play Console health apps declaration:

- Data type: Steps.
- Purpose: Show the user their daily step count inside the app.
- Access: Read only.
- Transfer: Data stays on the device and is not transmitted.

## Apple App Privacy

- Data linked to the user: None collected by the developer.
- Data not linked to the user: None collected by the developer.
- Tracking: No.
- Health and fitness: Step count is read on device with permission and is not transmitted to the developer.
- Diagnostics: None collected by the developer.
- Purchases: None.
- Advertising: None.

App Review notes:

- No account is required.
- Health access is optional and read only for step count.
- Reset local data is in Me, then Settings, then Data.
- The Social tab is a local sample experience and does not use a network.

## Open-source licenses

The app includes Flutter and Dart packages under their respective licenses. Bundled fonts use the SIL Open Font License 1.1:

- Barlow Condensed, Copyright 2017 The Barlow Project Authors.
- Inter, Copyright 2016 The Inter Project Authors.

The full texts ship in `assets/legal/OFL-BarlowCondensed.txt` and `assets/legal/OFL-Inter.txt`, and the app lists package licenses from Settings under Open-source licenses.

## Release notes, first version

Mova 1.0.0

- Local-first training plans, workout logging, and progress tracking.
- Personal records, strength score, streak, and weekly volume.
- Daily steps with manual entry or optional device health access.
- Local workout reminders.
- Social tab with sample posts and your own workout posts.
- Units, profile edit, privacy controls, and reset local data.
