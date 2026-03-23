# AI_CONTEXT.md - Dohaham (Fintel)
**Date:** March 23, 2026
**Current Constitution Version:** 12.82

## 1. Project Overview
"Dohaham" (Fintel) is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Financial Intelligence).

## 2. Recent Major Updates (v12.82 - Shopping UI & Dynamic Seed)
* **Shopping Screen Overhaul:** Replaced local app bar with `GlobalHeader` for brand consistency. Added a local Search Bar (magnifying glass) and rearranged action buttons (Zoom, Cart) below the budget card.
* **Shopping Sort Persistence:** Integrated `shared_preferences` to persist multi-level sorting choices across app sessions.
* **Frequency/History Bug Fix:** Fixed a bug where items purchased with a 0-week offset ("This Week") did not show the visual "Purchased" tag. Added Israeli calendar week alignment (Sunday start).
* **Dynamic Seed Delta:** Refactored `SeedService` to mathematically calculate the theoretical shopping basket cost based on marital status and children count. The Variable Expense "Shopping Anchor" is now strictly set to Basket Cost + 200 ILS to ensure a positive delta default.

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, fully secured, and Linter-warning-free (0 issues).

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.