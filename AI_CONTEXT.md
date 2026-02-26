[AI_CONTEXT_START]
**Project**: Fintel (דוחכם) - SaaS/Web Financial Intelligence Application
**Constitution Version**: 12.10 (Sinking Funds, Variable Ratios, Future Value)
**Status**: Zero Warnings, Web-Ready, Firebase Integrated.

**Recent Accomplishments (Last Session)**:
1. **App Icon & Branding**: Fully integrated the official Fintel Icon via `flutter_launcher_icons` across Android and Web, including implementation in `login_screen.dart` and `global_header.dart`.
2. **Smart Routing (`main.dart`)**: Upgraded `AuthGate` to check if the database is empty. Routes new/reset users to `OnboardingScreen` and existing users to `MainScreen`.
3. **Dynamic Onboarding (`onboarding_screen.dart`)**: Built a complete multi-step onboarding flow for capturing:
   - Full family members (Parents and Children with names & birth years).
   - Vehicle type (None/Car/Motorcycle) + leasing costs.
   - Anchor expenses (Rent, Supermarket, Electricity, Water).
4. **Seed Engine Overhaul (`seed_service.dart`)**: Rewrote the generator to accept dynamic parameters from the Onboarding screen. Fixed 'originalAmount' tracking for anchor expenses and removed legacy items (e.g., Pharm/Cleaning). Initial sinking funds start cleanly at 0.
5. **Provider & Reset Logic (`budget_provider.dart` & `global_header.dart`)**: 
   - Removed hardcoded fallback seeding.
   - Stopped auto-syncing categories if the DB is empty (preventing false "existing user" flags).
   - Fixed `fullAppReset` (Factory Reset) to wipe data and immediately force-route the user back to the Onboarding screen.

**Upcoming Mission (Next Session)**:
Pending the architect's decision, focus will likely shift to one of the following core areas:
- **Debt Management**: Integrating active debt impacts into the financial freedom algorithms.
- **Main Dashboard**: Upgrading the visual representation of sinking funds, standard of living, and financial freedom timeline.
- **Shopping Interface**: Building the detailed shopping list UI to sync dynamically with the defined frequencies (Weekly, Bi-Weekly, etc.).
[AI_CONTEXT_END]