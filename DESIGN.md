# MOVA: Mobile Design System & UI/UX Specification

**Document Version:** 1.0.0
**Product Name:** Mova - Fitness tracker
**Tagline:** Move. Log. Progress.
**Target Platforms:** iOS, Android, web (Flutter)
**Primary Aesthetic:** Dark athletic minimalism
**Reference Mockup:** `MOCK.html`
**Implementation Stack:** Flutter, Provider, shared_preferences
**Data Model:** Local-first, no backend, no Firebase

---

## 1. Brand

### 1.1 Product positioning

Mova is a personal training companion for people who want to know what to do next and whether they are improving. It is not a social network with a workout feature attached. The product earns its place by making the workout logger exceptionally fast, then by showing honest progress from the data the user logs.

### 1.2 Brand attributes

| Attribute | Expression in the UI |
|---|---|
| Direct | One primary action per screen, short labels, no marketing copy inside the app |
| Athletic | Condensed uppercase display type, high-contrast lime accent, dense data blocks |
| Calm | Dark surfaces, muted secondary text, no gradients competing for attention |
| Honest | Clear units, transparent calculations, no fake rankings or invented social proof |
| Personal | Onboarding shapes the plan, the Today screen speaks to the user's own schedule |
| Private | Local-first storage, clear permission prompts, no account required in v1 |

### 1.3 Brand voice

- Short, imperative, and specific: "Start workout", "Finish workout", "Log set".
- Sentence case for body copy. Uppercase only for display headings and micro labels.
- Never shame the user for missed workouts. Use neutral empty states.
- No em dashes. Use hyphens only.
- Units always follow the number with a thin space: `82.5 kg`, `8 reps`, `55 min`.
- Percentages and rankings are only shown when they are real. Otherwise omit them.

### 1.4 Logo and wordmark

- The brand mark is a rounded square with the letter `M`, lime gradient `#B7F24C` to `#7FC93A`, dark ink `#131A04`.
- Wordmark is lowercase `mova`, display font, weight 800, letter spacing 1.0.
- Minimum mark size: 24x24. Minimum wordmark size: 20 px height.
- Clear space around the mark is at least half the mark width.
- Do not place the mark on lime. Do not outline it. Do not rotate it.

---

## 2. Design principles

1. **One next action.** Every screen has a single primary action. Secondary actions are ghost buttons, chips, or overflow.
2. **Logger first.** The live workout experience gets the largest touch targets, the fewest taps, and the least navigation chrome.
3. **Data with context.** Any number shown must have a label, a unit, and a comparison where useful. No orphan metrics.
4. **Thumb-first.** Primary actions sit in the lower third. Destructive actions require confirmation.
5. **Progressive disclosure.** Show the next set, not the entire workout. Show summary metrics, not every set, until the user asks.
6. **Offline by default.** Every screen must render from local storage. Loading states exist only for cold start and optional integrations.
7. **Honest emptiness.** Empty states explain what will appear and offer the action that creates the first item.

---

## 3. Color

### 3.1 Core palette

Values are taken from `MOCK.html`.

| Token | Hex | Role | Typical use |
|---|---|---|---|
| `background` | `#0B0F16` | App background | Scaffold, splash, deep background |
| `panel` | `#101623` | Raised panel | Bottom nav, sheets, footers |
| `card` | `#171F2E` | Card surface | Cards, inputs, list rows, set rows |
| `line` | `#232D40` | Border and divider | Card borders, nav top border, disabled outline |
| `text` | `#E9EEF6` | Primary text | Titles, values, body |
| `muted` | `#8D97AB` | Secondary text | Labels, descriptions, inactive tabs |
| `lime` | `#B7F24C` | Primary accent | Primary buttons, active state, success, PR highlight |
| `limeInk` | `#131A04` | Ink on lime | Text and icons on lime surfaces |
| `orange` | `#FF8A4C` | Warning and destructive | Discard, delete, permission warning |
| `gold` | `#FFD166` | Achievement | PR badge, personal records |
| `blue` | `#5EA2FF` | Rest and info | Rest timer, informational links |
| `surfaceAlt` | `#20293C` | Control surface | Stepper buttons, tags, icon buttons |

### 3.2 Derived surfaces

| Token | Value | Use |
|---|---|---|
| `backgroundElevated` | `#131B2B` | Screen gradient top |
| `cardElevated` | `#1C2740` | Featured workout card |
| `limeSoft` | `rgba(183, 242, 76, 0.15)` | Selected chips, lime tags, completed state |
| `goldSoft` | `rgba(255, 209, 102, 0.12)` | PR badge background |
| `blueSoft` | `#13223D` | Rest timer background |
| `scrim` | `rgba(5, 7, 12, 0.72)` | Modal scrim |

### 3.3 Semantic color

| Semantic | Token | Notes |
|---|---|---|
| `actionPrimary` | `lime` | One per screen |
| `actionOnPrimary` | `limeInk` | Always pair with lime |
| `actionSecondary` | `text` on transparent with `line` border | Ghost buttons |
| `actionDestructive` | `orange` | Discard, delete, leave |
| `statusSuccess` | `lime` | Completed set, saved workout |
| `statusWarning` | `orange` | Unsaved changes, permission denied |
| `statusInfo` | `blue` | Rest timer, tips |
| `achievement` | `gold` | PR only |
| `textDisabled` | `#5D6880` | Disabled labels and placeholders |
| `tabInactive` | `#66718A` | Inactive bottom navigation |

### 3.4 Color rules

- Do not use lime for large backgrounds except the logo, the share card, and the primary button.
- Do not use gold outside PR and personal-record contexts.
- Do not use blue as a primary action color. Blue means rest or information.
- Status must never rely on color alone. Pair color with an icon or a text label.
- Borders carry structure. Shadows are reserved for overlays and the phone-frame marketing mock, not for in-app cards.
- Minimum text contrast is 4.5:1 for body and 3:1 for text at 24 px or larger. `muted` on `background` passes.
- Avoid pure black and pure white. The darkest surface is `#0B0F16`; the lightest text is `#E9EEF6`.

---

## 4. Typography

### 4.1 Type families

| Role | Family | Fallback | Notes |
|---|---|---|---|
| Display | Barlow Condensed | Oswald, Arial Narrow, system condensed | Uppercase headings, metrics, PR numerals |
| Body | Inter | SF Pro, Segoe UI, Roboto, system sans | Body copy, labels, inputs, navigation |
| Numeric | Inter with tabular figures | System tabular | Timers, weights, reps, volume |

Both families are open source. Bundle them in `assets/fonts/` for a consistent render across platforms. If assets are not available, the system fallback stack must preserve weight and letter spacing.

The HTML mockup uses a system sans at small sizes. Those values describe a 292 px-wide storyboard frame. The Flutter scale below is the authoritative mobile scale.

### 4.2 Type scale

| Token | Size / line height | Weight | Letter spacing | Case | Use |
|---|---|---|---|---|---|
| `displayXL` | 34 / 36 | 700 | 0.2 | Upper | Splash wordmark, PR value |
| `display` | 30 / 32 | 700 | 0.4 | Upper | Large metric, share card |
| `h1` | 24 / 28 | 800 | 0 | Sentence | Screen title, logger exercise name |
| `h2` | 19 / 24 | 800 | 0.1 | Sentence | Section title, card headline |
| `title` | 16 / 22 | 700 | 0 | Sentence | List item title, plan name |
| `body` | 14 / 20 | 400 | 0 | Sentence | Descriptions, instructions |
| `bodyStrong` | 14 / 20 | 600 | 0 | Sentence | Emphasis inside body |
| `label` | 12 / 16 | 600 | 0.1 | Sentence | Buttons, chips, field labels |
| `caption` | 11 / 15 | 500 | 0.1 | Sentence | Metadata, helper text |
| `micro` | 9.5 / 12 | 700 | 0.8 | Upper | Table headers, tag text, nav labels |
| `timer` | 32 / 34 | 700 | 1.0 | Tabular | Rest timer, workout elapsed |
| `metric` | 26 / 28 | 700 | 0.2 | Tabular | Strength score, volume, hero value |

