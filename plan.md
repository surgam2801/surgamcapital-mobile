# Surgam implementation plan

## Product scope

Surgam is a clean-room rebrand of the public investment-dashboard category represented by the referenced FundzBazar listing. It keeps the useful workflows—portfolio snapshot, reports, recurring plans, transactions, alerts, and help—while using original names, copy, palette, logo, and UI. The first build is a trustworthy interactive prototype with realistic demo data and locally handled interactions; it is structured so authentication, managed data, and real investment APIs can be added without redesigning the main experience.

## Implementation approach

Use the initialized Expo Router / React Native / TypeScript / NativeWind starter exactly as provided. Keep the existing root providers and runtime plumbing. Build a responsive app shell inside the tabs route group: a desktop/tablet layout uses a left navigation rail and a wider content canvas, while compact view uses Expo tabs with the same content blocks stacked for one-handed use. Use React Native primitives plus `@expo/vector-icons` so the same source renders on native and Expo Web.

Screens:

- **Dashboard**: greeting, last-updated status, total value, invested amount, gain/loss, a simple 6-month portfolio trend visual, pending actions, upcoming SIP, and large quick-action buttons.
- **Investments**: holdings list with readable cards, category filters, total value, and gain/loss with positive/neutral states.
- **Plans**: recurring SIP/STP/SWP cards, next dates, step-up labels, and a clear “Start a new plan” action.
- **Help & profile**: support call/chat shortcuts, readable account summary, notification preferences, and a simple education prompt.

Interaction rules: every major CTA has a visible pressed state and concise feedback. Quick actions open a controlled confirmation sheet/modal rather than silently doing anything. The demo uses a local state toggle for dismissing reminders and showing confirmation copy. Avoid destructive or financial side effects: all investment actions are clearly labeled as demo interactions.

## Design direction

### Style candidates

- Quiet financial wellness / Nordic editorial — probability 0.08.
- Warm civic utility / accessible public-service dashboard — probability 0.06.
- Soft neo-brutalist finance console — probability 0.04.

**Chosen direction: Quiet financial wellness / Nordic editorial.**

### Design movement

A calm, editorial financial-wellness interface: clear paper-like surfaces, generous margins, and restrained data visualization instead of a dense trading terminal.

### Core principles

1. Make the next safe action obvious with plain-language labels.
2. Give important numbers room to breathe and never rely on color alone.
3. Keep repeated patterns predictable for first-time and older users.
4. Use gentle encouragement without promising returns or using urgency.

### Color philosophy

Use a deep evergreen for trust and primary actions, a warm cream canvas for comfort, and a soft mint tint for positive progress. Coral is reserved for attention states, never used as the only signal. Text is near-black for strong contrast; borders are visible but quiet.

### Layout paradigm

A left-aligned reading column with an anchored “money at a glance” panel and staggered content sections. On narrow screens the rail collapses to a bottom navigation and the same sections become a clear vertical reading path.

### Signature elements

- An emerald “S” leaf-mark for the Surgam wordmark.
- Large rounded value cards with a slim vertical accent bar.
- Small sentence-like status labels such as “You are on track” instead of cryptic dashboard badges.

### Interaction and animation

Interactions are explicit and low motion: pressed opacity, short color transitions, and no auto-scrolling. Use haptic tab feedback from the starter on native. Do not animate important financial values or rely on motion to communicate state.

### Typography system

Use the Expo/system sans stack for native consistency. Headings are bold at 28–34px on large screens and 24–28px on compact screens. Body copy is 16–18px with 1.45 line height. Secondary text stays at 14–15px but never carries an essential instruction alone. Tap targets are at least 48px high.

### Brand essence and voice

Surgam is “a calmer way to understand and grow your long-term money plan,” for people who want confidence without complexity. Personality: calm, respectful, encouraging.

Example lines: “Here is your money at a glance.” “You do not need to do everything today.”

### Wordmark and logo

A custom circular emerald mark containing a simple white upward leaf/S path, paired with the Surgam wordmark. The mark is designed as a flat square launcher asset with no baked-in rounded corners so adaptive icons can mask it correctly.

### Signature brand color

Surgam Evergreen `#147D6B`.

## Project structure

- `app/_layout.tsx`: existing providers and route shell; keep runtime initialization intact.
- `app/(tabs)/_layout.tsx`: responsive navigation configuration and tab labels/icons.
- `app/(tabs)/index.tsx`: dashboard composition and demo interaction state.
- `app/(tabs)/investments.tsx`: holdings and category filters.
- `app/(tabs)/plans.tsx`: SIP/STP/SWP plan overview.
- `app/(tabs)/help.tsx`: support, profile, education, and preferences.
- `components/surgam/*`: shared brand header, cards, buttons, trend chart, layout helpers, and modal sheet.
- `constants/theme.ts` / `global.css`: preserve starter compatibility; app-local tokens live in the shared Surgam components for explicit contrast.
- `assets/images/*`: original Surgam launcher, splash, favicon, and adaptive-icon assets.
- `server/*`, `drizzle/*`: preserve the starter backend for future persistence; the first prototype does not invent remote financial data.

## Native/build constraints

Keep the generated Expo identifiers and fixed ports. Set the app name to Surgam, use the original launcher assets, and keep the project ready for Dashboard Android APK/AAB build handoff. Do not claim a built APK until the platform build actually completes.
