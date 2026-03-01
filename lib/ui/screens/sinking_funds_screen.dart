// 🔒 STATUS: EDITED (Fixed Linter Warning - unnecessary_brace_in_string_interps)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../data/expense_model.dart';
import '../widgets/global_header.dart';

class SinkingFundsScreen extends StatelessWidget {
  const SinkingFundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const GlobalHeader(title: 'מרכז חסכונות', showSavingsIcon: false),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          final sinkingExpenses = provider.expenses.where((e) => e.isSinking).toList();

          if (sinkingExpenses.isEmpty) {
            return const Center(child: Text('אין כרגע הוצאות צוברות (חסכונות).'));
          }

          double totalMonthlyDeposit = 0;
          double totalAccumulatedBalance = 0;

          // פיצול לקופות מאוחדות מול קופות בודדות
          final unifiedNames = ['רכב', 'ילדים - קבועות', 'אבא', 'אמא', 'ילדים - משתנות', 'חגים'];
          Map<String, List<Expense>> unifiedFunds = {};
          List<Expense> individualFunds = [];

          for (var e in sinkingExpenses) {
            int multiplier = e.isPerChild ? provider.childCount : 1;
            totalMonthlyDeposit += (e.monthlyAmount * multiplier);
            totalAccumulatedBalance += (e.currentBalance ?? 0);

            if (unifiedNames.contains(e.parentCategory)) {
              if (!unifiedFunds.containsKey(e.parentCategory)) {
                unifiedFunds[e.parentCategory] = [];
              }
              unifiedFunds[e.parentCategory]!.add(e);
            } else {
              individualFunds.add(e);
            }
          }

