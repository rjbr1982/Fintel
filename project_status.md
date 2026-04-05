# Project Status - Dohaham (Fintel)
**Version:** Constitution 12.85
**Last Updated:** April 5, 2026

## ✅ What is Working Perfectly (in 'dohaham' main project)
* **Fintel Brain Extractor (Admin):** Local pre-build script (`pack_code.dart`) bundles the entire system codebase into a text asset.
* **Premium Gating & UI:** Full UI infrastructure for feature locking, including explicit separation of Freedom Engine calibration (free) and Assets Management (Premium) in the PnL screen.
* **Freedom Gate Flow & UX:** Graceful handling of zero/negative PCF, explicit CTA for Infinity state (∞), and contextual info dialogs for all Freedom Engine metrics.
* **Dynamic Versioning:** Global Header and Admin Dashboard pull live app version directly from `pubspec.yaml` using `package_info_plus`.
* **Shopping Actuals History:** Users can view historical actual spending per month via a dynamic dropdown in the Shopping Screen.
* **Fintel Academy:** Content perfectly aligned with Fintel methodology, featuring clear naming conventions ("פרקטיקת השימוש").

## 🚧 Work In Progress (Gamma Phase Transition)
* **Sandbox Environment Setup:** Enforcing Section 12.7. All new payment and flavor infrastructure must be developed in a separate `fintel_playground` project to protect the production core.
* **Stripe/RevenueCat Payment Engine:** Transitioning from simulated Paywall to a live Hybrid Billing architecture.

## 🎯 Next Steps for Next Session (in fintel_playground)
1. **Initialize Staging:** Create `fintel-staging` Firebase project and configure Flutter Flavors (Staging/Production).
2. **Database Schema Update:** Add `createdAt` to User model and create `system_config` collection for Grandfathering logic.
3. **Hybrid Billing Integration:** Implement RevenueCat for Native Android IAP, and prepare architecture for Web Custom Gateway via Firebase Cloud Functions.
4. **Localization & FCM Topics:** Setup `AppLocalizations` (Hebrew active, English dormant) and auto-subscribe devices to FCM language topics for marketing.

## 📓 Strategic Decision Log
* **Dynamic Versioning (April 5, 2026):** Integrated `package_info_plus` to automatically track and display the app version in the UI, eliminating hardcoded technical debt.
* **Infinity State UX (April 5, 2026):** Resolved UX dead-ends when Time-to-Freedom is infinite (`null`). Added explicit CTAs and info dialogs to guide the user towards Engine Calibration, ensuring continuous user flow.
* **Shopping History Architecture (April 5, 2026):** To avoid complex DB schema changes, historical "Actual Spent" logic was implemented via a dynamic `targetMonth` offset in `ShoppingProvider`, filtering existing timestamps.
* **Navigation Protection (April 4, 2026):** Used `pushAndRemoveUntil` when completing onboarding to clear the navigation stack and ensure the Freedom Engine animation triggers cleanly in `MainScreen`.
* **SaaS Hybrid Model (March 27, 2026):** Adopted dual pricing (MRR + Lifetime). Android uses RevenueCat (Google Play), Web uses Custom Israeli Gateway.
* **Sandbox Doctrine Enforced (March 27, 2026):** All Gamma Phase payment integrations, environment splitting, and l10n must be built and stabilized in `fintel_playground` before manual merging to the main project.