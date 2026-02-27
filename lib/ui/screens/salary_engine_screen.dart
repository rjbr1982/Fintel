// 🔒 STATUS: EDITED (Removed Unused Import)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../data/expense_model.dart';
import '../../data/database_helper.dart';
import '../widgets/global_header.dart';

class SalaryEngineScreen extends StatefulWidget {
  const SalaryEngineScreen({super.key});

  @override
  State<SalaryEngineScreen> createState() => _SalaryEngineScreenState();
}

class _SalaryEngineScreenState extends State<SalaryEngineScreen> {
  int? _selectedExpenseId;

  String _formatMonthYear(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  void _showAddRecordDialog(BuildContext context, BudgetProvider provider, int expenseId) {
    final netController = TextEditingController();
    final hoursController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('הזנת נתוני משכורת'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('חודש ושנה:', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = DateTime(date.year, date.month, 1);
                      });
                    }
                  }
                ),
                const Divider(),
                TextField(
                  controller: netController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'שכר נטו (בפועל)', suffixText: '₪', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'שעות עבודה (בפועל)', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
              ElevatedButton(
                onPressed: () async {
                  final net = double.tryParse(netController.text);
                  final hours = double.tryParse(hoursController.text);
                  
                  if (net != null && hours != null && hours > 0) {
                    final record = SalaryRecord(
                      expenseId: expenseId,
                      monthYear: selectedDate.toIso8601String(),
                      netAmount: net,
                      hours: hours,
                    );
                    await DatabaseHelper.instance.insertSalaryRecord(record);
                    if (ctx.mounted) Navigator.pop(ctx);
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

  Widget _buildNativeBarChart(List<SalaryRecord> records, bool isHourly) {
    if (records.isEmpty) return const SizedBox.shrink();
    
    // מיון כרונולוגי
    records.sort((a, b) => DateTime.parse(a.monthYear).compareTo(DateTime.parse(b.monthYear)));
    
    // לקיחת 6 חודשים אחרונים למניעת עומס ויזואלי
    final displayRecords = records.length > 6 ? records.sublist(records.length - 6) : records;

    double maxValue = 0;
    for (var r in displayRecords) {
      double val = isHourly ? (r.netAmount / r.hours) : r.netAmount;
      if (val > maxValue) maxValue = val;
    }

    if (maxValue == 0) maxValue = 1;

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: displayRecords.map((r) {
          double val = isHourly ? (r.netAmount / r.hours) : r.netAmount;
          double heightRatio = val / maxValue;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                isHourly ? '₪${val.toStringAsFixed(1)}' : '${(val / 1000).toStringAsFixed(1)}k',
                style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: 100 * heightRatio,
                decoration: BoxDecoration(
                  color: isHourly ? Colors.purple[300] : Colors.blue[400],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 4),
              Text(_formatMonthYear(r.monthYear), style: const TextStyle(fontSize: 10)),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final incomeExpenses = provider.expenses.where((e) => e.category == 'הכנסות').toList();

    if (incomeExpenses.isEmpty) {
      return const Scaffold(
        appBar: GlobalHeader(title: 'ממוצע שכר'),
        body: Center(child: Text('אין מקורות הכנסה מוגדרים.')),
      );
    }

    if (_selectedExpenseId == null || !incomeExpenses.any((e) => e.id == _selectedExpenseId)) {
      _selectedExpenseId = incomeExpenses.first.id;
    }

    final selectedExpense = incomeExpenses.firstWhere((e) => e.id == _selectedExpenseId);
    final myRecords = provider.salaryRecords.where((r) => r.expenseId == _selectedExpenseId).toList();
    myRecords.sort((a, b) => DateTime.parse(b.monthYear).compareTo(DateTime.parse(a.monthYear)));

    double avgSalaryByWork = provider.getAverageSalary(selectedExpense.id!);
    double avgHourlyRate = provider.getAverageHourlyRate(selectedExpense.id!);
    
    // חישוב YTD השנה
    final currentYear = DateTime.now().year;
    double ytdAmount = 0;
    for (var r in myRecords) {
      if (DateTime.parse(r.monthYear).year == currentYear) {
        ytdAmount += r.netAmount;
      }
    }

    double annualizedAmount = avgSalaryByWork * 12;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const GlobalHeader(title: 'מנוע ממוצע שכר'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // בורר מקור הכנסה
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedExpenseId,
                    isExpanded: true,
                    icon: const Icon(Icons.work_outline, color: Colors.blue),
                    items: incomeExpenses.map((e) {
                      return DropdownMenuItem<int>(
                        value: e.id,
                        child: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedExpenseId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // קוביות סטטיסטיקה
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'שכר ממוצע (חודש פעיל)',
                      '₪${avgSalaryByWork.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'תעריף שעתי ממוצע',
                      '₪${avgHourlyRate.toStringAsFixed(1)} / שעה',
                      Icons.access_time_filled,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'הכנסה שנתית (YTD)',
                      '₪${ytdAmount.toStringAsFixed(0)}',
                      Icons.flag,
                      Colors.green,
                      subtitle: 'בפועל מתחילת השנה',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'פריסה שנתית (Annual)',
                      '₪${annualizedAmount.toStringAsFixed(0)}',
                      Icons.trending_up,
                      Colors.orange,
                      subtitle: 'קצב מוערך לשנה מלאה',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              
              // גרפים
              if (myRecords.isNotEmpty) ...[
                const Text('מגמת שכר נטו (6 חודשים אחרונים)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                  child: _buildNativeBarChart(myRecords, false),
                ),
                const SizedBox(height: 24),
                const Text('מגמת תעריף שעתי (6 חודשים אחרונים)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                  child: _buildNativeBarChart(myRecords, true),
                ),
                const SizedBox(height: 30),
              ],

              // היסטוריית חודשים
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('היסטוריית דיווחי שכר', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('הזן חודש'),
                    onPressed: () => _showAddRecordDialog(context, provider, selectedExpense.id!),
                  )
                ],
              ),
              const SizedBox(height: 12),

              if (myRecords.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('טרם הוזנו נתונים היסטוריים', style: TextStyle(color: Colors.grey))))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myRecords.length,
                  itemBuilder: (ctx, i) {
                    final r = myRecords[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[300]!)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: const Icon(Icons.receipt_long, color: Colors.blue),
                        ),
                        title: Text('חודש: ${_formatMonthYear(r.monthYear)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${r.hours.toStringAsFixed(1)} שעות עבודה'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₪${r.netAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => DatabaseHelper.instance.deleteSalaryRecord(r.id!),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]
        ],
      ),
    );
  }
}