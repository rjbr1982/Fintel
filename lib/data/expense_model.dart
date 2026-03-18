// 🔒 STATUS: EDITED (Added actualBankDeposit and copyWith for Sinking Funds Control)
// ignore_for_file: constant_identifier_names

import 'dart:convert';

// הגדרת האפשרויות לתדירות התשלום
enum Frequency { MONTHLY, BI_MONTHLY, YEARLY }

// --- תפקידים במשפחה (סעיף 11.8) ---
enum FamilyRole { parent, child }

// --- מודל בן משפחה ---
class FamilyMember {
  final int? id;
  final String name;
  final int birthYear;
  final FamilyRole role; 

  FamilyMember({
    this.id, 
    required this.name, 
    required this.birthYear,
    this.role = FamilyRole.child, 
  });

  int get age => DateTime.now().year - birthYear;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'birthYear': birthYear,
      'role': role.index,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'] ?? '',
      birthYear: map['birthYear'] ?? DateTime.now().year,
      role: map['role'] != null ? FamilyRole.values[map['role']] : FamilyRole.child,
    );
  }
}

// --- מודל תת-סעיף עסק (הכנסה/הוצאה פנימית) ---
class BusinessSubItem {
  String id;
  String name;
  double amount;

  BusinessSubItem({required this.id, required this.name, required this.amount});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'amount': amount};
  
  factory BusinessSubItem.fromMap(Map<String, dynamic> map) {
    return BusinessSubItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// --- מודל הוצאה / הכנסה / עסק ---
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

  // --- שדות מנוע ממוצע שכר ---
  final bool isDynamicSalary;
  final String? salaryStartDate;

  // --- שדות לעסק והכנסה פסיבית ---
  final bool isBusiness;
  final String businessIncomes; // JSON String
  final String businessExpenses; // JSON String
  final double businessWorkingHours; // Weekly Hours

  // --- שדה תשתית גמישה ---
  final bool isCustom; 

  final String date; 

  // --- שדה בקרת הפקדה בבנק (קופות צוברות) ---
  final double? actualBankDeposit; 

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
    this.isDynamicSalary = false,
    this.salaryStartDate,
    this.isBusiness = false,
    this.businessIncomes = '[]',
    this.businessExpenses = '[]',
    this.businessWorkingHours = 0.0,
    this.isCustom = false, 
    required this.date,
    this.actualBankDeposit,
  }) : originalAmount = originalAmount ?? monthlyAmount;

  // --- מתודת העתקה (לעדכון כירורגי במצב) ---
  Expense copyWith({
    int? id,
    String? name,
    String? category,
    String? parentCategory,
    double? monthlyAmount,
    Frequency? frequency,
    double? originalAmount,
    bool? isSinking,
    bool? isPerChild,
    double? targetAmount,
    double? currentBalance,
    double? allocationRatio,
    String? lastUpdateDate,
    bool? isLocked,
    double? manualAmount,
    bool? isDynamicSalary,
    String? salaryStartDate,
    bool? isBusiness,
    String? businessIncomes,
    String? businessExpenses,
    double? businessWorkingHours,
    bool? isCustom,
    String? date,
    double? actualBankDeposit,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      parentCategory: parentCategory ?? this.parentCategory,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      frequency: frequency ?? this.frequency,
      originalAmount: originalAmount ?? this.originalAmount,
      isSinking: isSinking ?? this.isSinking,
      isPerChild: isPerChild ?? this.isPerChild,
      targetAmount: targetAmount ?? this.targetAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      allocationRatio: allocationRatio ?? this.allocationRatio,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      isLocked: isLocked ?? this.isLocked,
      manualAmount: manualAmount ?? this.manualAmount,
      isDynamicSalary: isDynamicSalary ?? this.isDynamicSalary,
      salaryStartDate: salaryStartDate ?? this.salaryStartDate,
      isBusiness: isBusiness ?? this.isBusiness,
      businessIncomes: businessIncomes ?? this.businessIncomes,
      businessExpenses: businessExpenses ?? this.businessExpenses,
      businessWorkingHours: businessWorkingHours ?? this.businessWorkingHours,
      isCustom: isCustom ?? this.isCustom,
      date: date ?? this.date,
      actualBankDeposit: actualBankDeposit ?? this.actualBankDeposit,
    );
  }

  // --- לוגיקת עסק (Business Logic) ---
  List<BusinessSubItem> get parsedBusinessIncomes {
    if (businessIncomes.isEmpty || businessIncomes == '[]') return [];
    try {
      final List decoded = jsonDecode(businessIncomes);
      return decoded.map((e) => BusinessSubItem.fromMap(e)).toList();
    } catch(e) { return []; }
  }

  List<BusinessSubItem> get parsedBusinessExpenses {
    if (businessExpenses.isEmpty || businessExpenses == '[]') return [];
    try {
      final List decoded = jsonDecode(businessExpenses);
      return decoded.map((e) => BusinessSubItem.fromMap(e)).toList();
    } catch(e) { return []; }
  }

  double getBusinessNetProfit() {
    if (!isBusiness) return 0.0;
    double inc = parsedBusinessIncomes.fold(0.0, (sum, item) => sum + item.amount);
    double exp = parsedBusinessExpenses.fold(0.0, (sum, item) => sum + item.amount);
    return inc - exp; // יכול להיות שלילי (הפסד)
  }

  bool get isPassive {
    // נכס פסיבי מוגדר: 1. קיים רווח תזרימי חיובי, 2. דורש 4 שעות שבועיות או פחות.
    return isBusiness && getBusinessNetProfit() > 0 && businessWorkingHours <= 4.0;
  }

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
      'isDynamicSalary': isDynamicSalary ? 1 : 0,
      'salaryStartDate': salaryStartDate,
      'isBusiness': isBusiness ? 1 : 0,
      'businessIncomes': businessIncomes,
      'businessExpenses': businessExpenses,
      'businessWorkingHours': businessWorkingHours,
      'isCustom': isCustom ? 1 : 0,
      'date': date,
      'actualBankDeposit': actualBankDeposit,
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
      isDynamicSalary: (map['isDynamicSalary'] ?? 0) == 1,
      salaryStartDate: map['salaryStartDate'],
      isBusiness: (map['isBusiness'] ?? 0) == 1,
      businessIncomes: map['businessIncomes'] ?? '[]',
      businessExpenses: map['businessExpenses'] ?? '[]',
      businessWorkingHours: (map['businessWorkingHours'] as num?)?.toDouble() ?? 0.0,
      isCustom: (map['isCustom'] ?? 0) == 1,
      date: map['date'] ?? DateTime.now().toIso8601String(),
      actualBankDeposit: (map['actualBankDeposit'] as num?)?.toDouble(),
    );
  }
}

