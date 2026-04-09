# Fintel - AI Context & Architecture Guidelines

## 1. Project Overview
**Name:** Fintel (דוחכם)
**Core Concept:** Financial Intelligence application based on the Dohaham methodology.
**Current Phase:** Gamma (Pre-launch/Production testing).
**Environments:** `fintel_playground` (Sandbox/Dev), `dohaham` (Production).

## 2. Recent Architectural Updates (April 2026)
* **Premium Visual Assets:** Transitioned from text/emoji-based premium indicators to custom PNG assets.
    * `assets/icon/fintel_icon.png`: Default app icon (Free users).
    * `assets/icon/premium_icon.png`: Crowned app icon (Premium users/Paywall).
    * `assets/icon/crown_icon.png`: Inline premium feature indicator.
    * `assets/icon/fintel_pro_banner.jpg`: Paywall top banner.
    * *Rule:* Declared globally in `pubspec.yaml` as `- assets/icon/` to avoid case-sensitivity and specific file mapping issues.
* **Dynamic UI Sizing Rule:** The `premium_icon.png` in the `GlobalHeader` requires a hardcoded size of **48px** (Width/Height) to offset its internal transparent padding and match the visual footprint of the standard 28px icon.
* **Reactive State Management:** `PremiumService` now utilizes a `ValueNotifier<int> (stateNotifier)` to broadcast premium status changes (including Developer Force Free Mode toggles). `GlobalHeader` is Stateful and listens to this notifier for instant, flicker-free UI updates.
* **Freemium Strategy Refinement:** The "Reducing Expenses" (מנמיכות) screen is now accessible to Free users to input basic debts. However, the high-value "Sniper Box" (קופת צלף) and "Time Machine" features are locked behind an embedded Premium Teaser Card.
* **Unified Dialogs:** The `_showFreedomSettingsDialog` is unified and identical across `main_screen.dart` and `pnl_screen.dart`, including the explicit note that initial capital is pulled automatically from the Assets Screen.
* **Hybrid Billing Engine:** Currently uses placeholder URLs (`example.com`). Awaiting real integration (Meshulam for Web, RevenueCat for Mobile).

## 3. Strict Coding Policies
* **Zero Warnings:** Code must pass `flutter analyze` with 0 issues. Unused imports or variables are strictly prohibited.
* **Deployment Protocol:** Production UI/Client updates are deployed using `firebase deploy --only hosting` to protect backend security rules and functions from accidental overwrites.
* **State Updates:** Use `context.watch` for UI rebuilding and `context.read` for executing functions inside callbacks.