### 4.3 Typography rules

- Uppercase is reserved for display, micro labels, and the wordmark. Never uppercase a sentence of body copy.
- Use `FontFeature.tabularFigures()` for every changing number: timers, weights, reps, steps, volume.
- Do not use more than three type sizes in a single card.
- Maximum line length for body copy is 64 characters.
- Support dynamic text up to 1.3x. Prefer wrapping and flexible heights over fixed-height text containers.
- Numeric input fields use tabular figures and right-aligned values.

---

## 5. Spacing, grid, and layout

### 5.1 Spacing scale

| Token | Value | Use |
|---|---|---|
| `xxs` | 2 | Icon-to-label micro gap |
| `xs` | 4 | Tight pairs, tag padding vertical |
| `sm` | 6 | Chip gaps, list row internal gaps |
| `md` | 8 | Component internal padding, chip rows |
| `lg` | 10 | Card stack gap, set row gap |
| `xl` | 12 | Card padding, button padding |
| `2xl` | 16 | Screen horizontal padding, section gap |
| `3xl` | 20 | Screen title to content |
| `4xl` | 24 | Section separation |
| `5xl` | 32 | Major block separation |
| `6xl` | 40 | Splash and empty-state spacing |

### 5.2 Layout rules

- Base grid is 4 pt. All spacing and sizing values are multiples of 4, except the 6 pt chip gap and 10 pt card gap inherited from the mock.
- Screen horizontal padding is 16. Content width is the full width minus 32.
- Primary content sits above the safe area and above the bottom navigation.
- Bottom navigation height is 56 plus the bottom safe area.
- Minimum touch target is 44x44. Visual controls may be smaller if the hit area is expanded.
- Logger rows are at least 52 high. Primary logger actions are at least 56 high.
- On tablets and web, cap content at 560 px wide and center it. Do not stretch cards across the viewport.
- Lists use 10 px gaps between cards, not dividers.
- Never place two primary buttons on the same screen.

### 5.3 Safe areas

- Respect top status bar and bottom home indicator on iOS.
- Respect gesture navigation insets on Android.
- The logger must account for the keyboard when editing weight or reps.
- Modal sheets sit above the keyboard, not behind it.

---

## 6. Shape, borders, and elevation

### 6.1 Radii

| Token | Value | Use |
|---|---|---|
| `xs` | 6 | Micro tags, tiny badges |
| `sm` | 8 | Stepper buttons, small icon buttons |
| `md` | 11 | Inputs, set rows, search fields |
| `lg` | 13 | Stat tiles, choice rows |
| `xl` | 14 | Cards |
| `2xl` | 16 | Featured cards, PR cards, sheets on compact screens |
| `3xl` | 20 | Bottom sheets, dialogs |
| `pill` | 999 | Tags, chips, buttons where specified |

### 6.2 Borders

- Default card border: 1 px `line`.
- Active card border: 1 px `lime` at 45 percent opacity.
- Focused input border: 1.5 px `lime`.
- Error border: 1.5 px `orange`.
- Dividers: 1 px `line` at 60 percent opacity, used sparingly.
- Do not use a border and a drop shadow on the same card.

### 6.3 Elevation

| Level | Treatment | Use |
|---|---|---|
| 0 | Background | Scaffold |
| 1 | `card` plus 1 px border | Standard cards |
| 2 | `cardElevated` plus 1 px `line` | Featured workout, PR card |
| 3 | Shadow `0 12 32 rgba(0,0,0,0.35)` | Bottom sheets, dialogs |
| 4 | Shadow `0 20 48 rgba(183,242,76,0.18)` | PR celebration only |

---

## 7. Iconography, avatars, and imagery

### 7.1 Icons

- Icons are SVG files in `assets/icons/`, one icon per file, registered in `pubspec.yaml`.
- Every icon uses a 24x24 viewBox, no fill, a white 1.7 stroke, and round caps and joins. The runtime `AppIcon` widget tints them with `ColorFilter.srcMode` so one file serves every color.
- Default size is 22 for navigation, 20 inside cards, 18 for inline metadata.
- Default color is `muted`. Active navigation and confirmed actions use `lime`.
- The Today tab uses the activity glyph; Calendar uses the calendar glyph, and Progress, Social, and Me use the mock set.
- Icons must have a semantic label unless they are decorative and accompanied by text.
- Reference paths and asset names live in `AppIcons`.

### 7.2 Emoji

- Emoji are allowed inside seeded social content.
- Onboarding goal cards use SVG icons, not emoji.
- Do not use emoji as navigation icons, button labels, or data labels.
- Do not use emoji in the PR share card.

### 7.3 Avatars

- Circular, 34 px in feed rows, 52 px on the profile header, 64 px on the Me profile card.
- Default avatar shows the first initial in `limeInk` on a solid pastel background.
- The Me avatar uses a `lime` background with the icon picked on the onboarding experience step in `limeInk`: seedling, dumbbell, flame, or trophy. Without a saved level it falls back to the person glyph.
- No image upload in v1. Initials only elsewhere.

### 7.4 Imagery

- No stock photography in the MVP.
- Exercise demonstrations are text instructions plus muscle and equipment metadata.
- Empty states use a large icon or a simple geometric illustration, never a photo.
- The share card is the only exported visual.

---

## 8. Component library

Each component lives in its own file under `lib/widgets/`. No component file may contain more than one public widget.

### 8.1 Buttons

**Primary**
- Height 48, radius 12, background `lime`, label `limeInk`, `label` type at weight 800.
- Full width inside cards and screen footers.
- Pressed: opacity 0.9 and scale 0.98 for 120 ms.
- Disabled: `lime` at 30 percent opacity, label `limeInk` at 50 percent.
- Loading: 18 px spinner in `limeInk`, label hidden, width fixed to prevent layout jump.

**Ghost**
- Height 48, radius 12, transparent background, 1 px `line` border, `text` label.
- Used for the secondary action in a pair, such as Save under Share card.

**Destructive**
- Height 48, radius 12, transparent background, 1 px `orange` border at 50 percent, `orange` label.
- Requires a confirmation dialog or sheet.

**Icon button**
- Minimum 44x44 hit area, visual 36x36, radius 10, background `surfaceAlt`.
- Used for back, close, overflow, add, and stepper controls.

### 8.2 Cards

- Background `card`, 1 px `line` border, radius 14, padding 14.
- Title row uses `h2` or `title`, optional trailing tag.
- Body uses `caption` or `body` in `muted`.
- Cards are not tappable unless they show a chevron or a clear affordance.
- Featured card uses `cardElevated`, a 1 px border at `#2B3A58`, and radius 16.

### 8.3 Tags and chips

**Tag**
- Height 20, padding 3x8, radius `pill`, `micro` type.
- Variants: neutral (`surfaceAlt` background, `muted` text), lime (`limeSoft`, `lime`), gold (`goldSoft`, `gold`).
- Used for status: Planned, PR, synced, beta.

**Filter chip**
- Height 32, padding 6x12, radius `pill`, 1 px `line`, `label` type.
- Selected: `limeSoft` background, `lime` text, `lime` border at 45 percent.
- Chips scroll horizontally. Do not wrap into multiple rows.

### 8.4 Stat tile

- Background `card`, 1 px `line`, radius 13, padding 10x12.
- Value uses `metric` or `title`, weight 800.
- Label uses `micro` or `caption` in `muted`.
- Optional leading icon, 16 px, `muted`.
- Used in pairs and trios. Never more than three in a row on phones.

### 8.5 Stepper

