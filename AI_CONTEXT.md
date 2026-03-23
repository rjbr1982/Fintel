# AI_CONTEXT.md - Dohaham (Fintel)
**Date:** March 23, 2026
**Current Constitution Version:** 12.81

## 1. Project Overview
"Dohaham" (Fintel) is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Financial Intelligence).

## 2. Recent Major Updates (v12.81 - Academy & Contextual Onboarding)
* **Premium Academy Hub:** Implemented the "Fintel Academy" screen (`academy_screen.dart`) using a modular architecture. Content is decoupled from the UI via `academy_content.dart` utilizing a custom `AcademyBlock` structure for easy maintenance and zero UI clutter.
* **Contextual Onboarding:** Replaced standard tooltips with accessible `AlertDialog` info-popups across the app (Entertainment Traffic Light, Passive Asset Formula, Bank Withdrawal Station) to accommodate mobile UX and ADHD readability requirements.
* **Zero Warnings Verification:** All new features and string escaping issues were rigorously tested and resolved to strictly pass `flutter analyze` with 0 issues.

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, fully secured, and Linter-warning-free.

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.