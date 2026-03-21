# AI_CONTEXT.md - Dohaham (Fintel)
**Date:** March 22, 2026
**Current Constitution Version:** 12.81

## 1. Project Overview
"Dohaham" (Fintel) is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Financial Intelligence).

## 2. Recent Major Updates (v12.81 - Security & UI Precision)
* **Firestore Security Lockdown (Level 2):** Successfully executed a one-time data migration script to inject `ownerId` into all existing Firebase documents. Upgraded Firestore Security Rules to strictly enforce `request.auth.uid == userId`, closing the 30-day Test Mode vulnerability and complying with Constitution Section 5.10.5.
* **Sinking Funds Bank Control (Precision Fix):** Enhanced the bank deposit discrepancy check in `sinking_funds_screen.dart` and `category_drilldown_screen.dart`. Implemented explicit `.round()` logic prior to comparing Expected vs. Actual deposits to eliminate floating-point precision false warnings.
* **UI Contrast & Theming:** Fixed a critical contrast bug where white text disappeared on white BottomSheets by enforcing `ThemeData.light()`.
* **Dashboard Clean-up:** Removed redundant Shopping FAB and consolidated navigation into central Quick Action pills.

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, fully secured, and Linter-warning-free (`flutter analyze` returns 0 issues).

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.