// 🔒 STATUS: EDITED (Reorganized Hamburger Menu for Logical Flow)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/budget_provider.dart';
import '../../data/expense_model.dart';
import '../../utils/app_localizations.dart';
import '../../services/ai_export_service.dart';
import '../../services/premium_service.dart';
import '../screens/onboarding_screen.dart';
import '../screens/sinking_funds_screen.dart';
import '../screens/checking_history_screen.dart';
import '../screens/salary_engine_screen.dart';
import '../screens/shopping_screen.dart';
import '../screens/pnl_screen.dart';
import '../../main.dart'; 

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
              'assets/icon/Fintel_Icon.png', 
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
        
        IconButton(
          icon: const Icon(Icons.menu, color: brandBlue, size: 28),
          tooltip: 'תפריט ראשי',
          onPressed: () => _showMainMenuBottomSheet(context, budget, showSavingsIcon),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

Widget _buildBottomSheetHeader(BuildContext context, String title, VoidCallback? onBack) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 12),
      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
      const SizedBox(height: 8),
      Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.blueGrey), 
              onPressed: () {
                Navigator.pop(context); 
                onBack(); 
              },
            )
          else
            const SizedBox(width: 48), 
          
          Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
          
          IconButton(icon: const Icon(Icons.close, color: Colors.blueGrey), onPressed: () => Navigator.pop(context)),
        ],
      ),
      const Divider(height: 1),
    ],
  );
}

void _showMainMenuBottomSheet(BuildContext context, BudgetProvider budget, bool showSavings) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHeader(ctx, 'תפריט ראשי', null),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // --- קבוצה 1: פעולות שוטפות ---
                _buildMenuTile(
                  icon: Icons.shopping_cart_outlined, color: Colors.blueGrey[900]!, title: 'רשימת קניות',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingScreen()));
                  },
                ),
                _buildMenuTile(
                  icon: Icons.account_balance_wallet, color: Colors.blue, title: 'תזרים פיננסי (PnL)',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PnLScreen()));
                  },
                ),
                if (showSavings)
                  _buildMenuTile(
                    icon: Icons.savings_outlined, color: Colors.green, title: 'מרכז החסכונות',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SinkingFundsScreen()));
                    },
                  ),
                
                const Divider(), // מפריד קבוצות

                // --- קבוצה 2: בקרה וניתוח ---
                _buildMenuTile(
                  icon: Icons.account_balance_wallet_outlined, color: Colors.blueGrey, title: 'מעקב עו"ש',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckingHistoryScreen()));
                  },
                ),
                _buildMenuTile(
                  icon: Icons.insights, color: Colors.orange, title: 'ממוצע שכר', isPremium: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    PremiumService.requirePremium(context, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryEngineScreen()));
                    });
                  },
                ),
                _buildMenuTile(
                  icon: Icons.psychology, color: Colors.deepPurple, title: 'ייצוא נתונים ל-AI', isPremium: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    PremiumService.requirePremium(context, () async {
                      await AiExportService.generateAndCopy(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('הנתונים הועתקו בהצלחה! ניתן להדביק בצ\'אט עם ה-AI.'), backgroundColor: Colors.green),
                        );
                      }
                    });
                  },
                ),

                const Divider(), // מפריד קבוצות

                // --- קבוצה 3: הגדרות ושונות ---
                _buildMenuTile(
                  icon: Icons.settings, color: Colors.grey.shade700, title: 'הגדרות מערכת',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMainSettingsBottomSheet(context, budget, showSavings);
                  },
                ),
                _buildMenuTile(
                  icon: Icons.shield_outlined, color: Colors.teal, title: 'תמיכה ומשפטי',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSupportBottomSheet(context, budget, showSavings);
                  },
                ),

                const SizedBox(height: 16),
                const Text('© 2026 Fintel - כל הזכויות שמורות\nv1.0.0', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMenuTile({required IconData icon, required Color color, required String title, required VoidCallback onTap, bool isPremium = false}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 22)),
    title: Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
        if (isPremium) ...[
          const SizedBox(width: 8),
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 18),
        ]
      ],
    ),
    onTap: onTap,
  );
}

