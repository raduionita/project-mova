
## MVP user story

As a new or returning fitness user, I want to set my goal, see a recommended workout, complete the workout with clear guidance, log my effort, and see my progress so I feel motivated to continue.

My main recommendation is to build the MVP around one core user journey:

Set a goal → Get a training plan → Complete a workout → Track progress → Come back and improve.

Everything that supports this loop belongs in the MVP. Features that primarily create social engagement, competition, or visual polish can come later.

## Must-have screens & features for MVP
Focus on the core loop that makes a fitness/gym app sticky: onboarding → plan → log workout → see progress → return. Everything else can wait.

## Core (must ship):

- Onboarding / personalization (screens 01–03): Splash, “Who are you?” persona, goal + training days. This is what makes “Today” feel personal from day 1.
- Today / Home (04): One clear next action (planned workout), streak, synced steps. The daily hook.
- Live workout logger (05): Previous values, set logging, rest timer, “up next.” This is the gymrat retention engine — make it fast and immersive.
- Workout summary + PR detection (06): Auto PR call-out + shareable card. Instant dopamine and social proof.
- Progress (07): Strength Score / ranking + key lifts (PRs). Reason to come back and compare.
- Train / Exercise library + routines (08): Searchable exercises + saved routines so users can start an empty workout or follow the plan.
- Me / Profile + basic settings (10): Identity, lifetime stats, units, Health sync, reminders. Completes the 5-tab nav and handles essentials.

## Strongly recommended for MVP (still lightweight):

- Social feed with kudos only (09): Strava-style “kudos” without comments. Low-noise motivation and share target for PR cards. Can be friends-only or soft-launch later if you need to cut scope.
- Health/steps sync, basic notifications/reminders, and share cards (already implied).

## Screen tree
```
App Launch
│
├── 01 Splash (cold start / brand + Health sync warm-up)
│   └── (first launch only)
│
├── Onboarding (first-launch path)
│   ├── 02 Who are you? (persona: Just starting / Gym / Gymrat / Elite)
│   └── 03 Goal & schedule (goal + days/week + training days → builds Week 1 plan)
│
└── Main App (5-tab bottom navigation after onboarding)
    │
    ├── 🏠 Today (04)
    │   ├── Planned workout card → Start workout
    │   ├── Streak + steps
    │   └── Quick actions: ＋ Empty workout | 🚶 Walk | 📋 Routine
    │       │
    │       └── Live Logger (05)  [immersive, tab bar hidden]
    │           ├── Set logging (prev values, kg × reps)
    │           ├── Rest timer
    │           ├── Up next exercise
    │           └── Finish workout
    │               └── 06 Summary + PR
    │                   ├── Stats (time, volume, sets)
    │                   ├── Auto PR detection + share card
    │                   └── Save / Share → back to Today or Progress
    │
    ├── 🏋️ Train (08)
    │   ├── Exercise library (search + filters: All / Chest / Legs / …)
    │   ├── ＋ Add to workout
    │   └── My routines (Push / Pull / Legs …) → start or edit
    │       └── Can feed into Live Logger (empty or routine-based)
    │
    ├── 📈 Progress (07)
    │   ├── Strength Score + ranking (“Top X% at your gym”)
    │   ├── Weekly volume
    │   └── Top lifts / PRs (Squat, Deadlift, Bench…)
    │
    ├── 💬 Social (09)
    │   └── Feed of friends’ activities
    │       └── Kudos only (no comments)
    │           └── PR share cards land here
    │
    └── 👤 Me (10)
        ├── Profile (persona, stats: workouts / streak / PRs)
        └── Settings
            ├── Units
            ├── Apple Health sync
            ├── Workout reminders
            └── Privacy & social (Friends)
```


## 1. What should be in the MVP?
I'd divide your existing screens into three priorities.

### P0 — Essential for launch

Must have
These features make Mova a usable fitness tracking product.
- Onboarding and fitness profile
- Goal selection and training schedule
- Personalized workout plan
- Today dashboard
- Exercise library and search
- Saved routines
- Live workout logger
- Set, reps, and weight tracking
- Rest timer
- Workout completion summary
- Personal records (PRs)
- Basic progress and workout history
- Profile and essential settings
  
### P1 — Valuable additions
Next priority
  
These improve retention and make the app more compelling.
- Advanced progress charts
- Strength score
- Weekly training volume
- Workout streaks
- PR share cards
- Workout reminders
- Apple Health / Health Connect integration
- Exercise history and previous performance
  
### P2 — Post-MVP
Later  
These are interesting but aren't necessary to validate the core product.
- Social feed
- Friends and following
- Kudos / likes
- Gym rankings and leaderboards
- Ranking against other users
- Advanced social privacy controls
- Competitive strength scores


## 2. Review of your existing mockup screens

### Here's how I'd treat each of the 10 screens.
Mockup screen	MVP decision	Reason
01. Splash	Keep	App entry point
02. Who are you?	Keep	Personalization
03. Goal & schedule	Keep	Generates training plan
04. Today	Keep	Main dashboard
05. Live logger	Keep	Core product experience
06. Summary + PR	Keep	Reinforces progress
07. Progress	Simplify	Start with basic stats
08. Train / Library	Keep	Exercises and routines
09. Social feed	Defer	Not essential to workout tracking
10. Me / Profile	Keep	Account and settings

The existing mockup has a good separation between the main training experience and secondary features. 
MVP Flow · Linear Storyboard

### Important screens missing from the mockup
I'd add these before development starts:
1. Sign up / Login — Account creation, authentication and password recovery.
2. Plan overview / Edit plan — Let users review and change their weekly schedule.
3. Exercise details — Instructions, muscle groups, equipment and previous performance.
4. Workout history — List of completed workouts, with individual workout details.
5. Workout interruption — Pause, resume, discard or exit a workout safely.
6. Empty states — What happens when users have no workouts, routines or progress?
7. Permissions and integrations — Health data and notification permissions, requested at the appropriate moment.
These are important because the current mockup illustrates the happy path, but not all the situations users encounter in a real app.