- Row height 52, background `card`, 1 px `line`, radius 13, padding 11x14.
- Label on the left in `caption` `muted`.
- Minus and plus are 32x32, radius 8, background `surfaceAlt`, `text`, weight 800.
- Value is centered, `title` weight 800, tabular.
- Pressed state: background lightens to `#2A3548`.
- Long press repeats after 400 ms.

### 8.6 Day selector

- Seven equal cells in one row with 5 px gaps.
- Cell height 38, radius 9, background `#182134`, 1 px `line`.
- Selected: `limeSoft` background, `lime` text, `lime` border at 45 percent.
- Label is one letter, `micro`, weight 700.
- Disabled days use `textDisabled` and no border.

### 8.7 Inputs

- Height 44 for single line, minimum 88 for multiline.
- Background `card`, 1 px `line`, radius 11, padding 11x12.
- Placeholder `textDisabled`.
- Focus: `lime` border, no glow.
- Error: `orange` border plus helper text in `orange`.
- Numeric fields use tabular figures, a right-aligned value, and an in-app calculator keypad instead of the OS keyboard. The keypad has digits, a decimal when allowed, clear, backspace, add, subtract, multiply, divide, and equals.
- The sheet previews the calculated result while an expression is open. Done evaluates the expression, rejects fractions for whole-number fields, and enforces the field range.
- Hardware keyboards still type into the field.
- Weight and reps are edited inline in the logger, not in a separate screen.

### 8.8 Set row

- Grid: 28 px set number, flexible previous value, flexible current value with two boxed fields, 36 px check.
- Height 60, background `card`, 1 px `line`, radius 11, padding 8x10.
- Header row uses `micro` labels: SET, PREV, KG x REPS (centered over the fields), empty check column.
- Previous value is `caption` `#67748E` with strikethrough.
- Weight and reps sit in separate `surfaceAlt` boxes, 44 px tall, radius 8, 1 px `line`, weight box wider than the reps box. The whole box is the tap target.
- Current value is `bodyStrong` `text` once completed, `muted` while pending. The `x` between the boxes follows the same colour.
- Completed row: lime check, current value `text`, background stays `card`.
- Active row: `blue` border at 60 percent on the row and on both boxes.
- Pending row: current value shows `-` in `muted`.
- Tapping a box opens an inline numeric sheet with a calculator keypad and a Done action. The sheet selects the current value so the first key replaces it.
- Tapping the check completes the set, starts rest, and advances focus.
- Swiping the row left reveals an `orange` panel with a trash glyph and removes the set at once. The check stays the rightmost control and there is no close button. Removal is also exposed as a screen reader action.

### 8.9 Rest timer banner

- Background `blueSoft`, 1 px `#28406B`, radius 12, padding 10x12.
- Title `Rest · 1:24` in `bodyStrong`.
- Skip action in `blue`, `caption` weight 600.
- Progress bar height 4, radius 4, track `#1D3155`, fill `blue`.
- Counts down once per second without animation jitter.
- The logger header toggle turns the timer on or off. While off, completing a set does not start the banner.
- On completion, haptic plus a short sound if enabled, then the next set becomes active.

### 8.10 Progress ring

- Outer diameter 104, stroke 12, track `#223049`, fill `lime`.
- Inner diameter 80, background `#111827`.
- Value `metric`, label `micro` uppercase in `muted`.
- No animation on first paint. Animate from 0 to value over 500 ms on refresh.
- Always pair with a text value outside the ring for accessibility.

### 8.11 Volume bars

- Seven bars, equal width, 6 px gap, height up to 54.
- Fill gradient from `lime` to `#5D8A2C`, top radius 3.
- Days with no data use `#263044` at 30 percent height, not zero height.
- Day labels use `micro` in `muted`.
- Bars animate height on first paint over 400 ms, staggered by 30 ms.
- Provide a text summary above the chart: "9.4 t this week".

### 8.12 Bottom navigation

- Height 56 plus safe area, background `panel`, top border `line`.
- Five items: Today, Calendar, Progress, Social, Me.
- Icons are tinted SVGs from `assets/icons/`, 22 px. Today uses the activity glyph and Calendar uses the calendar glyph.
- Label `micro` at 10 px, gap 2.
- Active: `lime` icon and label. Inactive: `tabInactive`.
- No badges in v1 except an optional dot on Social for unseen seed content.
- Hidden entirely in the live logger and PR celebration routes.
- Tapping the active tab scrolls that tab to the top.

### 8.13 App bar

- Height 52, transparent over `background`, no shadow.
- Leading icon button for back or close.
- Title centered for modals, left-aligned for tabs.
- Trailing action is a single icon button, never a text button.
- Screen titles in tabs use `h1` inside the scroll content, not the app bar.

### 8.14 Sheets and dialogs

- Bottom sheet: radius 20 top corners, background `panel`, drag handle 36x4 in `line`, padding 20.
- Dialog: radius 20, background `card`, padding 20, max width 340.
- Actions stack vertically on phones, primary first.
- Destructive confirmation title states the consequence: "Discard this workout?"
- Sheets dismiss on scrim tap unless there are unsaved changes.

### 8.15 Snackbars

- Background `panel`, 1 px `line`, radius 12, padding 12x16.
- Text `body`, action in `lime`.
- Placed above the bottom navigation, never over the primary button.
- Duration 3 seconds for confirmations, 5 seconds when an undo action exists.

### 8.16 Empty state

- Centered block with a 56 px icon in `muted`, an `h2` title, a `body` explanation, and one ghost or primary action.
- Maximum width 280.
- No illustration library in v1.
- Examples: "No workouts yet", "No routines yet", "No PRs yet".

### 8.17 PR celebration

- Full-screen route with `background`, gold badge at top: "NEW PR".
- Exercise name in `h2`, estimated 1RM in `displayXL` with unit in `caption`.
- Delta chip in `goldSoft`: "+3.5 kg vs last session".
- Confetti is optional and disabled when reduced motion is on.
- Haptic medium impact once on entry.
- Primary action: Share card. Ghost action: Save and return to Today.

### 8.18 Share card

- 1080x1920 (9:16), lime gradient background `#B7F24C` to `#4D8A2A`, `limeInk` text.
- Content: Mova mark, exercise name, value plus unit, delta, date, "Move. Log. Progress."
- Rendered locally with a widget-to-image capture. No network.
- Exported through the native share sheet.
- Also offered as a 1:1 variant for feed posts in a later update.

---

## 9. Navigation

### 9.1 Structure

```text
Splash
  |
  +-- First launch --> Welcome --> Units --> Gender --> Birth date --> Weight
  |                     --> Height --> Goals --> Experience --> Schedule
  |                     --> Equipment --> Notifications --> Plan preview --> Main
  |
  +-- Returning user with profile --> Main
  +-- Paused session --> Main / Today with Resume
  +-- Active session --> Live logger

Main (5-tab shell)
  |-- Today
  |     |-- Live logger (full screen, nav hidden)
  |     |     |-- Workout summary + PR
  |     |           |-- Share card
  |     |-- Plan editor (/plan)
  |     |-- Choose session (sheet)
  |     |-- Focus drawer for empty workouts
  |     |-- Manual steps (sheet)
  |     |-- Quick actions: empty workout, walk, routine
  |-- Calendar
  |     |-- Day detail (sheet)
  |     |-- Plan editor (/plan)
  |     |-- Exercise library (/exercises)
  |     |     |-- Exercise details
  |     |     |-- Routine list
  |     |     |-- Routine details
  |     |     |-- Routine builder
  |-- Progress
  |     |-- Workout history
  |     |-- Workout detail
  |     |-- Body weight log
  |     |-- Body weight (sheet)
  |     |-- Progress photos
  |-- Social
  |     |-- Feed
  |     |-- PR share card preview
  |-- Me
        |-- Profile
        |-- Profile edit
        |-- Settings
              |-- Units
              |-- Week starts on
              |-- Equipment
              |-- Reminders
              |-- Integrations
              |-- Privacy and data
              |-- Legal
              |-- Licenses
              |-- Reset local data
```

