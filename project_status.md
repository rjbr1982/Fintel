# project_status.md

## Current State
* **Release Status:** Version 1.0.0 (AAB) uploaded to Google Play Console. Awaiting final rollout to Closed Testing track upon tester email list completion.
* **Codebase:** Sync updated on May 13, 2026. Key recent changes include `android/app/build.gradle.kts` (Keystore integration), `MainActivity.kt` (Namespace update), `google-services.json` (New Firebase client ID), and `notification_service.dart` (updated timezone handling).
* **Constitution:** Version 12.91.
* **Key Systems:**
    * Authentication: Firebase (Google Sign-In)
    * Database: Firebase Firestore (with offline support/local cache)
    * Hosting: Firebase Hosting (Web PWA) & Google Play Store (Android Native)

## Strategic Decision Log
* **[2026-05-13] Google Play Deployment & Build Configuration:** Transitioned project to production-ready status. Changed Android application ID/namespace to `com.myfintelapp.app` to comply with Google Play Console registration. Registered new Android client in Firebase and synchronized `google-services.json`. Upgraded outdated dependencies (`flutter_timezone`) to pass Kotlin 17 strict compilation. Successfully built and uploaded the first signed release App Bundle (.aab).
* **[2026-05-03] Financial Logic Implementation:** Integrated "The Buffer" (target = 1 month income), "The Bunker" (target = 3 months income), and "The Sweep Ritual" (active surplus management) into the `CheckingHistoryScreen` and `BudgetProvider`. Emphasized that investments continue concurrently and do not wait for the Bunker to fill. Updated the in-app Academy (Section 8.4) to explain these concepts.
* **[2026-05-03] Feature Categorization Update:** Clarified in the Constitution (v12.90) that "Auto-Rollover" and "Sinking Funds" are fundamental, free features available to all users. Removed them from the list of premium features to prevent future development errors regarding access control.
* **[Previous Decisions]**: (Maintain history of previous strategic shifts here, e.g., the move to a unified UI, the introduction of the Anchor & Remainder model, etc.)