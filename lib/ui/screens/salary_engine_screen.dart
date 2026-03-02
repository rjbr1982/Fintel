// 🔒 STATUS: EDITED (Replaced BarChart with Smooth Area Mountain Chart)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
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

  Widget _buildMountainChart(List<SalaryRecord> records, bool isHourly) {
    if (records.isEmpty) return const SizedBox.shrink();
    
    // מיון מהישן לחדש כדי שהגרף יזרום מימין (ישן) לשמאל (חדש) בעברית
    var sortedRecords = List<SalaryRecord>.from(records);
    sortedRecords.sort((a, b) => DateTime.parse(a.monthYear).compareTo(DateTime.parse(b.monthYear)));
    
    // רוחב דינמי המאפשר גלילה (לפחות 60 פיקסלים לכל חודש)
    double calculatedWidth = math.max(MediaQuery.of(context).size.width - 64, sortedRecords.length * 60.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // מתחיל את הגלילה מהצד השמאלי (העדכני ביותר)
      child: SizedBox(
        height: 200,
        width: calculatedWidth,
        child: CustomPaint(
          painter: _MountainChartPainter(sortedRecords, isHourly),
        ),
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
      appBar: const GlobalHeader(title: 'מנוע ממוצע שכר'),
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
                const Text('מגמת שכר נטו (תצוגת כלל החודשים)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                  child: _buildMountainChart(myRecords, false),
                ),
                const SizedBox(height: 24),
                const Text('מגמת תעריף שעתי (תצוגת כלל החודשים)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                  child: _buildMountainChart(myRecords, true),
                ),
                const SizedBox(height: 30),
              ],

              const Text('היסטוריית דיווחי שכר', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
// ציור גרף ההרים (Area Chart) - נקי, דינמי ונגלל
// ============================================================================
class _MountainChartPainter extends CustomPainter {
  final List<SalaryRecord> records;
  final bool isHourly;

  _MountainChartPainter(this.records, this.isHourly);

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
    for (var r in records) {
      double v = isHourly ? (r.netAmount / r.hours) : r.netAmount;
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
    
    // רווח בין הנקודות (גריד)
    double stepX = size.width / (records.length > 1 ? records.length - 1 : 1);
    
    // בגלל שעברית היא RTL, הגרף מרונדר מימין לשמאל במסכים כאלה.
    // אבל Canvas מרונדר תמיד LTR (נקודת 0,0 היא שמאלה למעלה).
    // לכן הקודקודים יהיו משמאל לימין. ה-SingleChildScrollView שהוספנו הופך את התצוגה.
    
    List<Offset> points = [];
    for (int i = 0; i < records.length; i++) {
      double v = isHourly ? (records[i].netAmount / records[i].hours) : records[i].netAmount;
      double x = size.width - (i * stepX); // היפוך כיוון ככה שהחדש בשמאל והישן בימין
      double y = size.height - 30 - (((v - bottomBase) / range) * (size.height - 60)); // מרווח מלמעלה ומלמטה
      points.add(Offset(x, y));
    }

    // ציור קו הגל ושטח ההרים
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
        // ניתן להשתמש ב-lineTo לקווים חדים או cubicTo לעקומות, בחרתי ב-lineTo למראה מודרני מדוייק
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, size.height);
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);

    // ציור נקודות וטקסט
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, Paint()..color = Colors.white);
      canvas.drawCircle(points[i], 5, paintLine..style = PaintingStyle.stroke);

      double v = isHourly ? (records[i].netAmount / records[i].hours) : records[i].netAmount;
      String label = isHourly ? '₪${v.toStringAsFixed(1)}' : '${(v / 1000).toStringAsFixed(1)}k';
      
      textPainter.text = TextSpan(text: label, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold));
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, points[i].dy - 22));
      
      DateTime d = DateTime.parse(records[i].monthYear);
      String dateLabel = '${d.month.toString().padLeft(2,'0')}/${d.year.toString().substring(2)}';
      textPainter.text = TextSpan(text: dateLabel, style: const TextStyle(color: Colors.grey, fontSize: 11));
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, size.height - 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}