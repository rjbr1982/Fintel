# AI_CONTEXT.md - Dohaham (Fintel)
**Date:** March 24, 2026
**Current Constitution Version:** 12.83

## 1. Project Overview
"Dohaham" (Fintel) is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Financial Intelligence).

## 2. Recent Major Updates (v12.83 - Infinity State & UI Polish)
* **Infinity State Handling (Section 4.18.3.ה):** Fully implemented a graceful fallback for zero/negative PCF scenarios in the Freedom Gate flow. The system now displays an animated infinity symbol (∞) with an empowering call to action before auto-routing to the dashboard.
* **Academy Screen Redesign:** Replaced the basic expansion list with an "Active Content View" architecture. A horizontal scrolling ChoiceChip bar now controls the visible chapter, with smooth fade transitions.
* **Shopping Search UI:** Enhanced the search bar in the shopping list with better contrast, a subtle shadow, and a prominent blue icon.

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, fully secured, and Linter-warning-free (0 issues).

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.