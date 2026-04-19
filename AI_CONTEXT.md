# Fintel Project Context (AI Bridge)

## 🎯 Mission
Fintel (Dohaham) - A high-end financial intelligence system focused on the Israeli market, helping users achieve financial freedom through "The Freedom Engine" and "Debt Sniper" algorithms.

## 🛠 Tech Stack
- **Frontend:** Flutter (Web/PWA focus).
- **Backend:** Firebase (Auth, Firestore, Hosting).
- **Automation:** Make.com (Webhooks for billing/notifications).
- **State Management:** Provider.

## 📐 Architecture Rules (The Constitution)
1. **Hebrew First:** All UI is RTL and Hebrew (Israel) by default.
2. **Lean Architecture:** Minimal dependencies, no excessive packages.
3. **Responsive Scaling:** Unified codebase for Mobile, Tablet, and Desktop.
4. **Security:** No hardcoded API keys. All sensitive data via Firestore/Secrets.
5. **Real-time Sync:** Real-time listeners for Premium status and data updates.

## 🔑 Core Services
- **PremiumService:** Handles Paywall logic, Founders' gifts, and Real-time Premium toggling.
- **AdminService:** Provides God-mode tools for the owner (Golden Key, User metrics, Sandbox toggles).
- **DatabaseHelper:** Singleton for Firestore CRUD and the Account Wipe Protocol.
- **NotificationService:** Handles periodic reminders and smart shopping alerts.

## 🧬 Key Features Implemented
- **Golden Key:** Manual Premium upgrade via Admin Dashboard with immediate effect.
- **Freedom Engine:** Goal-based calculation of financial independence year.
- **Split Paywall:** Adaptive pricing (Lifetime for Web/IL, Subscription for App Stores).
- **Legal Gate:** Mandatory terms and privacy consent during onboarding.
- **Responsive PWA:** Manifest and index settings optimized for "Add to Home Screen" experience.