`MOCK.html` is the canonical visual storyboard. It shows Splash, all 12 onboarding screens (Welcome plus the eleven steps), and the five-tab core screens: Today, Live logger, Summary and PR, Progress, Calendar, Social, and Me. Sub-routes such as profile edit, settings, history detail, plan, exercise library, routine detail, legal, and licenses reuse the same components and are listed in the route table below.

### 9.2 Route names

| Route | Screen | Nav visible |
|---|---|---|
| `/splash` | Splash | No |
| `/welcome` | Welcome | No |
| `/onboarding/units` | Unit selection | No |
| `/onboarding/gender` | Gender | No |
| `/onboarding/birth-date` | Birth date | No |
| `/onboarding/weight` | Weight | No |
| `/onboarding/height` | Height | No |
| `/onboarding/goals` | Goals | No |
| `/onboarding/experience` | Experience | No |
| `/onboarding/schedule` | Schedule | No |
| `/onboarding/equipment` | Equipment | No |
| `/onboarding/notifications` | Notification permission | No |
| `/onboarding/plan` | Plan preview | No |
| `/today` | Today | Yes |
| `/calendar` | Calendar | Yes |
| `/train` | Calendar alias | Yes |
| `/plan` | Plan editor | No |
| `/exercises` | Exercise library | Yes |
| `/train/exercises` | Exercise library alias | Yes |
| `/train/exercises/:id` | Exercise details | Yes |
| `/train/routines` | Routine list | Yes |
| `/train/routines/new` | Routine builder, new | No |
| `/train/routines/:id` | Routine details | Yes |
| `/train/routines/:id/edit` | Routine builder, edit | No |
| `/progress` | Progress | Yes |
| `/progress/history` | Workout history | Yes |
| `/progress/history/:id` | Workout detail | Yes |
| `/progress/weight` | Body weight log | Yes |
| `/progress/photos` | Progress photos | Yes |
| `/social` | Social feed | Yes |
| `/me` | Me | Yes |
| `/me/edit` | Profile edit | No |
| `/me/settings` | Settings | Yes |
| `/me/equipment` | Equipment | Yes |
| `/me/legal/:doc` | Legal document | Yes |
| `/me/licenses` | Licenses | Yes |
| `/logger` | Live logger | No |
| `/summary` | Summary and PR | No |

### 9.3 Navigation rules

- The logger is a full-screen route. Back opens the interruption sheet, not the previous screen.
- The summary is a full-screen route after the logger. Save replaces the stack with Today.
- After discarding, return to Today and keep the previous plan intact.
- Onboarding cannot be skipped once started. The only exit is closing the app, which resumes at the same step.
- Tabs keep their scroll position per session.
- Android back on a tab pops to the tab root, then exits.
- Deep links are not required in v1.

---

## 10. Screen specifications

All screens use `background`, 16 px horizontal padding, and the `body` type as the default.

### 10.1 Splash

- **Purpose:** Cold start, brand moment, local data warm-up.
- **Layout:** Centered 86x86 mark, lowercase wordmark, tagline, 120x4 loading bar, platform line at the bottom.
- **Components:** Logo mark, `displayXL` wordmark, `caption` tagline, lime progress bar.
- **Behavior:** Check for a stored profile and active session. Route to `/welcome`, `/today`, or `/logger` after at most 900 ms, or as soon as initialization finishes.
- **States:** No error UI. If storage fails, continue with a clean profile and surface a snackbar on Today.

### 10.2 Welcome

- **Purpose:** Introduce the product in one screen and start onboarding.
- **Layout:** 62x62 lime gradient mark with the letter M, headline "Train with a plan", three value bullets (plan, logger, progress), primary "Get started". No wordmark. The step progress indicator starts on the next screen.
- **Components:** Brand mark, `AppOnboardingType.title`, three rows with 28 px lime-tinted icon boxes and SVG icons, primary button.
- **Behavior:** "Get started" opens `/onboarding/units`. If a saved draft exists, the primary action becomes "Continue" and resumes at the saved step. "I have a profile" is not shown because local backup and accounts are out of scope in v1.
- **States:** No loading. The button is disabled only while a draft is being created.

### 10.3 Onboarding: units, gender, birth date, weight, height

- **Purpose:** Capture the measurements that personalise the plan and profile.
- **Screens:** `/onboarding/units`, `/onboarding/gender`, `/onboarding/birth-date`, `/onboarding/weight`, `/onboarding/height`.
- **Units:** Three segmented rows for weight (kg or lb), distance (km or mi), and body size (cm or in). Defaults are kg, km, and cm. All three persist before Continue. Distance is used for walks and runs.
- **Gender:** Three full-width `AppChoiceCard` buttons with an SVG icon and text for male, female, and other. Other uses the combined male-female sign. Selection is required.
- **Birth date:** Three vertical wheels for month, day, and year. Default is 25 years before today. The date must make the user at least 13 and no more than 120 years old. Leap years are handled.
- **Weight:** Horizontal ruler slider, 30 to 250 kg in 0.5 kg steps. The displayed value uses the weight unit. The stored value is kg. Skip stores 0.
- **Height:** Vertical roller, 120 to 230 cm in 1 cm steps. Limits sit on the left of the track and the value on the right. The displayed value uses the body unit. The stored value is cm. Skip stores 0.
- **Components:** `AppSegmentedControl`, `AppChoiceCard`, `AppWheelPicker`, `AppRulerSlider`, step progress, primary Continue, ghost Skip where allowed.
- **Behavior:** Every step persists the draft before moving forward. Back preserves values. Weight and height can be skipped; gender and birth date are required.
- **States:** Default, selected, skipped, restored draft, invalid age.

### 10.4 Onboarding: goals, experience, schedule, equipment, notifications

- **Purpose:** Turn the profile into a goal, a training week, an equipment set, and a reminder choice.
- **Screens:** `/onboarding/goals`, `/onboarding/experience`, `/onboarding/schedule`, `/onboarding/equipment`, `/onboarding/notifications`.
- **Goals:** Multi-select cards for build muscle, get stronger, lose weight, and stay healthy, each with a one-line description, a 40 px icon box, and 16 px inner padding. The cards match the experience step. At least one is required. The first selected goal is primary and is labelled as such.
- **Experience:** Single-select cards for beginner, regular, gym rat, and veteran, each with a one-line description, a 40 px icon box, and 16 px inner padding. Regular is selected by default and one level is always active.
- **Schedule:** First choose `Plan with Mova` or `Track on my own`. Planning shows average days per week from 1 to 7, with no weekday selector, and builds an ordered rotation. Tracking hides the frequency and keeps the app useful without a plan; a rotation can be added later from `/plan`. Default is 3 days. Copy explains that the frequency is an average target, that any day can start the rotation, and that unlogged days are rest days without blocking training.
- **Equipment:** Multi-select cards for bodyweight, dumbbells, barbell and EZ bar, machines, cable station, kettlebells, and accessories. Each group has its own glyph: a push-up, hex dumbbell, loaded barbell, pinned weight stack, cable pulley with a lat bar, kettlebell, and paneled medicine ball. Every group is selected by default so a new user keeps a full-gym plan. At least one group is required. The selection is stored on the profile and every generated plan. A Quick start preset bar above the cards applies a common setup (Bodyweight only, Home gym, Full gym) in one tap, then the cards can be fine-tuned.
- **Notifications:** Explain workout reminders. Enable asks for system permission. Deny, Not now, or unavailable continues with reminders off. The choice is stored and can be changed later in Settings.
- **Components:** `AppMultiSelect`, `AppChoiceCard`, stepper, day selector, equipment cards, step progress, primary Continue.
- **Behavior:** The schedule and equipment feed the plan generator. The notification choice never blocks progress.
- **States:** No goal, no day, invalid day count, no equipment, permission granted, denied, unavailable, skipped.

