class ProjectionEngine {
  /// מחשב כמה חודשים נותרו עד שההכנסה הפסיבית תכסה את היעד החודשי.
  /// 
  /// [currentNetWorth]: הון עצמי נוכחי (נכסים פחות חובות).
  /// [monthlyContribution]: כמה כסף מושקע כל חודש (PCF + Financial).
  /// [annualYield]: תשואה שנתית ממוצעת באחוזים (למשל 4.0).
  /// [targetMonthlyIncome]: היעד החודשי (למשל 20,000).
  static int calculateMonthsToFreedom({
    required double currentNetWorth,
    required double monthlyContribution,
    required double annualYield,
    required double targetMonthlyIncome,
  }) {
    if (targetMonthlyIncome <= 0) return 0;
    
    // אם כבר יש לנו מספיק הון שמייצר את היעד (לפי כלל ה-4% או התשואה שהוגדרה)
    double currentPassive = (currentNetWorth * (annualYield / 100)) / 12;
    if (currentPassive >= targetMonthlyIncome) {
      return 0; // כבר הגענו
    }

    // אם אנחנו לא חוסכים כלום ואין לנו מספיק הון - לעולם לא נגיע
    if (monthlyContribution <= 0 && currentPassive < targetMonthlyIncome) {
      return 9999; // אינסוף
    }

    double balance = currentNetWorth;
    double monthlyYieldRate = (annualYield / 100) / 12;
    int months = 0;

    // סימולציה חודשית
    while (months < 1200) { // מגבלת 100 שנה למניעת לולאה אינסופית
      // 1. הכסף עושה כסף
      balance += balance * monthlyYieldRate;
      
      // 2. מוסיפים הפקדה חודשית
      balance += monthlyContribution;
      
      // 3. בודקים האם הגענו ליעד
      double potentialPassive = balance * monthlyYieldRate;
      if (potentialPassive >= targetMonthlyIncome) {
        return months;
      }
      
      months++;
    }

    return 9999; // מעל 100 שנה
  }
}