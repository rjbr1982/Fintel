// 🔒 STATUS: EDITED (Fixed Housing/Utilities exclusion and expanded universal Shopping Seed List)
import '../data/database_helper.dart';
import '../data/expense_model.dart';
import '../data/shopping_model.dart';

class SeedService {
  
  static Future<void> generateInitialData({
    required String gender,
    required String maritalStatus,
    required String vehicleType,
    required String housingType,
    required int childrenCount,
    required double income1,
    required double income2,
    required bool includeReligion,
  }) async {
    final db = DatabaseHelper.instance;
    
    final existingExpenses = await db.getExpenses();
    if (existingExpenses.isNotEmpty) {
      return; 
    }

    // --- לוגיקת קביעת שמות הישויות (State Machine) ---
    String parent1Name = '';
    String parent2Name = '';

    if (maritalStatus == 'single') {
      if (childrenCount == 0) {
        parent1Name = 'אישי';
      } else {
        parent1Name = gender == 'male' ? 'אבא' : 'אמא';
      }
    } else { // married
      if (childrenCount == 0) {
        parent1Name = 'בעל';
        parent2Name = 'אישה';
      } else {
        parent1Name = 'אבא';
        parent2Name = 'אמא';
      }
    }

    final List<Expense> initialExpenses = [
      
      // === הכנסות ===
      _create(
        maritalStatus == 'single' ? (parent1Name == 'אישי' ? 'משכורת אישית' : 'הכנסת $parent1Name') : 'הכנסת $parent1Name', 
        'הכנסות', 'הכנסות', income1 > 0 ? income1 : 10000
      ), 
      if (maritalStatus == 'married') 
        _create('הכנסת $parent2Name', 'הכנסות', 'הכנסות', income2 > 0 ? income2 : 8000),
      if (childrenCount > 0)
        _create('קצבת ילדים', 'הכנסות', 'הכנסות', childrenCount * 170.0),
      
      // === קבועות ===
      if (includeReligion) _create('צדקה ומעשרות', 'קבועות', 'צדקה', 0)
      else _create('תרומות לקהילה', 'קבועות', 'תרומות', 0),

      if (housingType != 'none') ...[
        _create(housingType == 'mortgage' ? 'משכנתא' : 'שכירות', 'קבועות', 'דיור', 3300),
        _create('וועד בית', 'קבועות', 'דיור', 150),
        _create('ארנונה', 'קבועות', 'דיור', 380),
        _create('הובלה ותיקונים', 'קבועות', 'דיור', 0, isSinking: true),
        _create('חשמל', 'קבועות', 'מגורים', 750, frequency: Frequency.BI_MONTHLY), 
        _create('מים', 'קבועות', 'מגורים', 250, frequency: Frequency.BI_MONTHLY),
        _create('גז', 'קבועות', 'מגורים', 50),
      ],
      
      // רכב (מוזרק דינמית לפי בחירה)
      if (vehicleType == 'car' || vehicleType == 'two_cars') ...[
        _create('ביטוח (רכב 1)', 'קבועות', 'רכב', 3500, isSinking: true, frequency: Frequency.YEARLY),
        _create('טסט (רכב 1)', 'קבועות', 'רכב', 1250, isSinking: true, frequency: Frequency.YEARLY),
        _create('טיפול (רכב 1)', 'קבועות', 'רכב', 2000, isSinking: true, frequency: Frequency.YEARLY),
        _create('תיקונים (רכב 1)', 'קבועות', 'רכב', 500, isSinking: true),
        _create('דלק (רכב 1)', 'קבועות', 'רכב', 500), 
      ],
      if (vehicleType == 'two_cars') ...[
        _create('ביטוח (רכב 2)', 'קבועות', 'רכב', 3500, isSinking: true, frequency: Frequency.YEARLY),
        _create('טסט (רכב 2)', 'קבועות', 'רכב', 1250, isSinking: true, frequency: Frequency.YEARLY),
        _create('טיפול (רכב 2)', 'קבועות', 'רכב', 2000, isSinking: true, frequency: Frequency.YEARLY),
        _create('תיקונים (רכב 2)', 'קבועות', 'רכב', 500, isSinking: true),
        _create('דלק (רכב 2)', 'קבועות', 'רכב', 500), 
      ],
      if (vehicleType == 'motorcycle') ...[
        _create('ביטוח', 'קבועות', 'רכב', 3500, isSinking: true, frequency: Frequency.YEARLY),
        _create('טסט', 'קבועות', 'רכב', 250, isSinking: true, frequency: Frequency.YEARLY),
        _create('טיפול', 'קבועות', 'רכב', 500, isSinking: true, frequency: Frequency.YEARLY),
        _create('תיקונים', 'קבועות', 'רכב', 50, isSinking: true),
        _create('דלק', 'קבועות', 'רכב', 150), 
      ], 
      
      // מדיה ותקשורת
      _create('סלולר ואינטרנט', 'קבועות', 'מדיה', 150),
      _create('מנויים דיגיטליים', 'קבועות', 'מדיה', 0),
      
      // ילדים - קבועות
      if (childrenCount > 0) ...[
        _create('שכר לימוד', 'קבועות', 'ילדים - קבועות', 0, isPerChild: true, isSinking: true),
        _create('ציוד בית ספר', 'קבועות', 'ילדים - קבועות', 0, isPerChild: true, isSinking: true, frequency: Frequency.YEARLY),
        _create('חוגים', 'קבועות', 'ילדים - קבועות', 0, isPerChild: true, isSinking: true),
        _create('מתנות לימי הולדת', 'קבועות', 'ילדים - קבועות', 0, isPerChild: true, isSinking: true),
        _create('קייטנות', 'קבועות', 'ילדים - קבועות', 0, isPerChild: true, isSinking: true, frequency: Frequency.YEARLY),
      ],
      
      // חגים ואירועים
      if (includeReligion) ...[
        _create('ראש השנה', 'קבועות', 'חגים', 500, isSinking: true, frequency: Frequency.YEARLY),
        _create('יום כיפור', 'קבועות', 'חגים', 500, isSinking: true, frequency: Frequency.YEARLY),
        _create('סוכות', 'קבועות', 'חגים', 500, isSinking: true, frequency: Frequency.YEARLY),
        _create('שמחת תורה', 'קבועות', 'חגים', 500, isSinking: true, frequency: Frequency.YEARLY),
        _create('חנוכה', 'קבועות', 'חגים', 200, isSinking: true, frequency: Frequency.YEARLY),
        _create("ט''ו בשבט", 'קבועות', 'חגים', 200, isSinking: true, frequency: Frequency.YEARLY),
        _create('פורים', 'קבועות', 'חגים', 200, isSinking: true, frequency: Frequency.YEARLY),
        _create('פסח', 'קבועות', 'חגים', 1500, isSinking: true, frequency: Frequency.YEARLY),
        _create('יום העצמאות', 'קבועות', 'חגים', 500, isSinking: true, frequency: Frequency.YEARLY),
        _create("ל''ג בעומר", 'קבועות', 'חגים', 500, isSinking: true, frequency: Frequency.YEARLY),
        _create('שבועות', 'קבועות', 'חגים', 500, isSinking: true, frequency: Frequency.YEARLY),
      ] else ...[
        _create('חגים ואירועים מיוחדים', 'קבועות', 'חגים', 4000, isSinking: true, frequency: Frequency.YEARLY),
      ],
      
      // שונות קבועות
      _create('קופת חולים / ביטוחים', 'קבועות', 'קופת חולים', 0),
      _create('נסיעות (תחב"צ/מוניות)', 'קבועות', 'נסיעות', 100, isSinking: true),
      _create('תספורת', 'קבועות', 'תספורת', 0),
      _create('קטנות לבית (פארם/שונות)', 'קבועות', 'קטנות לבית', 100, isSinking: true),

      // === משתנות (קניות - עוגן) ===
      _create('קניות', 'משתנות', 'קניות', 3500),

      // === משתנות (חלוקה דינמית לפי משפחה) ===
      if (maritalStatus == 'single' && childrenCount > 0) ...[
        _create('בגדים $parent1Name', 'משתנות', parent1Name, 0, allocationRatio: 0.28, isSinking: true),
        _create('בילויים $parent1Name', 'משתנות', parent1Name, 0, allocationRatio: 0.33, isSinking: true),
        if (gender == 'female') 
          _create('טיפוח $parent1Name', 'משתנות', parent1Name, 0, allocationRatio: 0.15, isSinking: true),
        _create('בגדים ילדים', 'משתנות', 'ילדים - משתנות', 0, isPerChild: true, allocationRatio: 0.12, isSinking: true),
        _create('בילויים ילדים', 'משתנות', 'ילדים - משתנות', 0, isPerChild: true, allocationRatio: 0.12, isSinking: true),
      ] else if (maritalStatus == 'married' && childrenCount == 0) ...[
        _create('בגדים $parent1Name', 'משתנות', parent1Name, 0, allocationRatio: 0.25, isSinking: true),
        _create('בילויים $parent1Name', 'משתנות', parent1Name, 0, allocationRatio: 0.20, isSinking: true),
        _create('בגדים $parent2Name', 'משתנות', parent2Name, 0, allocationRatio: 0.15, isSinking: true),
        _create('בילויים $parent2Name', 'משתנות', parent2Name, 0, allocationRatio: 0.25, isSinking: true),
        _create('טיפוח $parent2Name', 'משתנות', parent2Name, 0, allocationRatio: 0.15, isSinking: true),
      ] else if (maritalStatus == 'single' && childrenCount == 0) ...[
        _create('בגדים $parent1Name', 'משתנות', parent1Name, 0, allocationRatio: gender == 'female' ? 0.40 : 0.45, isSinking: true),
        _create('בילויים $parent1Name', 'משתנות', parent1Name, 0, allocationRatio: gender == 'female' ? 0.45 : 0.55, isSinking: true),
        if (gender == 'female') 
          _create('טיפוח $parent1Name', 'משתנות', parent1Name, 0, allocationRatio: 0.15, isSinking: true),
      ] else ...[
        _create('בגדים $parent1Name', 'משתנות', parent1Name, 0, allocationRatio: 0.19, isSinking: true),
        _create('בילויים $parent1Name', 'משתנות', parent1Name, 0, allocationRatio: 0.14, isSinking: true),
        _create('בגדים $parent2Name', 'משתנות', parent2Name, 0, allocationRatio: 0.09, isSinking: true),
        _create('בילויים $parent2Name', 'משתנות', parent2Name, 0, allocationRatio: 0.19, isSinking: true),
        _create('טיפוח $parent2Name', 'משתנות', parent2Name, 0, allocationRatio: 0.15, isSinking: true),
        _create('בגדים ילדים', 'משתנות', 'ילדים - משתנות', 0, isPerChild: true, allocationRatio: 0.12, isSinking: true),
        _create('בילויים ילדים', 'משתנות', 'ילדים - משתנות', 0, isPerChild: true, allocationRatio: 0.12, isSinking: true),
      ],
      
      // === עתידיות ===
      _create('רכישות גדולות (רכב/נכס)', 'עתידיות', 'רכישות גדולות', 0, isSinking: true, allocationRatio: 0.67),
      _create('מוצרי חשמל וריהוט', 'עתידיות', 'רכישות קטנות', 0, isSinking: true, allocationRatio: 0.07),
      _create('אירועים משפחתיים (בר מצווה/חתונה)', 'עתידיות', 'הפקת אירועים', 0, isSinking: true, allocationRatio: 0.11),
      _create('תחזוקת נכס ושיפוצים', 'עתידיות', 'תיקונים', 0, isSinking: true, allocationRatio: 0.02),
      _create('בלת"ם רפואי (חירום)', 'עתידיות', 'רפואי', 0, isSinking: true, allocationRatio: 0.02),
      _create('חופשה שנתית', 'עתידיות', 'חופשה שנתית', 0, isSinking: true, allocationRatio: 0.11),
      
      // === פיננסיות ===
      _create('השקעות ותיקי ני"ע', 'פיננסיות', 'כללי', 0),
    ];

    for (var expense in initialExpenses) {
      await db.insertExpense(expense);
    }

    // --- רשימת האמת לקניות (Seed Data) ---
    final existingShopping = await db.getShoppingItems();
    if (existingShopping.isEmpty) {
      final List<ShoppingItem> initialShoppingItems = [
        _createShopping('ביצים (תבנית)', 'ביצים', 35.0, 1),
        _createShopping('חלב', 'מוצרי חלב', 6.0, 1),
        _createShopping('גבינות', 'מוצרי חלב', 30.0, 1),
        _createShopping('לחם/פיתות', 'לחמים', 15.0, 1),
        _createShopping('עגבניות', 'ירקות', 10.0, 1),
        _createShopping('מלפפונים', 'ירקות', 10.0, 1),
        _createShopping('פירות', 'פירות', 30.0, 1),
        _createShopping('בשר/עוף לשבת', 'בשר', 100.0, 1),
        _createShopping('דגים', 'דגים', 50.0, 2),
        _createShopping('נייר טואלט', 'חומרי ניקוי', 40.0, 4),
        _createShopping('סבון כלים', 'חומרי ניקוי', 15.0, 4),
        _createShopping('אבקת כביסה', 'חומרי ניקוי', 35.0, 4),
        _createShopping('שמפו/מרכך', 'טואלטיקה', 30.0, 4),
        _createShopping('משחת שיניים', 'טואלטיקה', 15.0, 4),
        _createShopping('פסטה/אורז', 'מזווה', 20.0, 2),
        _createShopping('שמן', 'מזווה', 15.0, 4),
        _createShopping('קפה/תה', 'מזווה', 25.0, 4),
        _createShopping('סוכר/מלח', 'מזווה', 10.0, 4),
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