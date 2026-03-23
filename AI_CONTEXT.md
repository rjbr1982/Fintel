# AI_CONTEXT.md - Dohaham (Fintel)
**Date:** March 23, 2026
**Current Constitution Version:** 12.82

## 1. Project Overview
"Dohaham" (Fintel) is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Financial Intelligence).

## 2. Recent Major Updates (v12.82 - Contextual Onboarding & UI Standardization)
* **The 11 Signposts (Contextual Onboarding):** Fully implemented Section 5.12. Removed all static explanatory banners across the app (PnL, Shopping, Sinking Funds, Assets, Reducing, Salary Engine) and replaced them with a uniform `_showInfoDialog` triggered by discreet `info_outline` icons.
* **Menu UI Standardization:** Refactored the Settings Bottom Sheet to share the exact same `_buildMenuTile` UI component as the Main Menu for pixel-perfect brand consistency.
* **WhatsApp Integration:** Added a direct WhatsApp support button to the Support & Legal menu, handling fallbacks (copy to clipboard) gracefully.
* **Async Dialog Fixes:** Resolved an issue where Sinking Fund dialogs wouldn't close after a database save by capturing the `Navigator` before the `await` gap and utilizing `try-finally` blocks.

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, fully secured, and Linter-warning-free (0 issues).

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.