# Project Status - Fintel

## Current Technical State
- **Sync Architecture:** GitHub Actions -> Rclone -> Google Drive -> Make.com Webhook.
- **Output Artifact:** `Fintel_Brain.txt` (Unified knowledge source).
- **Primary Branch:** main.
- **Linter Status:** Zero Warnings Policy (5.4) enforced.

## Strategic Decision Log (6.6)
| תאריך | החלטה ארכיטקטונית | נימוק ואילוץ |
| :--- | :--- | :--- |
| 01/03/26 | הקמת גשר "מוח פינטל" | הצורך להנגיש מידע טכני ליועץ אסטרטגי (Gemini) ללא גישה ל-Git. |
| 01/03/26 | הפרדת זהויות Jam/Gemini | מניעת בלבול בין הנחיות פיתוח קשיחות להצעות שיווקיות גמישות. |
| 01/03/26 | סנכרון תיקיית שורש (Root) | אילוץ: היועץ זקוק ל-project_status.md כדי להבין את ההקשר המלא. |

## Pending Tasks
- [ ] בדיקת תקינות הקובץ המאוחד (Fintel_Brain.txt) לאחר Push ראשון.
- [ ] המשך פיתוח לוגיקת ה-15% ומנוע החירות (4.14).