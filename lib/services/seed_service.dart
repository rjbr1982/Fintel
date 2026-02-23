// 🔒 STATUS: EDITED (Fixed Shopping Anchor Name & Removed Pharm)
import '../data/database_helper.dart';
import '../data/expense_model.dart';
import '../data/shopping_model.dart';

class SeedService {
  
  static Future<void> generateInitialData({
    required String vehicleType,
    required double leasingCost,
    required double rentAmount,
    required double supermarketAmount,
    required double electricityAmount,
    required double waterAmount,
  }) async {
    final db = DatabaseHelper.instance;
    
    final existingExpenses = await db.getExpenses();
    if (existingExpenses.isNotEmpty) {
      return; 
    }

    final List<Expense> initialExpenses = [
      
      // === הכנסות ===
      _create('משכורת נטו (1)', 'הכנסות', 'הכנסות', 11000), 
      _create('משכורת נטו (2)', 'הכנסות', 'הכנסות', 5570),
      _create('קצבת ילדים', 'הכנסות', 'הכנסות', 590),
      
      // === קבועות ===
      _create('צדקה', 'קבועות', 'צדקה', 0),
      _create('שכירות/משכנתא', 'קבועות', 'דיור', rentAmount),
      _create('וועד בית', 'קבועות', 'דיור', 0),
      _create('ארנונה', 'קבועות', 'דיור', 380),
      _create('הובלה ותיקונים', 'קבועות', 'דיור', 0, isSinking: true),
      _create('חשמל', 'קבועות', 'מגורים', electricityAmount, frequency: Frequency.BI_MONTHLY), 
      _create('מים', 'קבועות', 'מגורים', waterAmount, frequency: Frequency.BI_MONTHLY),
      _create('גז', 'קבועות', 'מגורים', 40),
      
      // רכב (מוזרק דינמית)
      if (vehicleType == 'car') ...[
        _create('ביטוח', 'קבועות', 'רכב', 3500, isSinking: true, frequency: Frequency.YEARLY),
        _create('טסט', 'קבועות', 'רכב', 1250, isSinking: true, frequency: Frequency.YEARLY),
        _create('טיפול', 'קבועות', 'רכב', 2000, isSinking: true, frequency: Frequency.YEARLY),
        _create('תיקונים', 'קבועות', 'רכב', 500, isSinking: true),
        _create('ליסינג', 'קבועות', 'רכב', leasingCost),
        _create('דלק', 'קבועות', 'רכב', 500), 
      ] else if (vehicleType == 'motorcycle') ...[
        _create('ביטוח', 'קבועות', 'רכב', 3500, isSinking: true, frequency: Frequency.YEARLY),
        _create('טסט', 'קבועות', 'רכב', 250, isSinking: true, frequency: Frequency.YEARLY),
        _create('טיפול', 'קבועות', 'רכב', 500, isSinking: true, frequency: Frequency.YEARLY),
        _create('תיקונים', 'קבועות', 'רכב', 50, isSinking: true),
        _create('דלק', 'קבועות', 'רכב', 30), 
      ],
      
      // מדיה
      _create('בזק', 'קבועות', 'מדיה', 0),
      _create('פרטנר', 'קבועות', 'מדיה', 0),
      _create('גוגל AI Pro', 'קבועות', 'מדיה', 0),
      _create('גוגל יוטיוב פרימיום', 'קבועות', 'מדיה', 0),
      _create('מייקרוסופט', 'קבועות', 'מדיה', 0, isSinking: true), 
      _create("צ'אט GPT", 'קבועות', 'מדיה', 0),
      _create('אפליקציית כושר', 'קבועות', 'מדיה', 0),
      
      // ילדים - קבועות (כולן צוברות)
      _create('שכר לימוד', 'קבועות', 'ילדים', 0, isPerChild: true, isSinking: true),
      _create('ציוד בית ספר', 'קבועות', 'ילדים', 0, isPerChild: true, isSinking: true, frequency: Frequency.YEARLY),
      _create('חוגים', 'קבועות', 'ילדים', 0, isPerChild: true, isSinking: true),
      _create('מתנות לימי הולדת', 'קבועות', 'ילדים', 0, isSinking: true),
      _create('קייטנות', 'קבועות', 'ילדים', 0, isSinking: true, frequency: Frequency.YEARLY),
      
      // חגים (כולם צוברים)
      _create('ראש השנה', 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      _create('יום כיפור', 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      _create('סוכות', 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      _create('שמחת תורה', 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      _create('חנוכה', 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      _create("ט''ו בשבט", 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      _create('פורים', 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      _create('פסח', 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      _create('יום העצמאות', 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      _create("ל''ג בעומר", 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      _create('שבועות', 'קבועות', 'חגים', 0, isSinking: true, frequency: Frequency.YEARLY),
      
      // שונות קבועות
      _create('קופת חולים', 'קבועות', 'קופת חולים', 0),
      _create('נסיעות', 'קבועות', 'נסיעות', 0, isSinking: true),
      _create('תספורת', 'קבועות', 'תספורת', 0),
      _create('קטנות לבית', 'קבועות', 'קטנות לבית', 0, isSinking: true),
      _create('בילויים', 'קבועות', 'בילויים', 0, isSinking: true),

      // === משתנות (קניות) ===
      // תוקן: השם הוחזר ל'קניות' כדי שהמסך יזהה אותו כעוגן, ופארם וניקיון נמחק!
      _create('קניות', 'משתנות', 'קניות', supermarketAmount),

      // === משתנות (אישיות - Waterfall) ===
      _create('בגדים אבא', 'משתנות', 'אבא', 0, allocationRatio: 0.1, isSinking: true),
      _create('בילויים אבא', 'משתנות', 'אבא', 0, allocationRatio: 0.1, isSinking: true),
      _create('בגדים אמא', 'משתנות', 'אמא', 0, allocationRatio: 0.1, isSinking: true),
      _create('בילויים אמא', 'משתנות', 'אמא', 0, allocationRatio: 0.1, isSinking: true),
      _create('טיפוח אמא', 'משתנות', 'אמא', 0, allocationRatio: 0.1, isSinking: true),
      
      _create('בגדים ילדים', 'משתנות', 'ילדים', 0, isPerChild: true, allocationRatio: 0.05, isSinking: true),
      _create('בילויים ילדים', 'משתנות', 'ילדים', 0, isPerChild: true, allocationRatio: 0.05, isSinking: true),
      
      // === עתידיות ===
      _create('מקדמה לבית', 'עתידיות', 'רכישות גדולות', 0, isSinking: true, allocationRatio: 0.5),
      _create('תנור גז', 'עתידיות', 'רכישות קטנות', 0, isSinking: true, allocationRatio: 0.1),
      _create('בר מצווה אליעזר', 'עתידיות', 'הפקת אירועים', 0, isSinking: true, allocationRatio: 0.1),
      _create('הדברה', 'עתידיות', 'תיקונים', 0, isSinking: true, allocationRatio: 0.1),
      _create('רפואי', 'עתידיות', 'רפואי', 0, isSinking: true, allocationRatio: 0.1),
      _create('חופשה שנתית', 'עתידיות', 'חופשה שנתית', 0, isSinking: true, allocationRatio: 0.1),
      
      // === פיננסיות ===
      _create('השקעות שונות', 'פיננסיות', 'כללי', 0),
    ];

    for (var expense in initialExpenses) {
      await db.insertExpense(expense);
    }

    // --- רשימת האמת לקניות (Seed Data) ---
    final existingShopping = await db.getShoppingItems();
    if (existingShopping.isEmpty) {
      final List<ShoppingItem> initialShoppingItems = [
        // 1 שבוע
        _createShopping('4 תבניות של 12 ביצים M', 'ביצים', 52.52, 1),
        _createShopping('קופסה בשר לחמין', 'בשר', 125.00, 1),
        _createShopping('חבילת נקניקיות/המבורגר/שניצלונים', 'בשר', 20.90, 1),
        _createShopping('חצי ק\' בשר טחון', 'בשר', 50.00, 1),
        _createShopping('קופסה כרעיים עוף', 'בשר', 50.00, 1),
        _createShopping('2 יחידות פילה לברק', 'דגים', 17.47, 1),
        _createShopping('קפסולות כביסה XPO', 'חומרי ניקוי', 29.90, 1),
        _createShopping('בייבי בטטה', 'ירקות', 7.63, 1),
        _createShopping('קילו וחצי מלפפונים', 'ירקות', 13.35, 1),
        _createShopping('עגבניות שרי', 'ירקות', 10.90, 1),
        _createShopping('חצי קילו פלפלים אדומים', 'ירקות', 5.95, 1),
        _createShopping('שק תפוחי אדמה', 'ירקות', 21.39, 1),
        _createShopping('200 ג\' חמוציות', 'ירקות', 20.00, 1),
        _createShopping('לקט המושב/כרוב לבן חתוך', 'ירקות', 12.90, 1),
        _createShopping('שקית סלק מבושל', 'ירקות', 8.90, 1),
        _createShopping('קילו לימונים', 'ירקות', 8.90, 1),
        _createShopping('2 מארזי אבוקדו', 'ירקות', 32.25, 1),
        _createShopping('קילו בצל', 'ירקות', 6.90, 1),
        _createShopping('שקית גזר', 'ירקות', 7.67, 1),
        _createShopping('צלחות גדולות חד פעמיות', 'לבית', 19.90, 1),
        _createShopping('כוסות פלסטיק (פאלאס)', 'לבית', 7.90, 1),
        _createShopping('מזלגות חד פעמיים', 'לבית', 10.90, 1),
        _createShopping('תבניות אלומיניום', 'לבית', 13.50, 1),
        _createShopping('2 חלות', 'לחמים', 31.00, 1),
        _createShopping('30 פיתות', 'לחמים', 38.70, 1),
        _createShopping('250 ג\' גבינה לבנה', 'מוצרי חלב', 11.62, 1),
        _createShopping('250 ג\' גבינת קוטג\' טרה', 'מוצרי חלב', 6.30, 1),
        _createShopping('200 ג\' גבינה צהובה', 'מוצרי חלב', 10.00, 1),
        _createShopping('משקה סויה', 'מוצרי חלב', 16.90, 1),
        _createShopping('2 ליטרים חלב', 'מוצרי חלב', 14.56, 1),
        _createShopping('חבילת מעדני חלב (שוניל)', 'מוצרי חלב', 16.10, 1),
        _createShopping('פחית אננס\\בקבוק ספרינג', 'מזווה', 7.90, 1),
        _createShopping('ערמונים', 'מזווה', 8.20, 1),
        _createShopping('1 בקבוק שמן צמחי', 'מזווה', 10.00, 1),
        _createShopping('חבילת ארטיקים/קרמבו', 'ממתקים', 18.90, 1),
        _createShopping('חבילת סוכריות גומי', 'ממתקים', 50.00, 1),
        _createShopping('3 ביצי הפתעה', 'ממתקים', 18.90, 1),
        _createShopping('אגוזי מלך', 'פיצוחים', 15.00, 1),
        _createShopping('גרעיני חמניה', 'פיצוחים', 25.00, 1),
        _createShopping('קילו תפוחי עץ', 'פירות', 19.90, 1),
        _createShopping('קילו וחצי בננות', 'פירות', 19.35, 1),
        _createShopping('חצי ק\' פרי העונה', 'פירות', 40.00, 1),
        _createShopping('דמי משלוח', 'משלוח', 30.00, 1),
        
        // 2 שבועות (דו-שבועי)
        _createShopping('מרכך כביסה', 'חומרי ניקוי', 36.90, 2),
        _createShopping('סבון כלים', 'חומרי ניקוי', 13.90, 2),
        _createShopping('חבילה מגבות נייר', 'חומרי ניקוי', 12.90, 2),
        _createShopping('שרוול שום', 'ירקות', 10.90, 2),
        _createShopping('כפיות חד פעמיות', 'לבית', 10.90, 2),
        _createShopping('חמאה', 'מוצרי חלב', 9.50, 2),
        _createShopping('4 קופסאות גדולות רסק עגבניות', 'מזווה', 16.00, 2),
        _createShopping('שקית פסטה /פתיתים', 'מזווה', 7.90, 2),
        _createShopping('ק\' אורז', 'מזווה', 18.90, 2),
        _createShopping('ממרח שוקולד', 'מזווה', 14.90, 2),
        _createShopping('ניילון נצמד', 'מטבח', 19.90, 2),
        _createShopping('בקבוק יין', 'משקאות', 14.90, 2),
        _createShopping('בקבוק סירופ', 'משקאות', 15.90, 2),
        _createShopping('קופסה תמרים', 'פירות', 30.00, 2),
        _createShopping('שמפו לילדים', 'רחצה', 17.90, 2),
        _createShopping('סבון ידיים', 'רחצה', 12.90, 2),
        _createShopping('דמי משלוח סופרפארם', 'משלוח', 0.00, 2),

        // 4 שבועות (חודשי)
        _createShopping('חבילה נייר טואלט', 'חומרי ניקוי', 45.90, 4),
        _createShopping('שקיות זבל גדולות', 'חומרי ניקוי', 19.90, 4),
        _createShopping('ג\'ל ניקוי אסלה ורדים (אסטוניש)', 'חומרי ניקוי', 12.90, 4),
        _createShopping('נייר טואלט לח', 'חומרי ניקוי', 22.50, 4),
        _createShopping('פחית מלפפון חמוץ קטן', 'מזווה', 10.50, 4),
        _createShopping('שקית גריסים', 'מזווה', 17.90, 4),
        _createShopping('פחית זיתים ירוקים מגולענים קטנים', 'מזווה', 12.90, 4),
        _createShopping('שקית קוסקוס', 'מזווה', 4.90, 4),
        _createShopping('בקבוק שמן זית (Mateo)', 'מזווה', 39.90, 4),
        _createShopping('שקית חומוס', 'מזווה', 6.50, 4),
        _createShopping('שקיות בישול', 'מטבח', 11.90, 4),
        _createShopping('נייר אלומיניום', 'מטבח', 11.90, 4),
        _createShopping('שקיות סנדוויץ\'', 'מטבח', 12.90, 4),
        _createShopping('בקבוק לחיץ דבש', 'רטבים', 16.50, 4),
        _createShopping('סבון נוזלי לילדים לגוף', 'רחצה', 17.90, 4),

        // 8 שבועות (דו-חודשי)
        _createShopping('ספוגיות ניקוי כלים לשבת', 'חומרי ניקוי', 10.90, 8),
        _createShopping('מטהר אויר ומילוי לאייר וויק', 'חומרי ניקוי', 11.70, 8),
        _createShopping('מטליות ניקוי כללי × 3', 'חומרי ניקוי', 19.90, 8),
        _createShopping('תרסיס ריח טוב למייבש', 'חומרי ניקוי', 17.90, 8),
        _createShopping('נרות שעווה לשבת', 'לבית', 10.90, 8),
        _createShopping('נייר אפייה', 'מוצרי אפיה', 5.90, 8),
        _createShopping('בקבוק קטשופ', 'רטבים', 12.90, 8),
        _createShopping('משחת שיניים אורביטול ענבים+מיניונים', 'רחצה', 24.90, 8),

        // 12 שבועות (תלת-חודשי)
        _createShopping('סבון רצפה\\חומר לרובוט', 'חומרי ניקוי', 82.00, 12),
        _createShopping('ספוגיות ניקוי כלים לחול', 'חומרי ניקוי', 7.70, 12),
        _createShopping('שקיות זבל קטנות', 'חומרי ניקוי', 13.90, 12),
        _createShopping('שמן זית לנרות', 'לבית', 30.00, 12),
        _createShopping('קופסה קטנה פתיתי קוקוס', 'מוצרי אפיה', 4.70, 12),
        _createShopping('חבילה אבקת אפיה', 'מוצרי אפיה', 2.90, 12),
        _createShopping('בקבוקון תמצית וניל', 'מוצרי אפיה', 4.90, 12),
        _createShopping('קופסה קטנה פתיתי שוקולד', 'מוצרי אפיה', 15.90, 12),
        _createShopping('חרדל\\עמבה', 'רטבים', 16.50, 12),
        _createShopping('בקבוק סילאן', 'רטבים', 20.00, 12),
        _createShopping('חצי ק\' פפריקה מתוקה', 'תבלינים', 36.90, 12),
        _createShopping('ק\' כורכום', 'תבלינים', 36.90, 12),
        _createShopping('קופסה קטנה כמון (200 גר\')', 'תבלינים', 14.80, 12),
        _createShopping('קופסה קטנה קימל טחון', 'תבלינים', 16.90, 12),
        _createShopping('ק\' מלח', 'תבלינים', 2.07, 12),
        _createShopping('ק\' סוכר לבן', 'תבלינים', 5.50, 12),
        _createShopping('קופסה קטנה קינמון', 'תבלינים', 10.70, 12),
        _createShopping('קופסה קטנה פלפל שחור', 'תבלינים', 13.90, 12),
        _createShopping('משחת שיניים להורים', 'רחצה', 32.90, 12),

        // 26 שבועות (חצי שנתי)
        _createShopping('תרסיס לניקוי חדרי מקלחת', 'חומרי ניקוי', 13.90, 26),
        _createShopping('תרסיס לניקוי כללי', 'חומרי ניקוי', 14.90, 26),
        _createShopping('פתיל צף לנרות', 'לבית', 4.00, 26),
        _createShopping('כוסות נייר', 'לבית', 17.90, 26),
      ];

      for (var item in initialShoppingItems) {
        await db.insertShoppingItem(item);
      }
    }
  }

  // פונקציית עזר להוצאות
  static Expense _create(String name, String category, String parentCategory, double amount, 
      {
        bool isSinking = false, 
        bool isPerChild = false,
        Frequency frequency = Frequency.MONTHLY,
        double allocationRatio = 0.0
      }) {
    
    double actualMonthly = amount;
    if (frequency == Frequency.YEARLY) {
      actualMonthly = amount / 12;
    } else if (frequency == Frequency.BI_MONTHLY) {
      actualMonthly = amount / 2;
    }

    return Expense(
      name: name,
      category: category,
      parentCategory: parentCategory,
      monthlyAmount: actualMonthly,
      originalAmount: actualMonthly,
      frequency: frequency,
      isSinking: isSinking,
      isPerChild: isPerChild,
      allocationRatio: allocationRatio,
      date: DateTime.now().toIso8601String(),
      currentBalance: 0.0, 
    );
  }

  static ShoppingItem _createShopping(String name, String category, double price, int weeks) {
    return ShoppingItem(
      name: name,
      category: category,
      price: price,
      quantity: 1, 
      frequencyWeeks: weeks,
      status: 'צהוב', 
    );
  }
}