### 10.5 Plan preview

- **Purpose:** Show the generated rotation before committing.
- **Layout:** `h1` "Your plan", subtitle with goal, average frequency, and experience, list of `Day 1..N` session cards, primary "Start using Mova", ghost "Edit schedule".
- **Components:** Plan day card with day label, workout name, muscle groups, exercise count, estimated duration.
- **Behavior:** Confirm persists the profile, settings, and plan through `AppCoordinator`, clears the draft, and routes to `/today`. When tracking without a plan, the preview shows a `Your Mova` summary and `Begin your Mova` instead, skips plan generation, and leaves the user free to log any workout. Edit returns to `/onboarding/schedule` with frequency preserved. The footer explains the rotation and that unlogged days are rest days. When the selected equipment leaves a muscle group without options, the preview shows a warning that names the skipped muscles and still produces a plan.
- **States:** Generated rotation, tracking without a plan, editing, generation in progress under 500 ms, skipped-muscle warning. If generation fails, show a retry card and a fallback full-body plan labelled "Starter plan".

### 10.6 Today

- **Purpose:** Answer "What should I do today?" and make starting a workout one tap away.
- **Layout:** Calendar/date header with `Edit plan`, training card, steps card, running card, streak badges, and plan stats when a rotation exists.
- **Components:** Training card with next-up, active, or completed states; completed rows with title, source, duration, and volume or distance plus Edit; Steps card with `Start walk` and `Edit steps`; Running card with `Start run`, `Continue run`, or `Run again`; horizontal `Streak badges`.
- **Content:** The next rotation session after the last completed plan session, every completed session from today, the latest manual or health step count, and today's completed run.
- **Actions:** Start the suggested session, choose another rotation session or saved workout, start an empty workout, start a walk, start or continue a run, edit steps, edit a completed workout, open the rotation planner.
- **States:**
  - Next up: session card plus Start workout and Choose another session.
  - Completed today: one row per completed session, optional Edit, then one Train again and Choose another session.
  - Active or paused session: Continue workout takes priority over the rotation; runs open the run timer.
  - No plan: positive `Track your training` card with Start workout and Choose saved workout.
  - Steps unavailable: show "Add steps" and open a manual entry sheet.
  - Badges: earned day tiers 3, 7, 14, 30; earned week tiers 1, 4, 12; locked tiers stay faint and show progress.
- **Rules:** Rest days never block training. Suggestion copy is brief, can cite the last trained session or a neglected muscle, and recovery is a warning rather than a block. Editing a completed workout keeps its original date and source, then recalculates PRs, streaks, volume, and calendar markers.

### 10.7 Live logger

- **Purpose:** Log sets faster than any competitor.
- **Layout:** Top row with close, session name, and a rest-timer toggle. Live totals bar with Duration, Volume, and Sets. Set table header. Current exercise set rows. Rest timer when active. Up-next card. Flexible spacer. The active set row is the primary control; "Finish workout" is a secondary action.
- **Components:** Live totals bar, set row, rest banner, up-next card, finish action, overflow menu.
- **Actions:** Complete set, edit weight or reps, add or remove a set, skip rest, toggle the rest timer, add or edit an exercise note, add exercise, replace exercise, open the plate calculator, pause, finish, discard.
- **Behavior:**
  - The totals bar stays pinned under the header and updates every second: elapsed workout time, completed working volume in the selected unit, and completed working sets out of all working sets. Warm-up sets never count toward volume or set totals.
  - Each exercise can carry one free-text note, opened from the note action beside the exercise name. A saved note shows a two-line preview under the set count and is stored with the workout history.
  - Completing a set starts the default rest timer for the exercise type. The header toggle turns the timer off for the workout and suppresses the banner until it is turned back on.
  - Prefill weight and reps from the previous session for the same exercise, then apply the progressive overload suggestion.
  - The progression hint sits above the set table. It reads `Progressive overload: +<increment>` when every working set of the last session reached the top of the rep range, or `Repeat last weight: <weight>` otherwise. Bodyweight exercises and exercises without history show no hint.
  - "Replace exercise" opens the picker filtered to the same primary muscle and the profile's equipment, excluding the current exercise. A swap keeps the set count, clears every completed set, zeros the weight, and asks for confirmation when sets are already logged.
  - The plate calculator opens from the logger toolbar. It is read-only and never changes logged sets.
  - Completing a set starts the default rest timer for the exercise type.
  - Completing the last set of an exercise moves focus to the next exercise with a brief card transition.
  - The keyboard never covers the active set row.
  - The elapsed timer continues while the app is backgrounded, using wall-clock time.
- **States:** Resting, active set, exercise complete, workout paused, no sets logged, offline.
- **Rules:** Navigation is hidden. Back opens the interruption sheet. No social or ad surfaces.

### 10.8 Summary and PR

- **Purpose:** Close the loop and reward progress.
- **Layout:** PR badge if any, PR card with exercise and estimated 1RM, three stat tiles (time, volume, sets), share card preview, primary "Share card", ghost "Save".
- **Components:** Gold badge, PR card, stat trio, story preview, buttons.
- **Behavior:** Save commits the session and its PRs, then returns to Today. Streak and volume derive from saved history. Share opens the native share sheet with the rendered card.
- **States:** New PR, no PR, empty workout, partial workout.
- **Rules:** If multiple PRs exist, show the highest estimated 1RM first and list the rest under "Also new". Never show a PR for an uncompleted set.

### 10.9 Calendar

- **Purpose:** Show when and what was trained, mark today, and preview the next suggested rotation sessions.
- **Layout:** `h1` Calendar with Plan and Exercises header actions, month bar with previous/next, weekday labels in the effective week order, month grid, legend, and day cells.
- **Components:** Day cell with date circle, source markers, today ring and label, check badge, dashed suggestion circle. Day detail sheet with session rows or rest/suggestion copy.
- **Behavior:**
  - Past logged workouts show plan, routine, walk, or empty-workout icons. Two or more sessions stack markers and add a count.
  - Today gets an accent ring and `Today` label, plus a check when trained.
  - The next three suggested sessions get dashed circles and a small plan icon.
  - Suggested days are never counted as logged or rest.
  - Tapping a past logged day lists sessions with title, source, time, duration, volume, and opens history detail.
  - Tapping a past empty day shows `Rest day` with no workout logged.
  - Tapping today adds `Start workout`.
  - Tapping a suggested future day shows `Suggested: [session]`, `View session`, and `Start now`.
  - Header actions open the rotation planner and exercise library.
- **States:** Empty month, logged day, multiple sessions, today trained, today untrained, suggested day, month away from today.
- **Rules:** Week start follows the Me setting with locale-aware automatic default. No 14-day projection.

### 10.9.1 Exercise library

- **Route:** `/exercises`, also reachable through `/train/exercises`.
- **Purpose:** Find an exercise and act on it immediately.
- **Layout:** `h1` Exercises, search field, focus chips with `All`, result list with equipment glyph, name, primary muscle, and equipment.
- **Components:** Search input, focus chips, exercise row with add action.
- **Actions:**
  - Active workout and exercise not added: the row add button adds it directly with default sets and shows `Added` plus `View`.
  - No active workout: the add button opens a choice sheet with `Start workout with this`, `Add to routine`, and `View details`.
  - Tapping the row opens exercise details.
- **States:** Default list, search results, no results, focus filtered, active-session add mode, already added.
- **Rules:** Search matches name, muscle group, and equipment. Result count is announced to screen readers.

### 10.10 Exercise details

