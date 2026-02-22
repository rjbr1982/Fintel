# Project Status: Fintel (Dohaham)
**Last Update:** 2026-02-21
**Constitution Version:** 12.6

## 📋 Current State
- **Sinking Funds (הוצאות צוברות):** Expanded coverage to Car, Kids, Holidays, and Media. Auto-rollover calculates active months and multipliers (kids) automatically.
- **Withdrawals Engine:** Full CRUD for `withdrawals` table. Users can record spending from accumulated funds with notes and delete history to restore balance.
- **Shopping Multi-Level Sort:** Advanced priority-based sorting (Drag & Drop). Fixed UI visibility and contrast issues in Dark/Light themes.
- **Debt Schedule Matrix:** Horizontal synchronized scrolling implemented for the entire list, ensuring years and months align perfectly in a spreadsheet-like view.
- **Annual Sums Visibility:** All expense drills now show "Annual Accumulated" (x12) alongside monthly amounts.
- **Code Health:** Zero Linter warnings (Zero Warnings Policy active).

## 🛠 Strategic Decision Log
| Date | Decision | Reason | Constraint |
| :--- | :--- | :--- | :--- |
| 2026-02-21 | DB Upgrade to v2 | Added `withdrawals` table with `onUpgrade` logic to preserve existing user data. | Section 0.7 |
| 2026-02-21 | Multi-Level Sort | Replaced simple selector with a tiered priority system (Drag & Drop) for granular shopping control. | Section 8.1.4 |
| 2026-02-21 | Unified Matrix Scroll | Wrapped the entire Debt Schedule in a single horizontal scroll to ensure vertical alignment of debt columns. | Section 5.6 |
| 2026-02-21 | Sinking Logic Sync | Hardcoded sinking rules in `_forceCategorySync` to apply logic to existing databases retroactively. | Section 4.17 |

## 🌲 Technical Tree Snippet
- `lib/data/database_helper.dart`: DB v2 Migration & Withdrawal CRUD.
- `lib/data/expense_model.dart`: `Withdrawal` model added.
- `lib/providers/budget_provider.dart`: Withdrawal logic & Global Sinking Rollover.
- `lib/ui/screens/shopping_screen.dart`: Reorderable Sort UI & Contrast Fixes.
- `lib/ui/screens/debt_schedule_screen.dart`: Horizontal Matrix Implementation.
- `lib/ui/screens/category_drilldown_screen.dart`: Withdrawals UI & Annual Sums.