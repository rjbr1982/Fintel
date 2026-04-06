# Project Status - Dohaham (Fintel)
**Version:** Constitution 12.87
**Last Updated:** April 6, 2026

## ✅ What is Working Perfectly (in 'dohaham' main project)
* **Fintel Brain Extractor (Admin):** Local pre-build script (`pack_code.dart`) bundles the entire system codebase into a text asset.
* **Premium Gating & UI:** Full UI infrastructure for feature locking.
* **Freedom Gate Flow & UX:** Graceful handling of zero/negative PCF, explicit CTA for Infinity state (∞).
* **Dynamic Versioning:** Global Header and Admin Dashboard pull live app version directly from `pubspec.yaml` using `package_info_plus`.
* **Shopping Actuals History:** Users can view historical actual spending per month via a dynamic dropdown.
* **Fintel Academy:** Content perfectly aligned with Fintel methodology.

## 🚧 Work In Progress (Gamma Phase Transition)
* **Sandbox Environment Setup:** Enforcing Section 12.7. All new infrastructure (Legal, Assets, Payments) must be developed in `fintel_playground`.
* **Legal Onboarding:** Designing the Terms of Use and Privacy Policy acceptance flow.
* **Sinking-Growth Asset (חיסגור):** Wiring the Auto-Rollover PCF to feed directly into designated assets.

## 🎯 Next Steps for Next Session (in fintel_playground)
1. **Initialize Staging & Sandbox:** Create `fintel-staging` Firebase project and configure Flutter Flavors (Staging/Production).
2. **Legal Onboarding:** Implement mandatory Checkbox and scrollable Modal for Terms & Privacy (Sec 5.14.5).
3. **Sinking-Growth Asset:** Build the toggle in Asset Settings and update the Auto-Rollover logic to deposit PCF directly into the selected asset (Sec 10.4.4).
4. **Hybrid Billing Integration:** Implement RevenueCat for Native Android IAP, and prepare Web Custom Gateway.

## 📓 Strategic Decision Log
* **Legal Onboarding Strategy (April 6, 2026):** Decided to enforce Terms of Use and Privacy Policy acceptance via a mandatory checkbox during the Login/Onboarding flow, rather than an intrusive pop-up. Crafted professional legal text protecting the developers from financial liability and clarifying the use of Firebase Auth.
* **Sinking-Growth Asset / 'חיסגור' (April 6, 2026):** Solved the PCF accumulation loop by routing the unspent PCF into the Assets Portfolio rather than Sinking Funds. Created a toggle ("נכס צובר תזרים לחירות") that allows users to wire their monthly PCF directly into any asset (e.g., a holding tank or directly to a Brokerage account).
* **Dynamic Versioning (April 5, 2026):** Integrated `package_info_plus` to automatically track and display the app version in the UI.
* **Sandbox Doctrine Enforced (March 27, 2026):** All Gamma Phase payment integrations, environment splitting, and new flows must be built and stabilized in `fintel_playground` before manual merging to the main project.