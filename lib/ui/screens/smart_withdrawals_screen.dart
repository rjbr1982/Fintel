// 🔒 STATUS: EDITED (Fixed TextField visibility and Dialog layout issues)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/budget_provider.dart';
import '../../data/expense_model.dart';
import '../widgets/global_header.dart';

class SmartWithdrawalsScreen extends StatelessWidget {
  const SmartWithdrawalsScreen({super.key});

  DateTime _getNextWithdrawalDate(int targetDay) {
    final now = DateTime.now();
    DateTime targetDate = DateTime(now.year, now.month, targetDay);
    
    // אם היום בחודש כבר עבר, נכוון לחודש הבא
    if (now.day > targetDay) {
      targetDate = DateTime(now.year, now.month + 1, targetDay);
    }
    return targetDate;
  }

  // פונקציית עזר לשליפת כל הקופות האפשריות (לצורך ה-Dropdown של ההוספה)
  List<String> _getAvailableBuckets(BudgetProvider provider) {
    Set<String> buckets = {};
    for (var e in provider.expenses.where((ex) => ex.isSinking)) {
      if (e.parentCategory == 'רכב') {
        buckets.add('רכב');
      } else if (e.parentCategory == 'ילדים - משתנות') {
        String kName = e.name.replaceAll('בגדים', '').replaceAll('בילויים', '').trim();
        buckets.add('ילדים: $kName');
      } else if (['ילדים - קבועות', 'אבא', 'אמא', 'אישי', 'חגים'].contains(e.parentCategory)) {
        buckets.add(e.parentCategory);
      } else {
        bool isFuture = e.category == 'עתידיות';
        buckets.add(isFuture ? e.parentCategory : e.name);
      }
    }
    return buckets.toList()..sort();
  }

