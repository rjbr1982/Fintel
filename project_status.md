# project_status.md

## Current State
*   **Codebase:** (Awaiting next sync command to capture current file tree and linter status).
*   **Constitution:** Version 12.91.
*   **Key Systems:**
    *   Authentication: Firebase (Google Sign-In)
    *   Database: Firebase Firestore (with offline support/local cache)
    *   Hosting: Firebase Hosting (Web PWA)

## Strategic Decision Log
*   **[2026-05-03] Financial Logic Implementation:** Integrated "The Buffer" (target = 1 month income), "The Bunker" (target = 3 months income), and "The Sweep Ritual" (active surplus management) into the `CheckingHistoryScreen` and `BudgetProvider`. Emphasized that investments continue concurrently and do not wait for the Bunker to fill. Updated the in-app Academy (Section 8.4) to explain these concepts.
*   **[2026-05-03] Feature Categorization Update:** Clarified in the Constitution (v12.90) that "Auto-Rollover" and "Sinking Funds" are fundamental, free features available to all users. Removed them from the list of premium features to prevent future development errors regarding access control.
*   **[Previous Decisions]**: (Maintain history of previous strategic shifts here, e.g., the move to a unified UI, the introduction of the Anchor & Remainder model, etc.)