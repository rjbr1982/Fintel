# 🧠 קונטקסט טכני והנחיות פיתוח: דוחכם (Dohaham)

## לוגיקות ליבה שעודכנו לאחרונה:
* **מבנה משפחה (FamilyMembers):** המערכת מתבססת כעת על רשימה דינמית של אובייקטי `FamilyMember` (שם + שנת לידה) במקום משתנים קשיחים. יש לוודא שכל לוגיקה עתידית שקשורה למבוגרים/ילדים נשאבת מתוך הרשימה הדינמית הזו ב-`BudgetProvider`.
* **חישוב הוצאות ילדים (isPerChild):**
  מנגנון התצוגה מציג את הסכום הכולל (סכום לילד יחיד * מספר הילדים). עם זאת, *בזמן עריכה או יצירה*, המשתמש מקליד את הסכום הכולל, והמערכת מחלקת אותו במספר הילדים לפני השמירה מחדש כ-`monthlyAmount`.
* **ניהול קופות (Sinking Funds / Unified Funds):**
  היסטוריית המשיכות (`Withdrawals`) מנוהלת דרך רכיבי BottomSheet ייעודיים בתוך `category_drilldown_screen.dart`. יש להקפיד על כך שטקסטים ארוכים בהערות הפעולה מקבלים `softWrap: true` כדי למנוע שגיאות תצוגה.
* **חוקת קוד (Code Constitution):**
  * **Zero Warnings:** אין להשאיר משתנים לא בשימוש, Imports מיותרים, או אזהרות Linter.
  * **הפרדת תצוגה ולוגיקה:** State management מנוהל אך ורק דרך `BudgetProvider`.
  * **שפות:** ממשק המשתמש נכתב בעברית (RTL), אך רוב המחרוזות הקבועות כעת מוטמעות ישירות בקוד ולא דורשות שאיבה מ-`AppLocalizations` אלא אם צוין אחרת.