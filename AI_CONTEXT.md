# AI_CONTEXT.md - דוחכם (Dohaham)
**Date:** March 18, 2026
**Current Constitution Version:** 12.81

## 1. Project Overview
"Dohaham" (Fintel) is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Financial Intelligence).

## 2. Recent Major Updates (v12.81 - Freedom Gate Flow)
* **The Freedom Gate (Progressive Disclosure):** Completely revamped the post-onboarding experience.
  - Users are now routed to a "Calibration Mode" in `PnLScreen` featuring a pulsing instructional banner and a FAB to confirm readiness.
  - Implemented a State Machine (`RevealState`) in `MainScreen` to manage the transition: Expectation Screen -> Grand Reveal Animation (Counting up to the Freedom Year with an Emerald glow) -> Dashboard.
  - Added `hasCompletedGrandReveal` flag in `BudgetProvider` (synced to DB) to ensure the reveal only happens once per account/reset.
  - Resolved all Render Flash issues by making the flag check synchronous before the first frame.
* **Zero Warnings Compliance:** Fixed `use_build_context_synchronously` and redundant `const` warnings. Codebase is 100% clean.

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, and Linter-warning-free.

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.