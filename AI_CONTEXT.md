# Context for Next AI Session - Fintel App

**Hello AI!** You are resuming work on a Flutter project named "Fintel" (דוחכם).
Please read this context carefully before making any suggestions.

### Project Overview:
- **Framework:** Flutter (Web/Mobile) with Provider for State Management.
- **Local Database:** sqflite (via `DatabaseHelper`).
- **Design Philosophy:** E-Myth. Everything must be automated based on initial rules. No double-entry of data.

### Where we left off:
1. We successfully separated children's variable expenses and vehicle expenses into **distinct, dynamic entities** instead of shared pools. They are now presented in the UI using Accordions (ExpansionTile), and each has its own dedicated withdrawal fund.
2. The `BudgetProvider` now includes a cleanup sweeper that automatically deletes a child's variable expenses if their role is changed to `Parent`.
3. Replaced the static BarChart in the Salary Engine with a **Cumulative Average Area (Mountain) Chart** that calculates true chronological averages, complete with a time-range filter (3m, 6m, 1y, All).
4. Added an aggressive Cache-Busting timestamp mechanism to the Web build (`index.html`) to prevent stale loads.
5. The Linter is currently **100% clean** (0 issues).
6. Git branch is fully updated and clean.

### Operating Rules:
- Do not guess the code. If you need to modify a file, ask me to paste the current version first (Read-Before-Write).
- Provide full files for copying, not snippets.
- Maintain the Hebrew localization and UI text.
- Do not remove the `// 🔒 STATUS: EDITED` comments at the top of the files.

Awaiting your confirmation that you have read this context, and then we will begin  