void _showSupportBottomSheet(BuildContext context, BudgetProvider budget, bool showSavings) {
  showModalBottomSheet(
    context: context, backgroundColor: Colors.white, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHeader(ctx, 'תמיכה ומשפטי', () => _showMainMenuBottomSheet(context, budget, showSavings)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.mail_outline, color: Colors.blue)),
                  title: const Text('פנו אלינו באימייל', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final String emailUrl = 'mailto:fintel.app.info@gmail.com?subject=${Uri.encodeComponent("פידבק על אפליקציית דוחכם")}';
                    
                    try {
                      await launchUrl(Uri.parse(emailUrl), mode: LaunchMode.externalApplication);
                    } catch (e) {
                      Clipboard.setData(const ClipboardData(text: 'fintel.app.info@gmail.com'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('לא הצלחנו לפתוח את אפליקציית הדואר, הכתובת הועתקה ללוח!'),
                            backgroundColor: Colors.blueGrey, duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, indent: 70),
                
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.orange.shade50, child: Icon(Icons.description_outlined, color: Colors.orange.shade700)),
                  title: const Text('תנאי שימוש', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showLegalBottomSheet(
                      context: context, budget: budget, showSavings: showSavings,
                      title: 'תנאי שימוש', icon: Icons.description_outlined, iconColor: Colors.orange.shade700,
                      content: 'האפליקציה מהווה כלי עזר חישובי בלבד לניהול תקציב אישי. המידע, התחזיות והחישובים (כולל מנוע החירות וחיסול החובות) אינם מהווים ייעוץ פנסיוני, ייעוץ השקעות או ייעוץ מס. קבלת החלטות פיננסיות על בסיס האפליקציה היא על אחריות המשתמש בלבד. האפליקציה מסופקת (As-Is) בגרסת הרצה (Beta).',
                    );
                  },
                ),
                const Divider(height: 1, indent: 70),
                
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: Icon(Icons.lock_outline, color: Colors.green.shade700)),
                  title: const Text('מדיניות פרטיות', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showLegalBottomSheet(
                      context: context, budget: budget, showSavings: showSavings,
                      title: 'מדיניות פרטיות', icon: Icons.lock_outline, iconColor: Colors.green.shade700,
                      content: 'הנתונים שלך, בשליטתך: כל הנתונים הפיננסיים מוזנים מרצונך ומיועדים אך ורק לחישוב התזרים שלך באפליקציה. המידע נשמר בענן המאובטח של Google (Firebase). איש מצוות המפתחים אינו קורא או מנתח את נתוניך האישיים. אנו מתחייבים לא למכור, להעביר או לשתף את הנתונים עם שום צד שלישי. ניתן למחוק את כל המידע בכל עת דרך תפריט ההגדרות.',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showLegalBottomSheet({
  required BuildContext context, required BudgetProvider budget, required bool showSavings,
  required String title, required IconData icon, required Color iconColor, required String content
}) {
  showModalBottomSheet(
    context: context, backgroundColor: Colors.white, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHeader(ctx, title, () => _showSupportBottomSheet(context, budget, showSavings)),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 28),
                    const SizedBox(width: 12),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(content, style: const TextStyle(height: 1.6, fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 32),
                const Center(child: Text('© 2026 Fintel - כל הזכויות שמורות.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54))),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showMainSettingsBottomSheet(BuildContext context, BudgetProvider budget, bool showSavings) {
  final user = FirebaseAuth.instance.currentUser;

  showModalBottomSheet(
    context: context, backgroundColor: Colors.white, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHeader(ctx, 'הגדרות מערכת', () => _showMainMenuBottomSheet(context, budget, showSavings)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user != null) _buildUserProfileCard(context, user),

                  if (!kIsWeb)
                    Consumer<BudgetProvider>(
                      builder: (context, budgetProv, child) {
                        return Card(
                          elevation: 0, color: Colors.teal.withValues(alpha: 0.05), margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.teal.withValues(alpha: 0.1))),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text('כניסה ביומטרית', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey[900])),
                            secondary: CircleAvatar(backgroundColor: Colors.teal.withValues(alpha: 0.15), radius: 18, child: const Icon(Icons.fingerprint, color: Colors.teal, size: 20)),
                            value: budgetProv.useBiometric, activeThumbColor: Colors.teal, 
                            onChanged: (val) { budgetProv.toggleBiometric(val); },
                          ),
                        );
                      }
                    ),

                  _buildSettingsCard(ctx, Icons.family_restroom_rounded, 'הגדרות משפחה וסטטוס', () {
                      Navigator.pop(ctx);
                      _showFamilySettingsBottomSheet(context, budget, showSavings);
                  }, Colors.blue),
              
                  _buildSettingsCard(ctx, Icons.pie_chart_outline, 'אחוז משתנות (רמת חיים)', () {
                      Navigator.pop(ctx);
                      _showRatioSettingsBottomSheet(context, budget, showSavings);
                  }, Colors.orange),
                  
                  _buildSettingsCard(ctx, Icons.balance, 'חלוקת שארית (עתידיות/פיננסיות)', () {
                      Navigator.pop(ctx);
                      _showFutureVsFinancialBottomSheet(context, budget, showSavings);
                  }, Colors.purple),
                  
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  
                  _buildSettingsCard(ctx, Icons.restore, 'איפוס כל הנתונים', () {
                      Navigator.pop(ctx);
                      _showFactoryResetConfirm(context, budget); 
                  }, Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildUserProfileCard(BuildContext context, User user) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueGrey.shade100)),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24, backgroundColor: Colors.blueGrey.shade200,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null ? const Icon(Icons.person, size: 30, color: Colors.white) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName ?? 'משתמש דוחכם', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(user.email ?? '', style: TextStyle(fontSize: 13, color: Colors.blueGrey[700])),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('התנתקות מהחשבון', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context); 
              AppGlobals.resetSession();
              try { await GoogleSignIn().disconnect(); } catch (e) { debugPrint('Google disconnect error: $e'); }
              try { await GoogleSignIn().signOut(); } catch (e) { debugPrint('Google SignOut error: $e'); }
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
            },
          ),
        )
      ],
    ),
  );
}