// --- מודל משיכה מהוצאה צוברת ---
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

// --- מודל תיעוד ממוצע שכר ---
class SalaryRecord {
  final int? id;
  final int expenseId; 
  final String monthYear; 
  final double netAmount;
  final double hours;

  SalaryRecord({
    this.id,
    required this.expenseId,
    required this.monthYear,
    required this.netAmount,
    required this.hours,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'monthYear': monthYear,
      'netAmount': netAmount,
      'hours': hours,
    };
  }

  factory SalaryRecord.fromMap(Map<String, dynamic> map) {
    return SalaryRecord(
      id: map['id'],
      expenseId: map['expenseId'],
      monthYear: map['monthYear'] ?? '',
      netAmount: (map['netAmount'] as num).toDouble(),
      hours: (map['hours'] as num).toDouble(),
    );
  }
}

// --- סטטוס משיכה מתוכננת ---
enum PlannedWithdrawalStatus { pending, executed }

// --- מודל הוצאה מתוכננת (מנהל משיכות חכם) ---
class PlannedWithdrawal {
  final int? id;
  final String name;
  final double amount;
  final String bucketName; // שם הקופה המאוחדת (למשל 'רכב' או 'אבא')
  final String targetDate; // תאריך יעד לתשלום
  final PlannedWithdrawalStatus status;

  PlannedWithdrawal({
    this.id,
    required this.name,
    required this.amount,
    required this.bucketName,
    required this.targetDate,
    this.status = PlannedWithdrawalStatus.pending,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'bucketName': bucketName,
      'targetDate': targetDate,
      'status': status.index,
    };
  }

  factory PlannedWithdrawal.fromMap(Map<String, dynamic> map) {
    return PlannedWithdrawal(
      id: map['id'],
      name: map['name'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      bucketName: map['bucketName'] ?? '',
      targetDate: map['targetDate'] ?? DateTime.now().toIso8601String(),
      status: map['status'] != null 
          ? PlannedWithdrawalStatus.values[map['status']] 
          : PlannedWithdrawalStatus.pending,
    );
  }
}