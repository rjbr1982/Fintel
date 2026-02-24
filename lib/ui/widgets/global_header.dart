// 🔒 STATUS: EDITED (Added Logout functionality)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // הייבוא החדש עבור ההתנתקות
import '../../providers/budget_provider.dart';
import '../../utils/app_localizations.dart';
import '../../services/ai_export_service.dart';
import '../screens/onboarding_screen.dart'; // הייבוא של מסך הקליטה!

class GlobalHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;

  const GlobalHeader({
    super.key,
    this.title,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();
    final loc = AppLocalizations.of(context);
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      
      leading: (showBackButton && canPop) 
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          )
        : null,

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/icon/icon.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: title != null 
              ? Text(title!, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)
              : Text(loc?.get('appTitle') ?? 'דוחכם', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey[400])),
          ),
        ],
      ),
      
      actions: [
        IconButton(
          icon: const Icon(Icons.psychology, color: Colors.deepPurple),
          tooltip: 'ייצוא נתונים ל-AI',
          onPressed: () async {
            await AiExportService.generateAndCopy(context);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('הנתונים הועתקו בהצלחה! ניתן להדביק בצ\'אט עם ה-AI.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
        ),

        if (canPop)
          IconButton(
            icon: const Icon(Icons.dashboard_outlined, color: Colors.blueGrey),
            tooltip: 'חזרה לדשבורד',
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
            },
          ),
        
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.blueGrey),
          tooltip: 'הגדרות מערכת',
          onPressed: () => _showMainSettingsDialog(context, budget),
        ),
        
        const SizedBox(width: 4),
      ],
    );
  }

  void _showMainSettingsDialog(BuildContext context, BudgetProvider budget) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('הגדרות מערכת', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          _buildSettingsTile(ctx, Icons.family_restroom_rounded, 'הגדרות משפחה', () {
              Navigator.pop(ctx);
              _showFamilySettingsDialog(context, budget);
          }),
          const Divider(),
          _buildSettingsTile(ctx, Icons.pie_chart_outline, 'אחוז משתנות (רמת חיים)', () {
              Navigator.pop(ctx);
              _showRatioSettingsDialog(context, budget);
          }),
          const Divider(),
          _buildSettingsTile(ctx, Icons.balance, 'חלוקת שארית (עתידיות/פיננסיות)', () {
              Navigator.pop(ctx);
              _showFutureVsFinancialDialog(context, budget);
          }),
          const Divider(),
          // מנגנון ההתנתקות החדש:
          _buildSettingsTile(ctx, Icons.logout, 'התנתקות מהחשבון (Log Out)', () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                // ניתוב מחדש לשער (AuthGate) שיזהה שהמשתמש התנתק ויציג מסך התחברות
                Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
              }
          }),
          const Divider(),
          _buildSettingsTile(ctx, Icons.restore, 'איפוס כל הנתונים (Factory Reset)', () {
              Navigator.pop(ctx);
              _showFactoryResetConfirm(context, budget);
          }, color: Colors.red[700]),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext ctx, IconData icon, String text, VoidCallback onTap, {Color? color}) {
    return SimpleDialogOption(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blueGrey, size: 22),
          const SizedBox(width: 16),
          Text(text, style: TextStyle(fontSize: 16, color: color)),
        ],
      ),
    );
  }

  void _showFutureVsFinancialDialog(BuildContext context, BudgetProvider budget) {
    final futureRatio = budget.futureAllocationRatio;
    final futureController = TextEditingController(text: (futureRatio * 100).toStringAsFixed(0));
    final financialController = TextEditingController(text: ((1 - futureRatio) * 100).toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('חלוקת יתרת החיסכון'),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                onPressed: () {
                  budget.resetFutureRatio();
                  Navigator.pop(ctx);
                  _showFutureVsFinancialDialog(context, budget);
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('קבע איך תחולק השארית לאחר המשתנות.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: futureController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'עתידיות', suffixText: '%', border: OutlineInputBorder()),
                      onChanged: (val) {
                        final num = double.tryParse(val) ?? 0;
                        if (num >= 0 && num <= 100) financialController.text = (100 - num).toStringAsFixed(0);
                      },
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.compare_arrows)),
                  Expanded(
                    child: TextField(
                      controller: financialController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'פיננסיות', suffixText: '%', border: OutlineInputBorder()),
                      onChanged: (val) {
                        final num = double.tryParse(val) ?? 0;
                        if (num >= 0 && num <= 100) futureController.text = (100 - num).toStringAsFixed(0);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(futureController.text);
                if (val != null) {
                  budget.setAllocationRatios(future: val / 100);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('עדכן חלוקה'),
            )
          ],
        ),
      ),
    );
  }

  void _showRatioSettingsDialog(BuildContext context, BudgetProvider budget) {
    final controller = TextEditingController(text: (budget.variableAllocationRatio * 100).toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('הגדרת רמת חיים'),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: () {
                budget.resetVariableRatio();
                Navigator.pop(ctx);
                _showRatioSettingsDialog(context, budget);
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('אחוז מההכנסה הפנויה להוצאות משתנות.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'אחוז הקצאה', suffixText: '%', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0 && val <= 100) {
                budget.setAllocationRatios(variable: val / 100);
                Navigator.pop(ctx);
              }
            },
            child: const Text('שמור'),
          )
        ],
      ),
    );
  }

  void _showFactoryResetConfirm(BuildContext context, BudgetProvider budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ אזהרה: איפוס נתונים'),
        content: const Text('פעולה זו תמחק הכל ותחזיר את האפליקציה למצב התחלתי. לא ניתן לבטל!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await budget.fullAppReset();
              if (ctx.mounted) {
                Navigator.pop(ctx); // סוגר את חלונית האישור
                // פקודת הניווט שזורקת ישירות למסך הקליטה לאחר איפוס
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('אפס הכל', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFamilySettingsDialog(BuildContext context, BudgetProvider budget) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('הגדרות משפחה', textAlign: TextAlign.center),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('מספר ילדים:'),
                      Row(
                        children: [
                          IconButton(onPressed: budget.childCount > 0 ? () { budget.setChildCount(budget.childCount - 1); setDialogState(() {}); } : null, icon: const Icon(Icons.remove_circle_outline)),
                          Text('${budget.childCount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () { budget.setChildCount(budget.childCount + 1); setDialogState(() {}); }, icon: const Icon(Icons.add_circle_outline)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: budget.familyMembers.length,
                      itemBuilder: (context, index) {
                        final member = budget.familyMembers[index];
                        return ListTile(
                          title: Text(member.name),
                          subtitle: Text('גיל: ${member.age}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red), 
                            onPressed: () async { 
                              if (member.id != null) { 
                                await budget.removeFamilyMember(member.id!); 
                                if (ctx.mounted) setDialogState(() {}); 
                              } 
                            }
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(onPressed: () => _showAddMemberDialog(context, budget, setDialogState), child: const Text('הוסף בן משפחה')),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('סגור'))],
          );
        },
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, BudgetProvider budget, Function parentState) {
    final nameController = TextEditingController();
    final yearController = TextEditingController(text: DateTime.now().year.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('בן משפחה חדש'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'שם')),
            TextField(controller: yearController, decoration: const InputDecoration(labelText: 'שנת לידה'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          ElevatedButton(
            onPressed: () async { 
              if (nameController.text.isNotEmpty) { 
                final birthYear = int.tryParse(yearController.text) ?? DateTime.now().year;
                await budget.addFamilyMember(nameController.text, birthYear); 
                if (ctx.mounted) {
                  parentState(() {}); 
                  Navigator.pop(ctx); 
                }
              } 
            }, 
            child: const Text('שמור')
          ),
        ],
      ),
    );
  }
}