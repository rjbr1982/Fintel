class Debt {
  final int? id;
  final String name;
  final double originalBalance;
  final double currentBalance;
  final double monthlyPayment;
  final String date;

  Debt({
    this.id,
    required this.name,
    required this.originalBalance,
    required this.currentBalance,
    required this.monthlyPayment,
    required this.date,
  });

  // --- לוגיקת המנמיכות (סעיף 9.3.1) ---
  
  /// חישוב מקדם הזמן (T): כמה חודשים נותרו לסיום טבעי של החוב.
  /// משמש את מנוע המיון של ה"צלף".
  double get timeFactor {
    if (monthlyPayment <= 0) return 9999; // מניעת חלוקה ב-0
    return currentBalance / monthlyPayment;
  }

  /// אחוז התקדמות פסיכולוגי (סעיף 9.1.2)
  /// מחשב כמה מהחוב כבר חוסל ביחס לסכום המקורי.
  double get progress {
    if (originalBalance <= 0) return 1.0;
    double p = 1 - (currentBalance / originalBalance);
    return p.clamp(0.0, 1.0); // הבטחת טווח תקין בין 0 ל-1
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'originalBalance': originalBalance,
      'currentBalance': currentBalance,
      'monthlyPayment': monthlyPayment,
      'date': date,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      name: map['name'],
      // תיקון קריטי: המרה בטוחה (Cast) למניעת קריסה בטעינת מספרים שלמים
      originalBalance: (map['originalBalance'] as num).toDouble(),
      currentBalance: (map['currentBalance'] as num).toDouble(),
      monthlyPayment: (map['monthlyPayment'] as num).toDouble(),
      date: map['date'],
    );
  }
}