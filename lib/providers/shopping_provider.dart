import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/shopping_model.dart';

class ShoppingProvider with ChangeNotifier {
  List<ShoppingItem> _items = [];

  List<ShoppingItem> get items => _items;

  List<String> get availableCategories {
    final categories = _items.map((e) => e.category).toSet().toList();
    categories.sort();
    return ['הכל', ...categories];
  }

  // --- 1. תוכנית אסטרטגית (מה שאמור לעלות חודש ממוצע) ---
  double get totalMonthlyPlannedCost {
    double total = 0.0;
    for (var item in _items) {
      double monthlyRatio = 4.0 / item.frequencyWeeks;
      total += (item.price * item.quantity * monthlyRatio);
    }
    return total;
  }

  // --- 2. סכום הסל הנוכחי (מה שסימנת עכשיו בשבוע זה) ---
  double get currentBasketTotal {
    return _items
        .where((item) => item.isChecked)
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // --- 3. ביצוע בפועל החודש (מה שכבר נקנה ותועד) ---
  double get actualMonthlySpent {
    double total = 0.0;
    final now = DateTime.now();
    for (var item in _items) {
      final lastDate = item.lastPurchaseDateTime;
      if (lastDate != null && 
          lastDate.month == now.month && 
          lastDate.year == now.year) {
        total += (item.price * item.quantity);
      }
    }
    return total;
  }

  // --- עדכון שם קטגוריה גורף ---
  Future<void> renameCategory(String oldName, String newName) async {
    final db = DatabaseHelper.instance;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].category == oldName) {
        _items[i] = _items[i].copyWith(category: newName);
        await db.updateShoppingItem(_items[i]);
      }
    }
    notifyListeners();
  }

  // פקודת "סיים קנייה" - מעדכנת תאריכים ושומרת להיסטוריה
  Future<void> finalizePurchase() async {
    final db = DatabaseHelper.instance;
    final nowStr = DateTime.now().toIso8601String();

    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isChecked) {
        _items[i] = _items[i].copyWith(
          lastPurchaseDate: nowStr,
          isChecked: false,
        );
        await db.updateShoppingItem(_items[i]);
      }
    }
    notifyListeners();
  }

  Future<void> loadItems() async {
    final db = DatabaseHelper.instance;
    _items = await db.getShoppingItems();
    
    if (_items.isEmpty) {
      await seedDefaultItems();
    } else {
      notifyListeners();
    }
  }

  Future<void> resetAndSeed() async {
    final db = DatabaseHelper.instance;
    final currentItems = await db.getShoppingItems();
    for (var item in currentItems) {
      if (item.id != null) await db.deleteShoppingItem(item.id!);
    }
    await loadItems();
  }

  Future<void> seedDefaultItems() async {
    final db = DatabaseHelper.instance;
    final List<ShoppingItem> defaultItems = [
      ShoppingItem(name: '4 תבניות של 12 ביצים M', category: 'ביצים', price: 52.52, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'קופסה בשר לחמין', category: 'בשר', price: 125.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'חבילת נקניקיות/המבורגר/שניצלונים', category: 'בשר', price: 20.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'חצי ק\' בשר טחון', category: 'בשר', price: 50.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'קופסה כרעיים עוף', category: 'בשר', price: 50.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: '2 יחידות פילה לברק', category: 'דגים', price: 17.47, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'קפסולות כביסה XPO', category: 'חומרי ניקוי', price: 29.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'בייבי בטטה', category: 'ירקות', price: 7.63, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'קילו וחצי מלפפונים', category: 'ירקות', price: 13.35, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'עגבניות שרי', category: 'ירקות', price: 10.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'חצי קילו פלפלים אדומים', category: 'ירקות', price: 5.95, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'שק תפוחי אדמה', category: 'ירקות', price: 21.39, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: '200 ג\' חמוציות', category: 'ירקות', price: 20.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'לקט המושב/כרוב לבן חתוך', category: 'ירקות', price: 12.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'שקית סלק מבושל', category: 'ירקות', price: 8.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'קילו לימונים', category: 'ירקות', price: 8.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: '2 מארזי אבוקדו', category: 'ירקות', price: 32.25, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'קילו בצל', category: 'ירקות', price: 6.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'שקית גזר', category: 'ירקות', price: 7.67, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'צלחות גדולות חד פעמיות', category: 'לבית', price: 19.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'כוסות פלסטיק', category: 'לבית', price: 7.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'מזלגות חד פעמיים', category: 'לבית', price: 10.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'תבניות אלומיניום', category: 'לבית', price: 13.50, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: '2 חלות', category: 'לחמים', price: 31.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: '30 פיתות', category: 'לחמים', price: 38.70, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: '250 ג\' גבינה לבנה', category: 'מוצרי חלב', price: 11.62, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: '250 ג\' קוטג\'', category: 'מוצרי חלב', price: 6.30, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: '200 ג\' גבינה צהובה', category: 'מוצרי חלב', price: 10.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'משקה סויה', category: 'מוצרי חלב', price: 16.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: '2 ליטר חלב', category: 'מוצרי חלב', price: 14.56, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'מעדני חלב', category: 'מוצרי חלב', price: 16.10, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'אננס/ספרינג', category: 'מזווה', price: 7.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'ערמונים', category: 'מזווה', price: 8.20, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'שמן צמחי', category: 'מזווה', price: 10.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'ארטיקים/קרמבו', category: 'ממתקים', price: 18.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'סוכריות גומי', category: 'ממתקים', price: 50.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: '3 ביצי הפתעה', category: 'ממתקים', price: 18.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'אגוזי מלך', category: 'פיצוחים', price: 15.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'גרעיני חמניה', category: 'פיצוחים', price: 25.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'קילו תפוחי עץ', category: 'פירות', price: 19.90, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'בננות', category: 'פירות', price: 19.35, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'חצי ק\' פרי העונה', category: 'פירות', price: 40.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'דמי משלוח', category: 'משלוח', price: 30.0, quantity: 1, frequencyWeeks: 1),
      ShoppingItem(name: 'מרכך כביסה פרש', category: 'חומרי ניקוי', price: 36.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: '4 קופסאות רסק עגבניות', category: 'מזווה', price: 16.0, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'בקבוק יין', category: 'משקאות', price: 14.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'קופסה תמרים', category: 'פירות', price: 30.0, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'סבון כלים', category: 'חומרי ניקוי', price: 13.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'מגבות נייר', category: 'חומרי ניקוי', price: 12.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'שרוול שום', category: 'ירקות', price: 10.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'כפיות חד פעמיות', category: 'לבית', price: 10.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'חמאה', category: 'מוצרי חלב', price: 9.50, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'פסטה/פתיתים', category: 'מזווה', price: 7.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'ק\' אורז', category: 'מזווה', price: 18.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'ממרח שוקולד', category: 'מזווה', price: 14.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'ניילון נצמד', category: 'מטבח', price: 19.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'בקבוק סירופ', category: 'משקאות', price: 15.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'שמפו לילדים', category: 'רחצה', price: 17.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'סבון ידיים', category: 'רחצה', price: 12.90, quantity: 1, frequencyWeeks: 2),
      ShoppingItem(name: 'מלפפון חמוץ קטן', category: 'מזווה', price: 10.50, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'שקית גריסים', category: 'מזווה', price: 17.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'חבילה נייר טואלט', category: 'חומרי ניקוי', price: 45.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'שקיות זבל גדולות', category: 'חומרי ניקוי', price: 19.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'ג\'ל ניקוי אסלה', category: 'חומרי ניקוי', price: 12.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'נייר טואלט לח', category: 'חומרי ניקוי', price: 22.50, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'זיתים ירוקים', category: 'מזווה', price: 12.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'שקית קוסקוס', category: 'מזווה', price: 4.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'שמן זית Mateo', category: 'מזווה', price: 39.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'שקית חומוס', category: 'מזווה', price: 6.50, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'שקיות בישול', category: 'מטבח', price: 11.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'נייר אלומיניום', category: 'מטבח', price: 11.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'שקיות סנדוויץ\'', category: 'מטבח', price: 12.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'סבון נוזלי גוף לילדים', category: 'רחצה', price: 17.90, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'דבש לחיץ', category: 'רטבים', price: 16.50, quantity: 1, frequencyWeeks: 4),
      ShoppingItem(name: 'ספוגיות כלים לשבת', category: 'חומרי ניקוי', price: 10.90, quantity: 1, frequencyWeeks: 8),
      ShoppingItem(name: 'מטהר אויר אייר וויק', category: 'חומרי ניקוי', price: 11.70, quantity: 1, frequencyWeeks: 8),
      ShoppingItem(name: 'מטליות ניקוי כללי', category: 'חומרי ניקוי', price: 19.90, quantity: 1, frequencyWeeks: 8),
      ShoppingItem(name: 'תרסיס ריח למייבש', category: 'חומרי ניקוי', price: 17.90, quantity: 1, frequencyWeeks: 8),
      ShoppingItem(name: 'נרות שעווה לשבת', category: 'לבית', price: 10.90, quantity: 1, frequencyWeeks: 8),
      ShoppingItem(name: 'נייר אפייה', category: 'מוצרי אפיה', price: 5.90, quantity: 1, frequencyWeeks: 8),
      ShoppingItem(name: 'משחת שיניים ילדים', category: 'רחצה', price: 24.90, quantity: 1, frequencyWeeks: 8),
      ShoppingItem(name: 'בקבוק קטשופ', category: 'רטבים', price: 12.90, quantity: 1, frequencyWeeks: 8),
      ShoppingItem(name: 'חרדל/עמבה', category: 'רטבים', price: 16.50, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'סבון רצפה/רובוט', category: 'חומרי ניקוי', price: 82.00, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'ספוגיות כלים לחול', category: 'חומרי ניקוי', price: 7.70, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'שקיות זבל קטנות', category: 'חומרי ניקוי', price: 13.90, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'שמן זית לנרות', category: 'לבית', price: 30.0, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'פתיתי קוקוס', category: 'מוצרי אפיה', price: 4.70, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'אבקת אפיה', category: 'מוצרי אפיה', price: 2.90, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'תמצית וניל', category: 'מוצרי אפיה', price: 4.90, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'פתיתי שוקולד', category: 'מוצרי אפיה', price: 15.90, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'משחת שיניים הורים', category: 'רחצה', price: 32.90, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'בקבוק סילאן', category: 'רטבים', price: 20.0, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'פפריקה מתוקה', category: 'תבלינים', price: 36.90, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'כורכום', category: 'תבלינים', price: 36.90, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'כמון', category: 'תבלינים', price: 14.80, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'קימל טחון', category: 'תבלינים', price: 16.90, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'מלח', category: 'תבלינים', price: 2.07, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'סוכר לבן', category: 'תבלינים', price: 5.50, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'קינמון', category: 'תבלינים', price: 10.70, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'פלפל שחור', category: 'תבלינים', price: 13.90, quantity: 1, frequencyWeeks: 12),
      ShoppingItem(name: 'תרסיס מקלחון', category: 'חומרי ניקוי', price: 13.90, quantity: 1, frequencyWeeks: 24),
      ShoppingItem(name: 'תרסיס ניקוי כללי', category: 'חומרי ניקוי', price: 14.90, quantity: 1, frequencyWeeks: 24),
      ShoppingItem(name: 'פתיל צף לנרות', category: 'לבית', price: 4.00, quantity: 1, frequencyWeeks: 24),
      ShoppingItem(name: 'כוסות נייר', category: 'לבית', price: 17.90, quantity: 1, frequencyWeeks: 24),
    ];

    for (var item in defaultItems) {
      await db.insertShoppingItem(item);
    }
    
    _items = await db.getShoppingItems();
    notifyListeners();
  }

  Future<void> addItem(ShoppingItem item) async {
    final db = DatabaseHelper.instance;
    await db.insertShoppingItem(item);
    await loadItems();
  }

  Future<void> updateItem(ShoppingItem item) async {
    final db = DatabaseHelper.instance;
    await db.updateShoppingItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    final db = DatabaseHelper.instance;
    await db.deleteShoppingItem(id);
    await loadItems();
  }

  bool isChecked(int id) {
    final index = _items.indexWhere((e) => e.id == id);
    return index != -1 ? _items[index].isChecked : false;
  }

  void toggleItem(int id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isChecked: !_items[index].isChecked);
      notifyListeners();
    }
  }

  void clearAllChecks() {
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isChecked: false);
    }
    notifyListeners();
  }
}