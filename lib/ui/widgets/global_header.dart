// 🔒 STATUS: EDITED (Fixed App Icon path to match Fintel_Icon.png)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/budget_provider.dart';
import '../../data/expense_model.dart';
import '../../utils/app_localizations.dart';
import '../../services/ai_export_service.dart';
import '../screens/onboarding_screen.dart';
import '../screens/sinking_funds_screen.dart';
import '../screens/checking_history_screen.dart';
import '../screens/salary_engine_screen.dart';

enum MenuAction { savings, checking, salary, ai, settings }

class GlobalHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final bool showSavingsIcon;

  const GlobalHeader({
    super.key,
    this.title,
    this.showBackButton = true,
    this.showSavingsIcon = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();
    final loc = AppLocalizations.of(context);
    final canPop = Navigator.of(context).canPop();

    const brandBlue = Color(0xFF00A3FF);

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
              'assets/icon/Fintel_Icon.png', // הנתיב תוקן לשם החדש
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
        if (canPop)
          IconButton(
            icon: const Icon(Icons.dashboard_outlined, color: brandBlue),
            tooltip: 'חזרה לדשבורד',
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
            },
          ),
        
        PopupMenuButton<MenuAction>(
          icon: const Icon(Icons.more_vert, color: brandBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          offset: const Offset(0, 40),
          tooltip: 'תפריט פעולות',
          onSelected: (MenuAction action) async {
            switch (action) {
              case MenuAction.savings:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SinkingFundsScreen()),
                );
                break;
              case MenuAction.checking:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckingHistoryScreen()),
                );
                break;
              case MenuAction.salary:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SalaryEngineScreen()),
                );
                break;
              case MenuAction.ai:
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
                break;
              case MenuAction.settings:
                _showMainSettingsDialog(context, budget);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuAction>>[
            if (showSavingsIcon)
              const PopupMenuItem<MenuAction>(
                value: MenuAction.savings,
                child: Row(
                  children: [
                    Icon(Icons.savings_outlined, color: Colors.green, size: 22),
                    SizedBox(width: 12),
                    Text('מרכז החסכונות'),
                  ],
                ),
              ),
            if (showSavingsIcon) const PopupMenuDivider(),
            const PopupMenuItem<MenuAction>(
              value: MenuAction.checking,
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: Colors.blueGrey, size: 22),
                  SizedBox(width: 12),
                  Text('מעקב יתרת עו"ש'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<MenuAction>(
              value: MenuAction.salary,
              child: Row(
                children: [
                  Icon(Icons.insights, color: Colors.blue, size: 22),
                  SizedBox(width: 12),
                  Text('מנוע סטטיסטיקת שכר'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<MenuAction>(
              value: MenuAction.ai,
              child: Row(
                children: [
                  Icon(Icons.psychology, color: Colors.deepPurple, size: 22),
                  SizedBox(width: 12),
                  Text('ייצוא נתונים ל-AI'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<MenuAction>(
              value: MenuAction.settings,
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.blueGrey, size: 22),
                  SizedBox(width: 12),
                  Text('הגדרות מערכת'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showMainSettingsDialog(BuildContext context, BudgetProvider budget) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings_outlined, color: Colors.blueGrey, size: 28),
                    SizedBox(width: 10),
                    Text('הגדרות מערכת', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsCard(ctx, Icons.family_restroom_rounded, 'הגדרות משפחה', () {
                    Navigator.pop(ctx);
                    _showFamilySettingsDialog(context, budget);
                }, Colors.blue),
                
                _buildSettingsCard(ctx, Icons.person_off_outlined, 'ניהול ישויות דינמי (משתנות)', () {
                    Navigator.pop(ctx);
                    _showDynamicEntitiesDialog(context, budget);
                }, Colors.teal),
            
                _buildSettingsCard(ctx, Icons.pie_chart_outline, 'אחוז משתנות (רמת חיים)', () {
                    Navigator.pop(ctx);
                    _showRatioSettingsDialog(context, budget);
                }, Colors.orange),
                
                _buildSettingsCard(ctx, Icons.balance, 'חלוקת שארית (עתידיות/פיננסיות)', () {
                    Navigator.pop(ctx);
                    _showFutureVsFinancialDialog(context, budget);
                }, Colors.purple),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                
                _buildSettingsCard(ctx, Icons.logout, 'התנתקות מהחשבון', () async {
                    Navigator.pop(ctx);
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                    }
                }, Colors.blueGrey),
                
                _buildSettingsCard(ctx, Icons.restore, 'איפוס כל הנתונים', () {
                    Navigator.pop(ctx);
                    _showFactoryResetConfirm(context, budget);
                }, Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext ctx, IconData icon, String text, VoidCallback onTap, Color iconColor) {
    return Card(
      elevation: 0,
      color: iconColor.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: iconColor.withValues(alpha: 0.1))
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withValues(alpha: 0.15),
                radius: 18,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey[900])),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blueGrey[300]),
            ],
          ),
        ),
      ),
    );
  }

  void _showDynamicEntitiesDialog(BuildContext context, BudgetProvider budget) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('ניהול ישויות - משתנות', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('כיבוי ישות יאפס את התקציב שלה ויחלק אותו יחסית בין שאר הישויות הפעילות.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('תקציב אבא פעיל', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: budget.isFatherActive,
                  activeThumbColor: Colors.teal,
                  onChanged: (val) { budget.toggleEntityActive('father', val); setDialogState((){}); },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('תקציב אמא פעיל', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: budget.isMotherActive,
                  activeThumbColor: Colors.teal,
                  onChanged: (val) { budget.toggleEntityActive('mother', val); setDialogState((){}); },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('תקציב ילדים פעיל', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: budget.isKidsActive,
                  activeThumbColor: Colors.teal,
                  onChanged: (val) { budget.toggleEntityActive('kids', val); setDialogState((){}); },
                ),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('סגור'))],
          );
        },
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('חלוקת יתרת החיסכון', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        if (num >= 0 && num <= 100) { financialController.text = (100 - num).toStringAsFixed(0); }
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
                        if (num >= 0 && num <= 100) { futureController.text = (100 - num).toStringAsFixed(0); }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('הגדרת רמת חיים', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 16),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚠️ אזהרה: איפוס נתונים', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('פעולה זו תמחק הכל ותחזיר את האפליקציה למצב התחלתי. לא ניתן לבטל!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(color: Colors.blueGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await budget.fullAppReset();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('אפס הכל', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('הגדרות משפחה', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('סה"כ ילדים מעודכנים:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${budget.childCount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: budget.familyMembers.length,
                      itemBuilder: (context, index) {
                        final member = budget.familyMembers[index];
                        bool isParent = member.role == FamilyRole.parent;
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isParent ? Colors.blue[50] : Colors.purple[50], 
                              child: Icon(isParent ? Icons.person : Icons.child_care, color: isParent ? Colors.blue : Colors.purple)
                            ),
                            title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${isParent ? "הורה" : "ילד"} | שנת לידה: ${member.birthYear}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20), 
                                  onPressed: () => _showEditMemberDialog(context, budget, member, setDialogState)
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), 
                                  onPressed: () async { 
                                    if (member.id != null) { 
                                      await budget.removeFamilyMember(member.id!); 
                                      if (ctx.mounted) setDialogState(() {}); 
                                    } 
                                  }
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('הוסף בן משפחה'),
                      onPressed: () => _showEditMemberDialog(context, budget, null, setDialogState)
                    ),
                  ],
                ),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('סגור'))],
          );
        },
      ),
    );
  }

  void _showEditMemberDialog(BuildContext context, BudgetProvider budget, FamilyMember? member, Function parentState) {
    final nameController = TextEditingController(text: member?.name ?? '');
    final yearController = TextEditingController(text: member?.birthYear.toString() ?? DateTime.now().year.toString());
    FamilyRole selectedRole = member?.role ?? FamilyRole.child;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(member == null ? 'הוספת בן משפחה' : 'עריכת פרטים', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'שם מלא', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: yearController, decoration: const InputDecoration(labelText: 'שנת לידה (למשל 2015)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerRight, child: Text('הגדרת תפקיד:', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              SegmentedButton<FamilyRole>(
                segments: const [
                  ButtonSegment(value: FamilyRole.parent, label: Text('הורה'), icon: Icon(Icons.person)), 
                  ButtonSegment(value: FamilyRole.child, label: Text('ילד'), icon: Icon(Icons.child_care))
                ],
                selected: {selectedRole},
                onSelectionChanged: (val) => setDialogState(() => selectedRole = val.first),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () async { 
                if (nameController.text.isNotEmpty) { 
                  final birthYear = int.tryParse(yearController.text) ?? DateTime.now().year;
                  if (member == null) {
                    await budget.addFamilyMember(nameController.text, birthYear, selectedRole); 
                  } else {
                    await budget.updateFamilyMember(FamilyMember(id: member.id, name: nameController.text, birthYear: birthYear, role: selectedRole));
                  }
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
      ),
    );
  }
}