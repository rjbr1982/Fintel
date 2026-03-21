// 🔒 STATUS: EDITED (Fixed Light Theme Contrast and Brightened BottomSheets)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../data/expense_model.dart';
import '../../utils/app_localizations.dart';
import '../widgets/global_header.dart';
import 'salary_engine_screen.dart';

String _formatMonthYear(String isoString) {
  try {
    final date = DateTime.parse(isoString);
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  } catch (e) {
    return '';
  }
}

// === פונקציה גלובלית להצגת חלונית 3 המצבים ===
void _showUnifiedModeDialog(BuildContext context, BudgetProvider provider, String parentCat) {
  int currentMode = provider.getCategoryUnifiedMode(parentCat);
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        return Theme(
          data: ThemeData.light(),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('תצורת קופה: $parentCat', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<int>(
                  style: SegmentedButton.styleFrom(
                    selectedForegroundColor: Colors.blue[900],
                    selectedBackgroundColor: Colors.blue[100],
                    foregroundColor: Colors.blueGrey[600],
                  ),
                  segments: const [
                    ButtonSegment(value: 0, label: Text('נפרד')),
                    ButtonSegment(value: 2, label: Text('משולב')),
                    ButtonSegment(value: 1, label: Text('מאוחד')),
                  ],
                  selected: {currentMode},
                  onSelectionChanged: (val) => setDialogState(() => currentMode = val.first),
                ),
                const SizedBox(height: 16),
                Text(
                  currentMode == 0 ? 'מצב 0 (נפרד):\nניהול משיכות וצבירה לכל תת-סעיף בנפרד בלבד.' :
                  currentMode == 1 ? 'מצב 1 (מאוחד):\nקופה משותפת כללית. הארנקים האישיים מוסתרים.' :
                  'מצב 2 (משולב):\nקופה משותפת בראש המסך + ארנקים נפרדים למטה.',
                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A3FF), foregroundColor: Colors.white),
                onPressed: () {
                  provider.setCategoryUnifiedMode(parentCat, currentMode);
                  Navigator.pop(ctx);
                },
                child: const Text('שמור מצב', style: TextStyle(fontWeight: FontWeight.bold))
              )
            ]
          )
        );
      }
    )
  );
}

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
      builder: (ctx) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("שינוי שם: $oldName", style: const TextStyle(color: Colors.black87)),
          content: TextField(
            controller: controller, 
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(labelText: 'שם קבוצה חדש', labelStyle: TextStyle(color: Colors.black54)), 
            autofocus: true
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
      ),
    );
  }

  void _showAddParentCategoryDialog(BuildContext context, BudgetProvider provider, String mainCat) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('הוספת קבוצה חדשה - $mainCat', style: const TextStyle(color: Colors.black87)),
          content: TextField(
            controller: nameController, 
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(labelText: 'שם הקבוצה החדשה', labelStyle: TextStyle(color: Colors.black54))
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newExpense = Expense(
                    name: 'סעיף ראשון - ${nameController.text}',
                    category: mainCat,
                    parentCategory: nameController.text.trim(),
                    monthlyAmount: 0,
                    isLocked: false,
                    isCustom: true,
                    date: DateTime.now().toIso8601String(),
                  );
                  await provider.addExpense(newExpense);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('הוסף'),
            )
          ]
        ),
      )
    );
  }

  void _showAddIncomeTypeDialog(BuildContext context, BudgetProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('מה תרצה להוסיף?', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.attach_money, color: Colors.green),
                title: const Text('הכנסה רגילה (משכורת, קצבה)', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddParentCategoryDialog(context, provider, mainCategory);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.storefront, color: Colors.blue),
                title: const Text('עסק / הכנסה צדדית מורכבת', style: TextStyle(color: Colors.black87)),
                subtitle: const Text('כולל שורות הכנסות והוצאות', style: TextStyle(fontSize: 11, color: Colors.black54)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBusinessDialog(context, provider);
                },
              ),
            ],
          ),
        ),
      )
    );
  }

  void _showEntertainmentTrafficLightEditor(BuildContext context, BudgetProvider provider) {
    final warningCtrl = TextEditingController(text: provider.entWarningLimit.toStringAsFixed(0));
    final successCtrl = TextEditingController(text: provider.entSuccessLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('כיול רמזור בילויים', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                tooltip: 'חזור לברירת מחדל אוטומטית',
                onPressed: () async {
                  await provider.resetEntertainmentLimits();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              )
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('קבע מאיזה סכום להציג התראות בקופת הבילויים שלך.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: successCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(labelText: 'סכום להצגת שפע (ירוק)', labelStyle: TextStyle(color: Colors.black54), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: warningCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(labelText: 'סכום לאזהרה (כתום)', labelStyle: TextStyle(color: Colors.black54), border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () async {
                final warning = double.tryParse(warningCtrl.text);
                final success = double.tryParse(successCtrl.text);
                if (warning != null && success != null) {
                  await provider.saveEntertainmentLimits(warning, success);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentsEntertainmentCard(BuildContext context, BudgetProvider provider) {
    double totalBalance = 0;
    bool hasEntertainment = false;
    
    for (var e in provider.expenses) {
      if (e.name == 'בילויים אבא' || e.name == 'בילויים אמא' || e.name == 'בילויים אישי' || e.name == 'בילויים בעל' || e.name == 'בילויים אישה') {
        totalBalance += (e.currentBalance ?? 0);
        hasEntertainment = true;
      }
    }
    
    if (!hasEntertainment) {
      return const SizedBox.shrink();
    }

    Color color;
    String message;

    final limitGreen = provider.entSuccessLimit;
    final limitOrange = provider.entWarningLimit;

    if (totalBalance >= limitGreen) {
      color = Colors.green;
      message = 'יש מספיק תקציב! צאו לבלות וליהנות החודש.';
    } else if (totalBalance >= limitOrange) {
      color = Colors.orange;
      message = 'שימו לב, התקציב לבילויים מוגבל. לבלות בזהירות.';
    } else {
      color = Colors.red;
      message = 'אין מספיק כסף לבילויים החודש. עדיף להישאר בבית ולהתפנק!';
    }
    
    String boxTitle = provider.maritalStatus == 'single' ? 'קופת הבילויים שלך' : 'קופת הבילויים שלכם';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(Icons.local_activity, color: color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$boxTitle: ₪${totalBalance.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color == Colors.orange ? Colors.orange[900] : color)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(fontSize: 12, color: Colors.blueGrey[800], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.edit, size: 16, color: Colors.blueGrey),
            onPressed: () => _showEntertainmentTrafficLightEditor(context, provider),
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalHeader(title: displayTitle),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (mainCategory == 'הכנסות') {
            _showAddIncomeTypeDialog(context, context.read<BudgetProvider>());
          } else {
            _showAddParentCategoryDialog(context, context.read<BudgetProvider>(), mainCategory);
          }
        },
        backgroundColor: Colors.blue,
        tooltip: 'הוסף קבוצת הוצאות/הכנסות',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          final categoryExpenses = provider.expenses.where((e) => e.category == mainCategory).toList();

          if (categoryExpenses.isEmpty) {
            return const Center(child: Text('אין נתונים בקטגוריה זו', style: TextStyle(color: Colors.black)));
          }

          final regularExpenses = categoryExpenses.where((e) => !e.isBusiness).toList();
          final businessExpenses = categoryExpenses.where((e) => e.isBusiness).toList();

          final Map<String, List<Expense>> grouped = {};
          for (var e in regularExpenses) {
            final pCat = e.parentCategory;
            if (!grouped.containsKey(pCat)) { grouped[pCat] = []; }
            grouped[pCat]!.add(e);
          }

          var entries = grouped.entries.toList();
          if (mainCategory == 'עתידיות') {
            const futureOrder = ['רכישות גדולות', 'רכישות קטנות', 'הפקת אירועים', 'תיקונים', 'רפואי', 'חופשה שנתית'];
            entries.sort((a, b) {
              int indexA = futureOrder.indexOf(a.key);
              int indexB = futureOrder.indexOf(b.key);
              if (indexA == -1) { indexA = 999; }
              if (indexB == -1) { indexB = 999; }
              return indexA.compareTo(indexB);
            });
          }

          return Column(
            children: [
              if (mainCategory == 'משתנות') ...[
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "עוגנים מול אחוזים: הוצאת ה'קניות' מוגדרת כעוגן קבוע. היא מופחתת תחילה, והיתרה מתחלקת אוטומטית לשאר הסעיפים לפי האחוזים שהוגדרו.",
                          style: TextStyle(color: Colors.blueGrey[800], fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider.variableDeficit > 0)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[50], border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'התראת תקציב: סך העוגנים חורג ב-₪${provider.variableDeficit.toStringAsFixed(0)}. השאר אופס.',
                            style: TextStyle(color: Colors.red[900], fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildParentsEntertainmentCard(context, provider),
              ],
                
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    ...entries.map((entry) {
                      final parentName = entry.key;
                      final items = entry.value;

                      double total = 0;
                      double totalBalance = 0;
                      double totalTarget = 0;
                      double monthlySinkingTotal = 0;
                      bool hasTarget = false;

                      for (var e in items) {
                        int multiplier = e.isPerChild ? provider.childCount : 1;
                        total += e.monthlyAmount * multiplier;
                        totalBalance += (e.currentBalance ?? 0);
                        if (e.isSinking) { monthlySinkingTotal += e.monthlyAmount * multiplier; }
                        if ((e.targetAmount ?? 0) > 0) { totalTarget += e.targetAmount!; hasTarget = true; }
                      }

                      int unifiedMode = provider.getCategoryUnifiedMode(parentName);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                        color: Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(
                            children: [
                              Text(_formatParentName(parentName), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                              const SizedBox(width: 8),
                              if (parentName != 'קניות' && parentName != 'ילדים - משתנות')
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                  padding: EdgeInsets.zero,
                                  onSelected: (val) {
                                    if (val == 'rename') _showRenameParentDialog(context, provider, parentName);
                                    if (val == 'manage_unified') _showUnifiedModeDialog(context, provider, parentName);
                                  },
                                  itemBuilder: (ctx) => [
                                    if (parentName != 'רכב')
                                      const PopupMenuItem(value: 'rename', child: Text('שינוי שם קבוצה', style: TextStyle(fontSize: 14))),
                                    const PopupMenuItem(
                                      value: 'manage_unified',
                                      child: Text('הגדרת מצב קופה (0/1/2)', style: TextStyle(fontSize: 14)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          subtitle: (mainCategory == 'עתידיות' || (parentName == 'ילדים' && provider.childCount > 0) || unifiedMode > 0) 
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (mainCategory == 'עתידיות') ...[
                                      if (hasTarget)
                                        LinearProgressIndicator(value: (totalTarget > 0) ? (totalBalance / totalTarget).clamp(0.0, 1.0) : 0.0, backgroundColor: Colors.grey[200], color: Colors.green, minHeight: 5, borderRadius: BorderRadius.circular(4)),
                                      const SizedBox(height: 6),
                                      Text(
                                        hasTarget ? 'נצבר: ₪${totalBalance.toStringAsFixed(0)} מתוך ₪${totalTarget.toStringAsFixed(0)}' : 'נצבר בקופה: ₪${totalBalance.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                    if (unifiedMode > 0 && mainCategory != 'עתידיות') ...[
                                      Text('להפרשה חודשית לקופה: ₪${monthlySinkingTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
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
                                  Text('${loc?.get('currency_symbol') ?? '₪'}${(total).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                                  Text('${loc?.get('currency_symbol') ?? '₪'}${(total * 12).toStringAsFixed(0)} בשנה', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              if (unifiedMode > 0 && parentName != 'רכב')
                                IconButton(
                                  icon: const Icon(Icons.account_balance_wallet, color: Colors.green),
                                  tooltip: 'ניהול קופה מאוחדת',
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context, isScrollControlled: true,
                                      backgroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                      builder: (ctx) => _UnifiedFundBottomSheet(provider: provider, parentCategory: parentName, expenses: items),
                                    );
                                  }
                                ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => SpecificExpensesScreen(parentCategory: parentName, mainCategory: mainCategory)
                            ));
                          },
                        ),
                      );
                    }),
                    
                    if (businessExpenses.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 8, right: 8),
                        child: Text("עסקים והכנסות צדדיות", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                      ...businessExpenses.map((business) => _buildBusinessTile(context, provider, business)),
                    ]
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBusinessTile(BuildContext context, BudgetProvider provider, Expense business) {
    double netProfit = business.getBusinessNetProfit();
    bool isPassive = business.isPassive;
    
    return Dismissible(
      key: Key(business.id?.toString() ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (direction) => provider.deleteExpense(business.id!),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isPassive ? Colors.green.shade200 : Colors.blue.shade200)),
        color: isPassive ? Colors.green.shade50 : Colors.white,
        child: InkWell(
          onTap: () => _showBusinessDialog(context, provider, business: business),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storefront, color: isPassive ? Colors.green[800] : Colors.blue[800]),
                        const SizedBox(width: 8),
                        Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                      ],
                    ),
                    const Icon(Icons.edit, size: 18, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('רווח נטו חודשי', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(
                          '₪${netProfit.toStringAsFixed(0)}', 
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: netProfit >= 0 ? Colors.green[800] : Colors.red[800])
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('השקעה שבועית: ${business.businessWorkingHours.toStringAsFixed(1)} שעות', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        if (isPassive)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green[600], borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('נכס פסיבי!', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBusinessDialog(BuildContext context, BudgetProvider provider, {Expense? business}) {
    final nameController = TextEditingController(text: business?.name ?? 'עסק חדש');
    
    List<BusinessSubItem> incomes = business?.parsedBusinessIncomes ?? [BusinessSubItem(id: UniqueKey().toString(), name: '', amount: 0.0)];
    if (incomes.isEmpty) incomes.add(BusinessSubItem(id: UniqueKey().toString(), name: '', amount: 0.0));
    
    List<BusinessSubItem> expenses = business?.parsedBusinessExpenses ?? [BusinessSubItem(id: UniqueKey().toString(), name: '', amount: 0.0)];
    if (expenses.isEmpty) expenses.add(BusinessSubItem(id: UniqueKey().toString(), name: '', amount: 0.0));
    
    String timeScale = 'week'; 
    final hoursCtrl = TextEditingController(text: business != null ? business.businessWorkingHours.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          double calculateNet() {
            double i = incomes.fold(0.0, (s, e) => s + e.amount);
            double e = expenses.fold(0.0, (s, e) => s + e.amount);
            return i - e;
          }
          
          double net = calculateNet();
          double weeklyH = double.tryParse(hoursCtrl.text) ?? 0.0;
          if (timeScale == 'day') weeklyH *= 5;
          bool isPassiveNow = net > 0 && weeklyH <= 4.0;

          Widget buildSubItemList(String title, List<BusinessSubItem> list, Color iconColor) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: iconColor),
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                      onPressed: () => setDialogState(() => list.add(BusinessSubItem(id: UniqueKey().toString(), name: '', amount: 0))),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                ...list.map((item) {
                  int idx = list.indexOf(item);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: item.name,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(labelText: 'שם סעיף', labelStyle: TextStyle(color: Colors.black54), isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) => item.name = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: item.amount == 0 ? '' : item.amount.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(labelText: 'סכום', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪', isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              item.amount = double.tryParse(val) ?? 0;
                              setDialogState((){}); 
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30),
                          onPressed: () => setDialogState(() { if(list.length > 1) list.removeAt(idx); }),
                        )
                      ],
                    ),
                  );
                }),
              ],
            );
          }

          return Theme(
            data: ThemeData.light(),
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('הגדרת עסק / הכנסה צדדית', style: TextStyle(fontSize: 18, color: Colors.black87)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'שם העסק / המיזם', labelStyle: TextStyle(color: Colors.black54), border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          buildSubItemList('מקורות הכנסה בעסק', incomes, Colors.green),
                          const Divider(height: 24),
                          buildSubItemList('הוצאות העסק', expenses, Colors.red),
                        ],
                      )
                    ),
                    const SizedBox(height: 16),
                    
                    const Align(alignment: Alignment.centerRight, child: Text('כמה זמן העסק הזה דורש ממך?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: hoursCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(labelText: 'כמות שעות', labelStyle: TextStyle(color: Colors.black54), border: OutlineInputBorder(), isDense: true),
                            onChanged: (_) => setDialogState((){}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: InputDecorator(
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), isDense: true),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: timeScale,
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black87),
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(value: 'day', child: Text('ביום')),
                                  DropdownMenuItem(value: 'week', child: Text('בשבוע')),
                                ],
                                onChanged: (val) => setDialogState(() => timeScale = val!),
                              )
                            )
                          )
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isPassiveNow ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('רווח נטו מחושב:', style: TextStyle(fontSize: 12, color: Colors.black87)),
                              Text('₪${net.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: net >= 0 ? Colors.green[800] : Colors.red[800])),
                            ],
                          ),
                          if (isPassiveNow)
                            const Row(
                              children: [
                                Icon(Icons.verified, color: Colors.green),
                                SizedBox(width: 4),
                                Text('נכס פסיבי!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                              ],
                            )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      String incJson = jsonEncode(incomes.map((e) => e.toMap()).toList());
                      String expJson = jsonEncode(expenses.map((e) => e.toMap()).toList());
                      
                      double finalHours = double.tryParse(hoursCtrl.text) ?? 0.0;
                      if (timeScale == 'day') finalHours *= 5;

                      final newExpense = Expense(
                        id: business?.id,
                        name: nameController.text.trim(),
                        category: 'הכנסות',
                        parentCategory: business?.parentCategory ?? 'עסקים',
                        monthlyAmount: 0, 
                        isLocked: false,
                        isCustom: true,
                        date: business?.date ?? DateTime.now().toIso8601String(),
                        isBusiness: true,
                        businessIncomes: incJson,
                        businessExpenses: expJson,
                        businessWorkingHours: finalHours,
                      );
                      
                      if (business == null) {
                        await provider.addExpense(newExpense);
                      } else {
                        await provider.updateExpense(newExpense);
                      }
                      
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Text(business == null ? 'הוסף עסק' : 'שמור שינויים'),
                )
              ]
            ),
          );
        }
      )
    );
  }
}

