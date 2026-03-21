// 🔒 STATUS: EDITED (Fixed Light Theme Contrast and Disappearing Text)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../data/expense_model.dart';
import '../../data/database_helper.dart'; 
import '../widgets/global_header.dart';
import 'smart_withdrawals_screen.dart'; 

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
            return const Center(child: Text('אין כרגע הוצאות צוברות (חסכונות).', style: TextStyle(color: Colors.black87)));
          }

          double totalMonthlyDeposit = 0;
          double totalAccumulatedBalance = 0;

          // לוגיקת הפיצול הדינמית
          Map<String, List<Expense>> dynamicFunds = {};
          List<Expense> individualFunds = [];

          for (var e in sinkingExpenses) {
            int multiplier = e.isPerChild ? provider.childCount : 1;
            totalMonthlyDeposit += (e.monthlyAmount * multiplier);
            totalAccumulatedBalance += (e.currentBalance ?? 0);

            String groupName = '';
            
            if (e.parentCategory == 'רכב') {
              groupName = 'רכב';
            } 
            else if (e.parentCategory == 'ילדים - משתנות') {
              String kName = e.name.replaceAll('בגדים', '').replaceAll('בילויים', '').trim();
              groupName = 'ילדים: $kName';
            } 
            else if (['ילדים - קבועות', 'אבא', 'אמא', 'אישי', 'חגים'].contains(e.parentCategory)) {
              groupName = e.parentCategory;
            }

            if (groupName.isNotEmpty) {
              if (!dynamicFunds.containsKey(groupName)) {
                dynamicFunds[groupName] = [];
              }
              dynamicFunds[groupName]!.add(e);
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

              // באנר כניסה למנהל המשיכות
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartWithdrawalsScreen()));
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.event_note, color: Colors.blue.shade800, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('מנהל משיכות חודשי', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900)),
                            const SizedBox(height: 4),
                            Text('תכנן ואחד משיכות מהקופות לתחנת יציאה אחת', style: TextStyle(fontSize: 13, color: Colors.blue.shade700)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade800),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (dynamicFunds.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, right: 8),
                        child: Text('קופות מאוחדות', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      ),
                      ...dynamicFunds.entries.map((entry) {
                        double fundExpected = 0;
                        double fundActual = 0;
                        double fundBalance = 0;
                        
                        for (var e in entry.value) {
                          int multiplier = e.isPerChild ? provider.childCount : 1;
                          double expected = (e.monthlyAmount * multiplier);
                          fundExpected += expected;
                          fundActual += (e.actualBankDeposit ?? expected);
                          fundBalance += (e.currentBalance ?? 0);
                        }
                        
                        double diff = fundActual - fundExpected;
                        bool hasMismatch = diff.abs() > 0.01;
                        String diffText = diff > 0 ? '+₪${diff.abs().toStringAsFixed(0)}' : '-₪${diff.abs().toStringAsFixed(0)}';

                        return Card(
                          color: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15), 
                            side: BorderSide(color: hasMismatch ? Colors.orange.shade300 : Colors.grey.shade200, width: hasMismatch ? 1.5 : 1.0)
                          ),
                          elevation: 0,
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.green[50], child: Icon(Icons.account_balance_wallet, color: Colors.green[700])),
                            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('להפרשה: ₪${fundExpected.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black54)),
                                if (hasMismatch)
                                  Text('⚠️ נדרש עדכון בבנק (פער: $diffText)', style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: Text('נצבר: ₪${fundBalance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                            onTap: () {
                              showModalBottomSheet(
                                context: context, 
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
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
                        double expectedDeposit = expense.monthlyAmount * multiplier;
                        double actualDeposit = expense.actualBankDeposit ?? expectedDeposit;
                        double balance = expense.currentBalance ?? 0;
                        
                        double diff = actualDeposit - expectedDeposit;
                        bool hasMismatch = diff.abs() > 0.01;
                        String diffText = diff > 0 ? '+₪${diff.abs().toStringAsFixed(0)}' : '-₪${diff.abs().toStringAsFixed(0)}';

                        bool isFuture = expense.category == 'עתידיות';
                        String displayTitle = isFuture ? expense.parentCategory : expense.name;
                        String specificNameInfo = isFuture ? '${expense.name} | ' : '';

                        return Card(
                          color: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15), 
                            side: BorderSide(color: hasMismatch ? Colors.orange.shade300 : Colors.grey.shade200, width: hasMismatch ? 1.5 : 1.0)
                          ),
                          elevation: 0,
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.blue[50], child: Icon(Icons.savings_outlined, color: Colors.blue[700])),
                            title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$specificNameInfoלהפרשה: ₪${expectedDeposit.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black54)),
                                if (hasMismatch)
                                  Text('⚠️ נדרש עדכון בבנק (פער: $diffText)', style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: Text('נצבר: ₪${balance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15)),
                            onTap: () {
                              showModalBottomSheet(
                                context: context, 
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
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

  void _showEditUnifiedDialog(List<Expense> currentExpenses) {
    showDialog(
      context: context,
      builder: (ctx) => _EditUnifiedBalancesDialog(expenses: currentExpenses, parentCategory: widget.parentCategory),
    );
  }

  void _showEditBankDepositDialog(List<Expense> currentExpenses, double currentActual) {
    showDialog(
      context: context,
      builder: (ctx) => _EditUnifiedBankDepositDialog(expenses: currentExpenses, parentCategory: widget.parentCategory, currentActual: currentActual),
    );
  }

  Widget _buildHistoryList() {
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('היסטוריה פעולות', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
              subtitle: Text('${w.note}\n${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey), onPressed: () async { await provider.deleteWithdrawal(w); _loadWithdrawals(); }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStandardUnifiedView(double totalCurrentBalance, double fundExpected, double fundActual, List<Expense> currentExpenses) {
    bool hasMismatch = (fundActual - fundExpected).abs() > 0.01;
    
    return Column(
      children: [
        // בלוק יתרה צבורה
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
        
        // בלוק בקרה בנקאית
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: hasMismatch ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('הפרשה בפועל בבנק', style: TextStyle(color: hasMismatch ? Colors.orange[800] : Colors.blueGrey, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text('₪${fundActual.toStringAsFixed(0)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: hasMismatch ? Colors.orange[800] : Colors.blueGrey)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showEditBankDepositDialog(currentExpenses, fundActual),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.edit, color: hasMismatch ? Colors.orange[800] : Colors.blueGrey, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (hasMismatch)
                Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 28),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(flex: 2, child: TextField(style: const TextStyle(color: Colors.black87), controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום משיכה', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪', border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: TextField(style: const TextStyle(color: Colors.black87), controller: _noteController, decoration: const InputDecoration(labelText: 'פירוט (לאן יצא?)', labelStyle: TextStyle(color: Colors.black54), border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 8),
            IconButton(style: IconButton.styleFrom(backgroundColor: Colors.blueGrey[900], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), icon: const Icon(Icons.arrow_downward), onPressed: () => _handleWithdrawal(null)),
          ],
        ),
        const SizedBox(height: 24),
        _buildHistoryList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BudgetProvider>(context);
    final currentExpenses = provider.expenses.where((e) => widget.originalExpenses.any((we) => we.id == e.id)).toList();
    
    double totalCurrentBalance = currentExpenses.fold(0.0, (sum, e) => sum + (e.currentBalance ?? 0));
    double fundExpected = 0;
    double fundActual = 0;
    
    for (var e in currentExpenses) {
      int multiplier = e.isPerChild ? provider.childCount : 1;
      double expected = (e.monthlyAmount * multiplier);
      fundExpected += expected;
      fundActual += (e.actualBankDeposit ?? expected);
    }
    
    // עטיפת הבוטום שיט ב-Theme בהיר
    return Theme(
      data: ThemeData.light(),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              Text('קופה מאוחדת: ${widget.parentCategory}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildStandardUnifiedView(totalCurrentBalance, fundExpected, fundActual, currentExpenses),
            ],
          ),
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

  void _showEditBankDepositDialog(Expense currentExpense, double currentActual) {
    showDialog(
      context: context,
      builder: (ctx) => _EditIndividualBankDepositDialog(expense: currentExpense, currentActual: currentActual),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BudgetProvider>(context);
    final currentExpense = provider.expenses.firstWhere((e) => e.id == widget.expense.id, orElse: () => widget.expense);
    
    int multiplier = currentExpense.isPerChild ? provider.childCount : 1;
    double expectedDeposit = currentExpense.monthlyAmount * multiplier;
    double actualDeposit = currentExpense.actualBankDeposit ?? expectedDeposit;
    bool hasMismatch = (actualDeposit - expectedDeposit).abs() > 0.01;

    // עטיפת הבוטום שיט ב-Theme בהיר
    return Theme(
      data: ThemeData.light(),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              Text('קופה: ${currentExpense.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              
              // בלוק יתרה צבורה
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
              
              // בלוק בקרה בנקאית
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: hasMismatch ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('הפרשה בפועל בבנק', style: TextStyle(color: hasMismatch ? Colors.orange[800] : Colors.blueGrey, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text('₪${actualDeposit.toStringAsFixed(0)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: hasMismatch ? Colors.orange[800] : Colors.blueGrey)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showEditBankDepositDialog(currentExpense, actualDeposit),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(Icons.edit, color: hasMismatch ? Colors.orange[800] : Colors.blueGrey, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (hasMismatch)
                      Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 28),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(flex: 2, child: TextField(style: const TextStyle(color: Colors.black87), controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום משיכה', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪', border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: TextField(style: const TextStyle(color: Colors.black87), controller: _noteController, decoration: const InputDecoration(labelText: 'פירוט (לאן יצא?)', labelStyle: TextStyle(color: Colors.black54), border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 8),
                  IconButton(style: IconButton.styleFrom(backgroundColor: Colors.blueGrey[900], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), icon: const Icon(Icons.arrow_downward), onPressed: _handleWithdrawal),
                ],
              ),
              const SizedBox(height: 24),
              const Align(alignment: Alignment.centerRight, child: Text('היסטוריה פעולות', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
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
                    subtitle: Text('${w.note}\n${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey), onPressed: () async { await provider.deleteWithdrawal(w); _loadWithdrawals(); }),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// דיאלוגים לעריכת יתרות והפקדות לבנק
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
    return Theme(
      data: ThemeData.light(),
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('עריכת יתרה צבורה', style: TextStyle(color: Colors.black87)),
        content: TextField(
          style: const TextStyle(color: Colors.black87),
          controller: _ctrl,
          keyboardType: TextInputType.number,
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
    return Theme(
      data: ThemeData.light(),
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Text('עריכת יתרה - ${widget.parentCategory}', style: const TextStyle(color: Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('הזן את הסכום הכולל שנצבר בקופה זו:', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.black87),
              controller: _ctrl,
              keyboardType: TextInputType.number,
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
      ),
    );
  }
}

class _EditIndividualBankDepositDialog extends StatefulWidget {
  final Expense expense;
  final double currentActual;
  const _EditIndividualBankDepositDialog({required this.expense, required this.currentActual});

  @override
  State<_EditIndividualBankDepositDialog> createState() => _EditIndividualBankDepositDialogState();
}

class _EditIndividualBankDepositDialogState extends State<_EditIndividualBankDepositDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentActual.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('בקרת הפרשה לבנק', style: TextStyle(color: Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('הזן את סכום הוראת הקבע שמוגדר בפועל בבנק:', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.black87),
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'מוגדר כרגע בבנק', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
            onPressed: () async {
              final val = double.tryParse(_ctrl.text);
              if (val != null) {
                final updatedExpense = widget.expense.copyWith(actualBankDeposit: val);
                await DatabaseHelper.instance.updateExpense(updatedExpense);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }
}

class _EditUnifiedBankDepositDialog extends StatefulWidget {
  final List<Expense> expenses;
  final String parentCategory;
  final double currentActual;
  const _EditUnifiedBankDepositDialog({required this.expenses, required this.parentCategory, required this.currentActual});

  @override
  State<_EditUnifiedBankDepositDialog> createState() => _EditUnifiedBankDepositDialogState();
}

class _EditUnifiedBankDepositDialogState extends State<_EditUnifiedBankDepositDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentActual.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Text('בקרה לבנק - ${widget.parentCategory}', style: const TextStyle(color: Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('הזן את סכום הוראת הקבע הכולל שמוגדר בפועל בבנק עבור כלל הקופה:', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.black87),
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'מוגדר כרגע בבנק', labelStyle: TextStyle(color: Colors.black54), suffixText: '₪', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
            onPressed: () async {
              final val = double.tryParse(_ctrl.text);
              if (val != null && widget.expenses.isNotEmpty) {
                for (int i = 0; i < widget.expenses.length; i++) {
                  if (i == 0) {
                    await DatabaseHelper.instance.updateExpense(widget.expenses[i].copyWith(actualBankDeposit: val));
                  } else {
                    await DatabaseHelper.instance.updateExpense(widget.expenses[i].copyWith(actualBankDeposit: 0));
                  }
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }
}