  void _showAddPlannedWithdrawalDialog(BuildContext context, BudgetProvider provider) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final buckets = _getAvailableBuckets(provider);
    String? selectedBucket = buckets.isNotEmpty ? buckets.first : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('תכנון הוצאה עתידית', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('בחר מאיזו קופה תרצה למשוך, ומנהל המשיכות יאגד אותה לתחנת היציאה הבאה.', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(height: 20),
                if (buckets.isEmpty)
                  const Text('אין קופות צוברות זמינות.', style: TextStyle(color: Colors.red))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBucket,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                        items: buckets.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(color: Colors.black87)))).toList(),
                        onChanged: (val) => setState(() => selectedBucket = val),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'עבור מה ההוצאה? (למשל: קייטנה)',
                    labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'סכום משוער',
                    labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
                    suffixText: '₪',
                    suffixStyle: const TextStyle(color: Colors.black87),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('ביטול', style: TextStyle(color: Colors.blueGrey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text);
                if (amt != null && amt > 0 && selectedBucket != null && nameCtrl.text.isNotEmpty) {
                  final pw = PlannedWithdrawal(
                    name: nameCtrl.text.trim(),
                    amount: amt,
                    bucketName: selectedBucket!,
                    targetDate: DateTime.now().toIso8601String(), // Will be grouped dynamically
                  );
                  await provider.addPlannedWithdrawal(pw);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('שמור תכנון', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetDayDialog(BuildContext context, BudgetProvider provider, String bucketName) {
    int currentDay = provider.getBucketWithdrawalDay(bucketName);
    int selectedDay = currentDay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('תחנת יציאה: $bucketName', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('באיזה יום בחודש ניתן למשוך כסף מפיקדון זה?', style: TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('כל ', style: TextStyle(fontSize: 16, color: Colors.black87)),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedDay,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                        items: List.generate(31, (index) => index + 1)
                            .map((day) => DropdownMenuItem(value: day, child: Text(day.toString(), style: const TextStyle(color: Colors.black87))))
                            .toList(),
                        onChanged: (val) => setState(() => selectedDay = val ?? 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('לחודש', style: TextStyle(fontSize: 16, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('ביטול', style: TextStyle(color: Colors.blueGrey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await provider.setBucketWithdrawalDay(bucketName, selectedDay);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('שמור', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const GlobalHeader(title: 'מנהל משיכות חכם', showBackButton: true),
      floatingActionButton: Consumer<BudgetProvider>(
        builder: (context, provider, child) => FloatingActionButton.extended(
          backgroundColor: Colors.blue.shade900,
          onPressed: () => _showAddPlannedWithdrawalDialog(context, provider),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('תכנן הוצאה', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          final pendingWithdrawals = provider.plannedWithdrawals.where((pw) => pw.status == PlannedWithdrawalStatus.pending).toList();

          if (pendingWithdrawals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 80, color: Colors.blue.shade200),
                  const SizedBox(height: 16),
                  const Text('אין משיכות מתוכננות', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  const Text('תכנן הוצאות עתידיות מהקופות שלך\nואנחנו נאגד אותן עבורך לתחנת יציאה אחת.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
                ],
              ),
            );
          }

          // קיבוץ לפי קופה
          Map<String, List<PlannedWithdrawal>> grouped = {};
          for (var pw in pendingWithdrawals) {
            grouped.putIfAbsent(pw.bucketName, () => []).add(pw);
          }

          // בניית רשימת כרטיסיות ממוינת כרונולוגית לפי התאריך הקרוב ביותר
          List<Map<String, dynamic>> bucketCards = [];
          final now = DateTime.now();

          grouped.forEach((bucketName, items) {
            int targetDay = provider.getBucketWithdrawalDay(bucketName);
            DateTime nextDate = _getNextWithdrawalDate(targetDay);
            double totalAmount = items.fold(0.0, (sum, item) => sum + item.amount);
            int daysLeft = nextDate.difference(DateTime(now.year, now.month, now.day)).inDays;

            bucketCards.add({
              'bucketName': bucketName,
              'items': items,
              'nextDate': nextDate,
              'totalAmount': totalAmount,
              'daysLeft': daysLeft,
              'targetDay': targetDay,
            });
          });

          // מיון: מהקרוב ביותר לרחוק ביותר
          bucketCards.sort((a, b) => (a['nextDate'] as DateTime).compareTo(b['nextDate'] as DateTime));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bucketCards.length,
            itemBuilder: (context, index) {
              final cardData = bucketCards[index];
              final String bucketName = cardData['bucketName'];
              final List<PlannedWithdrawal> items = cardData['items'];
              final DateTime nextDate = cardData['nextDate'];
              final double totalAmount = cardData['totalAmount'];
              final int daysLeft = cardData['daysLeft'];
              final int targetDay = cardData['targetDay'];

              final dateStr = DateFormat('dd/MM/yyyy').format(nextDate);
              
              // צבע לפי דחיפות (3 ימים ומטה - אדום/כתום, אחרת כחול)
              Color urgencyColor = daysLeft <= 3 ? Colors.deepOrange : Colors.blue.shade700;

              return Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: urgencyColor.withValues(alpha: 0.3), width: 1.5)),
                elevation: 2,
                shadowColor: urgencyColor.withValues(alpha: 0.1),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: InkWell(
                      onTap: () => _showSetDayDialog(context, provider, bucketName),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: urgencyColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(targetDay.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: urgencyColor, height: 1)),
                            Text('לחודש', style: TextStyle(fontSize: 9, color: urgencyColor)),
                          ],
                        ),
                      ),
                    ),
                    title: Text(bucketName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('תחנת יציאה: $dateStr ($daysLeft ימים)', style: TextStyle(color: urgencyColor, fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('סה"כ דרוש: ₪${totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    children: [
                      const Divider(height: 1, color: Colors.black12),
                      Container(
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('פירוט הוצאות מתוכננות:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            const SizedBox(height: 8),
                            ...items.map((pw) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('• ${pw.name}', style: const TextStyle(color: Colors.black87))),
                                  Text('₪${pw.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => provider.deletePlannedWithdrawal(pw.id!),
                                  ),
                                ],
                              ),
                            )),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C853),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                label: const Text('בוצעה משיכה בנקאית', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                onPressed: () async {
                                  // מפעילים את הפונקציה הלוגית מה-Provider שמקזזת מהקופה ומעדכנת סטטוס
                                  await provider.executePlannedWithdrawalsForBucket(bucketName);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('מצוין! הסכום קוזז מקופת "$bucketName" וממתין לחיוב בעו"ש.'),
                                        backgroundColor: Colors.green,
                                      )
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}