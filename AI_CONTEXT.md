# AI_CONTEXT.md - Dohaham (Fintel)
**Date:** March 23, 2026
**Current Constitution Version:** 12.82

## 1. Project Overview
"Dohaham" (Fintel) is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite synced to Firebase. The architecture follows a strict "E-Myth" philosophy (Financial Intelligence).

## 2. Recent Major Updates (v12.82 - UI Consistency & Onboarding Refinement)
* **Hamburger Menu Restructuring:** Reordered the main menu to prioritize core screens (PnL -> Shopping -> Savings -> Checking -> Salary). Created a distinct utility section at the bottom, highlighting the "Fintel Academy" with a premium boxed design.
* **Onboarding Screen (Light Theme & Dynamic Text):** Replaced the dark theme with a clean Light Theme (grey.shade50) to align with the brand's UI consistency. Implemented dynamic text rendering to adapt singular/plural pronouns based on both `gender` and `maritalStatus` (e.g., Single users are asked "Do *you* have kids?" instead of "Do *you both* have kids?").
* **Academy Screen (Light Theme):** Transitioned from Deep Slate to a clean Light Theme to maintain visual continuity with the rest of the application, while retaining the premium Amber/Gold accents.

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean, stable, fully secured, and Linter-warning-free (0 issues).

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.