# AI_CONTEXT.md - Dohaham (Fintel)
**Date:** March 22, 2026
**Current Constitution Version:** 12.81

## 1. Project Overview
"Dohaham" (Fintel) is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Financial Intelligence).

## 2. Recent Major Updates (v12.81 - UI & Precision Fixes Session)
* **Sinking Funds Bank Control (Precision Fix):** Enhanced the bank deposit discrepancy check in `sinking_funds_screen.dart` and `category_drilldown_screen.dart`. Implemented explicit `.round()` logic prior to comparing Expected vs. Actual deposits to eliminate floating-point precision false warnings (the "Gap 0" bug). Included Expected deposits in the UI for a clearer UX anchor.
* **UI Contrast & Theming:** Fixed a critical contrast bug where white text disappeared on white BottomSheets. Enforced `ThemeData.light()` and explicit `Colors.black87` styling on all inputs and dialogs in the Sinking Funds, Drilldown, and Checking History screens.
* **Dashboard & Navigation Overhaul:** Reorganized the `GlobalHeader` Hamburger menu for a cleaner, logical flow without empty spaces. Streamlined the Dashboard (`main_screen.dart`) by removing the redundant Shopping FAB and focusing the Quick Action pills strictly on "Sinking Funds" and "Shopping List".

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, and Linter-warning-free (`flutter analyze` returns 0 issues).

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.