# Context for AI Session - Fintel App (דוחכם)

**Hello AI!** You are resuming work on the "Fintel" (דוחכם) project architecture.

### Where we left off:
1. Implemented the "Contextual Onboarding" (המדריך השקט) system across 5 main screens.
2. Implemented a centralized Chronological Sorting Engine in `BudgetProvider`.
3. **Fixed Mobile UI in Shopping Screen:** Resolved an issue where the "Apply Sort" button in the Advanced Sorting BottomSheet was inaccessible on mobile devices.
4. **Refined Vehicle Sinking Funds Logic & UI:** - Enforced a blacklist approach in `BudgetProvider` ensuring all vehicle expenses default to Sinking Funds, except for immediate usage expenses ('דלק', 'ליסינג').
   - Updated `sinking_funds_screen.dart` to aggregate all vehicles into a single Unified Fund.
   - Updated `category_drilldown_screen.dart` to allow safe creation and editing of custom vehicle expenses (e.g., adding a specific tag like "(מאזדה 3)" seamlessly in the background).
5. Codebase remains clean with zero Linter warnings (Zero Warnings Policy enforced).

### Next Steps:
Await explicit instructions from Rafael. Proceeding with the next items on the WhatsApp fix-list or End-to-End testing.

### Constitution Status:
Up to date (v12.20). סטטוס חוקה: תואמת לקוד (לא נדרשים שינויים בסשן זה).