- **Purpose:** Explain the movement, show previous performance, and always offer a useful next action.
- **Layout:** Back bar, equipment hero with a large glyph and the exercise name, muscle and equipment caption, previous performance card, instructions section, primary action, and secondary `Add to routine` and `View history` actions.
- **Components:** Equipment hero, tag row, performance card with best set and last session, numbered instruction list, always-enabled primary button, filtered history sheet.
- **Primary action states:** No active workout -> `Start workout with this exercise`. Active workout and exercise absent -> `Add to current workout`. Active workout and exercise present -> `Already in workout` tag plus `View in workout`.
- **Secondary actions:** `Add to routine` opens a routine picker with a New routine route. `View history` opens a filtered sheet of recent sets, weights, reps, and dates.
- **States:** No history shows "First time? Log a set to start tracking.", already in workout, no active workout.
- **Rules:** The primary action is never disabled. Instructions are stored locally as short text. No video in v1.

### 10.11 Routine details and builder

- **Purpose:** Create, edit, reorder, and start a routine.
- **Layout:** Routine name field, ordered exercise list with drag handles, set and rep configuration per exercise, primary "Save routine", ghost "Start now", destructive "Delete routine".
- **Components:** Reorderable list, exercise row, set and rep steppers, add exercise button.
- **Behavior:** Drag to reorder. Swipe or overflow to remove. Save validates at least one exercise. Start now saves a draft and opens the logger.
- **States:** Empty builder, unsaved changes, deleting confirmation.
- **Rules:** Maximum 20 exercises per routine. Reordering uses a long-press drag handle.

### 10.12 Progress

- **Purpose:** Answer "Am I improving?" with honest local metrics and a clear next action.
- **Layout:** `h1` Progress with a Lifetime marker and "What counts" info action, then three sections:
  - **Training:** 2x2 totals for workouts, lifetime volume, day streak, and week streak; strength score card; weekly consistency; weekly volume; 28-day muscle balance; personal records; workout history shortcut.
  - **Body:** Body weight card, measurements, and progress photos in a 2-column grid.
  - **Wellness:** Nutrition, sleep, and resting heart rate in a 2-column grid.
- **Components:** Stat tiles, progress ring, weight chart, volume bars, consistency bar, muscle bars and neglect tags, PR rows, compact metric cards, faded `ProgressPlaceholderCard` cards, progress photo grid, "What counts" sheet. Compact Body and Wellness cards share one fixed height in a two-column grid, regardless of copy length.
- **Metrics:** Total workouts, total volume, current day streak, current week streak, sessions this week versus the plan target, current calendar-week volume, 28-day muscle balance, best estimated 1RM per tracked lift, body weight and trend, measurements, nutrition, sleep, and resting heart rate. The info action defines every metric in plain language.
- **Consistency and streaks:** The current week never ends a week streak while it is still in progress. A week joins the streak once the target is met. Week boundaries follow the effective week start.
- **Muscle balance:** Volume over the last 28 days. Primary muscles receive full volume and secondary muscles half. Muscles with no volume are tagged as neglected.
- **Placeholders:** Empty or future metrics use `Opacity 0.72` inside `DashedBorder`, keep labels and actions fully readable, and sit in a 2-column grid. Quick add actions are `Start workout` for training metrics, `Add body weight` for the strength score, the weight sheet for body weight, numeric sheets for measurements, nutrition, sleep, and resting heart rate, and a local picker for photos. No card repeats a large Start workout button.
- **Body weight:** One entry per local day, newest first, stored only on the device. The card shows the latest value and a trend line once two entries exist. The plus action opens the weight sheet, and tapping the card opens the full log. The weight sheet uses the shared calculator keypad.
- **Wellness:** Nutrition records calories and protein, sleep records hours and minutes, resting heart rate records bpm, and measurements record waist in cm. Entries are one row per local day, stored only on the device, and are trend notes rather than medical advice.
- **Progress photos:** Up to 12 photos, stored locally and downsized before saving. The grid shows thumbnails and dates with delete confirmation. Camera and gallery sources are offered on mobile; web uses the gallery picker. Permissions are requested at the moment of use.
- **Strength score:** Display with a "Beta" tag and a tap-through explanation. Do not show a gym or global ranking in v1.
- **States:** Empty metrics show placeholders rather than a blocking empty screen. Fewer than three sessions hides the numeric score and keeps the explanation.
- **Rules:** Every chart has a text summary. No chart is the only way to read a value. Photos never leave the device.

### 10.12.1 Body weight log

- **Route:** `/progress/weight`.
- **Layout:** Back bar, `h1` Body weight, current value card with an Add weight action, trend chart card, history list newest first.
- **Actions:** Add weight opens the numeric body weight sheet. Saving a value updates today's entry, replaces an earlier value from the same day, updates the profile body weight, and refreshes the strength score.
- **States:** Empty log shows one Add weight action. A single entry shows a point and asks for another entry to draw a trend. Missing or unreadable entries never block the screen.
- **Rules:** Values use the selected weight unit for display and stay stored in kilograms. Range checks match onboarding body weight.

### 10.13 Workout history and detail

- **Purpose:** Let the user review and trust their data.
- **Layout:** History list grouped by month, each row with date, workout name, duration, volume or distance, PR count. Detail screen shows exercises, sets, and notes. Run and walk details replace volume and sets with time and distance.
- **Components:** Month header, history row, detail set table, `Edit workout` action.
- **Actions:** Open detail, edit a completed workout, delete workout with confirmation.
- **States:** Empty history, no results for a filter, edit drawer, deleted workout confirmation.
- **Rules:** Editing keeps the original date and source, then recalculates PRs and streaks. Deleting a workout recalculates PRs and streaks.

### 10.13.1 Running

- **Purpose:** Log a run without GPS, accounts, or network access.
- **Route:** `/run`, opened from Today.
- **Layout:** Start card when idle; timer card with Pause/Resume and Finish when active; distance card.
- **Actions:** Start, pause, resume, finish, and enter an optional distance manually.
- **States:** Ready, running, paused, finishing, completed today.
- **Rules:** Distance is optional and stored in meters. Runs count toward day streak, week streak, and weekly consistency, but add no lifting volume or PRs. No location permission is requested.

### 10.14 Social feed

- **Purpose:** Low-noise motivation through kudos.
- **Layout:** `h1` Feed, list of activity posts, local-only notice in the first session, flexible spacer.
- **Components:** Post row with avatar, name, activity text, time, kudos button and count. Own posts show a "You" tag.
- **Actions:** Give or remove kudos, open own workout detail, open the PR share card.
- **States:** Empty feed, first-run welcome placeholder, own post, kudos given.
- **Rules:**
  - No comments, no direct messages, no follower graph in v1.
  - The feed is local. One faded, dashed welcome placeholder stands in until the first own post or until it is dismissed.
  - The placeholder carries no kudos count and is not a real workout.
  - Kudos are stored locally and never imply a network count.
  - No ranking, leaderboard, or gym comparison.

### 10.15 Me

- **Purpose:** Identity, lifetime totals, and settings entry.
- **Layout:** Profile header with avatar, name, experience tag, three stat tiles, settings list, app version.
- **Components:** Avatar showing the experience icon in `limeInk` on `lime`, name, tag, stat trio, setting rows with icon, label, value, chevron.
- **Entries:** Edit profile, Body weight, Units, Week starts on, Workout reminders, Integrations, Equipment, Privacy and social, Help and support, Reset local data, App version. Body weight opens `/progress/weight`. Week starts on shows `Automatic (Monday)` or the manual day and opens the same week-start sheet as Settings. Privacy policy, Terms of service, and Open-source licenses open from Settings.
- **States:** Default profile, edited name, no PRs.
- **Rules:** There is no account, sign-in, or log out in v1. Reset local data requires a confirmation and explains what is removed. Legal and license screens live under Settings, not as separate Me rows.

### 10.16 Settings

