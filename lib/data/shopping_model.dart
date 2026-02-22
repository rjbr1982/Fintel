class ShoppingItem {
  final int? id;
  final String name;
  final String category;
  final double price;
  final int quantity;
  final int frequencyWeeks;
  final String? lastPurchaseDate;
  final String status;
  final bool isChecked;

  ShoppingItem({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.frequencyWeeks,
    this.lastPurchaseDate,
    this.status = 'צהוב',
    this.isChecked = false,
  });

  // --- המוח של האקסל: לוגיקת ניהול תאריכים ותדירות ---

  // הפיכת התאריך מהדאטה-בייס לאובייקט DateTime לצורך חישובים
  DateTime? get lastPurchaseDateTime {
    if (lastPurchaseDate == null) return null;
    try {
      return DateTime.parse(lastPurchaseDate!);
    } catch (_) {
      return null;
    }
  }

  // בדיקה האם הקנייה מוקדמת מדי (חריגת תדירות)
  // פונקציה זו מחזירה אמת אם עבר פחות זמן מהתדירות שהוגדרה
  bool get isFrequencyViolation {
    final lastDate = lastPurchaseDateTime;
    if (lastDate == null) return false;

    final daysSincePurchase = DateTime.now().difference(lastDate).inDays;
    final requiredDays = frequencyWeeks * 7;

    // חריגה אם עברו פחות מ-90% מהזמן הנדרש (גמישות של יומיים-שלושה)
    return daysSincePurchase < (requiredDays * 0.9);
  }

  // מחשב כמה ימים עברו מהקנייה האחרונה (לצורך תצוגה "לפני X ימים")
  int get daysSinceLastPurchase {
    final lastDate = lastPurchaseDateTime;
    if (lastDate == null) return -1;
    return DateTime.now().difference(lastDate).inDays;
  }

  // ------------------------------------------------

  int get displayMonths => frequencyWeeks ~/ 4;
  int get displayWeeks => frequencyWeeks % 4;

  ShoppingItem copyWith({
    int? id,
    String? name,
    String? category,
    double? price,
    int? quantity,
    int? frequencyWeeks,
    String? lastPurchaseDate,
    String? status,
    bool? isChecked,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      frequencyWeeks: frequencyWeeks ?? this.frequencyWeeks,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      status: status ?? this.status,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'frequency_weeks': frequencyWeeks,
      'last_purchase_date': lastPurchaseDate,
      'status': status,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      name: map['name'] ?? '',
      category: map['category'] ?? 'כללי',
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] ?? 1,
      frequencyWeeks: map['frequency_weeks'] ?? 1,
      lastPurchaseDate: map['last_purchase_date'],
      status: map['status'] ?? 'צהוב',
      isChecked: false,
    );
  }
}