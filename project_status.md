# Project Status - Dohaham (Fintel)
**Version:** Constitution 12.87
**Last Updated:** April 6, 2026

## ✅ What is Working Perfectly (in 'dohaham' main project)
* **Legal Onboarding:** Mandatory Terms of Use and Privacy Policy acceptance flow integrated into Login via a secure Checkbox and scrollable Modal.
* **Sinking-Growth Asset (חיסגור):** PCF Auto-Rollover engine now successfully detects assets marked as "Accumulators" (⚡) and directly deposits the monthly free cash flow into them.
* **Fintel Brain Extractor (Admin):** Local pre-build script (`pack_code.dart`) bundles the entire system codebase into a text asset.
* **Premium Gating & UI:** Full UI infrastructure for feature locking. Persistent "Founders Gift" logic implemented via Firebase Metrics.
* **Freedom Gate Flow & UX:** Graceful handling of zero/negative PCF, explicit CTA for Infinity state (∞).
* **Dynamic Versioning:** Global Header and Admin Dashboard pull live app version directly from `pubspec.yaml` using `package_info_plus`.
* **Shopping Actuals History:** Users can view historical actual spending per month via a dynamic dropdown.

## 🚧 Work In Progress (Gamma Phase Transition)
* **Sandbox Environment Setup:** Enforcing Section 12.7. Transitioning to `fintel_playground` to build the payment gateways and flavors safely.
* **Hybrid Billing Integration:** Preparing to implement RevenueCat for Native Android IAP, and Web Custom Gateway.

## 🎯 Next Steps for Next Session (in fintel_playground)
1. **Initialize Sandbox:** Open `fintel_playground` and verify `pubspec.yaml` before running `flutter pub add purchases_flutter url_launcher`.
2. **Hybrid Billing Engine:** Implement the platform-specific logic in `PremiumService`.
3. **Initialize Staging:** Create `fintel-staging` Firebase project and configure Flutter Flavors (Staging/Production).

## 📓 Strategic Decision Log
* **Legal Onboarding Strategy (April 6, 2026):** Decided to enforce Terms of Use and Privacy Policy acceptance via a mandatory checkbox during the Login/Onboarding flow, rather than an intrusive pop-up. Crafted professional legal text protecting the developers from financial liability and clarifying the use of Firebase Auth.
* **Sinking-Growth Asset / 'חיסגור' (April 6, 2026):** Solved the PCF accumulation loop by routing the unspent PCF into the Assets Portfolio rather than Sinking Funds. Created a toggle ("נכס צובר תזרים לחירות") that allows users to wire their monthly PCF directly into any asset (e.g., a holding tank or directly to a Brokerage account).
* **Hybrid Billing Architecture (April 6, 2026):** Replaced hardcoded Premium mocks with a `HybridBillingEngine` class to separate Web (Custom Gateway/Stripe) from Native (RevenueCat), ensuring compliance with store policies while saving 30% fees on Web.
* **Sandbox Doctrine Enforced (March 27, 2026):** All Gamma Phase payment integrations, environment splitting, and new flows must be built and stabilized in `fintel_playground` before manual merging to the main project.