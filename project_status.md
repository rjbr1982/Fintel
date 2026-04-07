# Fintel (דוחכם) - Project Status
**Last Updated:** April 2026

## 🚀 Current Phase
Finalizing Core App Experience (UX/Flows), Freemium Strategy, and Local Notifications. Transitioning to Premium Billing Integration (Sandbox).

## ✅ Recent Accomplishments (Latest Session)
* **Legal Onboarding Post-Auth:** Moved the Terms & Conditions consent to *after* Google Auth. The system now checks `hasAcceptedTerms` in the user's Firebase document, creating a seamless login for returning users while strictly blocking new/unconsented users.
* **Global Sorting Engine:** Completely rewrote the sorting logic in `BudgetProvider`. Implemented a strict internal hierarchy for Fixed Expenses (Charity -> Housing -> Living -> Vehicle -> Kids -> Holidays -> Media -> Health -> Travel -> Haircut -> Household -> Others), alongside the existing Person and Item Type sorting.
* **Admin God-Mode Dashboard:** * Added live counters to Smart CTAs (Bottleneck, Churn, Success).
    * Converted CTAs and Macro Stats into clickable drill-down modals showing specific user emails.
    * Added copy-to-clipboard and bulk email (`mailto:bcc`) capabilities directly from the dashboard.
* **Freemium Pivot (Reducing / Debts Screen):** * Opened the base Debts screen to Free users (can add/edit/view debts to keep their cash flow accurate).
    * Locked the "Time Machine / Sniper" algorithm (accelerated payoff dates) behind a Premium Teaser Card.
    * Added visual locks (👑) to premium metrics.
* **Local Notification Engine:** Integrated `flutter_local_notifications` and `timezone`. Created `NotificationService` to handle:
    * *Operational:* 1st of the month rollover, Custom Withdrawal Day, 6-day Shopping Reminder.
    * *Conversion:* Smart delayed teasers (14, 30, 60 days) for Free users to upgrade to Premium.
* **Real-Time UI Fixes:** Fixed optimistic UI updating when executing withdrawals from Sinking Funds.
* **Academy Update:** Added the "Weekly Digital Shopping Rule" to Chapter 4 (promoting online weekly shopping over physical/monthly shopping).

## ⏳ Next Steps (Upcoming Session)
1.  **Fintel Playground:** Move to the Sandbox environment to build and test the Premium Billing infrastructure.
2.  **Subscription Management:** Integrate in-app purchases (RevenueCat/Stripe) to physically unlock the `isPremium` flag.
3.  **Advanced Push Notifications:** (Optional) Transition from local to server-side FCM if remote admin triggers are required.

## 🛑 Known Issues / Tech Debt
* No critical bugs currently identified. The core loop is stable and perfectly synced with the global sorting and notification engines.