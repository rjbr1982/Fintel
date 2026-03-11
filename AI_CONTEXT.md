# AI_CONTEXT.md - דוחכם (Dohaham)
**Date:** March 10, 2026
**Current Constitution Version:** 12.70

## 1. Project Overview
"Dohaham" is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite (via `DatabaseHelper`). The architecture follows a strict "E-Myth" philosophy (Fintel - Financial Intelligence).

## 2. Recent Major Updates (v12.70)
* **Smart App Bootstrapper:** Re-architected `main.dart` with a 3-stage gate (Pre-login splash -> Login -> Post-login auth screen). Uses `AppGlobals` to track session state, allowing seamless 1-second transitions when navigating back to home, while preserving the 2.5s branding duration on cold boots.
* **Graceful Biometrics:** Added `local_auth`. A fingerprint toggle in settings is conditionally rendered (hidden on Web, active on APK). The Bootstrapper intercepts login to demand biometric auth if enabled.
* **Deep Sign-Out:** Fixed Google Sign-In cache issue by forcing `prompt: 'select_account'` and executing deep `disconnect()` on logout.
* **Shopping Exact Dates:** Replaced retroactive weekly offsets with an exact Date Picker (Yesterday, 2 days ago, Custom Calendar) for precise frequency violation tracking.
* **Unified Funds 3 Modes:** Users can now toggle parent categories (like kids, cars, holidays) between Mode 0 (Separate), Mode 1 (Unified Only), and Mode 2 (Combined). 

## 3. UNRESOLVED ISSUES (Priority for this Session)
* None active. Await user instructions.

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume the content of a file. ALWAYS ask the user to paste the current version of the file before you modify it.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings or infos (e.g., handling deprecations immediately).