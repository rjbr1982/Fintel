# Project Status - Dohaham (דוחכם)
**Version:** Constitution 12.50
**Last Updated:** March 2026

## ✅ What is Working Perfectly
* **Onboarding Flow:** Fully functional. Captures gender, marital status, children, and income. Saves correctly to the database via `SeedService`.
* **Database & Architecture:** SQLite backend is stable. Provider structure is solid.
* **PWA Configuration:** App is ready for web deployment without desktop security warnings.
* **Premium Model:** UI accurately reflects locked features with the golden crown (👑) and `PremiumService` wrapper.
* **Global Settings UI:** The settings menu effectively uses `SegmentedButton` to manage family status dynamically, with a clean UI.

## 🚧 Work In Progress (Bugs to Fix)
* **The "State Machine" Deletion Bug:** The dynamic budget allocation in the Variable Expenses (משתנות) breaks when the user alters their family status in the settings.
  * *Symptom 1:* Changing gender doesn't clean up gender-specific categories (like grooming for women).
  * *Symptom 2:* Adding a child or changing to 'Married' triggers an aggressive database cleanup that wipes out essential budget categories, leaving only the Shopping (קניות) anchor.
* **Root Cause:** `_forceCategorySync` inside `budget_provider.dart` needs a complete logical overhaul to safely sync the UI names (Husband/Wife vs Mom/Dad vs Personal) with the database without triggering destructive Race Conditions via the active StreamListeners.

## 🎯 Next Steps for Next Session
1. Provide the AI with `lib/providers/budget_provider.dart`.
2. Ask the AI to specifically fix the `_forceCategorySync` and `_getDynamicVariableRatios` methods so they handle status transitions flawlessly according to Constitution section 4.8.4.
3. Test transitions: Single (F) -> Married -> Add Child -> Delete Child -> Single (M).