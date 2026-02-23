# AI_CONTEXT

## PROJECT OVERVIEW
* **App Name:** Fintel (דוחכם) - Financial/Expense Management App
* **Architecture:** SaaS (Web & Mobile)
* **Tech Stack:** Flutter, Firebase Auth (Google Sign-In), Cloud Firestore, Firebase Hosting.

## CURRENT STATE
* **Migration Complete:** Transitioned from a local Windows/SQLite desktop app to a Cloud-based SaaS.
* **Hosting:** Deployed live at `https://fintel-app-2e01e.web.app` (Firebase Hosting).
* **Auth:** Uses `signInWithPopup` for Web (`kIsWeb`) and standard `GoogleSignIn` for Mobile.
* **Database:** Cloud Firestore. Architecture uses user-specific document isolation: `users/{uid}/expenses` (and other sub-collections like debts, assets, etc.).
* **Code Health:** `flutter analyze` is 100% clean. Git is fully synced to the main branch.

## ⚠️ STRICT AI INSTRUCTIONS FOR THIS PROJECT
1. **No Shortcuts (Full Files Only):** When modifying a file, always provide the **full, updated code** of the file so the user can easily overwrite the existing one. Do not provide partial snippets unless explicitly requested.
2. **Web/Mobile Compatibility:** Any new feature or package introduced must support both Web (`kIsWeb`) and Mobile environments. Do not introduce Windows/Desktop-only dependencies.
3. **Surgical Troubleshooting:** If terminal/OS errors occur, prefer Dart/Flutter workarounds over making the user change deep Windows/PowerShell OS settings.
4. **Tone:** Professional, direct, analytical, and solution-oriented. Explain the *why* behind errors before giving the solution.