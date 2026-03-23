# Project Status - Dohaham (Fintel)
**Version:** Constitution 12.82
**Last Updated:** March 23, 2026

## ✅ What is Working Perfectly
* **Shopping Module:** Fully integrated with `GlobalHeader`, search functionality, text zooming, and `shared_preferences` for sorting persistence.
* **Dynamic Budget Seeding:** Automatically adapts the default shopping basket size and Variable Expenses anchor to create a consistent +200 ILS starting delta based on family structure.
* **Contextual Onboarding (The 11 Signposts):** Clean, distraction-free UI. All educational material is now hidden behind standardized `info_outline` icons.
* **Production Infrastructure:** Live on custom domain with Google Login. Firebase Cloud sync is strictly secured (Level 2 Rules).
* **The Freedom Engine:** Accurately calculates Time-to-Freedom based on Assets, PCF, and dynamically adjusts the target.
* **Sinking Funds Bank Control:** Real-time discrepancy tracking between app target and actual bank standing order.
* **Dashboard & Navigation:** Clean dashboard focusing purely on Freedom Year, Sinking Funds, and Shopping, with unified Bottom Sheet menus.

## 🚧 Work In Progress (Bugs to Fix)
* **Zero Bugs / Zero Warnings:** Current state is completely clean (`flutter analyze` passes without issues). App is secure and deployed.

## 🎯 Next Steps for Next Session
1. **Globalization Assessment & Implementation:** Analyze the codebase to determine the transition strategy for full language support (`AppLocalizations`).
2. **Premium Feature Gating:** Continue structural preparations and testing for the Freemium model (Section 5.13).

## 📜 Strategic Decision Log
* **Shopping Sort Persistence (March 23, 2026):** Implemented `shared_preferences` directly in the Shopping Screen state to decouple UI preference storage from the global database models.
* **Dynamic Seed Calculation (March 23, 2026):** Refactored `SeedService` to calculate base shopping costs mathematically using multipliers (married +80%, child +30%) to ensure realistic E-Myth onboarding out-of-the-box.
* **Contextual Onboarding (March 23, 2026):** Implemented the "Silent Guide" doctrine (Section 5.12). Replaced all static explanatory banners with uniform `_showInfoDialog` popups.
* **Async Navigation (March 23, 2026):** Standardized capturing `Navigator.of(context)` before async gaps and using `try-finally` blocks for dialog pops.
* **Fintel Academy Architecture (March 23, 2026):** Decided to separate the Academy UI (`academy_screen.dart`) from its textual content (`academy_content.dart`) by creating a custom `AcademyBlock` data structure.