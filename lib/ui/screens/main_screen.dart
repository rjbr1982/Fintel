// 🔒 STATUS: EDITED (Updated Welcome Dialog to explicitly list 0-amount expenses dynamically)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/debt_provider.dart';
import '../../utils/app_localizations.dart';
import '../widgets/global_header.dart'; 
import 'pnl_screen.dart'; 
import 'shopping_screen.dart';

class MainScreen extends StatefulWidget {
  final bool showWelcomeDialog; 
  final bool showDebtTask; 

  const MainScreen({super.key, this.showWelcomeDialog = false, this.showDebtTask = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BudgetProvider>().loadData();
      if (mounted) {
        await context.read<DebtProvider>().loadDebts();
      }
      
      // הקפצת הנחיתה הרכה אם הגענו מהאשף
      if (widget.showWelcomeDialog && mounted) {
        _showSoftLandingDialog(context);
      }
    });
  }

  void _showSoftLandingDialog(BuildContext context) {
    final budget = context.read<BudgetProvider>();
    final hasKids = budget.childCount > 0; // בדיקה דינמית אם יש ילדים

    // בניית טקסט ההסבר לסעיפי האפס בצורה דינמית ומפורטת
    String zeroAmountDesc = 'הסעיפים האישיים הבאים נוצרו עבורך עם סכום 0, והם ממתינים לעדכון שלך בקטגוריית ה"קבועות":\n'
        '• קופת חולים וביטוחים\n'
        '• מנויים דיגיטליים\n'
        '• תספורת\n'
        '• תרומות / מעשרות';
        
    if (hasKids) {
      zeroAmountDesc += '\n• הוצאות ילדים: שכר לימוד, חוגים, קייטנות, ציוד ומתנות';
    }
    
    zeroAmountDesc += '\n\n* הערה: אם סעיף מסוים אינו רלוונטי עבורך, פשוט השאר אותו על 0 או מחק אותו.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 40),
            SizedBox(height: 10),
            Text('ברוכים הבאים לחירות הפיננסית!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('המערכת בנתה עבורך תקציב אוטומטי מלא המבוסס על מודל "דוחכם". כעת, מומלץ לבצע את משימות הכיול הבאות:', style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
              const SizedBox(height: 20),
              
              _buildTaskRow('1', 'כיול הוצאות דיור', 'כנס לקטגוריות קבועות -> דיור, ועדכן את שכר הדירה/משכנתא האמיתי שלך.'),
              const SizedBox(height: 15),
              
              // המשימה המפורטת החדשה
              _buildTaskRow('2', 'השלמת הוצאות חסרות (סכום 0)', zeroAmountDesc),
              const SizedBox(height: 15),

              _buildTaskRow('3', 'בניית עוגן קניות', 'כנס לכפתור העגלה ובדוק את רשימת הקניות. המחיר הכולל יקבע את גובה כלל רמת החיים שלך.'),
              
              if (widget.showDebtTask) ...[
                const SizedBox(height: 15),
                _buildTaskRow('4', 'טעינת מנוע הצלף', 'הצהרת שיש לך חובות. כנס למסך תזרים -> מנמיכות, והזן את ההלוואות שלך כדי שהמערכת תחסל אותן עבורך.'),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A3FF),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('הבנתי, בוא נתחיל', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildTaskRow(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 12, backgroundColor: Colors.blue[50], child: Text(num, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
            ],
          ),
        )
      ],
    );
  }

  void _showFreedomSettingsDialog(BuildContext context, BudgetProvider budget) {
    final targetCtrl = TextEditingController(
      text: budget.manualTargetIncome != null ? budget.manualTargetIncome!.toStringAsFixed(0) : ''
    );
    final capitalCtrl = TextEditingController(text: budget.initialCapital.toStringAsFixed(0));
    final yieldCtrl = TextEditingController(text: budget.expectedYield.toStringAsFixed(1));
    int freq = budget.compoundingFrequency;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('הגדרות מנוע החירות', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'יעד הכנסה פסיבית (ריק = אוטומטי)',
                        hintText: budget.autoTargetIncome.toStringAsFixed(0),
                        prefixIcon: const Icon(Icons.track_changes),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: capitalCtrl,
                      readOnly: true, 
                      decoration: const InputDecoration(
                        labelText: 'הון עצמי נוכחי (נשאב מהנכסים)',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: yieldCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'תשואה שנתית נטו (%)',
                        prefixIcon: Icon(Icons.trending_up),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('תדירות צבירת ריבית:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: freq,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('שנתית (1)')),
                            DropdownMenuItem(value: 12, child: Text('חודשית (12)')),
                            DropdownMenuItem(value: 52, child: Text('שבועית (52)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => freq = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ביטול', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                  onPressed: () {
                    double? target = double.tryParse(targetCtrl.text);
                    double yld = double.tryParse(yieldCtrl.text) ?? 4.0;
                    
                    budget.setFreedomSettings(
                      manualTarget: target,
                      yieldRate: yld,
                      frequency: freq,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('שמור הגדרות', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showFamilyDrilldown(BuildContext context, BudgetProvider budget, int? targetYear) {
    if (targetYear == null) {
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('גילאי המשפחה בשנת $targetYear', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              ...budget.familyMembers.map((fm) {
                int age = targetYear - fm.birthYear;
                return ListTile(
                  leading: const Icon(Icons.person, color: Colors.blueGrey),
                  title: Text(fm.name, style: const TextStyle(fontSize: 16)),
                  trailing: Text('גיל $age', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00C853))),
                );
              }),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('סגור', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900]),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PnLScreen()));
              },
              child: const Text('עבור לתזרים (PnL)', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final budget = context.watch<BudgetProvider>();

    int? monthsToFreedom = budget.calculateMonthsToFreedom();
    
    String yearText = "∞";
    int? targetYear;

    if (monthsToFreedom != null) {
      if (monthsToFreedom == 0) {
        yearText = "הושג!";
        targetYear = DateTime.now().year;
      } else {
        targetYear = DateTime.now().year + (monthsToFreedom / 12).ceil();
        yearText = targetYear.toString();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlobalHeader(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey[900],
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ShoppingScreen()));
        },
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _showFreedomSettingsDialog(context, budget),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('יעד הכנסה פסיבית חודשית', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(width: 8),
                        Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
                Text(
                  '${loc?.get('currency_symbol') ?? '₪'}${budget.targetPassiveIncome.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                
                const SizedBox(height: 50),

                InkWell(
                  onTap: () {
                    if (targetYear != null) {
                      _showFamilyDrilldown(context, budget, targetYear);
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PnLScreen()));
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF00C853), width: 2),
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF00C853).withValues(alpha: 0.05),
                    ),
                    child: Column(
                      children: [
                        const Text('שנת החירות הפיננסית', 
                          style: TextStyle(fontSize: 16, color: Color(0xFF00C853), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        Text(
                          yearText,
                          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.family_restroom, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 5),
                            Text('לחץ לגילאי המשפחה והתזרים', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (budget.expectedYield <= 4.0)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "התחזית מבוססת על ריבית חסרת סיכון. מומלץ לבחון אפיקי השקעה עם תשואה גבוהה יותר.",
                              style: TextStyle(color: Colors.orange[800], fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: () {
                // TODO: Implement system check functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('בדיקת מערכת נכנסת לפיתוח'),
                    backgroundColor: Color(0xFF00A3FF),
                  ),
                );
              },
              icon: const Icon(Icons.health_and_safety),
              label: const Text(
                'בדיקת מערכת',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
