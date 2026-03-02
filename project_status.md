# Fintel (דוחכם) - Project Status & Constitution
**Version:** 12.17
**Last Updated:** March 2026
**Core Philosophy:** E-Myth (Systematic Automation, Single Source of Truth, Zero Manual Redundancy)

## 📌 Current State
- **Git Status:** Clean, fully synced with `origin/main` (0 conflicts).
- **Linter Status:** 100% Clean (0 Issues). Strict adherence to `use_build_context_synchronously`.
- **Architecture:** Role-Based Family Model (Parent/Child) fully integrated. Dynamic unified and individual Sinking Funds architecture active.
- **UI/UX:** Dynamic Accordion UI for multi-vehicle and multi-child tracking. Cumulative Average Area Chart in Salary Engine. Web Cache-Busting active.

## 🛠️ Recent Achievements (v12.17)
1. **Dynamic Entities Segregation:** Refactored BudgetProvider to create explicitly named expenses for each child (e.g., "בגדים אליעזר") and each vehicle, removing the legacy shared global pool logic.
2. **Sinking Funds Split:** The savings center now dynamically groups and displays specific unified funds per vehicle and individual funds per child.
3. **Auto-Cleanup Logic:** Added a cleanup sweeper in `_forceCategorySync` that automatically deletes child variable expenses if a family member's role is changed to 'Parent'.
4. **Salary Engine Revamp:** Replaced the BarChart with a responsive Cumulative Average Mountain Chart (Area Chart) with 3m/6m/1y/All time-range toggles.
5. **Web Cache-Busting:** Added timestamp parameters to `flutter_bootstrap.js` in `index.html` to force browsers to pull new updates immediately.
6. **Linter Eradication:** Ensured 0 warnings across all files (added blocks to if statements, removed unused imports).

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
- **7.1.1 Dynamic Entity & Child Count:** Child multiplier is automatically calculated based on `FamilyRole.child`. Specific variable funds are dynamically named and generated per child.

### 10. Freedom Engine & Assets
- **10.8 Separation of Yield:** Asset tracking provides total capital, but the yield is a single macro-level input defined globally in the Freedom Engine, avoiding granular yield tracking per asset.

### 11. Database & Models
- **11.8 Family Data Structure:** Every family member has a `name`, `birthYear`, and `role` (`FamilyRole.parent` or `FamilyRole.child`).

## 🚀 Next Steps (For next session)
- Open for new user feature requests.
- QA testing full user flow following the dynamic entity architecture changes.