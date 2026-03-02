# Context for Next AI Session - Fintel App

**Hello AI!** You are resuming work on a Flutter project named "Fintel" (דוחכם).
Please read this context carefully before making any suggestions.

### Project Overview:
- **Framework:** Flutter (Web/Mobile) with Provider for State Management.
- **Local Database:** sqflite (via `DatabaseHelper`).
- **Design Philosophy:** E-Myth. Everything must be automated based on initial rules. No double-entry of data.

### Where we left off:
1. We successfully implemented a **Role-Based Family System**. Every family member is defined as either a `Parent` or a `Child` via an enum (`FamilyRole`).
2. The `childCount` is no longer a saved integer; it is a dynamic getter in `BudgetProvider` that counts members with `FamilyRole.child`.
3. The Linter is currently **100% clean**. We have strict rules regarding `use_build_context_synchronously`. You MUST use `if (!context.mounted) return;` after any `await` inside a widget or dialog. Do NOT use just `if (!mounted)` if the context belongs to the `build` method parameter.
4. Git branch is fully updated and clean.

### Operating Rules:
- Do not guess the code. If you need to modify a file, ask me to paste the current version first (Read-Before-Write).
- Provide full files for copying, not snippets (unless proposing a draft).
- Maintain the Hebrew localization and UI text.
- Do not remove the `// 🔒 STATUS: EDITED` comments at the top of the files.

Awaiting your confirmation that you have read this context, and then we will begin!