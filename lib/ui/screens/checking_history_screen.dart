// 🔒 STATUS: EDITED (Fixed deprecated withOpacity warnings)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_helper.dart';
import '../../data/checking_model.dart';
import '../widgets/global_header.dart';

class CheckingHistoryScreen extends StatelessWidget {
  const CheckingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalHeader(title: 'מעקב עו"ש (בקרה)', showBackButton: true),
      body: StreamBuilder<List<CheckingEntry>>(
        stream: DatabaseHelper.instance.streamCheckingHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00A3FF)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('שגיאה בטעינת נתונים: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final entries = snapshot.data ?? [];
          
          return Column(
            children: [
              if (entries.isNotEmpty)
                _buildGraph(entries),
              if (entries.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('היסטוריית הזנות', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                ),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('לא נמצאו רשומות. לחץ על + כדי להוסיף דגימת עו"ש חדשה.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final dateObj = DateTime.parse(entry.date);
                          final formattedDate = DateFormat('dd/MM/yyyy').format(dateObj);
                          return Dismissible(
                            key: Key(entry.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              DatabaseHelper.instance.deleteCheckingEntry(entry.id!);
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: entry.amount >= 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                child: Icon(Icons.account_balance_wallet, color: entry.amount >= 0 ? Colors.green : Colors.red),
                              ),
                              title: Text('₪${entry.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: Text(formattedDate),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () => DatabaseHelper.instance.deleteCheckingEntry(entry.id!),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00A3FF),
        onPressed: () => _showAddEntryDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('דגימה חדשה', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGraph(List<CheckingEntry> entries) {
    // הגרף דורש מיון כרונולוגי עולה (משמאל לימין)
    final sorted = List<CheckingEntry>.from(entries)
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
    
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('מגמת יתרת העו"ש', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _CheckingGraphPainter(sorted),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('הזנת יתרת עו"ש', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('הזן את הסכום המדויק שיש כעת בחשבון העו"ש, לצורך בקרת צמיחת עודפים.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'סכום בעו"ש (₪)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.white24)),
                  title: const Text('תאריך נכונות'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today, color: Color(0xFF00A3FF)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A3FF)),
                onPressed: () async {
                  final val = double.tryParse(amountCtrl.text);
                  if (val != null) {
                    final entry = CheckingEntry(amount: val, date: selectedDate.toIso8601String());
                    await DatabaseHelper.instance.insertCheckingEntry(entry);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('שמור דגימה', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// מנוע הציור הגרפי של המגמה (Native Flutter Canvas)
class _CheckingGraphPainter extends CustomPainter {
  final List<CheckingEntry> entries;

  _CheckingGraphPainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    if (entries.length == 1) {
      final paint = Paint()..color = const Color(0xFF00A3FF)..strokeWidth = 4;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 6, paint);
      return;
    }

    double maxAmt = entries.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    double minAmt = entries.map((e) => e.amount).reduce((a, b) => a < b ? a : b);

    // מניעת חלוקה באפס אם כל הסכומים זהים
    if (maxAmt == minAmt) {
      maxAmt += 1000;
      minAmt -= 1000;
    }

    final path = Path();
    final paintLine = Paint()
      ..color = const Color(0xFF00A3FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final widthStep = size.width / (entries.length - 1);
    final heightRange = maxAmt - minAmt;

    List<Offset> points = [];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final x = i * widthStep;
      final normalizedY = (entry.amount - minAmt) / heightRange;
      final y = size.height - (normalizedY * size.height); // ציר Y הפוך בקנבס
      points.add(Offset(x, y));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = points[i - 1].dx;
        final prevY = points[i - 1].dy;
        // מתיחת קו מעוקל ואלגנטי במקום קווים שבורים
        path.quadraticBezierTo(
          prevX + (x - prevX) / 2, prevY, 
          x, y
        );
      }
    }

    canvas.drawPath(path, paintLine);

    for (var point in points) {
      canvas.drawCircle(point, 5, paintLine..style = PaintingStyle.fill);
      canvas.drawCircle(point, 3, paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}