- **Profile:** Edit name, experience, goals, gender, birth date, height, and body weight on `/me/edit`.
- **Units:** Weight, distance, and body units. Converts display only. Canonical storage stays kg, km, and cm.
- **Week starts on:** Automatic by locale or a manual Monday through Sunday. Automatic resolves through the device locale and falls back to Monday. One setting drives Calendar, weekly consistency, weekly volume, and week streak.
- **Equipment:** Opens `/me/equipment`. Shows the number of selected groups and reuses the onboarding equipment cards with the Quick start preset bar. Saving offers "Save only" or "Save and regenerate". Regeneration resets the rotation to Day 1 with a notice and keeps history and personal records.
- **Reminders:** Toggle plus weekday and time picker. Requires notification permission at the moment of enabling.
- **Integrations:** Apple Health or Health Connect row. Shows connected, not connected, or unavailable. Manual steps fallback is always available.
- **Privacy and social:** Local-only explanation. Toggle for showing own workouts in the feed.
- **Privacy and data:** Explains that data stays on the device and opens the reset local data dialog.
- **Help and support:** FAQ, contact link, document version.
- **Legal and licenses:** Opens the bundled privacy policy, terms of service, and open-source licenses pages.

### 10.17 Plan overview and edit

- **Purpose:** Review and change the ordered rotation without redoing onboarding.
- **Route:** `/plan`, opened from Today and Calendar.
- **Layout:** Full screen with `Your rotation`, frequency 1-7, split style, ordered `Day 1..N` session cards with expandable exercise previews, `Save as saved workout`, `Saved workouts`, and a staged `Regenerate` action. Without a plan, the same frequency and split controls create a first rotation.
- **Actions:** Change average frequency, choose a split style, reorder sessions with Move earlier/later, start a session, save a plan day as a saved workout, create or start saved workouts, and create or regenerate the rotation.
- **Behavior:** A plan is the ordered rotation that drives what comes next. A saved workout is a reusable template that can start any day without changing the rotation. `Save as saved workout` copies exercises, sets, reps, and rest one way; later edits do not sync. Frequency and split changes are staged and nothing changes until Regenerate. Regeneration confirms, resets the rotation to Day 1 with a notice, and appends any equipment warning. Move earlier/later stays within bounds.
- **States:** Empty plan, staged changes, regeneration confirmation, skipped-muscle warning, no saved workouts.
- **Rules:** Editing the plan never deletes completed history. History and PRs are unchanged by regeneration. Per-exercise editing is not part of v1.

### 10.18 Permissions

- **Purpose:** Request access at the moment it is useful, not on first launch.
- **Triggers:** Notifications when enabling reminders. Health when connecting an integration. Share cards use the native share sheet or a download and do not request photo library access.
- **Components:** Explanatory sheet with a benefit line, primary "Allow", ghost "Not now".
- **States:** Granted, denied, permanently denied with a link to system settings.

### 10.19 Workout interruption

- **Purpose:** Protect unsaved work.
- **Trigger:** Back, close, or app interruption during a live session.
- **Options:** Keep training, Pause and exit, Discard workout.
- **Behavior:** Pause persists the session and returns to Today with a Resume card. Discard requires a second confirmation and states how many sets will be lost.

---

## 11. Data display rules

### 11.1 Units and formatting

- Store weight in kilograms and distance in kilometers. Store durations in seconds.
- Display kg or lb based on the user's setting.
- Weight: one decimal when needed, no trailing zero. `82.5 kg`, `80 kg`.
- Body weight: one decimal.
- Reps: integer.
- Volume: kilograms with one decimal under 1000, tonnes with one decimal above 1000. `940 kg`, `9.4 t`.
- Duration: `mm:ss` under one hour, `h:mm` above.
- Steps: integer with thousands separators. `8,240`.
- Dates: `Mon, Nov 2` in lists and `Nov 2, 2026` in detail.
- Never show a unit without a number, or a number without a unit.

### 11.2 Workout volume

```text
volume = sum(weight_kg * reps) for every completed set with external load
```

Bodyweight sets contribute reps but zero volume. Warm-up sets are excluded unless the user marks them as working sets.

### 11.3 Estimated 1RM

Use the Epley formula for weighted sets with 1 to 12 reps:

```text
e1RM = weight * (1 + reps / 30)
```

- Above 12 reps, show the best set instead of an estimated 1RM.
- Round to 0.5 kg or 1 lb at display time.
- Store the unrounded value to keep comparisons stable.

### 11.4 Personal records

- A PR is the highest estimated 1RM for an exercise, or the highest reps for a bodyweight exercise.
- Only completed working sets count.
- A new PR requires a value strictly greater than the stored best.
- Record the previous best at detection time so the delta can be shown later.
- One PR celebration per exercise per session. Multiple PRs are summarized on the summary screen.
- Deleting a workout recomputes PRs from remaining history.

### 11.5 Streak

- A streak is the number of consecutive local calendar days with at least one completed workout or logged walk.
- A day with no activity resets the count to zero.
- Timezone is the device timezone at the moment of completion.
- A restored session counts on the day it was completed, not the day it was started.
- Never show a streak longer than the number of days since the profile was created.

### 11.6 Strength score

The score is a local, transparent training-load index, not a ranking.

```text
score = round(
  sum over tracked lifts of (best_e1RM_kg / bodyweight_kg) * 100
  / number_of_tracked_lifts
)
```

- Track squat, bench press, deadlift, and overhead press when data exists.
- Require at least three sessions and at least two tracked lifts.
- Label the score "Beta" and provide an explanation sheet.
- Do not show "Top X% at your gym" or any percentile unless a real dataset exists. In v1 this line is omitted.
- Show the 7-day change only when there is a previous score.

### 11.7 Steps and activity

- Steps come from the platform health integration when connected.
- Otherwise the user can add a manual step count from Today.
- The manual entry sheet uses the shared calculator keypad, so counts can be added as an expression with a live `= value` preview.
- Manual entries are labeled "Manual" with an edit action.
- Walks logged in Mova count as activity minutes, not steps.

### 11.8 Progressive overload

```text
if every completed working set of the newest session reaches reps_high:
    next_weight = min(last_weight + increment, 500 kg)
else:
    next_weight = last_weight
next_reps = reps_low
```

- The increment is 2.5 kg in kg mode and 5 lb converted to kg in lb mode.
- Only completed, non-warm-up sets count. A session with no completed working set is skipped and the next newest session is used.
- The suggestion pre-fills new sessions only. It never rewrites history.
- Bodyweight exercises and sets logged at 0 kg produce no suggestion.
- The logger hint names the change when the suggestion increases the weight and otherwise reads "Repeat last weight".

### 11.9 Plate calculator

- Target weight is the total including the bar.
- Per side load is `(target - bar) / 2`. A target below the bar is reported as below the bar, not as an error.
- Plates are chosen greedily from the heaviest available plate per loadout, unlimited per side.
- kg loadout: bars 20, 15, and 10 kg; plates 25, 20, 15, 10, 5, 2.5, and 1.25 kg.
- lb loadout: bars 45, 35, and 25 lb; plates 45, 35, 25, 10, 5, and 2.5 lb.
- When the target is not loadable, show the closest loadable weight and the remainder with one decimal.
- The target uses the shared calculator keypad, so a long-press-free expression like `45 + 25` resolves before loading. The field shows a live `= value` preview.
- The calculator is read-only. It never changes logged sets.

### 11.10 Empty and missing data

- Show `-` for a missing value, never `0` when the value is unknown.
- Show "Not connected" for integrations, not "Off".
- Show "No data yet" for charts with no history.
- Never fabricate a trend line from a single data point.

---

## 12. Motion

### 12.1 Timing

| Token | Duration | Use |
|---|---|---|
| `instant` | 80 ms | Press feedback |
| `fast` | 120 ms | Button scale, chip selection |
| `standard` | 200 ms | Tab content fade, card state |
| `sheet` | 280 ms | Bottom sheets, dialogs |
| `page` | 300 ms | Route transitions |
| `celebration` | 700 ms | PR badge, confetti |

### 12.2 Easing

- Standard: `Curves.easeOutCubic`.
- Entrances: `Curves.easeOutQuart`.
- Exits: `Curves.easeInCubic`.
- Never use bounce or elastic curves except on the optional PR confetti.

