// 🔒 STATUS: EDITED (Fixed UI colors in Dropdown and Dialogs for better contrast)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../providers/budget_provider.dart';
import '../../data/expense_model.dart';
import '../widgets/global_header.dart';

class ExemptDealerScreen extends StatefulWidget {
  const ExemptDealerScreen({super.key});

  @override
  State<ExemptDealerScreen> createState() => _ExemptDealerScreenState();
}

class _ExemptDealerScreenState extends State<ExemptDealerScreen> {
  int? _selectedBusinessId;
  int _tabIndex = 0; // 0: Incomes, 1: Expenses, 2: Report

  final List<String> _defaultIncomeTags = ['הכנסות מעסקה', 'ייעוץ', 'מכירת מוצרים', 'כללי'];
  final List<String> _defaultExpenseTags = ['שיווק ופרסום', 'ציוד משרדי', 'שירותים מקצועיים', 'תקשורת', 'נסיעות ורכב', 'עמלות סליקה', 'כללי'];

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.indigo),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(content, style: const TextStyle(height: 1.5, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('הבנתי', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<String> _getAvailableTags(Expense business, bool isIncome) {
    Set<String> tags = {};
    tags.addAll(isIncome ? _defaultIncomeTags : _defaultExpenseTags);
    
    final items = isIncome ? business.parsedBusinessIncomes : business.parsedBusinessExpenses;
    for (var item in items) {
      if (item.tag.trim().isNotEmpty) {
        tags.add(item.tag.trim());
      }
    }
    return tags.toList()..sort();
  }

  void _showAddTransactionDialog(BuildContext context, BudgetProvider provider, Expense business, bool isIncome) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final receiptCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    
    final availableTags = _getAvailableTags(business, isIncome);
    String selectedTag = availableTags.first;
    bool isCustomTag = false;
    final customTagCtrl = TextEditingController();

    // הגדרת עיצוב אחיד לשדות הטקסט כדי למנוע היעלמות על רקע בהיר
    const textStyle = TextStyle(color: Colors.black87);
    const labelStyle = TextStyle(color: Colors.black54);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isIncome ? 'רישום תקבול (הכנסה)' : 'רישום תשלום (הוצאה)', style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('תאריך העסקה:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(color: Colors.black54)),
                    trailing: const Icon(Icons.calendar_today, color: Colors.indigo),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now(),
                      );
                      if (date != null) { setDialogState(() => selectedDate = date); }
                    }
                  ),
                  const Divider(),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: textStyle,
                    decoration: const InputDecoration(labelText: 'סכום ₪', labelStyle: labelStyle, border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    style: textStyle,
                    decoration: InputDecoration(labelText: isIncome ? 'שם הלקוח / מהות השירות' : 'שם הספק / תיאור ההוצאה', labelStyle: labelStyle, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: receiptCtrl,
                    style: textStyle,
                    decoration: const InputDecoration(labelText: 'מספר קבלה/חשבונית (אופציונלי)', labelStyle: labelStyle, border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerRight, child: Text('סיווג חשבונאי:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87))),
                  const SizedBox(height: 8),
                  if (!isCustomTag)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedTag,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                style: textStyle,
                                items: availableTags.map((t) => DropdownMenuItem(value: t, child: Text(t, style: textStyle))).toList(),
                                onChanged: (val) { if (val != null) setDialogState(() => selectedTag = val); },
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.indigo),
                          tooltip: 'הוסף תיוג חדש',
                          onPressed: () => setDialogState(() => isCustomTag = true),
                        )
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customTagCtrl,
                            style: textStyle,
                            decoration: const InputDecoration(labelText: 'הזן סיווג חדש', labelStyle: labelStyle, border: OutlineInputBorder()),
                            autofocus: true,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setDialogState(() => isCustomTag = false),
                        )
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () async {
                  final amt = double.tryParse(amountCtrl.text);
                  final name = nameCtrl.text.trim();
                  final tagToSave = isCustomTag ? customTagCtrl.text.trim() : selectedTag;

                  if (amt != null && amt > 0 && name.isNotEmpty && tagToSave.isNotEmpty) {
                    final newItem = BusinessSubItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      amount: amt,
                      date: selectedDate.toIso8601String(),
                      tag: tagToSave,
                      receiptNumber: receiptCtrl.text.trim().isEmpty ? null : receiptCtrl.text.trim(),
                    );

                    final currentList = isIncome ? business.parsedBusinessIncomes : business.parsedBusinessExpenses;
                    currentList.add(newItem);
                    
                    final encodedList = jsonEncode(currentList.map((e) => e.toMap()).toList());
                    
                    final updatedExpense = business.copyWith(
                      businessIncomes: isIncome ? encodedList : business.businessIncomes,
                      businessExpenses: !isIncome ? encodedList : business.businessExpenses,
                    );

                    await provider.updateExpense(updatedExpense);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('שמור', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _deleteTransaction(BuildContext context, BudgetProvider provider, Expense business, String itemId, bool isIncome) async {
    final currentList = isIncome ? business.parsedBusinessIncomes : business.parsedBusinessExpenses;
    currentList.removeWhere((e) => e.id == itemId);
    
    final encodedList = jsonEncode(currentList.map((e) => e.toMap()).toList());
    final updatedExpense = business.copyWith(
      businessIncomes: isIncome ? encodedList : business.businessIncomes,
      businessExpenses: !isIncome ? encodedList : business.businessExpenses,
    );

    await provider.updateExpense(updatedExpense);
  }

  void _generateAndCopyReport(BuildContext context, Expense business) {
    final incomes = business.parsedBusinessIncomes;
    final expenses = business.parsedBusinessExpenses;

    Map<String, double> incomeByTag = {};
    double totalIncome = 0;
    for (var i in incomes) {
      incomeByTag[i.tag] = (incomeByTag[i.tag] ?? 0) + i.amount;
      totalIncome += i.amount;
    }

    Map<String, double> expenseByTag = {};
    double totalExpense = 0;
    for (var e in expenses) {
      expenseByTag[e.tag] = (expenseByTag[e.tag] ?? 0) + e.amount;
      totalExpense += e.amount;
    }

    final buffer = StringBuffer();
    buffer.writeln('=== דוח תקבולים ותשלומים - עוסק פטור ===');
    buffer.writeln('עסק: ${business.name}');
    buffer.writeln('תאריך הפקה: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}');
    buffer.writeln('----------------------------------------');
    
    buffer.writeln('תקבולים (הכנסות):');
    if (incomeByTag.isEmpty) { buffer.writeln('אין נתונים.'); }
    else {
      incomeByTag.forEach((tag, amount) {
        buffer.writeln('- $tag: ₪${amount.toStringAsFixed(0)}');
      });
      buffer.writeln('סה"כ תקבולים: ₪${totalIncome.toStringAsFixed(0)}');
    }
    
    buffer.writeln('----------------------------------------');
    buffer.writeln('תשלומים (הוצאות מוכרות):');
    if (expenseByTag.isEmpty) { buffer.writeln('אין נתונים.'); }
    else {
      expenseByTag.forEach((tag, amount) {
        buffer.writeln('- $tag: ₪${amount.toStringAsFixed(0)}');
      });
      buffer.writeln('סה"כ תשלומים: ₪${totalExpense.toStringAsFixed(0)}');
    }

    buffer.writeln('----------------------------------------');
    buffer.writeln('רווח/הפסד נטו: ₪${(totalIncome - totalExpense).toStringAsFixed(0)}');
    buffer.writeln('========================================');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('הדוח הועתק ללוח בהצלחה. ניתן לשלוח לרואה החשבון.'), backgroundColor: Colors.green));
  }

  Widget _buildTransactionList(BudgetProvider provider, Expense business, bool isIncome) {
    final items = isIncome ? business.parsedBusinessIncomes : business.parsedBusinessExpenses;
    items.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date))); // החדש ביותר למעלה

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isIncome ? Icons.account_balance_wallet_outlined : Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('טרם הוזנו נתונים.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final item = items[i];
        final dt = DateTime.parse(item.date);
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
            child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? Colors.green : Colors.red, size: 20),
          ),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${DateFormat('dd/MM/yy').format(dt)} | סיווג: ${item.tag}', style: const TextStyle(fontSize: 12)),
              if (item.receiptNumber != null && item.receiptNumber!.isNotEmpty)
                Text('אסמכתא: ${item.receiptNumber}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₪${item.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isIncome ? Colors.green : Colors.red)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.black26),
                onPressed: () => _deleteTransaction(context, provider, business, item.id, isIncome),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportTab(BuildContext context, Expense business) {
    double inc = business.parsedBusinessIncomes.fold(0.0, (s, i) => s + i.amount);
    double exp = business.parsedBusinessExpenses.fold(0.0, (s, i) => s + i.amount);
    double net = inc - exp;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('סיכום נתונים חשבונאיים', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              InkWell(
                onTap: () => _showInfoDialog(context, 'דוח עוסק פטור', 'המערכת מרכזת את כל הרישומים שלך על פי הסיווג החשבונאי שהגדרת, ומכינה את השורות התחתונות שרואה החשבון שלך או רשות המיסים דורשים לסוף שנה.'),
                child: const Icon(Icons.info_outline, color: Colors.indigo),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSummaryBox('סה"כ תקבולים', inc, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryBox('סה"כ תשלומים', exp, Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryBox('רווח תפעולי נטו', net, net >= 0 ? Colors.indigo : Colors.orange, isFullWidth: true),
          
          const SizedBox(height: 30),
          const Text('הפקת דוח לרואה חשבון', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('לחץ על הכפתור כדי להעתיק את הדוח השנתי המסוכם ללוח, ולהדביקו במייל או בווצאפ לרואה החשבון שלך.', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.copy, color: Colors.white),
              label: const Text('העתק דוח מסכם', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => _generateAndCopyReport(context, business),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, double amount, Color color, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text('₪${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final businesses = provider.expenses.where((e) => e.isBusiness).toList();

    if (businesses.isEmpty) {
      return Scaffold(
        appBar: const GlobalHeader(title: 'ניהול עוסק פטור'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront_outlined, size: 80, color: Colors.indigo),
                const SizedBox(height: 20),
                const Text('לא נמצאו עסקים במערכת.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('כדי לנהל פנקס תקבולים ותשלומים, עליך להוסיף תחילה "עסק" תחת מסך הוספת הכנסה.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, height: 1.5)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('חזור', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (_selectedBusinessId == null || !businesses.any((e) => e.id == _selectedBusinessId)) {
      _selectedBusinessId = businesses.first.id;
    }

    final selectedBusiness = businesses.firstWhere((e) => e.id == _selectedBusinessId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlobalHeader(title: 'ניהול עוסק פטור'),
      floatingActionButton: _tabIndex == 2 ? null : FloatingActionButton.extended(
        backgroundColor: _tabIndex == 0 ? Colors.green.shade700 : Colors.red.shade700,
        onPressed: () => _showAddTransactionDialog(context, provider, selectedBusiness, _tabIndex == 0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_tabIndex == 0 ? 'הוסף תקבול' : 'הוסף תשלום', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(16),
            child: DropdownButtonHideUnderline(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: DropdownButton<int>(
                  value: _selectedBusinessId,
                  isExpanded: true,
                  icon: const Icon(Icons.business, color: Colors.indigo),
                  dropdownColor: Colors.white, // מונע שקיפות לא רצויה
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Heebo'), // טקסט שחור קריא
                  items: businesses.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                  onChanged: (val) { if (val != null) setState(() => _selectedBusinessId = val); },
                ),
              ),
            ),
          ),
          
          // Tabs
          Row(
            children: [
              _buildTabButton(0, 'תקבולים', Icons.arrow_downward, Colors.green),
              _buildTabButton(1, 'תשלומים', Icons.arrow_upward, Colors.red),
              _buildTabButton(2, 'דוח לרו"ח', Icons.insert_chart_outlined, Colors.indigo),
            ],
          ),
          const Divider(height: 1),

          Expanded(
            child: _tabIndex == 0 ? _buildTransactionList(provider, selectedBusiness, true)
                 : _tabIndex == 1 ? _buildTransactionList(provider, selectedBusiness, false)
                 : _buildReportTab(context, selectedBusiness),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon, Color color) {
    bool isSelected = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? color : Colors.transparent, width: 3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}