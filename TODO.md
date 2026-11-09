# Surgam delivery TODO

## Responsive Surgam shell and navigation

- [x] Replace the starter welcome screen with a clean Surgam shell that works on desktop/tablet and mobile.
- [x] Use a left navigation rail on wide screens and a bottom navigation on compact screens.
- [x] Keep labels plain and readable, use strong contrast, keep tap targets at least 48px, and avoid dense technical tables.
- [x] Rebrand the app as Surgam with original visual assets, copy, palette, and a distinct mark; do not reuse the reference app's code, logo, screenshots, or store copy.

## Dashboard and portfolio snapshot

- [x] Show a dashboard snapshot of investments with total value, invested amount, today’s movement, and total gain/loss.
- [x] Show a readable portfolio trend visual and a short sentence explaining the current status.
- [x] Show pending transactions and upcoming SIP/STP/SWP items in scannable cards.
- [x] Provide large, clearly named actions for Add money, Withdraw, Move money, and View reports.
- [x] Make demo actions show clear confirmation feedback and avoid implying a real trade was submitted.

## Investments and reports

- [x] Provide an Investments screen with holdings that can be scanned without horizontal scrolling.
- [x] Show valuation and gain/loss at holding level with text and visual cues.
- [x] Provide simple category filters and an all-investments view.
- [x] Keep report entry points for valuation and gain/loss information easy to find.

## SIP, STP, SWP, and advanced plan flows

- [x] Provide a Plans screen covering SIP, STP, and SWP with next dates and amounts.
- [x] Show step-up SIP status in plain language.
- [x] Provide a clear Start a new plan action and a safe demo confirmation state.
- [x] Keep the information architecture ready for one-time mandate, purchase/switch triggers, and future real integrations without adding confusing technical controls.

## Help, profile, and trust cues

- [x] Provide a Help & profile screen with support contact actions, account summary, notification preferences, and a short learning prompt.
- [x] Use calm, respectful copy for non-technical and elderly users.
- [x] Include an updated/last-synced cue and avoid return promises or urgency language.

## Mobile build readiness

- [x] Replace starter native icon, splash, favicon, and Android adaptive-icon assets with the original Surgam mark.
- [x] Preserve the fixed Expo/Metro port configuration and generated Android package identifier.
- [x] Run TypeScript diagnostics, lint, and the available tests after implementation.
- [x] Run the managed preview and inspect representative desktop and mobile layouts.
- [x] Leave the accepted source/configuration ready for a Dashboard Android APK/AAB build handoff; do not claim an APK until that build succeeds.
