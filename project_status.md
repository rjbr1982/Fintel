# Project Status: Fintel (dohaham)

## 1. Current State (תמונת מצב טכנית)
* **Framework:** Flutter (Web/PWA & Android Native targeted).
* **Architecture:** Provider (State Management), Firebase (Auth + Firestore).
* **Core Modules:**
  - `BudgetProvider`: Manages PnL, Sinking Funds, Categories (5 Pillars), Freedom Engine.
  - `DebtProvider`: Manages Snowball/Sniper algorithm and historical payoffs.
  - `AssetProvider`: Manages Asset Portfolio and passive income calculations.
  - `AdminService`: Centralized Admin God-Mode with double-lock security.
* **Localization:** Custom Code-Based Map (`AppLocalizations`) supporting 'he' and 'en'.
* **Linter Status:** Zero Warnings (Strict enforcement).

## 2. Strategic Decision Log (יומן החלטות אסטרטגיות)
* **2026-04:** *Playground Integration Phase:* Ported critical sandbox features to main project.
  * **Admin Double Lock:** `isCurrentUserAdmin()` now checks both Firebase Auth AND the isolated `admins` collection, ensuring secure server-side validation even if UI triggers are bypassed.
  * **Bulletproof Legal UI:** Merged terms and privacy into a single `_showUnifiedConsentDialog` with a hardcoded `350px` height `Scrollbar` inside a `PopScope` to prevent rendering crashes on mobile/web.
  * **Code-Based L10n:** Implemented English (`en`) dictionary alongside Hebrew (`he`). Changed `AppLocalizations.of(context)` to return a non-nullable object, ensuring downstream UI components don't require `?.` or fallback operators (`??`).
* **2026-04:** *Zero Warnings Enforcement:* Stripped all `dead_null_aware_expression` and `unnecessary_non_null_assertion` flags from UI screens.
* **2026-04:** *Sinking-Growth Asset (חיסגור):* Added `isPcfAccumulator` toggle to Assets. When active, the auto-rollover mechanism deposits the monthly PCF directly into the asset's balance.
* **2026-04:** *UI & Flow Refinements:*
  * **Per-Child Unified Mode:** Moved the Unified Sinking Fund 3-dot menu from the "Children" parent level to each child's individual ExpansionTile in `category_drilldown_screen.dart` to allow independent mode configuration (0/1/2).
  * **Grand Reveal Hard-Lock:** Modified `main_screen.dart` to make the `RevealState` strictly reactive to the `hasCompletedGrandReveal` flag, preventing users from bypassing the animation via the hardware back button and entering a broken UI state.