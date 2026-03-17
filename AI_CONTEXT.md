# AI_CONTEXT.md - דוחכם (Dohaham)
**Date:** March 17, 2026
**Current Constitution Version:** 12.80

## 1. Project Overview
"Dohaham" is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Fintel - Financial Intelligence).

## 2. Recent Major Updates (v12.80 - Sync, Terminology & Smart Withdrawals)
* **Cloud Sync Fix:** Fixed a bug in `BudgetProvider` where `SalaryRecords` were not fetched during initial load, ensuring cross-device data continuity.
* **Terminology Alignment:** Standardized names across UI: 'ממוצע שכר' (Salary Engine), 'מעקב עו"ש' (Checking History), and 'מנמיכות' (Reducing/Debts).
* **Smart Withdrawal Manager (Complete Feature):**
  - Added `PlannedWithdrawal` model and CRUD operations in `DatabaseHelper`.
  - Implemented aggregation and execution logic (`executePlannedWithdrawalsForBucket`) in `BudgetProvider`.
  - Created `smart_withdrawals_screen.dart` with chronologically sorted cards, interactive date picking, and execution dialogs.
  - Fixed Material 3 TextField styling issues inside Dialogs (forced borders and background colors).
  - Connected the feature to the entry banner in `sinking_funds_screen.dart`.
* **Zero Warnings Compliance:** Fixed String interpolation and cleaned up Linter TODO warnings.

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, and Linter-warning-free.

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.