          return Column(
            children: [
              // דאשבורד עליון מרכזי
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green[700]!, Colors.green[500]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.savings, color: Colors.white, size: 28),
                        SizedBox(width: 8),
                        Text('סטטוס חסכונות כולל', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('להפרשה חודשית', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('₪${totalMonthlyDeposit.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(height: 40, width: 1, color: Colors.white30),
                        Column(
                          children: [
                            const Text('הון צבור עד כה', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('₪${totalAccumulatedBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (unifiedFunds.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, right: 8),
                        child: Text('קופות מאוחדות', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      ),
                      ...unifiedFunds.entries.map((entry) {
                        double fundDeposit = 0;
                        double fundBalance = 0;
                        for (var e in entry.value) {
                          int multiplier = e.isPerChild ? provider.childCount : 1;
                          fundDeposit += (e.monthlyAmount * multiplier);
                          fundBalance += (e.currentBalance ?? 0);
                        }
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.green[100], child: Icon(Icons.account_balance_wallet, color: Colors.green[800])),
                            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('להפרשה: ₪${fundDeposit.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
                            trailing: Text('נצבר: ₪${fundBalance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                            onTap: () {
                              showModalBottomSheet(
                                context: context, isScrollControlled: true,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (ctx) => _UnifiedFundBottomSheetFromCenter(parentCategory: entry.key, originalExpenses: entry.value),
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    if (individualFunds.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, right: 8),
                        child: Text('קופות ייעודיות', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      ),
                      ...individualFunds.map((expense) {
                        int multiplier = expense.isPerChild ? provider.childCount : 1;
                        double deposit = expense.monthlyAmount * multiplier;
                        double balance = expense.currentBalance ?? 0;
                        
                        // תצוגת חסכונות עתידיות לפי הקטגוריה ולא לפי שם היעד
                        bool isFuture = expense.category == 'עתידיות';
                        String displayTitle = isFuture ? expense.parentCategory : expense.name;
                        String specificNameInfo = isFuture ? '${expense.name} | ' : '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.blue[50], child: Icon(Icons.savings_outlined, color: Colors.blue[800])),
                            title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                            // Linter fix: removed unnecessary braces around specificNameInfo
                            subtitle: Text('$specificNameInfoלהפרשה: ₪${deposit.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
                            trailing: Text('נצבר: ₪${balance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15)),
                            onTap: () {
                              showModalBottomSheet(
                                context: context, isScrollControlled: true,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (ctx) => _SinkingFundBottomSheetFromCenter(expense: expense),
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
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
}

// =========================================================================
// פאנלי המשיכה והעריכה
// =========================================================================

class _UnifiedFundBottomSheetFromCenter extends StatefulWidget {
  final String parentCategory;
  final List<Expense> originalExpenses;

  const _UnifiedFundBottomSheetFromCenter({required this.parentCategory, required this.originalExpenses});

  @override
  State<_UnifiedFundBottomSheetFromCenter> createState() => _UnifiedFundBottomSheetFromCenterState();
}

class _UnifiedFundBottomSheetFromCenterState extends State<_UnifiedFundBottomSheetFromCenter> {
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
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    List<Withdrawal> all = [];
    for (var e in widget.originalExpenses) {
      if (e.id != null) {
        final w = await provider.getWithdrawalsForExpense(e.id!);
        all.addAll(w);
      }
    }
    all.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
    if (mounted) setState(() { _withdrawals = all; _isLoading = false; });
  }

  void _handleWithdrawal([String? childName]) async {
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    final amt = double.tryParse(_amountController.text);
    if (amt != null && amt > 0 && widget.originalExpenses.isNotEmpty && widget.originalExpenses.first.id != null) {
      String finalNote = _noteController.text.trim();
      if (childName != null) {
        finalNote = '[$childName] $finalNote'; 
      }
      await provider.addWithdrawal(widget.originalExpenses.first.id!, amt, finalNote);
      _amountController.clear();
      _noteController.clear();
      _loadWithdrawals();
    }
  }

  void _openWithdrawalDialog([String? childName]) {
    _amountController.clear();
    _noteController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(childName != null ? 'משיכה עבור $childName' : 'משיכה משותפת'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true, decoration: const InputDecoration(labelText: 'סכום המשיכה', suffixText: '₪', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'פירוט/הערה (לאן יצא?)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900]),
            onPressed: () {
              _handleWithdrawal(childName);
              Navigator.pop(ctx);
            },
            child: const Text('אישור משיכה', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editChildBalance(FamilyMember child, double currentChildBalance) {
    final ctrl = TextEditingController(text: currentChildBalance.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("עדכון יתרה: ${child.name}", style: const TextStyle(fontSize: 18)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '₪', helperText: 'הזן את היתרה החדשה לילד זה')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ביטול")),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null) {
                double diff = val - currentChildBalance;
                if (diff != 0 && widget.originalExpenses.isNotEmpty && widget.originalExpenses.first.id != null) {
                  final provider = Provider.of<BudgetProvider>(context, listen: false);
                  await provider.addWithdrawal(
                    widget.originalExpenses.first.id!,
                    -diff,
                    '[${child.name}] עדכון יתרה ידני'
                  );
                  _amountController.clear();
                  _noteController.clear();
                  _loadWithdrawals();
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text("שמור")
          ),
        ],
      )
    );
  }

  void _showEditUnifiedDialog(List<Expense> currentExpenses) {
    showDialog(
      context: context,
      builder: (ctx) => _EditUnifiedBalancesDialog(expenses: currentExpenses, parentCategory: widget.parentCategory),
    );
  }

  Widget _buildHistoryList() {
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('היסטוריה פעולות', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const Divider(),
        if (_isLoading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_withdrawals.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('לא בוצעו פעולות בקופה זו', style: TextStyle(color: Colors.grey))))
        else ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _withdrawals.length,
          itemBuilder: (ctx, i) {
            final w = _withdrawals[i];
            final date = DateTime.parse(w.date);
            bool isDeposit = w.amount < 0;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(isDeposit ? Icons.add_circle_outline : Icons.money_off, color: isDeposit ? Colors.green : Colors.redAccent),
              title: Text('₪${w.amount.abs().toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : Colors.redAccent)),
              subtitle: Text('${w.note}\n${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 12)),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () async { await provider.deleteWithdrawal(w); _loadWithdrawals(); }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStandardUnifiedView(double totalCurrentBalance, List<Expense> currentExpenses) {
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
                  Row(
                    children: [
                      Text('₪${totalCurrentBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showEditUnifiedDialog(currentExpenses),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.edit, color: Colors.green, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(flex: 2, child: TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום משיכה', suffixText: '₪', border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'פירוט (לאן יצא?)', border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 8),
            IconButton(style: IconButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), icon: const Icon(Icons.arrow_downward), onPressed: () => _handleWithdrawal(null)),
          ],
        ),
        const SizedBox(height: 24),
        _buildHistoryList(),
      ],
    );
  }

  Widget _buildKidsView(double totalCurrentBalance, List<FamilyMember> kids) {
    double totalWithdrawals = 0;
    double totalSpecificDeposits = 0;

    for (var w in _withdrawals) {
      if (w.amount < 0) {
        totalSpecificDeposits += w.amount.abs();
      } else {
        totalWithdrawals += w.amount;
      }
    }

    double sharedPoolCurrentBalance = totalCurrentBalance - totalSpecificDeposits;
    double sharedPoolHistorical = sharedPoolCurrentBalance + totalWithdrawals;
    double sharePerChild = kids.isNotEmpty ? sharedPoolHistorical / kids.length : 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('סה״כ צבור בקופה המשותפת', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('₪${totalCurrentBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green, size: 20),
                  tooltip: 'עדכון יתרה משותפת',
                  onPressed: () {
                    final ctrl = TextEditingController(text: totalCurrentBalance.toStringAsFixed(0));
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text("עדכון יתרה מאוחדת", style: TextStyle(fontSize: 18)),
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
                                double diff = val - totalCurrentBalance;
                                if (diff != 0 && widget.originalExpenses.isNotEmpty && widget.originalExpenses.first.id != null) {
                                  final provider = Provider.of<BudgetProvider>(context, listen: false);
                                  provider.setExpenseCurrentBalance(
                                    widget.originalExpenses.first.id!, 
                                    (widget.originalExpenses.first.currentBalance ?? 0) + diff
                                  ).then((_) => _loadWithdrawals());
                                }
                                Navigator.pop(ctx);
                              }
                            }, 
                            child: const Text("שמור")
                          ),
                        ],
                      ),
                    );
                  },
                ),
                OutlinedButton.icon(
                  onPressed: () => _openWithdrawalDialog(null),
                  icon: const Icon(Icons.group, size: 18),
                  label: const Text('משיכה לכולם'),
                ),
              ],
            ),
          ],
        ),
        const Divider(height: 30),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kids.length,
          itemBuilder: (ctx, i) {
            final child = kids[i];
            
            double specificWithdrawals = 0;
            double generalWithdrawals = 0;
            double specificDeposits = 0;
            
            for (var w in _withdrawals) {
              if (w.amount < 0) {
                if (w.note.startsWith('[${child.name}]')) {
                  specificDeposits += w.amount.abs();
                }
              } else {
                if (w.note.startsWith('[${child.name}]')) {
                  specificWithdrawals += w.amount;
                } else if (!w.note.startsWith('[')) {
                  generalWithdrawals += w.amount;
                }
              }
            }
            
            double childBalance = sharePerChild + specificDeposits - specificWithdrawals - (kids.isNotEmpty ? generalWithdrawals / kids.length : 0);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1), 
                  child: Text(child.name.isNotEmpty ? child.name[0] : '?', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                ),
                title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('יתרה: ₪${childBalance.toStringAsFixed(0)}', style: TextStyle(color: childBalance >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                      tooltip: 'עדכון יתרה',
                      onPressed: () => _editChildBalance(child, childBalance),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900], foregroundColor: Colors.white),
                      onPressed: () => _openWithdrawalDialog(child.name),
                      child: const Text('משיכה'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildHistoryList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BudgetProvider>(context);
    final currentExpenses = provider.expenses.where((e) => widget.originalExpenses.any((we) => we.id == e.id)).toList();
    double totalCurrentBalance = currentExpenses.fold(0.0, (sum, e) => sum + (e.currentBalance ?? 0));
    
    bool isKidsVariable = widget.parentCategory == 'ילדים - משתנות';
    final kids = provider.familyMembers.where((fm) => (DateTime.now().year - fm.birthYear) <= 25).toList();
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('קופה מאוחדת: ${widget.parentCategory}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (isKidsVariable && kids.isNotEmpty)
              _buildKidsView(totalCurrentBalance, kids)
            else
              _buildStandardUnifiedView(totalCurrentBalance, currentExpenses),
          ],
        ),
      ),
    );
  }
}

class _SinkingFundBottomSheetFromCenter extends StatefulWidget {
  final Expense expense;
  const _SinkingFundBottomSheetFromCenter({required this.expense});

  @override
  State<_SinkingFundBottomSheetFromCenter> createState() => _SinkingFundBottomSheetFromCenterState();
}

class _SinkingFundBottomSheetFromCenterState extends State<_SinkingFundBottomSheetFromCenter> {
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
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    final data = await provider.getWithdrawalsForExpense(widget.expense.id!);
    if (mounted) setState(() { _withdrawals = data; _isLoading = false; });
  }

  void _handleWithdrawal() async {
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    final amt = double.tryParse(_amountController.text);
    if (amt != null && amt > 0) {
      await provider.addWithdrawal(widget.expense.id!, amt, _noteController.text.trim());
      _amountController.clear();
      _noteController.clear();
      _loadWithdrawals();
    }
  }

  void _showEditIndividualDialog(Expense currentExpense) {
    showDialog(
      context: context,
      builder: (ctx) => _EditIndividualBalanceDialog(expense: currentExpense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BudgetProvider>(context);
    final currentExpense = provider.expenses.firstWhere((e) => e.id == widget.expense.id, orElse: () => widget.expense);
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('קופה: ${currentExpense.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      Row(
                        children: [
                          Text('₪${(currentExpense.currentBalance ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _showEditIndividualDialog(currentExpense),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.edit, color: Colors.blue, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(flex: 2, child: TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום משיכה', suffixText: '₪', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'פירוט (לאן יצא?)', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 8),
                IconButton(style: IconButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), icon: const Icon(Icons.arrow_downward), onPressed: _handleWithdrawal),
              ],
            ),
            const SizedBox(height: 24),
            const Align(alignment: Alignment.centerRight, child: Text('היסטוריה פעולות', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
            const Divider(),
            if (_isLoading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
            else if (_withdrawals.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('לא בוצעו פעולות', style: TextStyle(color: Colors.grey)))
            else ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _withdrawals.length,
              itemBuilder: (ctx, i) {
                final w = _withdrawals[i];
                final date = DateTime.parse(w.date);
                bool isDeposit = w.amount < 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(isDeposit ? Icons.add_circle_outline : Icons.money_off, color: isDeposit ? Colors.green : Colors.redAccent),
                  title: Text('₪${w.amount.abs().toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : Colors.redAccent)),
                  subtitle: Text('${w.note}\n${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () async { await provider.deleteWithdrawal(w); _loadWithdrawals(); }),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// דיאלוגים לעריכת יתרות
// =========================================================================

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
      title: const Text('עריכת יתרה צבורה'),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'סכום צבור חדש', suffixText: '₪'),
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
      title: Text('עריכת יתרה - ${widget.parentCategory}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('הזן את הסכום הכולל שנצבר בקופה זו:', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'סכום צבור כולל', suffixText: '₪', border: OutlineInputBorder()),
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