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
* **2026-04:** *Exempt Dealer Ledger (Premium):* Created `exempt_dealer_screen.dart` and upgraded `BusinessSubItem` model with `date`, `tag`, and `receiptNumber`. UI contrast issues fixed. Pending integration into the Incomes drilldown screen.
* **2026-04:** *UI & UX Polish:* Added a "PRO" badge for premium users in the global header. Replaced fixed Column with `SingleChildScrollView` in the hamburger menu to fix overflow issues. Added historical purchase viewer to the shopping list.
* **2026-04:** *Optimistic UI for Sinking Funds:* Removed `await` from Firebase write operations (`saveSetting`, `insertPlannedWithdrawal`, `updatePlannedWithdrawal`) in `smart_withdrawals_screen.dart` and `budget_provider.dart` (Fire & Forget protocol).
* **2026-04:** *Playground Integration Phase:* Ported critical sandbox features to main project (Admin Double Lock, Bulletproof Legal UI, Code-Based L10n).
* **2026-04:** *Zero Warnings Enforcement:* Stripped all `dead_null_aware_expression` and `unnecessary_non_null_assertion` flags from UI screens.
* **2026-04:** *Sinking-Growth Asset (חיסגור):* Added `isPcfAccumulator` toggle to Assets.