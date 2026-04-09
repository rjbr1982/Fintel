// 🔒 STATUS: EDITED (Fixed Debt model field name and removed unused import)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/asset_provider.dart';

class AiExportService {
  static Future<void> generateAndCopy(BuildContext context) async {
    final budget = Provider.of<BudgetProvider>(context, listen: false);
    final debt = Provider.of<DebtProvider>(context, listen: false);
    final asset = Provider.of<AssetProvider>(context, listen: false);

    final buffer = StringBuffer();
    
    buffer.writeln('# דוח מצב פיננסי - Fintel (דוחכם)');
    buffer.writeln('תאריך הפקה: ${DateTime.now().toString().split(' ')[0]}\n');

    // --- מאקרו כלכלי ---
    buffer.writeln('## נתוני מאקרו (Macro)');
    buffer.writeln('* סך הכנסות: ₪${budget.totalIncome.toStringAsFixed(0)}');
    buffer.writeln('* סך הוצאות בסיס (קבועות + חובות): ₪${(budget.totalFixedExpenses + budget.totalReducingExpenses).toStringAsFixed(0)}');
    buffer.writeln('* תזרים פנוי (לרמת חיים וחירות): ₪${budget.disposableIncome.toStringAsFixed(0)}');
    buffer.writeln('* סך הוצאות משתנות (רמת חיים): ₪${budget.totalVariableExpenses.toStringAsFixed(0)}');
    buffer.writeln('* סך הוצאות עתידיות: ₪${budget.totalFutureExpenses.toStringAsFixed(0)}');
    buffer.writeln('* תזרים פנוי לחירות פיננסית: ₪${budget.totalFinancialExpenses.toStringAsFixed(0)}\n');

    // --- הכנסות ---
    buffer.writeln('## 1. הכנסות');
    final incomes = budget.expenses.where((e) => e.category == 'הכנסות').toList();
    for (var e in incomes) {
      buffer.writeln('- ${e.name}: ₪${e.monthlyAmount.toStringAsFixed(0)}');
    }
    buffer.writeln('');

    // --- בסיס / קבועות ---
    buffer.writeln('## 2. הוצאות בסיס (קבועות)');
    final fixed = budget.expenses.where((e) => e.category == 'קבועות').toList();
    for (var e in fixed) {
      double amount = e.isPerChild ? e.monthlyAmount * budget.childCount : e.monthlyAmount;
      String note = e.isPerChild ? ' (מכפיל ${budget.childCount} ילדים)' : '';
      String sinkingNote = e.isSinking ? ' [צוברת: יתרה ₪${e.currentBalance?.toStringAsFixed(0) ?? 0}]' : '';
      buffer.writeln('- ${e.name}: ₪${amount.toStringAsFixed(0)}$note$sinkingNote');
    }
    buffer.writeln('');

    // --- מנמיכות (חובות) ---
    buffer.writeln('## 3. מנמיכות (חובות)');
    if (debt.debts.isEmpty) {
      buffer.writeln('- אין חובות פעילים.');
    } else {
      for (var d in debt.debts) {
        buffer.writeln('- ${d.name}: החזר חודשי ₪${d.monthlyPayment.toStringAsFixed(0)} | יתרה: ₪${d.currentBalance.toStringAsFixed(0)}');
      }
    }
    buffer.writeln('');

    // --- משתנות ---
    buffer.writeln('## 4. הוצאות משתנות (רמת חיים)');
    final variables = budget.expenses.where((e) => e.category == 'משתנות').toList();
    for (var e in variables) {
      String ratioNote = (e.allocationRatio != null && e.allocationRatio! > 0) 
          ? ' [הקצאה: ${(e.allocationRatio! * 100).toStringAsFixed(1)}%]' 
          : ' [עוגן/קבוע]';
      String lockedNote = e.isLocked ? ' (נעול ידנית)' : '';
      buffer.writeln('- ${e.name}: ₪${e.monthlyAmount.toStringAsFixed(0)}$ratioNote$lockedNote');
    }
    buffer.writeln('');

    // --- עתידיות ---
    buffer.writeln('## 5. הוצאות עתידיות');
    final futures = budget.expenses.where((e) => e.category == 'עתידיות').toList();
    for (var e in futures) {
      String ratioNote = (e.allocationRatio != null) ? ' [הקצאה: ${(e.allocationRatio! * 100).toStringAsFixed(1)}%]' : '';
      String targetNote = (e.targetAmount != null && e.targetAmount! > 0) 
          ? ' | יעד: ₪${e.targetAmount!.toStringAsFixed(0)} | נצבר: ₪${(e.currentBalance ?? 0).toStringAsFixed(0)}' 
          : '';
      buffer.writeln('- ${e.name}: הפקדה חודשית ₪${e.monthlyAmount.toStringAsFixed(0)}$ratioNote$targetNote');
    }
    buffer.writeln('');

    // --- נכסים (פיננסיות) ---
    buffer.writeln('## 6. נכסים ומנוע חירות');
    buffer.writeln('* הון עצמי התחלתי: ₪${budget.initialCapital.toStringAsFixed(0)}');
    buffer.writeln('* תשואה שנתית מצופה: ${budget.expectedYield}%');
    buffer.writeln('* יעד הכנסה פסיבית נדרש: ₪${budget.targetPassiveIncome.toStringAsFixed(0)} / חודש');
    if (asset.assets.isEmpty) {
      buffer.writeln('- טרם הוזנו נכסים פרטניים.');
    } else {
      for (var a in asset.assets) {
        buffer.writeln('- ${a.name} (${a.type}): שווי ₪${a.value.toStringAsFixed(0)}');
      }
    }

    // העתקה ללוח
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }
}