# Fintel - AI Context & Architecture Guidelines

## 1. Project Overview
**Name:** Fintel (דוחכם)
**Core Concept:** Financial Intelligence application based on the Dohaham methodology.
**Current Phase:** Gamma (Pre-launch/Production testing).
**Environments:** `fintel_playground` (Sandbox/Dev), `dohaham` (Production).

## 2. Recent Architectural Updates (April 2026)
* **Visual Asset Standardization:** Enforced strict lowercase `snake_case` for all assets (e.g., `fintel_icon.png`, `dashboard_background.png`) to prevent cross-platform Case-Sensitivity crashes and `errorBuilder` UI fallbacks.
* **Dashboard Background:** Applied `dashboard_background.png` specifically to `main_screen.dart` using a transparent Scaffold over a decorated Container.
* **Contextual Header UX:** Upgraded `GlobalHeader` to display the large brand logo (50px) only on the main dashboard. Deep screens hide the logo to free up space, and titles are wrapped in a `FittedBox` to gracefully scale down long Hebrew titles (like "אקדמיית Fintel") instead of truncating them.
* **Premium State:** Reverted complex premium icon padding math; both standard and premium icons now render uniformly at 50px.
* **Authentication UI:** Cleaned `login_screen.dart` to directly call the correct brand PNG without fallback overrides.

## 3. Strict Coding Policies
* **Zero Warnings:** Code must pass `flutter analyze` with 0 issues. Unused imports or variables are strictly prohibited.
* **Deployment Protocol:** Production UI/Client updates are deployed using `firebase deploy --only hosting`.
* **State Updates:** Use `context.watch` for UI rebuilding and `context.read` for callbacks.