class SpecificExpensesScreen extends StatelessWidget {
  final String parentCategory;
  final String mainCategory;

  const SpecificExpensesScreen({
    super.key, 
    required this.parentCategory,
    required this.mainCategory,
  });

  String _formatParentName(String name) {
    if (name == 'בית') { return 'קטנות לבית'; }
    return name;
  }

  void _showRenameParentDialog(BuildContext context, BudgetProvider provider, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("שינוי שם: $oldName", style: const TextStyle(color: Colors.black87)),
          content: TextField(
            controller: controller, 
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(labelText: 'שם קבוצה חדש', labelStyle: TextStyle(color: Colors.black54)), 
            autofocus: true
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ביטול")),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty && controller.text != oldName) {
                  provider.renameParentCategory(oldName, controller.text);
                  Navigator.pop(ctx);
                  Navigator.pop(context); 
                }
              },
              child: const Text("עדכן"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context, BudgetProvider provider) {
    final nameController = TextEditingController();
    String selectedType = 'car';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Theme(
          data: ThemeData.light(),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('הוספת רכב חדש', style: TextStyle(color: Colors.black87)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController, 
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(labelText: 'כינוי הרכב (למשל: מאזדה 3)', labelStyle: TextStyle(color: Colors.black54))
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'סוג רכב', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedType, 
                      isExpanded: true,
                      style: const TextStyle(color: Colors.black87),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'car', child: Text('מכונית פרטית')),
                        DropdownMenuItem(value: 'motorcycle', child: Text('קטנוע / אופנוע')),
                      ],
                      onChanged: (val) {
                        if (val != null) { setDialogState(() => selectedType = val); }
                      }
                    )
                  )
                )
              ]
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    await provider.addVehicleTemplate(nameController.text.trim(), selectedType);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('הוסף רכב'),
              )
            ]
          ),
        )
      )
    );
  }

  void _showAddIncomeTypeDialog(BuildContext context, BudgetProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('מה תרצה להוסיף?', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.attach_money, color: Colors.green),
                title: const Text('הכנסה רגילה (משכורת, קצבה)', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddExpenseDialog(context, provider, parentCategory, mainCategory);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.storefront, color: Colors.blue),
                title: const Text('עסק / הכנסה צדדית מורכבת', style: TextStyle(color: Colors.black87)),
                subtitle: const Text('כולל שורות הכנסות והוצאות', style: TextStyle(fontSize: 11, color: Colors.black54)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBusinessDialog(context, provider);
                },
              ),
            ],
          ),
        ),
      )
    );
  }

  void _showRenameVehicle(BuildContext context, BudgetProvider provider, List<Expense> items, String oldName) {
    final ctrl = TextEditingController(text: oldName == 'כללי' ? '' : oldName);
    showDialog(
      context: context,
      builder: (c) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('שינוי כינוי רכב', style: TextStyle(color: Colors.black87)),
          content: TextField(
            controller: ctrl, 
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(labelText: 'כינוי חדש (למשל: סובארו)', labelStyle: TextStyle(color: Colors.black54))
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('ביטול')),
            ElevatedButton(onPressed: () async {
               String newVName = ctrl.text.trim();
               if (newVName.isNotEmpty && newVName != oldName) {
                 for (var e in items) {
                   String newExName;
                   if (oldName == 'כללי' || !e.name.contains('($oldName)')) {
                      newExName = '${e.name.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim()} ($newVName)';
                   } else {
                      newExName = e.name.replaceAll('($oldName)', '($newVName)');
                   }
                   await provider.updateFutureExpenseDetails(e.id!, name: newExName);
                 }
                 if (c.mounted) Navigator.pop(c);
               }
            }, child: const Text('שמור')),
          ]
        ),
      )
    );
  }

  void _showAddVehicleExpenseDialog(BuildContext context, BudgetProvider provider, String vehicleName) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    bool isSinking = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Theme(
          data: ThemeData.light(),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('הוספת סעיף ל-$vehicleName', style: const TextStyle(fontSize: 18, color: Colors.black87)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController, 
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(labelText: 'שם הסעיף (למשל: שטיפה)', labelStyle: TextStyle(color: Colors.black54))
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController, 
                  keyboardType: TextInputType.number, 
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(labelText: 'סכום חודשי משוער', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪')
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('הוצאה צוברת (קופה)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  subtitle: const Text('דלק וליסינג סמנו כלא צובר', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  value: isSinking,
                  activeThumbColor: Colors.green,
                  onChanged: (val) { setDialogState(() { isSinking = val; }); },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (nameController.text.isNotEmpty) {
                    final newExpense = Expense(
                      name: '${nameController.text.trim()} ($vehicleName)',
                      category: 'קבועות',
                      parentCategory: 'רכב',
                      monthlyAmount: amount,
                      frequency: Frequency.MONTHLY,
                      isLocked: true, 
                      isPerChild: false,
                      date: DateTime.now().toIso8601String(),
                      isDynamicSalary: false, 
                      isSinking: isSinking,
                      isCustom: true, 
                      allocationRatio: 0.0,
                    );
                    await provider.addExpense(newExpense);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('הוסף'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKidsSections(BuildContext context, BudgetProvider provider, List<Expense> currentExpenses) {
    Map<String, List<Expense>> kids = {};
    for (var e in currentExpenses) {
      String kName = e.name.replaceAll('בגדים', '').replaceAll('בילויים', '').trim();
      kids.putIfAbsent(kName, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: kids.entries.map((entry) {
        final childName = entry.key;
        final items = entry.value;
        double childTotal = items.fold(0.0, (sum, e) => sum + e.monthlyAmount);
        double childBalance = items.fold(0.0, (sum, e) => sum + (e.currentBalance ?? 0));
        double childRatio = items.fold(0.0, (sum, e) => sum + (e.allocationRatio ?? 0));
        String ratioText = childRatio > 0 ? ' | הקצאה: ${(childRatio * 100).toStringAsFixed(1)}%' : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: CircleAvatar(backgroundColor: Colors.purple[50], child: Icon(Icons.child_care, color: Colors.purple[400])),
              title: Text(childName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
              subtitle: Text('צבור: ₪${childBalance.toStringAsFixed(0)} | תקציב: ₪${childTotal.toStringAsFixed(0)}$ratioText', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[50], foregroundColor: Colors.purple[800], elevation: 0),
                          icon: const Icon(Icons.account_balance_wallet, size: 18),
                          label: const Text('ניהול קופה אישית', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context, isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (ctx) => _UnifiedFundBottomSheet(provider: provider, parentCategory: 'ילדים: $childName', expenses: items),
                            );
                          }
                        )
                      ),
                    ]
                  )
                ),
                ...items.map((e) => _buildExpenseTile(context, provider, e, childName: childName, unifiedMode: 1))
              ]
            ),
          )
        );
      }).toList()
    );
  }

  Widget _buildVehicleSections(BuildContext context, BudgetProvider provider, List<Expense> currentExpenses) {
    Map<String, List<Expense>> vehicles = {};
    for (var e in currentExpenses) {
      String vName = 'כללי';
      final match = RegExp(r'\((.*?)\)').firstMatch(e.name);
      if (match != null) { vName = match.group(1)!; }
      vehicles.putIfAbsent(vName, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: vehicles.entries.map((entry) {
        final vehicleName = entry.key;
        final items = entry.value;
        
        double vehicleTotal = items.fold(0.0, (sum, e) => sum + e.monthlyAmount);
        double vehicleBalance = items.where((e)=>e.isSinking).fold(0.0, (sum, e) => sum + (e.currentBalance ?? 0));
        double vehicleSinkingTotal = items.where((e)=>e.isSinking).fold(0.0, (sum, e) => sum + e.monthlyAmount);

        int unifiedMode = provider.getCategoryUnifiedMode('רכב');

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: CircleAvatar(backgroundColor: Colors.blue[50], child: Icon(Icons.directions_car, color: Colors.blue[400])),
              title: Text(vehicleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unifiedMode > 0)
                    Text('צבור בקופה: ₪${vehicleBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('${unifiedMode > 0 ? 'הפרשה חודשית לקופה: ₪${vehicleSinkingTotal.toStringAsFixed(0)} | ' : ''}עלות חודשית כוללת: ₪${vehicleTotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
                ],
              ),
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (unifiedMode > 0)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.1), foregroundColor: Colors.green, elevation: 0),
                          icon: const Icon(Icons.account_balance_wallet, size: 18),
                          label: const Text('ניהול קופה', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            final sinkingItems = items.where((e) => e.isSinking).toList();
                            showModalBottomSheet(
                              context: context, isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (ctx) => _UnifiedFundBottomSheet(provider: provider, parentCategory: 'רכב: $vehicleName', expenses: sinkingItems),
                            );
                          }
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blue), tooltip: 'הוסף סעיף לרכב', onPressed: () => _showAddVehicleExpenseDialog(context, provider, vehicleName)),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blueGrey), tooltip: 'ערוך שם רכב', onPressed: () => _showRenameVehicle(context, provider, items, vehicleName)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: 'מחק רכב זה', onPressed: () async {
                            bool? confirm = await showDialog(
                              context: context,
                              builder: (c) => Theme(
                                data: ThemeData.light(),
                                child: AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text('מחיקת רכב', style: TextStyle(color: Colors.black87)),
                                  content: Text('האם למחוק את כל ההוצאות המשויכות לרכב "$vehicleName"?', style: const TextStyle(color: Colors.black87)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('ביטול')),
                                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(c, true), child: const Text('מחק רכב', style: TextStyle(color: Colors.white))),
                                  ]
                                ),
                              )
                            );
                            if (confirm == true) {
                              for (var e in items) { if (e.id != null) await provider.deleteExpense(e.id!); }
                            }
                          })
                        ],
                      )
                    ]
                  )
                ),
                ...items.map((e) => _buildExpenseTile(context, provider, e, isVehicle: true, unifiedMode: unifiedMode))
              ]
            ),
          )
        );
      }).toList(),
    );
  }

  Widget _buildBusinessTile(BuildContext context, BudgetProvider provider, Expense business) {
    double netProfit = business.getBusinessNetProfit();
    bool isPassive = business.isPassive;
    
    return Dismissible(
      key: Key(business.id?.toString() ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (direction) => provider.deleteExpense(business.id!),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isPassive ? Colors.green.shade200 : Colors.blue.shade200)),
        color: isPassive ? Colors.green.shade50 : Colors.white,
        child: InkWell(
          onTap: () => _showBusinessDialog(context, provider, business: business),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storefront, color: isPassive ? Colors.green[800] : Colors.blue[800]),
                        const SizedBox(width: 8),
                        Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                      ],
                    ),
                    const Icon(Icons.edit, size: 18, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('רווח נטו חודשי', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(
                          '₪${netProfit.toStringAsFixed(0)}', 
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: netProfit >= 0 ? Colors.green[800] : Colors.red[800])
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('השקעה שבועית: ${business.businessWorkingHours.toStringAsFixed(1)} שעות', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        if (isPassive)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green[600], borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('נכס פסיבי!', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBusinessDialog(BuildContext context, BudgetProvider provider, {Expense? business}) {
    final nameController = TextEditingController(text: business?.name ?? 'עסק חדש');
    
    List<BusinessSubItem> incomes = business?.parsedBusinessIncomes ?? [BusinessSubItem(id: UniqueKey().toString(), name: '', amount: 0.0)];
    if (incomes.isEmpty) incomes.add(BusinessSubItem(id: UniqueKey().toString(), name: '', amount: 0.0));
    
    List<BusinessSubItem> expenses = business?.parsedBusinessExpenses ?? [BusinessSubItem(id: UniqueKey().toString(), name: '', amount: 0.0)];
    if (expenses.isEmpty) expenses.add(BusinessSubItem(id: UniqueKey().toString(), name: '', amount: 0.0));
    
    String timeScale = 'week'; 
    final hoursCtrl = TextEditingController(text: business != null ? business.businessWorkingHours.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          double calculateNet() {
            double i = incomes.fold(0.0, (s, e) => s + e.amount);
            double e = expenses.fold(0.0, (s, e) => s + e.amount);
            return i - e;
          }
          
          double net = calculateNet();
          double weeklyH = double.tryParse(hoursCtrl.text) ?? 0.0;
          if (timeScale == 'day') weeklyH *= 5; 
          bool isPassiveNow = net > 0 && weeklyH <= 4.0;

          Widget buildSubItemList(String title, List<BusinessSubItem> list, Color iconColor) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: iconColor),
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                      onPressed: () => setDialogState(() => list.add(BusinessSubItem(id: UniqueKey().toString(), name: '', amount: 0))),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                ...list.map((item) {
                  int idx = list.indexOf(item);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: item.name,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(labelText: 'שם סעיף', labelStyle: TextStyle(color: Colors.black54), isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) => item.name = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: item.amount == 0 ? '' : item.amount.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(labelText: 'סכום', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪', isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              item.amount = double.tryParse(val) ?? 0;
                              setDialogState((){}); 
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30),
                          onPressed: () => setDialogState(() { if(list.length > 1) list.removeAt(idx); }),
                        )
                      ],
                    ),
                  );
                }),
              ],
            );
          }

          return Theme(
            data: ThemeData.light(),
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('הגדרת עסק / הכנסה צדדית', style: TextStyle(fontSize: 18, color: Colors.black87)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'שם העסק / המיזם', labelStyle: TextStyle(color: Colors.black54), border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          buildSubItemList('מקורות הכנסה בעסק', incomes, Colors.green),
                          const Divider(height: 24),
                          buildSubItemList('הוצאות העסק', expenses, Colors.red),
                        ],
                      )
                    ),
                    const SizedBox(height: 16),
                    
                    const Align(alignment: Alignment.centerRight, child: Text('כמה זמן העסק הזה דורש ממך?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: hoursCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(labelText: 'כמות שעות', labelStyle: TextStyle(color: Colors.black54), border: OutlineInputBorder(), isDense: true),
                            onChanged: (_) => setDialogState((){}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: InputDecorator(
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), isDense: true),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: timeScale,
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black87),
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(value: 'day', child: Text('ביום')),
                                  DropdownMenuItem(value: 'week', child: Text('בשבוע')),
                                ],
                                onChanged: (val) => setDialogState(() => timeScale = val!),
                              )
                            )
                          )
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isPassiveNow ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('רווח נטו מחושב:', style: TextStyle(fontSize: 12, color: Colors.black87)),
                              Text('₪${net.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: net >= 0 ? Colors.green[800] : Colors.red[800])),
                            ],
                          ),
                          if (isPassiveNow)
                            const Row(
                              children: [
                                Icon(Icons.verified, color: Colors.green),
                                SizedBox(width: 4),
                                Text('נכס פסיבי!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                              ],
                            )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      String incJson = jsonEncode(incomes.map((e) => e.toMap()).toList());
                      String expJson = jsonEncode(expenses.map((e) => e.toMap()).toList());
                      
                      double finalHours = double.tryParse(hoursCtrl.text) ?? 0.0;
                      if (timeScale == 'day') finalHours *= 5;

                      final newExpense = Expense(
                        id: business?.id,
                        name: nameController.text.trim(),
                        category: 'הכנסות',
                        parentCategory: parentCategory, 
                        monthlyAmount: 0, 
                        isLocked: false,
                        isCustom: true,
                        date: business?.date ?? DateTime.now().toIso8601String(),
                        isBusiness: true,
                        businessIncomes: incJson,
                        businessExpenses: expJson,
                        businessWorkingHours: finalHours,
                      );
                      
                      if (business == null) {
                        await provider.addExpense(newExpense);
                      } else {
                        await provider.updateExpense(newExpense);
                      }
                      
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Text(business == null ? 'הוסף עסק' : 'שמור שינויים'),
                )
              ]
            ),
          );
        }
      )
    );
  }

  Widget _buildExpenseTile(BuildContext context, BudgetProvider provider, Expense expense, {bool isVehicle = false, String? childName, int unifiedMode = 0}) {
    final loc = AppLocalizations.of(context);
    final multiplier = expense.isPerChild ? provider.childCount : 1;
    final displayAmount = expense.monthlyAmount * multiplier;
    
    bool isVariable = (expense.category == 'משתנות');
    bool isFuture = (expense.category == 'עתידיות');
    bool isIncome = (expense.category == 'הכנסות');
    bool isAnchor = expense.name.trim() == 'קניות' || (isVariable && expense.parentCategory == 'קניות');

    String timeText = '';
    if (isFuture && (expense.targetAmount ?? 0) > 0) {
      double remaining = (expense.targetAmount!) - (expense.currentBalance ?? 0);
      if (remaining <= 0) {
        timeText = 'היעד הושג 🎉';
      } else if (displayAmount > 0) {
        int months = (remaining / displayAmount).ceil();
        if (months == 1) { timeText = 'נותר חודש אחד'; }
        else if (months == 2) { timeText = 'נותרו חודשיים'; }
        else { timeText = 'נותרו $months חודשים'; }
      } else {
        timeText = 'ללא צפי הגעה';
      }
    }

    String cleanName = expense.name;
    String? vName;
    if (isVehicle) {
      final match = RegExp(r'\((.*?)\)').firstMatch(expense.name);
      vName = match != null ? match.group(1) : 'כללי';
      cleanName = cleanName.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
    }
    if (childName != null) {
      cleanName = cleanName.replaceAll(childName, '').trim();
    }

    Widget tile = ListTile(
      title: Row(
        children: [
          Text(cleanName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: (isVehicle || childName != null) ? Colors.black87 : Colors.black)),
          if (expense.isLocked && !isIncome) const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.lock, size: 14, color: Colors.orange))
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expense.isPerChild) ...[
            Text('₪${expense.monthlyAmount.toStringAsFixed(0)} לחודש × ${provider.childCount} ילדים', style: TextStyle(fontSize: 12, color: Colors.orange[900], fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('עלות שנתית לילד יחיד: ₪${(expense.monthlyAmount * 12).toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.purple[700], fontWeight: FontWeight.bold)),
          ] else if (!expense.isPerChild && expense.parentCategory == 'ילדים - קבועות' && provider.childCount > 0) ...[
            const SizedBox(height: 4),
            Text('עלות חודשית לילד יחיד: ₪${(displayAmount / provider.childCount).toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.purple[700], fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('עלות שנתית לילד יחיד: ₪${((displayAmount / provider.childCount) * 12).toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.purple[700], fontWeight: FontWeight.bold)),
          ] else if ((isVariable || isFuture) && !expense.isLocked && !isAnchor) ...[
            Text('${((expense.allocationRatio ?? 0) * 100).toStringAsFixed(1)}% מהיתרה', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          
          if (isIncome && expense.isDynamicSalary)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('מחושב אוטומטית ע"פ ממוצע שכר', style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.bold)),
            ),

          if (expense.isSinking && !isFuture && unifiedMode != 1 && childName == null) ...[
            const SizedBox(height: 4),
            Text('קופה נצברת: ₪${(expense.currentBalance ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
          ],

          if (isFuture) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (expense.targetAmount ?? 0) > 0 ? ((expense.currentBalance ?? 0) / (expense.targetAmount ?? 1)).clamp(0.0, 1.0) : 0.0, backgroundColor: Colors.grey[200], color: Colors.green, minHeight: 6, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₪${(expense.currentBalance ?? 0).toStringAsFixed(0)} מתוך ₪${(expense.targetAmount ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (timeText.isNotEmpty) Text(timeText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[400])),
              ],
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${loc?.get('currency_symbol') ?? '₪'}${(displayAmount).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: expense.isLocked ? Colors.orange[800] : Colors.black)),
            Text('${loc?.get('currency_symbol') ?? '₪'}${(displayAmount * 12).toStringAsFixed(0)} בשנה', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
            if (isFuture) const Text('הפרשה חודשית', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
          const SizedBox(width: 12),
          
          if (expense.isSinking && unifiedMode != 1 && childName == null)
            IconButton(
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.green),
              tooltip: 'ניהול קופה ומשיכות',
              onPressed: () {
                showModalBottomSheet(
                  context: context, isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  builder: (ctx) => _SinkingFundBottomSheet(provider: provider, expense: expense)
                );
              },
            ),

          IconButton(
            icon: Icon((isVariable || isFuture) ? Icons.tune : Icons.edit, size: 20, color: Colors.blueGrey),
            onPressed: () {
              if (isFuture) {
                _showFutureEditDialog(context, provider, expense);
              } else if (isVariable && (expense.allocationRatio != null || isAnchor)) {
                _showSmartEditDialog(context, provider, expense);
              } else {
                _showEditDialog(context, provider, expense, isVehicle: isVehicle, vehicleName: vName);
              }
            },
          ),
        ],
      ),
    );

    if (expense.isCustom || expense.category == 'הכנסות') {
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
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final provider = context.watch<BudgetProvider>(); 
    final currentExpenses = provider.expenses.where((e) => e.parentCategory == parentCategory).toList();
    
    double total = 0;
    double totalSinkingMonthly = 0;

    for (var current in currentExpenses) {
        int multiplier = current.isPerChild ? provider.childCount : 1;
        total += current.monthlyAmount * multiplier;
        if (current.isSinking) {
            totalSinkingMonthly += current.monthlyAmount * multiplier;
        }
    }

    int unifiedMode = provider.getCategoryUnifiedMode(parentCategory);

    final regularExpenses = currentExpenses.where((e) => !e.isBusiness).toList();
    final businessExpenses = currentExpenses.where((e) => e.isBusiness).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalHeader(title: _formatParentName(parentCategory)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (parentCategory == 'רכב') {
            _showAddVehicleDialog(context, provider);
          } else if (mainCategory == 'הכנסות') {
            _showAddIncomeTypeDialog(context, provider);
          } else {
            _showAddExpenseDialog(context, provider, parentCategory, mainCategory);
          }
        },
        backgroundColor: Colors.blue,
        icon: Icon(parentCategory == 'רכב' ? Icons.directions_car : Icons.add, color: Colors.white),
        label: Text(parentCategory == 'רכב' ? 'הוסף רכב' : 'סעיף חדש', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), border: const Border(bottom: BorderSide(color: Colors.black12))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('סה"כ תזרים חודשי:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${loc?.get('currency_symbol') ?? '₪'}${(total).toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                            Text('${loc?.get('currency_symbol') ?? '₪'}${(total * 12).toStringAsFixed(0)} בשנה', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (val) {
                            if (val == 'rename') _showRenameParentDialog(context, provider, parentCategory);
                            if (val == 'manage_unified') _showUnifiedModeDialog(context, provider, parentCategory);
                          },
                          itemBuilder: (ctx) => [
                            if (parentCategory != 'קניות' && parentCategory != 'רכב' && parentCategory != 'ילדים - משתנות' && parentCategory != 'עסקים')
                              const PopupMenuItem(value: 'rename', child: Text('שינוי שם קבוצה', style: TextStyle(fontSize: 14))),
                            if (parentCategory != 'קניות' && parentCategory != 'ילדים - משתנות' && parentCategory != 'עסקים')
                              const PopupMenuItem(
                                value: 'manage_unified',
                                child: Text('הגדרת מצב קופה (0/1/2)', style: TextStyle(fontSize: 14)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (mainCategory == 'הכנסות') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.15), foregroundColor: Colors.blue[800], elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      icon: const Icon(Icons.insights),
                      label: const Text('מנוע סטטיסטיקת שכר', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const SalaryEngineScreen()));
                      },
                    ),
                  )
                ],

                if (unifiedMode > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('להפרשה חודשית לקופה:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('₪${totalSinkingMonthly.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
                    ]
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('יתרה צבורה (נצבר עד כה):', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('₪${currentExpenses.fold(0.0, (s, e) => s + (e.currentBalance ?? 0)).toStringAsFixed(0)}', style: const TextStyle(color: Colors.blueGrey, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.1), foregroundColor: Colors.green, elevation: 0),
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('ניהול משיכות (קופה מאוחדת)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => showModalBottomSheet(
                        context: context, isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (ctx) => _UnifiedFundBottomSheet(provider: provider, parentCategory: parentCategory, expenses: currentExpenses),
                      ),
                    ),
                  )
                ]
              ],
            ),
          ),
          Expanded(
            child: parentCategory == 'רכב'
              ? _buildVehicleSections(context, provider, currentExpenses)
              : (parentCategory == 'ילדים - משתנות' 
                  ? _buildKidsSections(context, provider, currentExpenses)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ...regularExpenses.map((e) => Column(
                          children: [
                            _buildExpenseTile(context, provider, e, unifiedMode: unifiedMode),
                            const Divider()
                          ],
                        )),
                        if (businessExpenses.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 24, bottom: 8, right: 8),
                            child: Text("עסקים והכנסות צדדיות", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                          ...businessExpenses.map((business) => _buildBusinessTile(context, provider, business)),
                        ]
                      ],
                    )
                ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, BudgetProvider provider, String parentCat, String mainCat) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    bool isSinking = mainCat == 'עתידיות' || parentCat == 'חגים';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Theme(
          data: ThemeData.light(),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('הוספת סעיף ($parentCat)', style: const TextStyle(color: Colors.black87)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'שם הסעיף', labelStyle: TextStyle(color: Colors.black54))),
                const SizedBox(height: 10),
                TextField(controller: amountController, style: const TextStyle(color: Colors.black87), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום חודשי כולל', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪')),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('הוצאה צוברת (קופה)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  subtitle: const Text('תוצג במסגרת הירוקה כחיסכון בצד', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  value: isSinking,
                  activeThumbColor: Colors.green,
                  onChanged: (val) {
                    setDialogState(() { isSinking = val; });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (nameController.text.isNotEmpty) {
                    bool isChildCat = parentCat == 'ילדים - קבועות';
                    int multiplier = isChildCat ? provider.childCount : 1;
                    if (multiplier < 1) { multiplier = 1; }
                    
                    bool isLocked = true;
                    if (mainCat == 'משתנות' || mainCat == 'עתידיות') {
                      isLocked = false; 
                    }

                    final newExpense = Expense(
                      name: nameController.text.trim(),
                      category: mainCat,
                      parentCategory: parentCat,
                      monthlyAmount: amount / multiplier, 
                      frequency: Frequency.MONTHLY,
                      isLocked: isLocked, 
                      isPerChild: isChildCat,
                      date: DateTime.now().toIso8601String(),
                      isDynamicSalary: false, 
                      isSinking: isSinking,
                      isCustom: true, 
                      allocationRatio: 0.0,
                    );
                    await provider.addExpense(newExpense);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('הוסף'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, BudgetProvider provider, Expense expense, {bool isVehicle = false, String? vehicleName}) {
    double factor = 1.0;
    if (expense.frequency == Frequency.YEARLY) { factor = 12.0; }
    else if (expense.frequency == Frequency.BI_MONTHLY) { factor = 2.0; }
    
    int multiplier = expense.isPerChild ? provider.childCount : 1;
    if (multiplier < 1) { multiplier = 1; }
    
    String cleanName = expense.name;
    if (isVehicle && vehicleName != null) {
      cleanName = cleanName.replaceAll('($vehicleName)', '').trim();
    }

    final nameController = TextEditingController(text: cleanName); 
    final amountController = TextEditingController();
    Frequency selectedFreq = expense.frequency;
    bool isSinking = expense.isSinking;

    bool isIncome = expense.category == 'הכנסות';
    bool isDynamic = expense.isDynamicSalary;
    String? startDateStr = expense.salaryStartDate;
    double avgSalary = 0.0;
    
    if (isIncome && expense.id != null) { avgSalary = provider.getAverageSalary(expense.id!); }
    
    if (isIncome && isDynamic) {
      amountController.text = (avgSalary * factor * multiplier).toStringAsFixed(0);
    } else {
      amountController.text = (expense.monthlyAmount * factor * multiplier).toStringAsFixed(0);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Theme(
            data: ThemeData.light(),
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('עריכת סעיף', style: TextStyle(color: Colors.black87)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'שם הסעיף', labelStyle: TextStyle(color: Colors.black54))),
                    const SizedBox(height: 10),
                    
                    if (isIncome) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('משכורת דינמית', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        subtitle: const Text('שאיבה ממוצעת מהיסטוריית עבודה', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        value: isDynamic, activeThumbColor: Colors.blue,
                        onChanged: (val) {
                          setDialogState(() {
                            isDynamic = val;
                            amountController.text = isDynamic ? (avgSalary * factor * multiplier).toStringAsFixed(0) : (expense.monthlyAmount * factor * multiplier).toStringAsFixed(0);
                          });
                        },
                      ),
                      if (isDynamic) ...[
                         ListTile(
                           contentPadding: EdgeInsets.zero,
                           title: const Text('חודש תחילת עבודה:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                           subtitle: Text(startDateStr != null ? _formatMonthYear(startDateStr!) : 'מתחילת השנה', style: const TextStyle(color: Colors.black54)),
                           trailing: const Icon(Icons.edit_calendar, size: 20, color: Colors.blue),
                           onTap: () async {
                             DateTime initial = startDateStr != null ? DateTime.parse(startDateStr!) : DateTime.now();
                             final date = await showDatePicker(
                               context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime.now(),
                               builder: (context, child) => Theme(data: ThemeData.light(), child: child!),
                             );
                             if (date != null) { setDialogState(() => startDateStr = DateTime(date.year, date.month, 1).toIso8601String()); }
                           }
                         ),
                      ],
                      const Divider(),
                    ],

                    TextField(
                      controller: amountController, 
                      keyboardType: TextInputType.number, 
                      readOnly: (isIncome && isDynamic),
                      style: TextStyle(
                        color: (isIncome && isDynamic) ? Colors.blueGrey[900] : Colors.black87,
                        fontWeight: (isIncome && isDynamic) ? FontWeight.bold : FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        labelText: expense.isPerChild ? 'סכום לתשלום (עבור כל הילדים)' : (isIncome ? 'סכום חודשי' : 'סכום לתשלום'), 
                        labelStyle: const TextStyle(color: Colors.black54),
                        suffixText: '₪',
                        filled: (isIncome && isDynamic), 
                        fillColor: Colors.grey[100],
                        prefixIcon: (isIncome && isDynamic) ? const Icon(Icons.lock, size: 16, color: Colors.blueGrey) : null,
                        border: const OutlineInputBorder()
                      )
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), isDense: true),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Frequency>(
                          value: selectedFreq, isExpanded: true,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black87),
                          items: const [DropdownMenuItem(value: Frequency.MONTHLY, child: Text('חודשי')), DropdownMenuItem(value: Frequency.BI_MONTHLY, child: Text('דו-חודשי')), DropdownMenuItem(value: Frequency.YEARLY, child: Text('שנתי'))],
                          onChanged: (isIncome && isDynamic) ? null : (val) { if (val != null) { setDialogState(() => selectedFreq = val); } },
                        )
                      )
                    ),
                    
                    if (!isIncome) ...[
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('הוצאה צוברת (קופה)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        subtitle: const Text('הצגה במסגרת הירוקה כחיסכון שוטף', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        value: isSinking, activeThumbColor: Colors.green,
                        onChanged: (val) { setDialogState(() => isSinking = val); },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
                ElevatedButton(
                  onPressed: () async {
                    final val = double.tryParse(amountController.text);
                    final rawName = nameController.text.trim().isNotEmpty ? nameController.text.trim() : cleanName;
                    final finalName = (isVehicle && vehicleName != null) ? '$rawName ($vehicleName)' : rawName;
                    
                    if (val != null || (isIncome && isDynamic)) {
                      double monthly = val ?? 0;
                      if (selectedFreq == Frequency.YEARLY) { monthly = monthly / 12; }
                      else if (selectedFreq == Frequency.BI_MONTHLY) { monthly = monthly / 2; }
                      monthly = monthly / multiplier;

                      await provider.updateExpense(Expense(
                        id: expense.id, name: finalName, category: expense.category, parentCategory: expense.parentCategory,
                        monthlyAmount: (isIncome && isDynamic) ? avgSalary : monthly, frequency: selectedFreq, 
                        isSinking: isSinking, isPerChild: expense.isPerChild, allocationRatio: expense.allocationRatio, 
                        isLocked: expense.isLocked, manualAmount: expense.manualAmount, date: expense.date,
                        isDynamicSalary: isDynamic, salaryStartDate: startDateStr, targetAmount: expense.targetAmount, currentBalance: expense.currentBalance, isCustom: expense.isCustom,
                        isBusiness: expense.isBusiness, businessIncomes: expense.businessIncomes, businessExpenses: expense.businessExpenses, businessWorkingHours: expense.businessWorkingHours,
                      ));
                      
                      await provider.loadData();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('שמור'),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showSmartEditDialog(BuildContext context, BudgetProvider provider, Expense expense) {
    int multiplier = expense.isPerChild ? provider.childCount : 1;
    if (multiplier < 1) { multiplier = 1; }

    bool isAnchor = expense.name.trim() == 'קניות' || (expense.category == 'משתנות' && expense.parentCategory == 'קניות');

    final amountController = TextEditingController(text: expense.isLocked ? (expense.monthlyAmount * multiplier).toStringAsFixed(0) : "");
    final ratioController = TextEditingController(text: ((expense.allocationRatio ?? 0) * 100).toStringAsFixed(1));
    bool isRatioMode = isAnchor ? false : !expense.isLocked; 
    bool isSinking = expense.isSinking;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Theme(
          data: ThemeData.light(),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('כיול ${expense.name}', style: const TextStyle(fontSize: 18, color: Colors.black87))),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  tooltip: 'חזרה לברירת מחדל',
                  onPressed: () {
                    provider.resetExpenseToDefault(expense.id!, isSinking: isSinking);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isAnchor) ...[
                  ToggleButtons(
                    isSelected: [isRatioMode, !isRatioMode],
                    onPressed: (index) => setState(() => isRatioMode = index == 0),
                    borderRadius: BorderRadius.circular(10),
                    children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('אחוז')), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('סכום'))],
                  ),
                  const SizedBox(height: 20),
                ],
                isRatioMode 
                  ? TextField(controller: ratioController, style: const TextStyle(color: Colors.black87), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'אחוז מהיתרה', labelStyle: TextStyle(color: Colors.black54), suffixText: '%', border: OutlineInputBorder()))
                  : TextField(controller: amountController, style: const TextStyle(color: Colors.black87), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: expense.isPerChild ? 'סכום קבוע (כולל)' : 'סכום קבוע', labelStyle: const TextStyle(color: Colors.black54), suffixText: '₪', border: const OutlineInputBorder())),
                const Divider(height: 30),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('הוצאה צוברת (קופה)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  subtitle: const Text('הצגה במסגרת הירוקה כחיסכון שוטף', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  value: isSinking, activeThumbColor: Colors.green,
                  onChanged: (val) { setState(() => isSinking = val); },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
              ElevatedButton(
                onPressed: () async {
                  if (isRatioMode && !isAnchor) {
                    final val = double.tryParse(ratioController.text);
                    if (val != null) { await provider.updateExpenseRatio(expense.id!, val / 100, isSinking: isSinking); }
                  } else {
                    final valText = amountController.text.trim();
                    if (valText.isEmpty) {
                      await provider.resetExpenseToDefault(expense.id!, isSinking: isSinking);
                    } else {
                      final val = double.tryParse(valText);
                      if (val != null) { await provider.lockExpenseAmount(expense.id!, val / multiplier, isSinking: isSinking); }
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('עדכן'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFutureEditDialog(BuildContext context, BudgetProvider provider, Expense expense) {
    int multiplier = expense.isPerChild ? provider.childCount : 1;
    if (multiplier < 1) { multiplier = 1; }

    final nameController = TextEditingController(text: expense.name);
    final targetController = TextEditingController(text: (expense.targetAmount ?? 0).toStringAsFixed(0));
    final balanceController = TextEditingController(text: (expense.currentBalance ?? 0).toStringAsFixed(0));
    final ratioController = TextEditingController(text: ((expense.allocationRatio ?? 0) * 100).toStringAsFixed(1));
    final amountController = TextEditingController(text: expense.isLocked ? (expense.monthlyAmount * multiplier).toStringAsFixed(0) : "");
    final monthsController = TextEditingController(); 

    int selectedMode = expense.isLocked ? 1 : 0; 
    bool isSinking = expense.isSinking;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Theme(
          data: ThemeData.light(),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: Text('הגדרת יעד', style: TextStyle(fontSize: 18, color: Colors.black87))),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue), tooltip: 'חזרה לברירת מחדל',
                  onPressed: () { provider.resetExpenseToDefault(expense.id!, isSinking: isSinking); Navigator.pop(ctx); },
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'שם היעד', labelStyle: TextStyle(color: Colors.black54))),
                  const SizedBox(height: 10),
                  TextField(controller: targetController, style: const TextStyle(color: Colors.black87), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום היעד הסופי', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪')),
                  const SizedBox(height: 10),
                  TextField(controller: balanceController, style: const TextStyle(color: Colors.black87), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'נצבר כיום', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪')),
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
                  if (selectedMode == 0) TextField(controller: ratioController, style: const TextStyle(color: Colors.black87), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'אחוז מהחיסכון', labelStyle: TextStyle(color: Colors.black54), suffixText: '%', border: OutlineInputBorder()))
                  else if (selectedMode == 1) TextField(controller: amountController, style: const TextStyle(color: Colors.black87), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: expense.isPerChild ? 'סכום קבוע כולל' : 'סכום קבוע חודשי', labelStyle: const TextStyle(color: Colors.black54), suffixText: '₪', border: const OutlineInputBorder()))
                  else if (selectedMode == 2) TextField(controller: monthsController, style: const TextStyle(color: Colors.black87), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'חודשים נותרים ליעד', labelStyle: TextStyle(color: Colors.black54), suffixText: 'חודשים', border: OutlineInputBorder(), helperText: 'המערכת תחשב ותנעל את הסכום החודשי')),
                  const Divider(height: 30),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero, title: const Text('הוצאה צוברת (קופה)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    subtitle: const Text('הצגה במסגרת הירוקה כחיסכון שוטף', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    value: isSinking, activeThumbColor: Colors.green,
                    onChanged: (val) { setState(() => isSinking = val); },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
              ElevatedButton(
                onPressed: () async {
                  double? newManualAmount;
                  bool newIsLocked = selectedMode != 0;
                  double? newRatio = selectedMode == 0 ? (double.tryParse(ratioController.text) ?? 0) / 100 : expense.allocationRatio;

                  if (selectedMode == 1) {
                    newManualAmount = double.tryParse(amountController.text);
                    if (newManualAmount != null) { newManualAmount = newManualAmount / multiplier; }
                  } else if (selectedMode == 2) {
                    int? months = int.tryParse(monthsController.text);
                    double target = double.tryParse(targetController.text) ?? 0;
                    double balance = double.tryParse(balanceController.text) ?? 0;
                    if (months != null && months > 0) {
                      newManualAmount = (target - balance) / months;
                      if (newManualAmount < 0) { newManualAmount = 0; } 
                      newManualAmount = newManualAmount / multiplier;
                    }
                  }

                  if (newIsLocked && newManualAmount == null && selectedMode != 2) {
                    await provider.resetExpenseToDefault(expense.id!, isSinking: isSinking);
                  } else {
                    await provider.updateFutureExpenseDetails(
                      expense.id!, name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : expense.name,
                      target: double.tryParse(targetController.text), balance: double.tryParse(balanceController.text),
                      ratio: newRatio, isLocked: newIsLocked, manualAmount: newManualAmount, isSinking: isSinking,
                    );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('עדכן יעד'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnifiedFundBottomSheet extends StatefulWidget {
  final BudgetProvider provider;
  final String parentCategory;
  final List<Expense> expenses;

  const _UnifiedFundBottomSheet({required this.provider, required this.parentCategory, required this.expenses});

  @override
  State<_UnifiedFundBottomSheet> createState() => _UnifiedFundBottomSheetState();
}

class _UnifiedFundBottomSheetState extends State<_UnifiedFundBottomSheet> {
  List<Withdrawal> _withdrawals = [];
  bool _isLoading = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() { super.initState(); _loadWithdrawals(); }

  Future<void> _loadWithdrawals() async {
    List<Withdrawal> all = [];
    try {
      for (var e in widget.expenses) {
        if (e.id != null) {
          final w = await widget.provider.getWithdrawalsForExpense(e.id!);
          all.addAll(w);
        }
      }
      all.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
    } catch (e) {
      debugPrint('Error loading unified withdrawals: $e');
    } finally {
      if (mounted) { setState(() { _withdrawals = all; _isLoading = false; }); }
    }
  }

  Widget _buildHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('היסטוריית משיכות והפקדות', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        Divider(color: Colors.grey[300]),
        if (_isLoading) 
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.green)))
        else if (_withdrawals.isEmpty) 
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('לא בוצעו פעולות בקופה זו', style: TextStyle(color: Colors.grey))))
        else ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _withdrawals.length,
          itemBuilder: (ctx, i) {
            final w = _withdrawals[i];
            final date = DateTime.parse(w.date);
            bool isDeposit = w.amount < 0;
            final displayAmount = w.amount.abs();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(isDeposit ? Icons.add_circle_outline : Icons.money_off, color: isDeposit ? Colors.green : Colors.redAccent),
              title: Text('₪${displayAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : Colors.redAccent)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (w.note.isNotEmpty) Text(w.note, style: const TextStyle(color: Colors.black87), softWrap: true),
                    const SizedBox(height: 2),
                    Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey), tooltip: 'מחק פעולה והחזר יתרה', onPressed: () async { await widget.provider.deleteWithdrawal(w); _loadWithdrawals(); }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStandardUnifiedView(BuildContext context, double totalCurrentBalance) {
    return Column(
      children: [
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
                  Text('₪${totalCurrentBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.green), tooltip: 'עדכון יתרה משותפת',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => Theme(
                      data: ThemeData.light(),
                      child: _EditUnifiedBalancesDialog(expenses: widget.expenses, parentCategory: widget.parentCategory)
                    )
                  ).then((_) {
                    if (mounted) _loadWithdrawals();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Align(alignment: Alignment.centerRight, child: Text('משיכה חדשה מהקופה', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
        const SizedBox(height: 4),
        const Align(alignment: Alignment.centerRight, child: Text("הוצאת כסף עבור סעיף זה? רשום 'משיכה'. הסכום ירד מהיתרה הצבורה מבלי לעוות את התזרים השוטף.", style: TextStyle(fontSize: 12, color: Colors.black54))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2, 
              child: TextField(
                controller: _amountController, 
                keyboardType: TextInputType.number, 
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'סכום', 
                  labelStyle: const TextStyle(color: Colors.black54),
                  suffixText: '₪', 
                  suffixStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  isDense: true
                )
              )
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3, 
              child: TextField(
                controller: _noteController, 
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'לאן יצא הכסף?', 
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  isDense: true
                )
              )
            ),
            const SizedBox(width: 8),
            IconButton(
              style: IconButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
              icon: const Icon(Icons.arrow_downward), 
              onPressed: () {
                _handleWithdrawalWithoutPop();
              }
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildHistoryList(),
      ],
    );
  }

  void _handleWithdrawalWithoutPop() async {
    final amt = double.tryParse(_amountController.text);
    if (amt != null && amt > 0 && widget.expenses.isNotEmpty && widget.expenses.first.id != null) {
      String finalNote = _noteController.text.trim();
      final provider = widget.provider;
      final expenseId = widget.expenses.first.id!;
      
      await provider.addWithdrawal(expenseId, amt, finalNote);
      
      if (!mounted) return;
      _amountController.clear(); 
      _noteController.clear(); 
      _loadWithdrawals();
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalCurrentBalance = widget.expenses.fold(0.0, (sum, e) => sum + (e.currentBalance ?? 0));

    return Theme(
      data: ThemeData.light(),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('קופה מאוחדת: ${widget.parentCategory}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildStandardUnifiedView(context, totalCurrentBalance),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditUnifiedBalancesDialog extends StatefulWidget {
  final List<Expense> expenses;
  final String parentCategory;
  const _EditUnifiedBalancesDialog({required this.expenses, required this.parentCategory});

  @override
  State<_EditUnifiedBalancesDialog> createState() => _EditUnifiedBalancesDialogState();
}

class _EditUnifiedBalancesDialogState extends State<_EditUnifiedBalancesDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    double totalCurrent = widget.expenses.fold(0.0, (sum, e) => sum + (e.currentBalance ?? 0));
    _ctrl = TextEditingController(text: totalCurrent.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text('עריכת יתרה - ${widget.parentCategory}', style: const TextStyle(color: Colors.black87)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('הזן את הסכום הכולל שנצבר בקופה זו:', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(labelText: 'סכום צבור כולל', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
        ElevatedButton(
          onPressed: () async {
            final val = double.tryParse(_ctrl.text);
            if (val != null) {
              final provider = Provider.of<BudgetProvider>(context, listen: false);
              for (int i = 0; i < widget.expenses.length; i++) {
                if (i == 0) {
                  await provider.setExpenseCurrentBalance(widget.expenses[i].id!, val);
                } else {
                  await provider.setExpenseCurrentBalance(widget.expenses[i].id!, 0);
                }
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            }
          },
          child: const Text('שמור'),
        ),
      ],
    );
  }
}

class _EditIndividualBalanceDialog extends StatefulWidget {
  final Expense expense;
  const _EditIndividualBalanceDialog({required this.expense});

  @override
  State<_EditIndividualBalanceDialog> createState() => _EditIndividualBalanceDialogState();
}

class _EditIndividualBalanceDialogState extends State<_EditIndividualBalanceDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: (widget.expense.currentBalance ?? 0).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('עריכת יתרה צבורה', style: TextStyle(color: Colors.black87)),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.black87),
        decoration: const InputDecoration(labelText: 'סכום צבור חדש', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
        ElevatedButton(
          onPressed: () async {
            final val = double.tryParse(_ctrl.text);
            if (val != null) {
              await Provider.of<BudgetProvider>(context, listen: false).setExpenseCurrentBalance(widget.expense.id!, val);
              if (!context.mounted) return;
              Navigator.pop(context);
            }
          },
          child: const Text('שמור'),
        ),
      ],
    );
  }
}

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
  void initState() { super.initState(); _loadWithdrawals(); }

  Future<void> _loadWithdrawals() async {
    try {
      final data = await widget.provider.getWithdrawalsForExpense(widget.expense.id!);
      if (mounted) { setState(() { _withdrawals = data; _isLoading = false; }); }
    } catch (e) {
      debugPrint('Error loading withdrawals: $e');
      if (mounted) { setState(() { _withdrawals = []; _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentExpense = widget.provider.expenses.firstWhere(
      (e) => e.id == widget.expense.id, 
      orElse: () => widget.expense
    );
    
    return Theme(
      data: ThemeData.light(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ניהול קופה: ${currentExpense.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('יתרה צבורה כיום', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        Text('₪${(currentExpense.currentBalance ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue), tooltip: 'עדכון יתרה',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Theme(
                            data: ThemeData.light(),
                            child: _EditIndividualBalanceDialog(expense: currentExpense)
                          )
                        ).then((_) {
                          if (mounted) _loadWithdrawals();
                        });
                      }
                    )
                  ]
                )
              ),
              const SizedBox(height: 20),
              
              const Align(alignment: Alignment.centerRight, child: Text('משיכה חדשה מהקופה', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
              const SizedBox(height: 4),
              const Align(alignment: Alignment.centerRight, child: Text("הוצאת כסף עבור סעיף זה? רשום 'משיכה'. הסכום ירד מהיתרה הצבורה מבלי לעוות את התזרים השוטף.", style: TextStyle(fontSize: 12, color: Colors.black54))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2, 
                    child: TextField(
                      controller: _amountController, 
                      keyboardType: TextInputType.number, 
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'סכום', 
                        labelStyle: const TextStyle(color: Colors.black54),
                        suffixText: '₪', 
                        suffixStyle: const TextStyle(color: Colors.black54),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                        isDense: true
                      )
                    )
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3, 
                    child: TextField(
                      controller: _noteController, 
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'לאן יצא הכסף?', 
                        labelStyle: const TextStyle(color: Colors.black54),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                        isDense: true
                      )
                    )
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: () async {
                      final amt = double.tryParse(_amountController.text);
                      if (amt != null && amt > 0) {
                        await widget.provider.addWithdrawal(currentExpense.id!, amt, _noteController.text);
                        if (!mounted) return;
                        _amountController.clear(); _noteController.clear(); _loadWithdrawals();
                      }
                    },
                  )
                ]
              ),
              
              const SizedBox(height: 24),
              const Align(alignment: Alignment.centerRight, child: Text('היסטוריית משיכות והפקדות', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
              Divider(color: Colors.grey[300]),
              
              if (_isLoading) 
                const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.blue))
              else if (_withdrawals.isEmpty) 
                const Padding(padding: EdgeInsets.all(20), child: Text('לא בוצעו פעולות בקופה זו', style: TextStyle(color: Colors.grey)))
              else ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _withdrawals.length,
                itemBuilder: (ctx, i) {
                  final w = _withdrawals[i];
                  final date = DateTime.parse(w.date);
                  bool isDeposit = w.amount < 0;
                  final displayAmount = w.amount.abs();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(isDeposit ? Icons.add_circle_outline : Icons.money_off, color: isDeposit ? Colors.green : Colors.redAccent),
                    title: Text('₪${displayAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : Colors.redAccent)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (w.note.isNotEmpty) Text(w.note, style: const TextStyle(color: Colors.black87), softWrap: true),
                          const SizedBox(height: 2),
                          Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey), tooltip: 'מחק פעולה והחזר יתרה', onPressed: () async { await widget.provider.deleteWithdrawal(w); _loadWithdrawals(); }),
                  );
                }
              ),
              const SizedBox(height: 20),
            ]
          )
        )
      ),
    );
  }
}