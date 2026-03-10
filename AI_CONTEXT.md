# AI_CONTEXT.md - דוחכם (Dohaham)
**Date:** March 10, 2026
**Current Constitution Version:** 12.50

## 1. Project Overview
"Dohaham" is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite (via `DatabaseHelper`). The architecture follows a strict "E-Myth" philosophy (Fintel - Financial Intelligence), meaning the app does the heavy lifting, calculating percentages, sinking funds (קופות מאוחדות/ייעודיות), and auto-generating categories based on the user's family status.

## 2. Recent Major Updates (v12.50)
* **PWA & Freemium:** The app is now defined as a Progressive Web App (PWA). Added a `PremiumService` to lock certain features behind a paywall (represented by a 👑 icon).
* **The Family State Machine:** We removed manual toggles for "Husband/Wife/Kids". Instead, the app relies purely on `maritalStatus` (single/married), `gender` (male/female), and `childCount`.
* **Smart Naming Convention:**
  * Single + 0 kids = 'אישי' (Personal).
  * Single + kids = 'אבא' or 'אמא' (Based on gender).
  * Married + 0 kids = 'בעל' and 'אישה'.
  * Married + kids = 'אבא' and 'אמא'.
* **Smart Entertainment Traffic Light:** The "Entertainment" (בילויים) budget box dynamically sets its warning/success limits based on whether the user is single (80/250) or married (150/500), with an option for manual override.

## 3. UNRESOLVED ISSUES (Priority for this Session)
We attempted to implement a "Garbage Collection" mechanism (`_forceCategorySync` inside `budget_provider.dart`) to clean up old categories when the user changes their family status, but it is currently buggy and causing cascading deletions:
1. **Gender Switching Bug:** If a Single Female (with 'אישי' including 'טיפוח') switches to Single Male, the 'טיפוח' (Grooming) sub-category is not deleted.
2. **Marriage Switching Bug:** When switching from Single to Married, the system fails to create the 'בעל' (Husband) entity properly, and deletes almost all sub-categories leaving only 'בגדים אישי'.
3. **Child Addition Bug:** When adding a child, the system aggressively deletes almost ALL variable categories (משתנות), leaving only the anchor category 'קניות' (Shopping).
*Root Cause Suspicion:* There is a severe race condition or logical flaw in `_forceCategorySync` and `_getDynamicVariableRatios` within `budget_provider.dart`. The provider receives updates from DB streams, causing infinite loops or premature deletions while the state machine is trying to rename/create categories.

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume the content of a file. ALWAYS ask the user to paste the current version of the file before you modify it.
* **No Speculation:** If the logic for the State Machine isn't working, analyze `budget_provider.dart` surgically and explain the flaw before dumping new code.