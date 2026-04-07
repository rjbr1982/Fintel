# Fintel - AI Development Context

## Project Overview
Fintel (דוחכם) is a sophisticated financial intelligence application based on the Dohaham methodology. It shifts users from passive tracking to proactive cash flow management, utilizing concepts like "Sinking Funds" (קופות צוברות), "Zero-Based Budgeting", the "Sniper Method" for debt snowballing, and the "Freedom Engine" for passive income planning.

## Architecture
* **Framework:** Flutter (Mobile + Web capabilities).
* **Backend:** Firebase (Auth, Firestore for cross-device sync).
* **Local Storage:** SQLite (`DatabaseHelper`) serving as the single source of truth for rapid offline UI performance, syncing to Firebase in the background.
* **State Management:** `Provider` (`BudgetProvider`, `AssetProvider`, `DebtProvider`, `ShoppingProvider`).
* **Notifications:** `flutter_local_notifications` integrated with `timezone` for offline, device-level smart scheduling.

## Freemium Strategy (The "Tease & Protect" Model)
* **Free Tier:** Users get full access to Zero-Based Budgeting, Fixed/Variable tracking, Sinking Funds, and basic Debt entry (to maintain accurate cash-flow).
* **Premium Tier (👑):** * *Assets & Freedom:* Free users see their "Freedom Year" as infinite. Premium unlocks Asset Management which feeds the Freedom Engine.
    * *Time Machine (Sniper):* Free users can list debts. Premium unlocks the accelerated payoff dates, interest savings, and automated snowball reallocation.
    * *Salary Stabilizer:* Premium unlocks the dynamic salary averaging engine for freelancers/shift workers.
    * *Exports:* AI Text Export generation.

## Key Services & Providers
1.  **`NotificationService`:** A 3-layer notification engine:
    * *Operational:* Shopping reminders (6 days post-purchase), Monthly Rollover (1st of month), Withdrawal Day.
    * *Conversion:* Drip marketing for Free users (14, 30, 60 days) teasing Premium features.
    * *Immediate:* Real-time victory notifications (e.g., Debt payoff).
2.  **`BudgetProvider`:** The core brain. Handles the Waterfall logic (Income -> Fixed -> Debts -> Variable -> Future -> Financial). Contains the `_sortInMemoryData` Global Sorting Engine ensuring strict hierarchical UI consistency.
3.  **`AdminService` & Dashboard:** A hidden God-Mode dashboard triggered by 5 taps on the version number + PIN. Features live screener, smart CTA drill-downs (Bottleneck, Churn, Success), and mass BCC mailing.
4.  **`SeedService`:** Auto-populates categories and dynamic shopping lists upon first login based on family demographics (marital status, kids, housing, vehicles).

## Current Development State
The Core App (UX, Logic, Onboarding, Sorting, Notifications, Freemium UI constraints) is **complete and stable**.
The system successfully enforces a Legal Consent gate *post*-Google Authentication (`hasAcceptedTerms`).

## Next Immediate Goal
Transitioning to the `fintel_playground` (Sandbox) to engineer the **Billing and Subscription Architecture** (In-App Purchases) that will dynamically toggle the `isPremium` root metric.