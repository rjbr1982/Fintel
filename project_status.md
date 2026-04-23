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
* **2026-04:** *Exempt Dealer Ledger (Premium):* Created `exempt_dealer_screen.dart` and upgraded `BusinessSubItem` model with `date`, `tag`, and `receiptNumber`. This allows generating a formatted accounting report for exempt dealers directly to the clipboard.
* **2026-04:** *Optimistic UI for Sinking Funds:* Removed `await` from Firebase write operations (`saveSetting`, `insertPlannedWithdrawal`, `updatePlannedWithdrawal`) in `smart_withdrawals_screen.dart` and `budget_provider.dart` (Fire & Forget protocol). This prevents the UI from hanging indefinitely during offline or flaky network states.
* **2026-04:** *Playground Integration Phase:* Ported critical sandbox features to main project.
  * **Admin Double Lock:** `isCurrentUserAdmin()` now checks both Firebase Auth AND the isolated `admins` collection.
  * **Bulletproof Legal UI:** Merged terms and privacy into a single `_showUnifiedConsentDialog`.
  * **Code-Based L10n:** Implemented English (`en`) dictionary alongside Hebrew (`he`).
* **2026-04:** *Zero Warnings Enforcement:* Stripped all `dead_null_aware_expression` and `unnecessary_non_null_assertion` flags from UI screens.
* **2026-04:** *Sinking-Growth Asset (חיסגור):* Added `isPcfAccumulator` toggle to Assets. When active, the auto-rollover mechanism deposits the monthly PCF directly into the asset's balance.