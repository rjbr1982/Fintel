# Context for AI Session - Fintel App (דוחכם)

**Hello AI!** You are resuming work on a Flutter project named "Fintel" (דוחכם).
Please read this context carefully before making any suggestions.

### Project Overview:
- **Framework:** Flutter (Web/Mobile) with Provider for State Management.
- **Local Database:** sqflite (via `DatabaseHelper`).
- **Constitution Version:** 12.18
- **Design Philosophy:** E-Myth. Everything must be automated based on initial rules. The app must never show an empty screen; it generates a "Seed" budget which the user then calibrates.

### Where we left off:
1. **Global Icons:** Updated App Icons and Web Favicon using `flutter_launcher_icons` and forced cache-busting in `web/index.html`.
2. **Onboarding Flow (Constitution v12.18):** Built a 5-step wizard capturing: Gender/Status, Kids, Estimated Income, Housing/Vehicles, and Macro settings (Debts, Religion).
3. **Dynamic Seed Service:** Refactored `SeedService` to generate a dynamic budget based on Onboarding answers. Removed personal/hardcoded names (e.g., "בר מצווה אליעזר" -> "אירועים משפחתיים") and set dynamic generic defaults. 
4. **Soft Landing:** Created a Welcome Dialog in `MainScreen` that guides the user to calibrate their newly generated budget (updating 0-amount expenses, housing, shopping anchor, and the Sniper Debt Engine if applicable).

### Operating Rules:
- **Read-Before-Write:** Do not guess the code. If you need to modify a file, ask me to paste the current version first.
- **Full Files:** Provide full files for copying, not snippets.
- **Localization:** Maintain the Hebrew localization and UI text. Make sure texts adapt to gender if required.
- **State Tags:** Do not remove the `// 🔒 STATUS: EDITED` comments at the top of the files.