// 🔒 STATUS: EDITED (Added Withdrawal Model for Sinking Funds)
// ignore_for_file: constant_identifier_names

// הגדרת האפשרויות לתדירות התשלום
enum Frequency { MONTHLY, BI_MONTHLY, YEARLY }

// --- מודל בן משפחה ---
class FamilyMember {
  final int? id;
  final String name;
  final int birthYear;

  FamilyMember({this.id, required this.name, required this.birthYear});

  int get age => DateTime.now().year - birthYear;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'birthYear': birthYear,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'] ?? '',
      birthYear: map['birthYear'] ?? DateTime.now().year,
    );
  }
}

// --- מודל הוצאה ---
class Expense {
  final int? id;
  final String name;          
  final String category;      
  final String parentCategory; 
  final double monthlyAmount;  
  
  final Frequency frequency;  
  final double originalAmount; 
  final bool isSinking;        
  final bool isPerChild;      
  
  final double? targetAmount;   
  final double? currentBalance; 
  final double? allocationRatio; 
  final String? lastUpdateDate; 

  final bool isLocked;        
  final double? manualAmount; 

  final String date; 

  Expense({
    this.id,
    required this.name,
    required this.category,
    required this.parentCategory,
    required this.monthlyAmount,
    this.frequency = Frequency.MONTHLY,
    double? originalAmount,
    this.isSinking = false,
    this.isPerChild = false,
    this.targetAmount,
    this.currentBalance,
    this.allocationRatio,
    this.lastUpdateDate,
    this.isLocked = false, 
    this.manualAmount,
    required this.date,
  }) : originalAmount = originalAmount ?? monthlyAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'parentCategory': parentCategory,
      'monthlyAmount': monthlyAmount,
      'originalAmount': originalAmount,
      'frequency': frequency.index,
      'isSinking': isSinking ? 1 : 0,
      'isPerChild': isPerChild ? 1 : 0,
      'targetAmount': targetAmount,
      'currentBalance': currentBalance,
      'allocationRatio': allocationRatio,
      'lastUpdateDate': lastUpdateDate,
      'isLocked': isLocked ? 1 : 0,
      'manualAmount': manualAmount,
      'date': date,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      parentCategory: map['parentCategory'] ?? 'כללי',
      monthlyAmount: (map['monthlyAmount'] as num).toDouble(),
      originalAmount: (map['originalAmount'] as num?)?.toDouble() ?? (map['monthlyAmount'] as num).toDouble(),
      frequency: Frequency.values[map['frequency'] ?? 0],
      isSinking: (map['isSinking'] ?? 0) == 1,
      isPerChild: (map['isPerChild'] ?? 0) == 1,
      targetAmount: (map['targetAmount'] as num?)?.toDouble(),
      currentBalance: (map['currentBalance'] as num?)?.toDouble(),
      allocationRatio: (map['allocationRatio'] as num?)?.toDouble(),
      lastUpdateDate: map['lastUpdateDate'],
      isLocked: (map['isLocked'] ?? 0) == 1,
      manualAmount: (map['manualAmount'] as num?)?.toDouble(),
      date: map['date'] ?? DateTime.now().toIso8601String(),
    );
  }
}

// --- מודל משיכה מהוצאה צוברת (NEW) ---
class Withdrawal {
  final int? id;
  final int expenseId;
  final double amount;
  final String date;
  final String note;

  Withdrawal({
    this.id,
    required this.expenseId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'amount': amount,
      'date': date,
      'note': note,
    };
  }

  factory Withdrawal.fromMap(Map<String, dynamic> map) {
    return Withdrawal(
      id: map['id'],
      expenseId: map['expenseId'],
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] ?? '',
      note: map['note'] ?? '',
    );
  }
}