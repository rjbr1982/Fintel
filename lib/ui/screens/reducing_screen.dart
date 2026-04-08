// 🔒 STATUS: FINAL (Freemium Teaser updated to use Crown emoji, removed unused imports)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/budget_provider.dart';
import '../../data/debt_model.dart';
import '../../utils/app_localizations.dart';
import '../widgets/global_header.dart';
import 'debt_schedule_screen.dart';
import '../../services/premium_service.dart';

class ReducingScreen extends StatefulWidget {
  const ReducingScreen({super.key});

  @override
  State<ReducingScreen> createState() => _ReducingScreenState();
}

class _ReducingScreenState extends State<ReducingScreen> {
  bool _isPremium = false;
  bool _isLoadingPremium = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumService.isUserPremium();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _isLoadingPremium = false;
      });
    }
  }

  // === פונקציית עזר לתמרורי הדרכה ===
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final debtProvider = context.watch<DebtProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    final activeDebts = debtProvider.debts.where((d) => d.currentBalance > 0).toList();
    final hasActiveDebts = activeDebts.isNotEmpty;
    
    // חישוב ממוקד כוח אש לקופת הצלף: פיננסיות + החזרים שחוסלו בלבד
    final diversion = budgetProvider.financialDiversionAmount;
    final freedUpPayments = debtProvider.debts
        .where((d) => d.currentBalance <= 0)
        .fold(0.0, (sum, d) => sum + d.monthlyPayment);
    final actualMissionAmount = diversion + freedUpPayments;
    
    final targetDebt = debtProvider.nextTargetDebt;
    final acceleratedDates = debtProvider.calculateAcceleratedDates(diversion);
    final acceleratedFinalDate = debtProvider.getAcceleratedFinalPayoffDate(diversion);
    final originalFinalDate = debtProvider.originalFinalPayoffDate;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalHeader(
        title: loc?.get('debts_title') ?? 'מכונת זמן פיננסית',
      ),
      floatingActionButton: _isLoadingPremium ? null : FloatingActionButton(
        onPressed: () => _showDebtDialog(context, debtProvider),
        backgroundColor: const Color(0xFF00A3FF), 
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoadingPremium 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A3FF)))
        : Column(
        children: [
          if (!hasActiveDebts) 
            Expanded(child: _buildVictoryState()) 
          else ...[
            const SizedBox(height: 8),
            if (_isPremium) ...[
              _buildMissionCard(actualMissionAmount, targetDebt),
              _buildTimeMachineHeader(context, originalFinalDate, acceleratedFinalDate),
            ] else ...[
              _buildPremiumTeaserCard(context),
            ],
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Divider(thickness: 1, color: Colors.black12),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeDebts.length,
                itemBuilder: (context, index) {
                  final debt = activeDebts[index];
                  final payoffDate = acceleratedDates[debt.id];
                  final acceleratedPayment = debtProvider.getAcceleratedPaymentForDebt(debt.id!, diversion);
                  
                  return _buildDebtCard(
                    context, 
                    debt, 
                    debt.id == targetDebt?.id, 
                    payoffDate, 
                    acceleratedPayment, 
                    debtProvider
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPremiumTeaserCard(BuildContext context) {
    return InkWell(
      onTap: () {
        PremiumService.requirePremium(context, () {
          setState(() => _isPremium = true);
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.black87],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('👑', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Flexible(
                  child: Text('מתי באמת תסיימו לשלם את החובות?', 
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'מערכת הצלף של Fintel מחשבת כיצד הסטה של העודפים התזרימיים שלכם תחסל את ההלוואות שנים מוקדם יותר ותחסוך לכם אלפי שקלים בריבית. פתחו את מכונת הזמן כדי לראות את לוח הסילוקין המואץ.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: const Text('לפתיחת מכונת הזמן 👑', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVictoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 80,
                color: Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'אתה חופשי!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00C853),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'חיסלת את כל החובות שלך.\nהכסף שלך כעת עובד נטו בשבילך,\nלצמיחה, השקעות ורמת חיים.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'הוסף חוב חדש רק אם זה משרת מטרה כלכלית חכמה (מינוף).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(double amount, Debt? target) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), 
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A3FF), Color(0xFF0066FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A3FF).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            'כוח אש לחיסול חובות (קופת הצלף)',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const Text(
            '(החזרים שחוסלו + פיננסיות)',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 6),
          Text(
            '₪${amount.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold), 
          ),
          const SizedBox(height: 8),
          if (target != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.track_changes, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'היעד הנוכחי: ${target.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTimeMachineHeader(BuildContext context, DateTime original, DateTime accelerated) {
    final monthsSaved = (original.year - accelerated.year) * 12 + (original.month - accelerated.month);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A3FF).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'תחזית לסיום כל החובות',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0066FF)),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showInfoDialog(context, 'מכונת הזמן', "כל חוב שתסיים לשלם לא ייבלע בשוטף, אלא יופנה אוטומטית כ'כוח אש' לחיסול מואץ של החוב הבא."),
                child: const Icon(Icons.info_outline, size: 18, color: Color(0xFF0066FF)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _timeBox('ללא תוכנית', '${original.month.toString().padLeft(2, '0')}/${original.year}', Colors.black45),
              const Icon(Icons.arrow_back, color: Color(0xFF00C853), size: 20),
              _timeBox('עם דוחכם', '${accelerated.month.toString().padLeft(2, '0')}/${accelerated.year}', const Color(0xFF00C853)),
            ],
          ),
          if (monthsSaved > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'חיסכון של $monthsSaved חודשים מהחיים!',
                style: const TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DebtScheduleScreen()),
                );
              },
              icon: const Icon(Icons.calendar_month_outlined, size: 16),
              label: const Text('צפה במפת הדרכים המפורטת', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00A3FF),
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: Color(0xFF00A3FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String label, String date, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(date, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt, bool isTarget, DateTime? payoffDate, double acceleratedPayment, DebtProvider provider) {
    final statusColor = (_isPremium && isTarget) ? const Color(0xFFFF4B4B) : Colors.black87;
    final dateStr = _isPremium 
        ? (payoffDate != null ? "${payoffDate.month.toString().padLeft(2, '0')}/${payoffDate.year}" : "--") 
        : "נעול 👑";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_isPremium && isTarget) ? statusColor.withValues(alpha: 0.5) : Colors.black12, 
          width: (_isPremium && isTarget) ? 2 : 1
        ),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    debt.name, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18, 
                      color: statusColor,
                    )
                  ),
                ),
                if (_isPremium && isTarget)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                    child: const Text('המטרה הבאה', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: debt.progress,
                minHeight: 8,
                backgroundColor: Colors.grey[100],
                color: const Color(0xFF00C853),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('יתרה: ₪${debt.currentBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text('סיום: $dateStr', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00A3FF))),
              ],
            ),
            const Divider(height: 24, color: Colors.black12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('החזר בסיס: ₪${debt.monthlyPayment.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.black38)),
                    if (_isPremium && isTarget)
                      Text(
                        'החזר מואץ: ₪${acceleratedPayment.toStringAsFixed(0)}', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900], fontSize: 15)
                      ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Color(0xFF00C853), size: 20),
                      tooltip: 'סיום חוב זה',
                      onPressed: () => _confirmPayoff(context, provider, debt),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF00A3FF), size: 20),
                      onPressed: () => _showDebtDialog(context, provider, debt: debt),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.black38, size: 20),
                      onPressed: () => _confirmDelete(context, provider, debt.id!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTopNotification(BuildContext context, double freedAmount, String debtName, bool isLastDebt) {
    final message = isLastDebt
        ? '🎉 ניצחון אמיתי! חיסלת את "$debtName" וזו הייתה ההלוואה האחרונה. אתה חופשי לגמרי!'
        : '✅ כל הכבוד! חיסלת את "$debtName".\nהעבר כעת ₪${freedAmount.toStringAsFixed(0)} לקופת הצלף או לחוב הבא.';

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    bool isRemoved = false;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () {
                      if (!isRemoved) {
                        overlayEntry.remove();
                        isRemoved = true;
                      }
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 6), () {
      if (!isRemoved) {
        overlayEntry.remove();
        isRemoved = true;
      }
    });
  }

  void _confirmPayoff(BuildContext context, DebtProvider provider, Debt debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('חגיגת סיום חוב'),
        content: Text('האם ברצונך לסמן את "${debt.name}" כחוב שחוסל במלואו?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          ElevatedButton(
            onPressed: () {
              final activeCount = provider.debts.where((d) => d.currentBalance > 0).length;
              final isLastDebt = activeCount <= 1;

              final d = Debt(
                id: debt.id,
                name: debt.name,
                originalBalance: debt.originalBalance,
                currentBalance: 0,
                monthlyPayment: debt.monthlyPayment,
                date: debt.date,
              );
              provider.updateDebt(d);
              Navigator.pop(ctx);
              
              _showTopNotification(context, debt.monthlyPayment, debt.name, isLastDebt);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
            child: const Text('כן, סומן שחוסל!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDebtDialog(BuildContext context, DebtProvider provider, {Debt? debt}) {
    final isEdit = debt != null;
    final nameCtrl = TextEditingController(text: debt?.name ?? '');
    final originalBalanceCtrl = TextEditingController(text: debt?.originalBalance.toStringAsFixed(0) ?? '');
    final currentBalanceCtrl = TextEditingController(text: debt?.currentBalance.toStringAsFixed(0) ?? '');
    final paymentCtrl = TextEditingController(text: debt?.monthlyPayment.toStringAsFixed(0) ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'עריכת חוב' : 'הוספת חוב חדש'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'שם ההלוואה')),
              TextField(controller: originalBalanceCtrl, decoration: const InputDecoration(labelText: 'סכום הלוואה מקורי'), keyboardType: TextInputType.number),
              TextField(controller: currentBalanceCtrl, decoration: const InputDecoration(labelText: 'יתרה נוכחית לסילוק'), keyboardType: TextInputType.number),
              TextField(controller: paymentCtrl, decoration: const InputDecoration(labelText: 'החזר חודשי קבוע'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          ElevatedButton(
            onPressed: () {
              final orig = double.tryParse(originalBalanceCtrl.text);
              final curr = double.tryParse(currentBalanceCtrl.text);
              final pay = double.tryParse(paymentCtrl.text);
              
              if (orig != null && curr != null && pay != null && nameCtrl.text.isNotEmpty) {
                final d = Debt(
                  id: debt?.id,
                  name: nameCtrl.text,
                  originalBalance: orig,
                  currentBalance: curr,
                  monthlyPayment: pay,
                  date: debt?.date ?? DateTime.now().toIso8601String(),
                );
                
                bool isJustPaidOff = false;
                if (debt != null) {
                  isJustPaidOff = curr <= 0 && debt.currentBalance > 0;
                }
                
                final activeCount = provider.debts.where((item) => item.currentBalance > 0).length;
                final isLastDebt = activeCount <= 1;
                
                if (isEdit) {
                  provider.updateDebt(d);
                } else {
                  // חוק "הלוח החלק" - הוספת חוב ממצב של ניצחון מנקה את ההיסטוריה לחלוטין
                  if (activeCount == 0) {
                    final ghostDebts = provider.debts.where((item) => item.currentBalance <= 0).toList();
                    for (var ghost in ghostDebts) {
                      provider.deleteDebt(ghost.id!);
                    }
                  }
                  provider.addDebt(d);
                }
                
                Navigator.pop(ctx);
                
                if (isJustPaidOff) {
                  _showTopNotification(context, pay, nameCtrl.text, isLastDebt);
                }
              }
            },
            child: Text(isEdit ? 'עדכן' : 'הוסף'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DebtProvider provider, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('מחיקת חוב'),
        content: const Text('האם אתה בטוח שברצונך למחוק חוב זה?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          ElevatedButton(
            onPressed: () { provider.deleteDebt(id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4B4B)),
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}