# AI_CONTEXT.md - דוחכם (Dohaham)
**Date:** March 11, 2026
**Current Constitution Version:** 12.70

## 1. Project Overview
"Dohaham" is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite (via `DatabaseHelper`). The architecture follows a strict "E-Myth" philosophy (Fintel - Financial Intelligence).

## 2. Recent Major Updates (v12.70)
* **Smart App Bootstrapper:** Re-architected `main.dart` with a 3-stage gate (Pre-login splash -> Login -> Post-login auth screen). Uses `AppGlobals` to track session state, allowing seamless 1-second transitions when navigating back to home, while preserving the 2.5s branding duration on cold boots.
* **Graceful Biometrics:** Added `local_auth`. A fingerprint toggle in settings is conditionally rendered (hidden on Web, active on APK). The Bootstrapper intercepts login to demand biometric auth if enabled.
* **Deep Sign-Out & Session Reset:** Fixed Google Sign-In cache issue by forcing `prompt: 'select_account'` and executing deep `disconnect()` on logout, alongside resetting `AppGlobals.hasAuthenticatedSession`.
* **Shopping Auto-Seed:** Added logic to `shopping_provider.dart` to automatically fetch and seed the default 100+ items catalog if the user's database returns 0 items.
* **Zero Warnings Compliance:** Fixed flow control curly braces and deprecated properties (e.g., `activeThumbColor`) to maintain a clean terminal.

## 3. UNRESOLVED ISSUES (Priority for this Session)
* None active. Await user instructions.

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume the content of a file. ALWAYS ask the user to paste the current version of the file before modifying it (Constitution 0.10).
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings or infos.
* **Graceful Degradation:** Features requiring Native APIs (like biometrics) must be wrapped in `kIsWeb` checks so the Web PWA remains unaffected.