Widget _buildSettingsCard(BuildContext ctx, IconData icon, String text, VoidCallback onTap, Color iconColor) {
  return Card(
    elevation: 0, color: iconColor.withValues(alpha: 0.05), margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: iconColor.withValues(alpha: 0.1))),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: iconColor.withValues(alpha: 0.15), radius: 18, child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey[900]))),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blueGrey[300]),
          ],
        ),
      ),
    ),
  );
}

InputDecoration _customInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.black87),
    suffixText: '%',
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

void _showFutureVsFinancialBottomSheet(BuildContext context, BudgetProvider budget, bool showSavings) {
  final futureRatio = budget.futureAllocationRatio;
  final futureController = TextEditingController(text: (futureRatio * 100).toStringAsFixed(0));
  final financialController = TextEditingController(text: ((1 - futureRatio) * 100).toStringAsFixed(0));

  showModalBottomSheet(
    context: context, backgroundColor: Colors.white, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomSheetHeader(ctx, 'חלוקת יתרת החיסכון', () => _showMainSettingsBottomSheet(context, budget, showSavings)),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('קבע איך תחולק השארית לאחר המשתנות.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: futureController, keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                          decoration: _customInputDecoration('עתידיות'),
                          onChanged: (val) {
                            final num = double.tryParse(val) ?? 0;
                            if (num >= 0 && num <= 100) { financialController.text = (100 - num).toStringAsFixed(0); }
                          },
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.compare_arrows)),
                      Expanded(
                        child: TextField(
                          controller: financialController, keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                          decoration: _customInputDecoration('פיננסיות'),
                          onChanged: (val) {
                            final num = double.tryParse(val) ?? 0;
                            if (num >= 0 && num <= 100) { futureController.text = (100 - num).toStringAsFixed(0); }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        final val = double.tryParse(futureController.text);
                        if (val != null) {
                          budget.setAllocationRatios(future: val / 100);
                          Navigator.pop(ctx);
                          _showMainSettingsBottomSheet(context, budget, showSavings);
                        }
                      },
                      child: const Text('עדכן חלוקה', style: TextStyle(fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showRatioSettingsBottomSheet(BuildContext context, BudgetProvider budget, bool showSavings) {
  final controller = TextEditingController(text: (budget.variableAllocationRatio * 100).toStringAsFixed(1));
  
  showModalBottomSheet(
    context: context, backgroundColor: Colors.white, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomSheetHeader(ctx, 'הגדרת רמת חיים', () => _showMainSettingsBottomSheet(context, budget, showSavings)),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('אחוז מההכנסה הפנויה להוצאות משתנות.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller, 
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                    decoration: _customInputDecoration('אחוז הקצאה'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        final val = double.tryParse(controller.text);
                        if (val != null && val > 0 && val <= 100) {
                          budget.setAllocationRatios(variable: val / 100);
                          Navigator.pop(ctx);
                          _showMainSettingsBottomSheet(context, budget, showSavings);
                        }
                      },
                      child: const Text('שמור', style: TextStyle(fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showFamilySettingsBottomSheet(BuildContext context, BudgetProvider budget, bool showSavings) {
  showModalBottomSheet(
    context: context, backgroundColor: Colors.white, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHeader(ctx, 'הגדרות משפחה וסטטוס', () => _showMainSettingsBottomSheet(context, budget, showSavings)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Consumer<BudgetProvider>(
                builder: (context, budgetProvider, child) {
                  final adults = budgetProvider.familyMembers.where((m) => m.role != FamilyRole.child).toList();
                  
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueGrey.shade100)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('המגדר שלי:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              style: SegmentedButton.styleFrom(selectedForegroundColor: Colors.blue[900], selectedBackgroundColor: Colors.blue[100], foregroundColor: Colors.blueGrey[400]),
                              segments: const [ButtonSegment(value: 'male', label: Text('זכר')), ButtonSegment(value: 'female', label: Text('נקבה'))],
                              selected: {budgetProvider.gender},
                              onSelectionChanged: (val) { budgetProvider.updateFamilyStructure(gender: val.first); },
                            ),
                            const SizedBox(height: 20),
                            const Text('סטטוס אישי:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              style: SegmentedButton.styleFrom(selectedForegroundColor: Colors.blue[900], selectedBackgroundColor: Colors.blue[100], foregroundColor: Colors.blueGrey[400]),
                              segments: const [ButtonSegment(value: 'single', icon: Icon(Icons.person), label: Text('רווק/ה')), ButtonSegment(value: 'married', icon: Icon(Icons.people), label: Text('נשוי/אה'))],
                              selected: {budgetProvider.maritalStatus},
                              onSelectionChanged: (val) { budgetProvider.updateFamilyStructure(maritalStatus: val.first); },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      if (adults.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text('הורים / מנהלי תקציב:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                        ),
                        const SizedBox(height: 12),
                        ...adults.map((member) => Card(
                          elevation: 0, color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.shade200)),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.person, color: Colors.blue)),
                            title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            subtitle: Text('שנת לידה: ${member.birthYear}', style: const TextStyle(color: Colors.black54)),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showEditMemberBottomSheet(context, budgetProvider, member, showSavings);
                              },
                            ),
                          ),
                        )),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                      ],

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('סה"כ ילדים רשומים:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                            Text('${budgetProvider.childCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (budgetProvider.childCount > 0)
                        ListView.builder(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                          itemCount: budgetProvider.familyMembers.where((m) => m.role == FamilyRole.child).length,
                          itemBuilder: (context, index) {
                            final childrenList = budgetProvider.familyMembers.where((m) => m.role == FamilyRole.child).toList();
                            final member = childrenList[index];
                            return Card(
                              elevation: 0, color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: Colors.purple[50], child: const Icon(Icons.child_care, color: Colors.purple)),
                                title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                subtitle: Text('שנת לידה: ${member.birthYear}', style: const TextStyle(color: Colors.black54)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20), onPressed: () {
                                      Navigator.pop(ctx);
                                      _showEditMemberBottomSheet(context, budgetProvider, member, showSavings);
                                    }),
                                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () async { if (member.id != null) { await budgetProvider.removeFamilyMember(member.id!); } }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.blueGrey[900], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          icon: const Icon(Icons.person_add, size: 20),
                          label: const Text('הוסף ילד/ה', style: TextStyle(fontSize: 16)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showEditMemberBottomSheet(context, budgetProvider, null, showSavings);
                          }
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showEditMemberBottomSheet(BuildContext context, BudgetProvider budget, FamilyMember? member, bool showSavings) {
  final nameController = TextEditingController(text: member?.name ?? '');
  final yearController = TextEditingController(text: member?.birthYear.toString() ?? DateTime.now().year.toString());
  
  final isAdult = member != null && member.role != FamilyRole.child;
  final titleText = member == null ? 'הוספת ילד/ה' : (isAdult ? 'עריכת פרטי הורה' : 'עריכת פרטי ילד');
  final nameLabel = member == null ? 'שם הילד/ה' : (isAdult ? 'שם ההורה' : 'שם הילד/ה');
  final roleToSave = member?.role ?? FamilyRole.child; 

  showModalBottomSheet(
    context: context, backgroundColor: Colors.white, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomSheetHeader(ctx, titleText, () => _showFamilySettingsBottomSheet(context, budget, showSavings)),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextField(
                    controller: nameController, 
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(labelText: nameLabel, labelStyle: const TextStyle(color: Colors.black87), border: const OutlineInputBorder())
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: yearController, 
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(labelText: 'שנת לידה (למשל 1990)', labelStyle: TextStyle(color: Colors.black87), border: OutlineInputBorder()), 
                    keyboardType: TextInputType.number
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async { 
                        if (nameController.text.isNotEmpty) { 
                          final birthYear = int.tryParse(yearController.text) ?? DateTime.now().year;
                          if (member == null) {
                            await budget.addFamilyMember(nameController.text, birthYear, roleToSave); 
                          } else {
                            await budget.updateFamilyMember(FamilyMember(id: member.id, name: nameController.text, birthYear: birthYear, role: roleToSave));
                          }
                          if (ctx.mounted) { 
                            Navigator.pop(ctx); 
                            _showFamilySettingsBottomSheet(context, budget, showSavings); 
                          }
                        } 
                      }, 
                      child: const Text('שמור שינויים', style: TextStyle(fontSize: 16))
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showFactoryResetConfirm(BuildContext context, BudgetProvider budget) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: const Text('⚠️ אזהרה: איפוס נתונים', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      content: const Text('פעולה זו תמחק הכל ותחזיר את האפליקציה למצב התחלתי. לא ניתן לבטל!', style: TextStyle(color: Colors.black87)),
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