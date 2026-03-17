# AI_CONTEXT.md - דוחכם (Dohaham)
**Date:** March 17, 2026
**Current Constitution Version:** 12.80

## 1. Project Overview
"Dohaham" is a smart family budget management application designed for Israeli users. It uses Flutter, Provider for state management, and local SQLite. The architecture follows a strict "E-Myth" philosophy (Fintel - Financial Intelligence).

## 2. Recent Major Updates (v12.80 - UI & Auth Polish)
* **Robust Google Auth:** Rewrote `login_screen.dart` to bypass `firebase_ui_auth` internal profile screens. Implemented a strict "Deep Sign-Out" protocol clearing both Firebase and Google SignIn tokens to prevent session ghosting.
* **UI Cleanups (Premium Light Theme):** Fixed invisible/light text issues in the Settings bottom sheets and entry dialogs by explicitly defining `Colors.black87`.
* **Sinking Funds Refinement:** Removed hardcoded debugging texts (e.g., "דינמיות") from the unified funds category titles.
* **Checking History Polish:** Updated the Empty State instructional text to be more precise (suggesting the 20th of the month) and fixed text visibility in the "Add Entry" dialog.
* **Zero Warnings Compliance:** Maintained a clean `flutter analyze` state across all modified files.

## 3. UNRESOLVED ISSUES
* None. The infrastructure is clean and stable.

## 4. Strict Protocols for AI
* **Read-Before-Write:** NEVER rewrite or assume file content. ALWAYS ask for the current version before modifying.
* **Zero Warnings Policy:** All code must pass `flutter analyze` without any warnings.
* **Graceful Degradation:** Use `kIsWeb` for native-specific features (Biometrics, etc.).