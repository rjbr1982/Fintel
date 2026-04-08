# Fintel (דוחכם) - Project Status
**Last Updated:** April 2026

## 🚀 Current Phase
Finalized Hybrid Notification Architecture and UX Polishing. Transitioning to Premium Billing Integration (Sandbox).

## ✅ Recent Accomplishments (Latest Session)
* **Hybrid Notification Engine (FCM):** Implemented Firebase Cloud Messaging for Web. Built the `firebase-messaging-sw.js` infrastructure to support Push Notifications for iOS/Web users.
* **Notification Control Center:** Created a dedicated UI for granular notification management and integrated contextual "Notification Bells" in Shopping and Sinking Funds screens.
* **Fixed Global Sorting:** Enforced strict hierarchical sorting for "Future Expenses" (רכישות גדולות -> חופשה שנתית) across all views.
* **Legal Onboarding V2:** Implemented a strict 2-stage consent flow with a mandatory checkbox and a secondary scrollable modal for full T&C text.
* **Bank Deposit Logic Fix:** Resolved a bug where dynamic variable expenses were incorrectly "frozen," creating artificial gaps. The system now distinguishes between fixed-amount and ratio-based items for bank verification.
* **Information Architecture:** Reorganized the Hamburger menu to group system-level settings (Notifications, Biometrics, Ratios) under "System Settings."
* **Linter Compliance:** Optimized codebase for zero warnings, enforcing strict curly brace blocks and removing deprecated UI parameters.

## ⏳ Next Steps (Upcoming Session)
1.  **Fintel Playground:** Move to the Sandbox environment to build the In-App Purchase (IAP) logic.
2.  **Billing Integration:** Wire the `isPremium` flag to real-world subscription states (RevenueCat/Stripe).
3.  **Admin Broadcast:** (Future) Use FCM tokens collected this session to enable mass-push capabilities from the Admin Dashboard.

## 🛑 Known Issues / Tech Debt
* **Local Notifications on Web:** Explicitly disabled to prevent browser crashes; handled gracefully via Hybrid logic.
* **FCM Token Management:** Tokens are successfully collected and stored in Firestore, ready for server-side triggers.

**Constitution Status:** 12.88 (Aligned with Code)