# AI_CONTEXT.md - Dohaham (Fintel)
**Date:** March 18, 2026
**Current Constitution Version:** 12.81

## 1. Project Overview
"Dohaham" (Fintel) is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Financial Intelligence).

## 2. Recent Major Updates (v12.81 - Late Session)
* **Universal Shopping Seed:** Updated `seed_service.dart` to inject a universal, generalized shopping list (e.g., "ביצים" instead of specific quantities) for new users, while preserving the existing macro-categories for filtering.
* **Sinking Funds Bank Control (Traffic Light):** Added `actualBankDeposit` to `expense_model.dart`. The Sinking Funds screen now cross-references the app's calculated monthly allocation against the actual bank standing order. Any discrepancy triggers a visual warning ("נדרש עדכון בבנק") and allows in-place editing of the bank deposit value via bottom sheets.
* **Zero Warnings Compliance:** Maintained 100% clean codebase. 

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, and Linter-warning-free.

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.