# Context for AI Session - Fintel App (דוחכם)

**Hello AI!** You are resuming work on the "Fintel" (דוחכם) project architecture.

### Where we left off:
1. Implemented the "Contextual Onboarding" (המדריך השקט) system across 5 main screens (`category_drilldown_screen`, `salary_engine_screen`, `reducing_screen`, `shopping_screen`, `assets_screen`) using native, non-intrusive UI elements.
2. Fixed the "disappearing first asset" UI bug in `assets_screen.dart` by converting it to a StatefulWidget and fetching data explicitly on init.
3. Implemented a centralized Chronological Sorting Engine in `BudgetProvider` to automatically sort family members and kids' expenses by age (oldest to youngest) across the entire app.
4. **Fixed Mobile UI in Shopping Screen:** Resolved an issue where the "Apply Sort" button in the Advanced Sorting BottomSheet was inaccessible on mobile devices by making the sheet scroll-controlled and layout-constrained.
5. **Fixed Vehicle Sinking Funds Bug:** Corrected the logic to ensure all vehicle expenses (excluding strictly 'דלק' and 'ליסינג') are forced to act as Sinking Funds (`isSinking = true`). Furthermore, updated `category_drilldown_screen.dart` to properly aggregate and display the monthly sinking deposit amount within the vehicle unified fund card.
6. Codebase remains clean with zero Linter warnings (Zero Warnings Policy enforced).

### Next Steps:
Await explicit instructions from Rafael. Proceeding with the next items on the WhatsApp fix-list or End-to-End testing.

### Constitution Status:
Up to date (v12.20). סטטוס חוקה: תואמת לקוד (לא נדרשים שינויים בסשן זה).