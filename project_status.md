# Fintel (דוחכם) - Project Status & Constitution
**Version:** 12.17
**Last Updated:** March 2026
**Core Philosophy:** E-Myth (Systematic Automation, Single Source of Truth, Zero Manual Redundancy)

## 📌 Current State
- **Git Status:** Clean, fully synced with `origin/main` (0 conflicts).
- **Linter Status:** 100% Clean (0 Issues). Strict adherence to `use_build_context_synchronously` using `context.mounted`.
- **Architecture:** Transitioned from static age-based logic to a dynamic **Role-Based** Family Model (Parent/Child).
- **UI/UX:** Fully functional Onboarding, Main Dashboard, Category Drilldown, Sinking Funds, Checking History, and Salary Engine.

## 🛠️ Recent Achievements (v12.17)
1. **Role-Based Family Structure:** Added `FamilyRole` (Parent/Child) enum to `FamilyMember` model.
2. **Dynamic Child Count:** Removed manual `childCount` setting. The system now automatically calculates `childCount` globally via a dynamic getter in `BudgetProvider` based on the assigned roles.
3. **UI Enhancements:** - Added a "Pencil" edit icon in GlobalHeader settings to modify family member roles, names, and birth years.
   - Fixed continuous loading spinner in "Kids Separate Funds" by enforcing `try-finally` state updates.
   - Improved UI contrast for vehicle texts and Dropdown menus (Salary Engine).
4. **Linter Eradication:** Fixed all `BuildContext` async gap issues in dialogs.

## 📜 Core Architecture Rules (The Constitution)

### 4. Code Quality & Modularity
- **4.7 Flexible Model Principle:** User-generated items (Vehicles, specific Sinking Funds) must have `isCustom: true` to allow deletion. System seed data is protected (`isCustom: false`).
- **4.18 Onboarding Flow:** 4-step wizard setting up Marital Status, Children (Roles), Vehicle Type, and Housing/Core Expenses.

### 5. AI-User Protocol
- **5.5.1 Zero-Zombie Rule:** The AI must NEVER overwrite code without verifying the current local state of the file first.
- **5.7.1 Read-Before-Write:** The AI will request the current file contents before executing major logic changes.
- **5.7.2 Delta Principle:** Propose changes in a draft before providing the full copy-paste file.
- **0.9 Two-Step Git Protocol:** The user will execute `git pull --no-edit` prior to `git push` to avoid Vim merge conflicts.

### 7. Variable Expenses & Allocation
- **7.1.1 Dynamic Entity & Child Count (UPDATED v12.17):** The system does not require manual entry of "Child Count". The multiplier is automatically calculated at all times based on the number of `FamilyMember` instances classified under the `FamilyRole.child` category. 

### 11. Database & Models
- **11.8 Family Data Structure (UPDATED v12.17):** Every family member has a `name`, `birthYear`, and `role` (`FamilyRole.parent` or `FamilyRole.child`). 

## 🚀 Next Steps (For next session)
- Open for new user feature requests.
- Potential refinement of the personal withdrawal mechanics inside the separate child funds.