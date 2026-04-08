// 🔒 STATUS: EDITED (Fixed TextDirection intl collision)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui' as ui;
import '../../data/database_helper.dart';
import '../../data/checking_model.dart';
import '../widgets/global_header.dart';

class CheckingHistoryScreen extends StatelessWidget {
  const CheckingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: const GlobalHeader(title: 'מעקב עו"ש', showBackButton: true),
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
                    ? _buildEmptyState(context)
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
                              title: Text('₪${entry.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                              subtitle: Text(formattedDate, style: const TextStyle(color: Colors.black54)),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00A3FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Color(0xFF00A3FF)),
            ),
            const SizedBox(height: 24),
            const Text(
              'מעקב יתרת העו"ש',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'מסך זה נועד לבקרה בלבד. המערכת תצייר עבורך גרף מגמה כדי שתוכל לראות את התקדמות היתרה שלך לאורך זמן.\n\nטיפ: לקבלת תמונת צמיחה אמינה, הזן את היתרה ביום קבוע (מומלץ ב-20 לחודש, לאחר ירידת החיובים).',
              style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('לחץ על הכפתור למטה כדי להתחיל', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Icon(Icons.arrow_downward, color: Colors.blueGrey, size: 18),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGraph(List<CheckingEntry> entries) {
    final sorted = List<CheckingEntry>.from(entries)
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
    
    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          const SizedBox(height: 20),
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
          return Theme(
            data: ThemeData.light(),
            child: AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('הזנת יתרת עו"ש', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('הזן את הסכום המדויק שיש כעת בחשבון העו"ש, לצורך בקרת צמיחת עודפים.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18), 
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'סכום בעו"ש (₪)',
                      labelStyle: TextStyle(color: Colors.black54, fontSize: 14),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                    title: const Text('תאריך נכונות', style: TextStyle(color: Colors.black87)),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFF00A3FF)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF00A3FF),
                                onPrimary: Colors.white,
                                onSurface: Colors.black87,
                              ),
                            ),
                            child: child!,
                          );
                        },
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
            ),
          );
        },
      ),
    );
  }
}

class _CheckingGraphPainter extends CustomPainter {
  final List<CheckingEntry> entries;

  _CheckingGraphPainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    // אילוץ קו ה-0: מוודאים ש-minAmt הוא לכל היותר 0, ו-maxAmt הוא לפחות 0.
    double maxAmt = entries.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    double minAmt = entries.map((e) => e.amount).reduce((a, b) => a < b ? a : b);
    
    maxAmt = max(maxAmt, 0.0);
    minAmt = min(minAmt, 0.0);

    double heightRange = maxAmt - minAmt;
    if (heightRange == 0) heightRange = 1000;

    final path = Path();
    final paintLine = Paint()
      ..color = const Color(0xFF00A3FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // מרווחים למעלה ולמטה עבור הטקסט
    const double paddingY = 24.0;
    final double usableHeight = size.height - (paddingY * 2);
    final double widthStep = entries.length > 1 ? size.width / (entries.length - 1) : size.width;

    // ציור קו ה-0 (Zero-Line)
    final zeroNormalized = (0 - minAmt) / heightRange;
    final zeroY = usableHeight - (zeroNormalized * usableHeight) + paddingY;
    
    final zeroPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);
    
    final tpZero = TextPainter(
      text: const TextSpan(text: '0', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tpZero.paint(canvas, Offset(0, zeroY - 14));

    // שרטוט הגרף (משמאל לימין)
    List<Offset> points = [];
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final x = entries.length > 1 ? i * widthStep : size.width / 2;
      final normalizedY = (entry.amount - minAmt) / heightRange;
      final y = usableHeight - (normalizedY * usableHeight) + paddingY; 
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

    if (entries.length > 1) {
      canvas.drawPath(path, paintLine);
    }

    // ציור נקודות ותוויות נתונים
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, paintLine..style = PaintingStyle.fill);
      canvas.drawCircle(points[i], 3, paintDot);

      // תווית סכום (מעל הנקודה)
      final amt = '₪${entries[i].amount.toStringAsFixed(0)}';
      textPainter.text = TextSpan(text: amt, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold));
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - (textPainter.width / 2), points[i].dy - 20));

      // תווית תאריך (מתחת לנקודה)
      final dateObj = DateTime.parse(entries[i].date);
      final dateStr = '${dateObj.day.toString().padLeft(2,'0')}/${dateObj.month.toString().padLeft(2,'0')}';
      textPainter.text = TextSpan(text: dateStr, style: const TextStyle(color: Colors.white54, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - (textPainter.width / 2), points[i].dy + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}