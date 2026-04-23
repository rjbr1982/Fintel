// 🔒 STATUS: EDITED (Fixed if-statement curlies & TextDirection, UI Proportions Tightened)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
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
  int _selectedRange = 6; // 3, 6, 12, 0 (0 means All)

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(content, style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('הבנתי', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

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
                    
                    await DatabaseHelper.instance.updateUserMetric('hasSalary', true);

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

  Widget _buildMountainChart(List<SalaryRecord> records, bool isHourly) {
    if (records.isEmpty) return const SizedBox.shrink();
    
    var sortedRecords = List<SalaryRecord>.from(records);
    sortedRecords.sort((a, b) => DateTime.parse(a.monthYear).compareTo(DateTime.parse(b.monthYear)));
    
    List<double> cumulativeValues = [];
    double runningNet = 0;
    double runningHours = 0;
    
    for (int i = 0; i < sortedRecords.length; i++) {
      runningNet += sortedRecords[i].netAmount;
      runningHours += sortedRecords[i].hours;
      
      double val;
      if (isHourly) {
        val = runningHours > 0 ? runningNet / runningHours : 0;
      } else {
        val = runningNet / (i + 1); 
      }
      cumulativeValues.add(val);
    }

    List<SalaryRecord> displayRecords = sortedRecords;
    List<double> displayValues = cumulativeValues;

    if (_selectedRange > 0 && sortedRecords.length > _selectedRange) {
      displayRecords = sortedRecords.sublist(sortedRecords.length - _selectedRange);
      displayValues = cumulativeValues.sublist(cumulativeValues.length - _selectedRange);
    }

    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _MountainChartPainter(displayRecords, displayValues, isHourly),
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
      appBar: const GlobalHeader(title: 'ממוצע שכר'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecordDialog(context, provider, selectedExpense.id!),
        backgroundColor: Colors.blue[900],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('הזן חודש', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('מקור הכנסה לחישוב:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                  InkWell(
                    onTap: () => _showInfoDialog(context, 'ייצוב התזרים', 'הזן נתוני שכר כדי לייצב את התזרים ולהימנע מגירעון סמוי עקב תנודות שכר.'),
                    child: const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedExpenseId,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.work_outline, color: Colors.blue),
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Heebo'),
                    items: incomeExpenses.map((e) {
                      return DropdownMenuItem<int>(
                        value: e.id,
                        child: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedExpenseId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16), // Reduced
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'שכר ממוצע (פעיל)',
                      '₪${avgSalaryByWork.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8), // Reduced
                  Expanded(
                    child: _buildStatCard(
                      'תעריף שעתי ממוצע',
                      '₪${avgHourlyRate.toStringAsFixed(1)} / ש',
                      Icons.access_time_filled,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // Reduced
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
                  const SizedBox(width: 8), // Reduced
                  Expanded(
                    child: _buildStatCard(
                      'פריסה (Annual)',
                      '₪${annualizedAmount.toStringAsFixed(0)}',
                      Icons.trending_up,
                      Colors.orange,
                      subtitle: 'קצב מוערך לשנה',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Reduced

              if (myRecords.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('מגמות וסטטיסטיקה', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(minHeight: 30, minWidth: 50),
                      fillColor: Colors.blue.withValues(alpha: 0.1),
                      selectedColor: Colors.blue[900],
                      color: Colors.blueGrey,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      isSelected: [_selectedRange == 3, _selectedRange == 6, _selectedRange == 12, _selectedRange == 0],
                      onPressed: (idx) {
                        setState(() {
                          if (idx == 0) {
                            _selectedRange = 3;
                          } else if (idx == 1) {
                            _selectedRange = 6;
                          } else if (idx == 2) {
                            _selectedRange = 12;
                          } else if (idx == 3) {
                            _selectedRange = 0;
                          }
                        });
                      },
                      children: const [Text('3ח\''), Text('6ח\''), Text('שנה'), Text('הכל')],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                const Text('גרף ממוצע שכר נטו', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                _buildMountainChart(myRecords, false),
                
                const SizedBox(height: 24),
                const Text('גרף ממוצע תעריף שעתי', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                _buildMountainChart(myRecords, true),
                const SizedBox(height: 30),
              ],

              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[300]!)),
                child: ExpansionTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: const Icon(Icons.history, color: Colors.blueGrey),
                  title: const Text('היסטוריית דיווחי שכר', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  children: [
                    const Divider(height: 1),
                    if (myRecords.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30), 
                        child: Text(
                          "טרם הוזנו נתונים. הוסף חודשים כדי לבנות היסטוריה.", 
                          textAlign: TextAlign.center, 
                          style: TextStyle(color: Colors.grey)
                        )
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myRecords.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final r = myRecords[i];
                          return ListTile(
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
                          );
                        }
                      ),
                  ],
                ),
              ),
                
              const SizedBox(height: 60), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]
        ],
      ),
    );
  }
}

// ============================================================================
// ציור הגרף בתצורה אחידה (Dark Mode & LTR)
// ============================================================================
class _MountainChartPainter extends CustomPainter {
  final List<SalaryRecord> records;
  final List<double> values;
  final bool isHourly;

  _MountainChartPainter(this.records, this.values, this.isHourly);

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final primaryColor = isHourly ? Colors.purpleAccent : const Color(0xFF00A3FF);

    final paintLine = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    double maxVal = values.reduce((a, b) => a > b ? a : b);
    double minVal = values.reduce((a, b) => a < b ? a : b);
    if (maxVal == minVal) {
      maxVal += 1000;
      minVal -= 1000;
    }

    double range = maxVal - minVal;
    if (range <= 0) range = 1;

    final path = Path();
    
    const double paddingY = 24.0;
    final double usableHeight = size.height - (paddingY * 2);
    final double widthStep = records.length > 1 ? size.width / (records.length - 1) : size.width;

    List<Offset> points = [];
    for (int i = 0; i < records.length; i++) {
      double v = values[i]; 
      double x = records.length > 1 ? i * widthStep : size.width / 2; // משמאל לימין (LTR)
      double normalizedY = (v - minVal) / range;
      double y = usableHeight - (normalizedY * usableHeight) + paddingY;
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = points[i - 1].dx;
        final prevY = points[i - 1].dy;
        path.quadraticBezierTo(
          prevX + (x - prevX) / 2, prevY, 
          x, y
        );
      }
    }

    if (records.length > 1) {
      canvas.drawPath(path, paintLine);
    }

    // ציור נקודות ותוויות נתונים
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, paintLine..style = PaintingStyle.fill);
      canvas.drawCircle(points[i], 3, paintDot);

      // תווית סכום
      double v = values[i];
      String valLabel = '₪${v.toStringAsFixed(isHourly ? 1 : 0)}';
      
      textPainter.text = TextSpan(text: valLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold));
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, points[i].dy - 20));
      
      // תווית תאריך
      DateTime d = DateTime.parse(records[i].monthYear);
      String dateLabel = '${d.month.toString().padLeft(2,'0')}/${d.year.toString().substring(2)}';
      textPainter.text = TextSpan(text: dateLabel, style: const TextStyle(color: Colors.white54, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, points[i].dy + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}