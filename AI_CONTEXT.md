# AI_CONTEXT.md - Dohaham (Fintel)
**Date:** March 24, 2026
**Current Constitution Version:** 12.82

## 1. Project Overview
"Dohaham" (Fintel) is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Financial Intelligence).

## 2. Recent Major Updates (v12.82 - Academy Refinement & UI Polish)
* **Academy Screen Redesign:** Replaced the basic expansion list with an "Active Content View" architecture. A horizontal scrolling ChoiceChip bar now controls the visible chapter, with smooth fade transitions, saving vertical space on mobile devices.
* **Academy Content Rationalization:** Rewrote the introduction to remove illogical marketing cliches (e.g., the "surprise" of needing data to calculate freedom). The text now strictly focuses on mathematical reality, Parkinson's Law, and the concept of the "objective mirror."
* **Shopping Search UI:** Enhanced the search bar in the shopping list with better contrast, a subtle shadow, and a prominent blue icon to prevent it from blending into the Light Theme background.

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, fully secured, and Linter-warning-free (0 issues).

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.