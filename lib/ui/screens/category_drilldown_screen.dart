// 🔒 STATUS: FIXED (Pro Surgical Edit: Zero Warnings + Per-Child Cost UI)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../data/expense_model.dart';
import '../../utils/app_localizations.dart';
import '../widgets/global_header.dart';

// --- רמה 3: רשימת ראשי הוצאות (Parents) ---
class CategoryDrilldownScreen extends StatelessWidget {
  final String mainCategory;
  final String displayTitle;

  const CategoryDrilldownScreen({
    super.key,
    required this.mainCategory,
    required this.displayTitle,
  });

  String _formatParentName(String name) {
    if (name == 'בית') {
      return 'קטנות לבית';
    }
    return name;
  }

  void _showRenameParentDialog(BuildContext context, BudgetProvider provider, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("שינוי שם: $oldName"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'שם קבוצה חדש'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ביטול")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty && controller.text != oldName) {
                provider.renameParentCategory(oldName, controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text("עדכן"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalHeader(title: displayTitle),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          final categoryExpenses = provider.expenses
              .where((e) => e.category == mainCategory)
              .toList();

          if (categoryExpenses.isEmpty) {
            return const Center(child: Text('אין הוצאות בקטגוריה זו', style: TextStyle(color: Colors.black)));
          }

          final Map<String, List<Expense>> grouped = {};
          for (var e in categoryExpenses) {
            final pCat = e.parentCategory;
            if (!grouped.containsKey(pCat)) {
              grouped[pCat] = [];
            }
            grouped[pCat]!.add(e);
          }

          // סידור קשיח לעתידיות לפי הדרישה האסטרטגית
          var entries = grouped.entries.toList();
          if (mainCategory == 'עתידיות') {
            const futureOrder = ['רכישות גדולות', 'רכישות קטנות', 'הפקת אירועים', 'תיקונים', 'רפואי', 'חופשה שנתית'];
            entries.sort((a, b) {
              int indexA = futureOrder.indexOf(a.key);
              int indexB = futureOrder.indexOf(b.key);
              if (indexA == -1) indexA = 999;
              if (indexB == -1) indexB = 999;
              return indexA.compareTo(indexB);
            });
          }

          return Column(
            children: [
              if (mainCategory == 'משתנות' && provider.variableDeficit > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'התראת תקציב: סך ההוצאות הקבועות מראש (עוגנים כמו קניות) חורג ב-₪${provider.variableDeficit.toStringAsFixed(0)} מהתקציב הכולל שהוקצה למשתנות.\nבשל כך, שאר הסעיפים אופסו.',
                          style: TextStyle(color: Colors.red[900], fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: entries.map((entry) {
                    final parentName = entry.key;
                    final items = entry.value;
                    double total = 0;
                    double totalBalance = 0;
                    double totalTarget = 0;
                    bool hasTarget = false;

                    for (var e in items) {
                      int multiplier = e.isPerChild ? provider.childCount : 1;
                      total += e.monthlyAmount * multiplier;
                      totalBalance += (e.currentBalance ?? 0);
                      if ((e.targetAmount ?? 0) > 0) {
                        totalTarget += e.targetAmount!;
                        hasTarget = true;
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), 
                        side: BorderSide(color: Colors.grey[200]!)
                      ),
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          children: [
                            Text(_formatParentName(parentName), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                            const SizedBox(width: 8),
                            if (parentName != 'קניות')
                              InkWell(
                                onTap: () => _showRenameParentDialog(context, provider, parentName),
                                child: const Icon(Icons.edit, size: 14, color: Colors.grey),
                              ),
                          ],
                        ),
                        subtitle: (mainCategory == 'עתידיות' || (parentName == 'ילדים' && provider.childCount > 0)) 
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (mainCategory == 'עתידיות') ...[
                                    if (hasTarget)
                                      LinearProgressIndicator(
                                        value: (totalTarget > 0) ? (totalBalance / totalTarget).clamp(0.0, 1.0) : 0.0,
                                        backgroundColor: Colors.grey[200],
                                        color: Colors.green,
                                        minHeight: 5,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      hasTarget 
                                          ? 'נצבר: ₪${totalBalance.toStringAsFixed(0)} מתוך ₪${totalTarget.toStringAsFixed(0)}'
                                          : 'נצבר בקופה: ₪${totalBalance.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                  if (parentName == 'ילדים' && provider.childCount > 0) ...[
                                    if (mainCategory == 'עתידיות') const SizedBox(height: 6),
                                    Text(
                                      'עלות ממוצעת לילד יחיד: ₪${(total / provider.childCount).toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 12, color: Colors.purple[700], fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ],
                              ),
                            ) 
                          : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${loc?.get('currency_symbol') ?? '₪'}${total.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                                ),
                                Text(
                                  '${loc?.get('currency_symbol') ?? '₪'}${(total * 12).toStringAsFixed(0)} בשנה',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => SpecificExpensesScreen(
                              parentCategory: parentName, 
                              mainCategory: mainCategory,
                            )
                          ));
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- רמה 4: רשימת הוצאות ספציפיות ---
class SpecificExpensesScreen extends StatelessWidget {
  final String parentCategory;
  final String mainCategory;

  const SpecificExpensesScreen({
    super.key, 
    required this.parentCategory,
    required this.mainCategory,
  });

  String _formatParentName(String name) {
    if (name == 'בית') {
      return 'קטנות לבית';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final provider = context.watch<BudgetProvider>(); 
    final currentExpenses = provider.expenses.where((e) => e.parentCategory == parentCategory).toList();
    
    double total = 0;
    for (var current in currentExpenses) {
        int multiplier = current.isPerChild ? provider.childCount : 1;
        total += current.monthlyAmount * multiplier;
    }

    bool isFixedOrIncome = (mainCategory == 'קבועות' || mainCategory == 'הכנסות');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalHeader(title: _formatParentName(parentCategory)),
      floatingActionButton: isFixedOrIncome ? FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context, provider, parentCategory, mainCategory),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), border: const Border(bottom: BorderSide(color: Colors.black12))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('סה"כ:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${loc?.get('currency_symbol') ?? '₪'}${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text('${loc?.get('currency_symbol') ?? '₪'}${(total * 12).toStringAsFixed(0)} בשנה', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: currentExpenses.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (context, index) {
                final expense = currentExpenses[index];
                final multiplier = expense.isPerChild ? provider.childCount : 1;
                final displayAmount = expense.monthlyAmount * multiplier;
                bool isVariable = (expense.category == 'משתנות');
                bool isFuture = (expense.category == 'עתידיות');

                String timeText = '';
                if (isFuture && (expense.targetAmount ?? 0) > 0) {
                  double remaining = (expense.targetAmount!) - (expense.currentBalance ?? 0);
                  if (remaining <= 0) {
                    timeText = 'היעד הושג 🎉';
                  } else if (displayAmount > 0) {
                    int months = (remaining / displayAmount).ceil();
                    if (months == 1) {
                      timeText = 'נותר חודש אחד';
                    } else if (months == 2) {
                      timeText = 'נותרו חודשיים';
                    } else {
                      timeText = 'נותרו $months חודשים';
                    }
                  } else {
                    timeText = 'ללא צפי הגעה';
                  }
                }

                Widget tile = ListTile(
                  title: Row(
                    children: [
                      Text(expense.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      if (expense.isLocked) const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.lock, size: 14, color: Colors.orange))
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (expense.isPerChild)
                        Text('₪${expense.monthlyAmount.toStringAsFixed(0)} ליחידה × ${provider.childCount} ילדים', style: TextStyle(fontSize: 12, color: Colors.orange[900], fontWeight: FontWeight.w600))
                      else if ((isVariable || isFuture) && !expense.isLocked)
                        Text('${((expense.allocationRatio ?? 0) * 100).toStringAsFixed(1)}% מהיתרה', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      
                      // חישוב מיוחד: עלות פר ילד עבור סעיפים גלובליים בקטגוריית ילדים
                      if (!expense.isPerChild && expense.parentCategory == 'ילדים' && provider.childCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'עלות לילד יחיד: ₪${(displayAmount / provider.childCount).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12, color: Colors.purple[700], fontWeight: FontWeight.w600),
                        ),
                      ],

                      if (expense.isSinking && !isFuture) ...[
                        const SizedBox(height: 4),
                        Text('קופה נצברת: ₪${(expense.currentBalance ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],

                      if (isFuture) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (expense.targetAmount ?? 0) > 0 ? ((expense.currentBalance ?? 0) / (expense.targetAmount ?? 1)).clamp(0.0, 1.0) : 0.0,
                          backgroundColor: Colors.grey[200],
                          color: Colors.green,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₪${(expense.currentBalance ?? 0).toStringAsFixed(0)} מתוך ₪${(expense.targetAmount ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (timeText.isNotEmpty)
                              Text(timeText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[400])),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${loc?.get('currency_symbol') ?? '₪'}${displayAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: expense.isLocked ? Colors.orange[800] : Colors.black)),
                        Text('${loc?.get('currency_symbol') ?? '₪'}${(displayAmount * 12).toStringAsFixed(0)} בשנה', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                        if (isFuture) const Text('הפרשה חודשית', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ]),
                      const SizedBox(width: 12),
                      
                      if (expense.isSinking)
                        IconButton(
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.green),
                          tooltip: 'ניהול קופה ומשיכות',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              builder: (ctx) => _SinkingFundBottomSheet(provider: provider, expense: expense),
                            );
                          },
                        ),

                      IconButton(
                        icon: Icon((isVariable || isFuture) ? Icons.tune : Icons.edit, size: 20, color: Colors.blueGrey),
                        onPressed: () {
                          if (isFuture) {
                            _showFutureEditDialog(context, provider, expense);
                          } else if (isVariable && expense.allocationRatio != null) {
                            _showSmartEditDialog(context, provider, expense);
                          } else {
                            _showEditDialog(context, provider, expense);
                          }
                        },
                      ),
                    ],
                  ),
                );

                if (isFixedOrIncome || mainCategory == 'הכנסות') {
                  return Dismissible(
                    key: Key(expense.id?.toString() ?? UniqueKey().toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      provider.deleteExpense(expense.id!);
                    },
                    child: tile,
                  );
                }
                return tile;
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, BudgetProvider provider, String parentCat, String mainCat) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('הוספת סעיף ($parentCat)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'שם הסעיף')),
            const SizedBox(height: 10),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום חודשי', suffixText: '₪')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (nameController.text.isNotEmpty) {
                final newExpense = Expense(
                  name: nameController.text.trim(),
                  category: mainCat,
                  parentCategory: parentCat,
                  monthlyAmount: amount,
                  frequency: Frequency.MONTHLY,
                  isLocked: true, 
                  date: DateTime.now().toIso8601String(),
                );
                provider.addExpense(newExpense);
                Navigator.pop(ctx);
              }
            },
            child: const Text('הוסף'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, BudgetProvider provider, Expense expense) {
    double factor = 1.0;
    if (expense.frequency == Frequency.YEARLY) {
      factor = 12.0;
    }
    if (expense.frequency == Frequency.BI_MONTHLY) {
      factor = 2.0;
    }
    
    final nameController = TextEditingController(text: expense.name); 
    final amountController = TextEditingController(text: (expense.monthlyAmount * factor).toStringAsFixed(0));
    Frequency selectedFreq = expense.frequency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('עריכת סעיף'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController, 
                  decoration: const InputDecoration(labelText: 'שם הסעיף')
                ),
                const SizedBox(height: 10),
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום לתשלום', suffixText: '₪')),
                const SizedBox(height: 16),
                DropdownButton<Frequency>(
                  value: selectedFreq, isExpanded: true,
                  items: const [DropdownMenuItem(value: Frequency.MONTHLY, child: Text('חודשי')), DropdownMenuItem(value: Frequency.BI_MONTHLY, child: Text('דו-חודשי')), DropdownMenuItem(value: Frequency.YEARLY, child: Text('שנתי'))],
                  onChanged: (val) { 
                    if (val != null) {
                      setDialogState(() { selectedFreq = val; }); 
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(amountController.text);
                  final finalName = nameController.text.trim().isNotEmpty ? nameController.text.trim() : expense.name;
                  
                  if (val != null) {
                    double monthly = val;
                    if (selectedFreq == Frequency.YEARLY) {
                      monthly = val / 12;
                    } else if (selectedFreq == Frequency.BI_MONTHLY) {
                      monthly = val / 2;
                    }
                    provider.updateExpense(Expense(
                      id: expense.id, 
                      name: finalName, 
                      category: expense.category, 
                      parentCategory: expense.parentCategory,
                      monthlyAmount: monthly, frequency: selectedFreq, isSinking: expense.isSinking, isPerChild: expense.isPerChild,
                      allocationRatio: expense.allocationRatio, isLocked: expense.isLocked, manualAmount: expense.manualAmount, date: expense.date,
                    ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('שמור'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showSmartEditDialog(BuildContext context, BudgetProvider provider, Expense expense) {
    final amountController = TextEditingController(text: expense.isLocked ? expense.monthlyAmount.toStringAsFixed(0) : "");
    final ratioController = TextEditingController(text: ((expense.allocationRatio ?? 0) * 100).toStringAsFixed(1));
    bool isRatioMode = !expense.isLocked; 

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text('כיול ${expense.name}', style: const TextStyle(fontSize: 18))),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                tooltip: 'חזרה לברירת מחדל',
                onPressed: () {
                  provider.resetExpenseToDefault(expense.id!);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToggleButtons(
                isSelected: [isRatioMode, !isRatioMode],
                onPressed: (index) => setState(() => isRatioMode = index == 0),
                borderRadius: BorderRadius.circular(10),
                children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('אחוז')), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('סכום'))],
              ),
              const SizedBox(height: 20),
              isRatioMode 
                ? TextField(controller: ratioController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'אחוז מהיתרה', suffixText: '%', border: OutlineInputBorder()))
                : TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום קבוע', suffixText: '₪', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () {
                if (isRatioMode) {
                  final val = double.tryParse(ratioController.text);
                  if (val != null) {
                    provider.updateExpenseRatio(expense.id!, val / 100);
                  }
                } else {
                  final valText = amountController.text.trim();
                  if (valText.isEmpty) {
                    provider.resetExpenseToDefault(expense.id!);
                  } else {
                    final val = double.tryParse(valText);
                    if (val != null) {
                      provider.lockExpenseAmount(expense.id!, val);
                    }
                  }
                }
                Navigator.pop(ctx);
              },
              child: const Text('עדכן'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFutureEditDialog(BuildContext context, BudgetProvider provider, Expense expense) {
    final nameController = TextEditingController(text: expense.name);
    final targetController = TextEditingController(text: (expense.targetAmount ?? 0).toStringAsFixed(0));
    final balanceController = TextEditingController(text: (expense.currentBalance ?? 0).toStringAsFixed(0));
    final ratioController = TextEditingController(text: ((expense.allocationRatio ?? 0) * 100).toStringAsFixed(1));
    final amountController = TextEditingController(text: expense.isLocked ? expense.monthlyAmount.toStringAsFixed(0) : "");
    final monthsController = TextEditingController(); 

    int selectedMode = expense.isLocked ? 1 : 0; 

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text('הגדרת יעד', style: TextStyle(fontSize: 18))),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                tooltip: 'חזרה לברירת מחדל',
                onPressed: () {
                  provider.resetExpenseToDefault(expense.id!);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'שם היעד')),
                const SizedBox(height: 10),
                TextField(controller: targetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום היעד הסופי', suffixText: '₪')),
                const SizedBox(height: 10),
                TextField(controller: balanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'נצבר כיום', suffixText: '₪')),
                const Divider(height: 30),
                ToggleButtons(
                  isSelected: [selectedMode == 0, selectedMode == 1, selectedMode == 2],
                  onPressed: (index) => setState(() => selectedMode = index),
                  borderRadius: BorderRadius.circular(10),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('אחוז')), 
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('סכום')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('תקופה'))
                  ],
                ),
                const SizedBox(height: 15),
                if (selectedMode == 0)
                  TextField(controller: ratioController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'אחוז מהחיסכון', suffixText: '%', border: OutlineInputBorder()))
                else if (selectedMode == 1)
                  TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום קבוע חודשי', suffixText: '₪', border: OutlineInputBorder()))
                else if (selectedMode == 2)
                  TextField(controller: monthsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'חודשים נותרים ליעד', suffixText: 'חודשים', border: OutlineInputBorder(), helperText: 'המערכת תחשב ותנעל את הסכום החודשי')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () {
                double? newManualAmount;
                bool newIsLocked = selectedMode != 0;
                double? newRatio = selectedMode == 0 ? (double.tryParse(ratioController.text) ?? 0) / 100 : expense.allocationRatio;

                if (selectedMode == 1) {
                  newManualAmount = double.tryParse(amountController.text);
                } else if (selectedMode == 2) {
                  int? months = int.tryParse(monthsController.text);
                  double target = double.tryParse(targetController.text) ?? 0;
                  double balance = double.tryParse(balanceController.text) ?? 0;
                  if (months != null && months > 0) {
                    newManualAmount = (target - balance) / months;
                    if (newManualAmount < 0) {
                      newManualAmount = 0;
                    }
                  }
                }

                if (newIsLocked && newManualAmount == null && selectedMode != 2) {
                  provider.resetExpenseToDefault(expense.id!);
                } else {
                  provider.updateFutureExpenseDetails(
                    expense.id!,
                    name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : expense.name,
                    target: double.tryParse(targetController.text),
                    balance: double.tryParse(balanceController.text),
                    ratio: newRatio,
                    isLocked: newIsLocked,
                    manualAmount: newManualAmount,
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('עדכן יעד'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ניהול משיכות ויתרה מקופה צוברת (BottomSheet) ---
class _SinkingFundBottomSheet extends StatefulWidget {
  final BudgetProvider provider;
  final Expense expense;

  const _SinkingFundBottomSheet({required this.provider, required this.expense});

  @override
  State<_SinkingFundBottomSheet> createState() => _SinkingFundBottomSheetState();
}

class _SinkingFundBottomSheetState extends State<_SinkingFundBottomSheet> {
  List<Withdrawal> _withdrawals = [];
  bool _isLoading = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    final data = await widget.provider.getWithdrawalsForExpense(widget.expense.id!);
    if (mounted) {
      setState(() {
        _withdrawals = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentExpense = widget.provider.expenses.firstWhere(
      (e) => e.id == widget.expense.id, 
      orElse: () => widget.expense
    );
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ניהול קופה: ${currentExpense.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('יתרה צבורה כיום', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('₪${(currentExpense.currentBalance ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  tooltip: 'עדכון יתרה',
                  onPressed: () {
                    final ctrl = TextEditingController(text: (currentExpense.currentBalance ?? 0).toStringAsFixed(0));
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text("עדכון יתרה צבורה", style: TextStyle(fontSize: 18)),
                        content: TextField(
                          controller: ctrl, 
                          keyboardType: TextInputType.number, 
                          decoration: const InputDecoration(suffixText: '₪', helperText: 'הזן את הסכום הקיים כיום בקופה זו')
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ביטול")),
                          ElevatedButton(
                            onPressed: () {
                              final val = double.tryParse(ctrl.text);
                              if (val != null) {
                                widget.provider.setExpenseCurrentBalance(currentExpense.id!, val);
                                Navigator.pop(ctx);
                              }
                            }, 
                            child: const Text("שמור")
                          )
                        ]
                      )
                    );
                  }
                )
              ]
            )
          ),
          const SizedBox(height: 20),
          
          const Align(alignment: Alignment.centerRight, child: Text('משיכה חדשה מהקופה', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'סכום', suffixText: '₪', border: OutlineInputBorder(), isDense: true),
                )
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'לאן יצא הכסף?', border: OutlineInputBorder(), isDense: true),
                )
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.arrow_downward),
                onPressed: () async {
                  final amt = double.tryParse(_amountController.text);
                  if (amt != null && amt > 0) {
                    await widget.provider.addWithdrawal(currentExpense.id!, amt, _noteController.text);
                    _amountController.clear();
                    _noteController.clear();
                    _loadWithdrawals();
                  }
                },
              )
            ]
          ),
          
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerRight, child: Text('היסטוריית משיכות', style: TextStyle(fontWeight: FontWeight.bold))),
          const Divider(),
          
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
          else if (_withdrawals.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('לא בוצעו משיכות מקופה זו', style: TextStyle(color: Colors.grey)))
          else
            SizedBox(
              height: 180, 
              child: ListView.builder(
                itemCount: _withdrawals.length,
                itemBuilder: (ctx, i) {
                  final w = _withdrawals[i];
                  final date = DateTime.parse(w.date);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.money_off, color: Colors.redAccent),
                    title: Text('₪${w.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    subtitle: Text('${w.note}${w.note.isNotEmpty ? " • " : ""}${date.day}/${date.month}/${date.year}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      tooltip: 'מחק והחזר יתרה',
                      onPressed: () async {
                        await widget.provider.deleteWithdrawal(w);
                        _loadWithdrawals();
                      },
                    ),
                  );
                }
              )
            ),
          const SizedBox(height: 20),
        ]
      )
    );
  }
}