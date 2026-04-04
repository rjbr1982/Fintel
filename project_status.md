# Project Status - Dohaham (Fintel)
**Version:** Constitution 12.85
**Last Updated:** April 4, 2026

## ✅ What is Working Perfectly (in 'dohaham' main project)
* **Fintel Brain Extractor (Admin):** Local pre-build script (`pack_code.dart`) bundles the entire system codebase into a text asset, enabling full source-code extraction directly to the mobile device's clipboard via the Admin Dashboard.
* **Standardized Graphs:** Both Salary and Checking graphs follow a standard financial LTR direction with smooth Bezier curves, explicit Date/Amount labels, and a Zero-Line indicator.
* **Premium Gating & UI:** Full UI infrastructure for feature locking. Founders Gift dialog for Alpha/Beta users, high-converting Paywall screen, and persistent Premium Crown in the Global Header.
* **Admin Dashboard & SaaS Metrics:** Admin Center correctly tracks user metrics, applies advanced screening, and handles bulk mailing.
* **Freedom Gate Flow:** Graceful handling of zero/negative PCF, locked navigation during calibration, and accurate memory sync triggering the target year animation cleanly.
* **Fintel Academy:** Content View with chip navigation is operational. Chapter 3 accurately reflects the Isolated/Unified Sinking Funds architecture.
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
* **Navigation Protection (April 4, 2026):** Used `pushAndRemoveUntil` when completing onboarding to clear the navigation stack and ensure the Freedom Engine animation triggers cleanly in `MainScreen` without stale routes triggering early.
* **State Sync (April 4, 2026):** Enforced DB write before `budget.loadData()` during onboarding completion to prevent stale memory bugs regarding the `hasCompletedGrandReveal` flag.
* **Academy Consistency (April 4, 2026):** Rewrote Academy Chapter 3 to explicitly forbid "one giant bank deposit" and enforce isolated bank deposits per sinking fund, aligning educational content with the Fintel software architecture (Section 4.4.6).
* **IP Protection vs. User Data (April 4, 2026 - v12.85):** Separated the concepts of "Data Export" and "Code Extraction". The public Hamburger menu now only exports personal User Data. A hidden Admin-only "Brain Extractor" handles full source-code extraction. Bypassed mobile compilation limits by introducing a pre-build `pack_code.dart` script that injects the source code as an internal asset (`fintel_brain_capsule.txt`).
* **SaaS Hybrid Model (March 27, 2026):** Adopted dual pricing (MRR + Lifetime). Android uses RevenueCat (Google Play), Web uses Custom Israeli Gateway via Firebase Cloud Function. Firestore serves as the absolute SSOT.
* **Grandfathering Logic (March 27, 2026):** Users with a `createdAt` timestamp prior to `commercial_launch_date` in `system_config` receive automatic `isFounder: true` status, seamlessly bypassing all paywalls.
* **Localization & Push Notifications (March 27, 2026):** Rejected auto-translation for push notifications. Implemented FCM Topics (e.g., `marketing_he`) for targeted, human-crafted marketing copy. System messages use Data-Only keys translated locally via `AppLocalizations`.
* **Sandbox Doctrine Enforced (March 27, 2026):** All Gamma Phase payment integrations, environment splitting, and l10n must be built and stabilized in `fintel_playground` before manual merging to the main project.
* **Graph Standardization (March 26, 2026):** Aligned all visual trends to a professional LTR standard with a hardcoded Zero-Line in checking history.
* **Context Protection (March 26, 2026):** Enforced `mounted` checks across all async premium gates to comply with Flutter best practices and prevent crashes during navigation.