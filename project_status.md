# Project Status - Dohaham (Fintel)
**Version:** Constitution 12.84
**Last Updated:** March 27, 2026

## ✅ What is Working Perfectly (in 'dohaham' main project)
* **Standardized Graphs:** Both Salary and Checking graphs follow a standard financial LTR direction with smooth Bezier curves, explicit Date/Amount labels, and a Zero-Line indicator.
* **Premium Gating (Simulated):** Full UI infrastructure for feature locking. Founders Gift dialog for Alpha/Beta users and a high-converting Paywall screen for Regular users.
* **Admin Dashboard & SaaS Metrics:** Admin Center correctly tracks user metrics and metadata.
* **Infinity State Flow:** Graceful handling of zero/negative PCF in the Freedom Gate flow.
* **Fintel Academy:** Content View with chip navigation is operational.
* **The Freedom Engine:** Accurately calculates Time-to-Freedom based on Assets and PCF.

## 🚧 Work In Progress (Gamma Phase Transition)
* **Sandbox Environment Setup:** Enforcing Section 12.7. All new payment and flavor infrastructure must be developed in a separate `fintel_playground` project to protect the production core.
* **Stripe/RevenueCat Payment Engine:** Transitioning from simulated Paywall to a live Hybrid Billing architecture.

## 🎯 Next Steps for Next Session (in fintel_playground)
1. **Initialize Staging:** Create `fintel-staging` Firebase project and configure Flutter Flavors (Staging/Production).
2. **Database Schema Update:** Add `createdAt` to User model and create `system_config` collection for Grandfathering logic.
3. **Hybrid Billing Integration:** Implement RevenueCat for Native Android IAP, and prepare architecture for Web Custom Gateway via Firebase Cloud Functions.
4. **Localization & FCM Topics:** Setup `AppLocalizations` (Hebrew active, English dormant) and auto-subscribe devices to FCM language topics for marketing.

## 📓 Strategic Decision Log
* **SaaS Hybrid Model (March 27, 2026):** Adopted dual pricing (MRR + Lifetime). Android uses RevenueCat (Google Play), Web uses Custom Israeli Gateway via Firebase Cloud Function. Firestore serves as the absolute SSOT.
* **Grandfathering Logic (March 27, 2026):** Users with a `createdAt` timestamp prior to `commercial_launch_date` in `system_config` receive automatic `isFounder: true` status, seamlessly bypassing all paywalls.
* **Localization & Push Notifications (March 27, 2026):** Rejected auto-translation for push notifications. Implemented FCM Topics (e.g., `marketing_he`) for targeted, human-crafted marketing copy. System messages use Data-Only keys translated locally via `AppLocalizations`.
* **Sandbox Doctrine Enforced (March 27, 2026):** All Gamma Phase payment integrations, environment splitting, and l10n must be built and stabilized in `fintel_playground` before manual merging to the main project.
* **Graph Standardization (March 26, 2026):** Aligned all visual trends to a professional LTR standard with a hardcoded Zero-Line in checking history.
* **Context Protection (March 26, 2026):** Enforced `mounted` checks across all async premium gates to comply with Flutter best practices and prevent crashes during navigation.