// 🔒 STATUS: EDITED (Fixed AppBar Title to 'ממוצע שכר')
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

  Widget _buildMountainChart(List<SalaryRecord> records, bool isHourly) {
    if (records.isEmpty) return const SizedBox.shrink();
    
    // סידור מהישן לחדש (כדי לחשב את הממוצעים לאורך ציר הזמן)
    var sortedRecords = List<SalaryRecord>.from(records);
    sortedRecords.sort((a, b) => DateTime.parse(a.monthYear).compareTo(DateTime.parse(b.monthYear)));
    
    // חישוב הממוצע המצטבר (Cumulative Average) לכל נקודת זמן
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
        val = runningNet / (i + 1); // הממוצע חלקי כמות החודשים שהיו עד כה
      }
      cumulativeValues.add(val);
    }

    // סינון לפי הטווח שנבחר (למשל רק 6 אחרונים)
    List<SalaryRecord> displayRecords = sortedRecords;
    List<double> displayValues = cumulativeValues;

    if (_selectedRange > 0 && sortedRecords.length > _selectedRange) {
      displayRecords = sortedRecords.sublist(sortedRecords.length - _selectedRange);
      displayValues = cumulativeValues.sublist(cumulativeValues.length - _selectedRange);
    }

    // הגרף נמתח או מתכווץ לרוחב המסך הקיים, ללא גלילה
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CustomPaint(
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
    
    // רשימה הפוכה (מהחדש לישן) עבור רשימת ההיסטוריה ההגיונית
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
              
              // CONTEXTUAL ONBOARDING - תמיד מוצג בראש המסך
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.insights, color: Colors.blue[800], size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "ייצוב התזרים: הזן משכורות עבר כדי שהמנוע יחשב ממוצע אמיתי וימנע גירעון סמוי עקב תנודות שכר.",
                        style: TextStyle(color: Colors.blueGrey[900], fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              // בורר מקור הכנסה
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
              const SizedBox(height: 20),

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

              if (myRecords.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('מגמות וסטטיסטיקה', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    // סרגל טווחים (Toggles)
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
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                  child: _buildMountainChart(myRecords, false),
                ),
                const SizedBox(height: 24),
                const Text('גרף ממוצע תעריף שעתי', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                  child: _buildMountainChart(myRecords, true),
                ),
                const SizedBox(height: 30),
              ],

              // חלונית ההיסטוריה הנסתרת (אקורדיון)
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

// ============================================================================
// ציור גרף ההרים (Area Chart)
// ============================================================================
class _MountainChartPainter extends CustomPainter {
  final List<SalaryRecord> records;
  final List<double> values;
  final bool isHourly;

  _MountainChartPainter(this.records, this.values, this.isHourly);

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final primaryColor = isHourly ? Colors.purple : Colors.blue;

    final paintLine = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        [
          primaryColor.withValues(alpha: 0.4),
          primaryColor.withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.fill;

    double maxVal = 0;
    double minVal = double.infinity;
    for (var v in values) {
      if (v > maxVal) maxVal = v;
      if (v < minVal) minVal = v;
    }
    if (maxVal == 0) maxVal = 1;
    // נשאיר קצת אוויר מתחת למינימום
    double bottomBase = (minVal * 0.8).clamp(0.0, double.infinity); 
    double range = maxVal - bottomBase;
    if (range <= 0) range = 1;

    final path = Path();
    final fillPath = Path();
    
    // רווח בין הנקודות - מתפרס על כל הרוחב
    double stepX = size.width / (records.length > 1 ? records.length - 1 : 1);
    
    List<Offset> points = [];
    for (int i = 0; i < records.length; i++) {
      double v = values[i]; 
      double x = size.width - (i * stepX); // משמאל לימין
      double y = size.height - 30 - (((v - bottomBase) / range) * (size.height - 60));
      points.add(Offset(x, y));
    }

    if (points.length == 1) {
      path.moveTo(0, points[0].dy);
      path.lineTo(size.width, points[0].dy);
      fillPath.moveTo(0, points[0].dy);
      fillPath.lineTo(size.width, points[0].dy);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
    } else {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);
      
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, size.height);
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, Paint()..color = Colors.white);
      canvas.drawCircle(points[i], 4, paintLine..style = PaintingStyle.stroke);

      double v = values[i];
      String label = isHourly ? '₪${v.toStringAsFixed(1)}' : '${(v / 1000).toStringAsFixed(1)}k';
      
      textPainter.text = TextSpan(text: label, style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold));
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, points[i].dy - 20));
      
      DateTime d = DateTime.parse(records[i].monthYear);
      String dateLabel = '${d.month.toString().padLeft(2,'0')}/${d.year.toString().substring(2)}';
      textPainter.text = TextSpan(text: dateLabel, style: const TextStyle(color: Colors.grey, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, size.height - 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}