### 12.3 Interaction feedback

- Completing a set: check scale 1.0 to 1.15 to 1.0 over 180 ms plus light haptic.
- Starting rest: banner slides in from the bottom over 200 ms.
- Rest complete: banner fades out over 150 ms plus medium haptic.
- PR entry: badge fades and scales from 0.9 to 1.0 over 500 ms plus medium haptic.
- Tab change: cross-fade content over 150 ms, keep the nav static.
- Pull to refresh is not used. Data is local.

### 12.4 Reduced motion

- Disable confetti, scale transitions, and staggered bars.
- Keep opacity fades at 120 ms or less.
- Never remove state feedback entirely. Use color and text changes instead.

---

## 13. Accessibility

- Minimum touch target 44x44.
- Body text contrast at least 4.5:1. Large text at least 3:1.
- Do not communicate completion, PR, or error with color alone. Use icons and labels.
- Every icon button has a semantic label. Every chart has a text summary.
- Set rows announce: "Set 3, previous 80 by 6, current 82.5 by 8, completed".
- The rest timer announces the remaining time every 30 seconds when a screen reader is active.
- Order focus logically: header, primary content, primary action.
- Support dynamic text to 1.3x without clipping. Avoid fixed heights on text containers.
- The logger supports one-handed reach: primary controls in the lower half.
- Haptics are supplementary. Sound is off by default.
- Test with VoiceOver on iOS and TalkBack on Android before release.

---

## 14. Content and voice

### 14.1 Rules

- Use sentence case for body, labels, and buttons.
- Keep buttons to one to three words: Start workout, Finish, Save, Share card.
- Numbers are always specific. Avoid "some", "a few", "many".
- Use "workout" for a session and "routine" for a saved template.
- Use "exercise" for a movement.
- Use "set" for a group of reps.
- Use "PR" only after defining it once as "personal record".
- Never use exclamation marks except in the PR celebration.
- No em dashes. Hyphens only.
- No guilt, no streak shaming, no comparisons the user did not ask for.

### 14.2 Key strings

| Context | String |
|---|---|
| Today, planned | `Push Day` / `Chest · Shoulders · Triceps` |
| Today, rest | `Rest day` / `Recover and come back stronger` |
| Today, resume | `Resume workout` / `Started 32 min ago` |
| Logger, next | `Up next` / `Incline DB Press · 3 sets` |
| Rest | `Rest · 1:24` / `Skip` |
| Summary, PR | `New PR` / `Bench Press · est. 1RM` |
| Summary, delta | `+3.5 kg vs last session` |
| Empty history | `No workouts yet` / `Finish a workout to see it here` |
| Empty social | `Your feed is quiet` / `Finish a workout to share your first post` |
| Settings, local | `Your data stays on this device` |

---

## 15. Flutter implementation mapping

### 15.1 Token files

```text
lib/theme/
  app_colors.dart        // Color constants and semantic aliases
  app_typography.dart    // TextTheme and named text styles
  app_spacing.dart       // Spacing constants
  app_radii.dart         // Radius constants
  app_theme.dart         // ThemeData assembly, dark only
```

### 15.2 Rules

- Widgets never hardcode a hex color, font size, radius, or spacing value. They read from the token classes.
- One public widget per file. Files use `snake_case.dart`.
- `build()` is the last method in a class. Widget-returning helpers are named `_build...` and placed above `build()`.
- Screens live in `lib/screens/<feature>/`. Shared widgets live in `lib/widgets/`.
- Models live in `lib/models/` with `fromJson` and `toJson`.
- Providers live in `lib/providers/` and extend `ChangeNotifier`.
- Services live in `lib/services/` and have no widget imports.
- Navigation constants live in `lib/navigation/`.
- Theme is dark only. `ThemeMode.dark` is fixed in v1.

### 15.3 Storage keys

```text
mova.v1.profile
mova.v1.settings
mova.v1.plan
mova.v1.activeSession
mova.v1.workouts
mova.v1.routines
mova.v1.prs
mova.v1.social
mova.v1.steps
mova.v1.onboarding
```

- Every stored object has a `schemaVersion` field.
- Writes are debounced for high-frequency changes and immediate for completed sets and saved workouts.
- Corrupt payloads are discarded with a logged warning and a safe default. Never crash on read.

### 15.4 Local-first behavior

- The app opens with no network dependency.
- Social content is local. One faded welcome placeholder is clearly removable.
- Share cards are rendered and shared on device.
- Health integration is optional. The manual steps fallback is part of the MVP.
- No analytics SDK and no remote config in v1.

---

## 16. Decision log

| Date | Decision | Rationale |
|---|---|---|
| 2026-11-02 | Brand is Mova, not RepForge | Every resource except `mock-qwen.html` uses Mova. RepForge is a discarded experiment |
| 2026-11-02 | Five tabs: Today, Train, Progress, Social, Me | Preserves the original mockup navigation and includes Social in the launch scope |
| 2026-11-02 | MVP scope is P0 plus P1 plus Social | User confirmed the broader scope |
| 2026-11-02 | Local guest profile, no authentication in v1 | No backend and no Firebase. A profile is created during onboarding |
| 2026-11-02 | Dark theme only | Matches every mockup. Tokens allow a light theme later |
| 2026-11-02 | Social is local-first | No backend. Feed uses one welcome placeholder plus the user's own posts and local kudos |
| 2026-11-02 | Strength score is beta and unranked | A local-only app cannot compute "Top X% at your gym" honestly |
| 2026-11-02 | Health sync has a manual fallback | Prevents Today from depending on a platform permission |
| 2026-11-02 | Nutrition and GPS are post-MVP | They do not support the core loop |
| 2026-11-12 | Replace the Train tab with Calendar and an exercise library | Users need to see when and what they trained. Exercises are reachable from Calendar and Today |
| 2026-11-12 | Plans are ordered rotations, not weekday schedules | Schedules that do not line up with weekdays still work. Any unlogged day is rest without blocking training |
| 2026-11-12 | Week start is automatic by locale with a manual override | Calendar, consistency, volume, and week streaks must agree while allowing a user preference |
| 2026-11-12 | Plans are optional and saved workouts are templates | Users can track without a rotation; plan-day copies are one-way and never auto-sync |
| 2026-11-12 | Completed workouts are editable | Users forget a set or exercise; saving recalculates PRs, streaks, volume, and calendar markers |
| 2026-11-12 | Running is local and distance is manual | No GPS or location permission in v1; timer and distance still count as activity |

---

## 17. Known limitations and deferred work

- **No ranking or leaderboard.** The gym ranking line from the mockup is not implemented. It requires real comparative data.
- **No networked social graph.** Friends, following, and comments are post-MVP. The feed is local.
- **No account recovery.** The profile is local. Clearing app data removes it.
- **No exercise media.** Instructions are text only in v1.
- **No Apple Watch or Wear OS app.** The phone app is the source of truth.
- **No AI plan generation.** The plan is generated from deterministic rules by goal, experience, and schedule.
- **No nutrition tracking or GPS routes.** Both are post-MVP.
- **Light theme is not implemented.** Tokens are structured for it, but only dark is built and tested.

---

## 18. Reference inventory

| File | Use |
|---|---|
| `MOCK.html` | Canonical 10-screen storyboard, colors, component sizes |
| `resources/mockup.html` | Identical copy of `MOCK.html` |
| `resources/mock-01.jpg` | Rendered onboarding, Today, and logger screens |
| `resources/mock-02.jpg` | Rendered logger, summary, progress, and feed screens |
| `resources/screen-tree.jpg` | Mova screen tree with MVP labels |
| `resources/overview.md` | MVP priorities, missing screens, user flows, roadmap |
| `resources/overview.html` | Extended version of the overview with the complete screen tree |
| `resources/mock-qwen.html` | Alternate RepForge concept, retained for reference only |
