# Fintel - AI Context & Guidelines

## 📌 Project Overview
Fintel is a comprehensive personal finance and financial freedom tracking application built with Flutter and Firebase. 
The app supports tracking salaries, sinking funds (קופות), expenses, and generating financial projections.

## 🏗 Architecture & Firebase Structure
* **Backend:** Firebase (Auth, Firestore, Hosting).
* **Admin Identity:** The primary admin email is `rjbrrjbr@gmail.com`. Firebase Security Rules are strictly configured to allow read/write access to all user documents ONLY for this email.
* **Firestore Data Model:**
  * `users/{uid}`: Contains core user data (`email`, `generation`, `country`, `isPremium`, `metrics`, `createdAt`, `lastActive`, and newly added `adminNotes`).
  * `users/{uid}/family_members/{docId}`: Contains family members. The primary user's name is fetched by querying this sub-collection, ordered by `birthYear` (ascending), limiting to 1.
  * Other sub-collections: `expenses`, `shopping_items`, `app_settings`.
* **Security Rules:** Configured to secure `users` and `system` collections, relying on the `isAdmin()` function.

## 🛠 Key Components & Features (Admin Dashboard)
* **Location:** `lib/ui/screens/admin_dashboard_screen.dart` & `lib/services/admin_service.dart`.
* **Features:**
  * **Macro Stats & Triggers:** Bottleneck alerts, churn tracking, success metrics.
  * **Smart Screener:** Advanced filtering by Generation, Country, Salary, Sinking Funds, and Freedom screen views.
  * **Mail Triggering:** Bulk BCC email launching directly from filtered lists.
  * **Golden Key:** A toggle to instantly grant or revoke "Pro" (Premium) status for any user.
  * **Admin Notes (`_AdminNoteField`):** An auto-saving (800ms Debounce), vertically expanding text field attached to each user for internal CRM purposes.
  * **Raw Data Table:** A horizontally scrollable, light-themed `DataTable` that accommodates expanding rows for long admin notes.

## 🧠 Working Rules for AI (Surgical Protocol)
1. **Never drop existing code:** When adding new features to UI files (especially complex ones like the Admin Dashboard), preserve all existing widgets, methods, and logic (e.g., Mail triggers, Sandboxes).
2. **Surgical Updates:** Provide full, copy-pasteable files ONLY when requested, ensuring no partial classes or missing imports.
3. **No Assumptions:** Do not generate or modify files without explicit permission. Discuss architecture and logic first.
4. **Language:** Communicate in Hebrew, keep variables and code logic in English.