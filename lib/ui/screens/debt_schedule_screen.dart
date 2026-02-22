// 🔒 STATUS: EDITED (Fixed horizontal scrolling sync across all rows - Matrix Layout)
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/budget_provider.dart';
import '../../data/debt_model.dart';
import '../widgets/global_header.dart';

class DebtScheduleScreen extends StatelessWidget {
  const DebtScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final debtProvider = context.watch<DebtProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    
    final diversion = budgetProvider.financialDiversionAmount;
    
    // שימוש ברשימת החובות הפעילים בלבד
    final List<Debt> activeDebtsList = debtProvider.activeDebts;
    final schedule = debtProvider.generatePayoffSchedule(diversion);

    // חישוב דינמי של הרוחב הנדרש כדי ליצור סנכרון גלילה מושלם (Matrix)
    final screenWidth = MediaQuery.of(context).size.width;
    // 128 רוחב קוביה + 12 שוליים = 140 לכל עמודה. ועוד 32 לשולי המסך.
    final double requiredWidth = (activeDebtsList.length * 140.0) + 32.0;
    final double minWidth = math.max(screenWidth, requiredWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlobalHeader(title: 'מפת דרכים לחיסול'),
      body: activeDebtsList.isEmpty
          ? const Center(child: Text('אין חובות פעילים להצגה'))
          : SingleChildScrollView(
              // גלילה אופקית אחת ויחידה שעוטפת את כל הטבלה
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minWidth,
                child: Column(
                  children: [
                    _buildLegend(activeDebtsList), 
                    Expanded(
                      // הגלילה האנכית הרגילה של החודשים
                      child: ListView.builder(
                        itemCount: schedule.length,
                        itemBuilder: (context, index) {
                          final monthData = schedule[index];
                          return _buildMonthRow(context, monthData, activeDebtsList, index == 0);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getHebrewMonthName(int month) {
    const months = [
      'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'
    ];
    return months[month - 1];
  }

  Widget _buildLegend(List<Debt> debts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.grey[50],
      child: Row(
        children: debts.map((d) {
          return Container(
            width: 128, // רוחב קבוע כדי לשמש כ"כותרת עמודה"
            margin: const EdgeInsets.only(left: 12.0),
            child: Row(
              children: [
                Container(
                  width: 8, 
                  height: 8, 
                  decoration: const BoxDecoration(color: Color(0xFF00A3FF), shape: BoxShape.circle)
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    d.name, 
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  )
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthRow(BuildContext context, DebtScheduleMonth data, List<Debt> activeDebts, bool isFirst) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        color: isFirst ? const Color(0xFFF0F7FF) : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_getHebrewMonthName(data.month.month)} ${data.month.year}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                      color: isFirst ? const Color(0xFF00A3FF) : Colors.black87
                    ),
                  ),
                  if (isFirst)
                    const Text("מצב נוכחי", style: TextStyle(fontSize: 10, color: Color(0xFF00A3FF), fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₪${data.totalRemaining.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: data.totalRemaining <= 0 ? const Color(0xFF00C853) : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                  ),
                  const Text("יתרה כוללת", style: TextStyle(fontSize: 10, color: Colors.black38)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: activeDebts.map((debt) {
              final balance = data.debtBalances[debt.id] ?? 0.0;
              final isPaid = balance <= 0;
              
              return Container(
                width: 128, // רוחב קבוע היוצר את העמודות המושלמות
                margin: const EdgeInsets.only(left: 12.0),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isPaid 
                      ? Colors.green.withValues(alpha: 0.1) 
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: isPaid ? Colors.green[700] : Colors.black54,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₪${balance.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isPaid ? FontWeight.bold : FontWeight.w600,
                        color: isPaid ? const Color(0xFF00C853) : Colors.black87,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}