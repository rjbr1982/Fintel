// 🔒 STATUS: EDITED (Added Notification Control Center Navigation & AppBar Actions support)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
import '../screens/academy_screen.dart'; 
import '../screens/admin_dashboard_screen.dart';
import '../screens/category_drilldown_screen.dart';
import '../screens/reducing_screen.dart';
import '../screens/assets_screen.dart';
import '../screens/notification_settings_screen.dart'; // 🔔 הזרקת מסך התראות

class GlobalHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final bool showSavingsIcon;
  final List<Widget>? actions; // 🔒 תמיכה ב-Actions מותאמים אישית (למשל פעמון התראות)

  const GlobalHeader({
    super.key,
    this.title,
    this.showBackButton = true,
    this.showSavingsIcon = true,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();
    final loc = AppLocalizations.of(context);
    final isRevealed = budget.hasCompletedGrandReveal;
    final canPop = Navigator.of(context).canPop() && isRevealed;

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
              width: 28, height: 28, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title ?? (loc?.get('appTitle') ?? 'דוחכם'),
                    style: title != null 
                      ? const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
                      : TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey[400]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.workspace_premium, color: Colors.amber, size: 18),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (actions != null) ...actions!, // הזרקת ה-Actions המותאמים אישית
        if (canPop)
          IconButton(
            icon: const Icon(Icons.dashboard_outlined, color: brandBlue),
            tooltip: 'חזרה לדשבורד',
            onPressed: () { Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false); },
          ),
        if (isRevealed)
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
              onPressed: () { Navigator.pop(context); onBack(); },
            )
          else const SizedBox(width: 48), 
          Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
          IconButton(icon: const Icon(Icons.close, color: Colors.blueGrey), onPressed: () => Navigator.pop(context)),
        ],
      ),
      const Divider(height: 1),
    ],
  );
}

int _adminTapCount = 0;
Timer? _adminTapTimer;
const String _masterPin = "0511820511";

void _handleAdminTap(BuildContext context) {
  _adminTapCount++;
  if (_adminTapTimer?.isActive ?? false) { _adminTapTimer!.cancel(); }
  _adminTapTimer = Timer(const Duration(seconds: 2), () { _adminTapCount = 0; });
  if (_adminTapCount >= 5) {
    _adminTapCount = 0; _adminTapTimer?.cancel();
    Navigator.pop(context); _showAdminPinDialog(context);
  }
}

void _showAdminPinDialog(BuildContext context) {
  final TextEditingController pinController = TextEditingController();
  final ValueNotifier<bool> hasError = ValueNotifier(false);
  showDialog(
    context: context, barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: const Center(child: Text('Fintel Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('הזן קוד מאסטר:', style: TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: hasError,
            builder: (context, error, child) {
              return TextField(
                controller: pinController, obscureText: true, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                style: const TextStyle(letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.grey.shade100, errorText: error ? 'קוד שגוי' : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (_) => hasError.value = false,
              );
            }
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(color: Colors.blueGrey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () {
            if (pinController.text == _masterPin) {
              Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('קוד מאושר. מתחבר לשרת...'), backgroundColor: Colors.green));
            } else { hasError.value = true; pinController.clear(); }
          },
          child: const Text('התחבר', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

void _showMainMenuBottomSheet(BuildContext context, BudgetProvider budget, bool showSavings) {
  showModalBottomSheet(
    context: context, backgroundColor: Colors.white, isScrollControlled: true,
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
                _buildExpansionMenuTile(
                  icon: Icons.account_balance_wallet, color: Colors.blue, title: 'תזרים פיננסי (PnL)',
                  children: [
                    _buildSubMenuTile('מסך תזרים ראשי', Icons.dashboard, () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const PnLScreen())); }),
                    _buildSubMenuTile('הכנסות', Icons.arrow_downward, () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryDrilldownScreen(mainCategory: 'הכנסות', displayTitle: 'הכנסות'))); }),
                    _buildSubMenuTile('קבועות', Icons.push_pin, () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryDrilldownScreen(mainCategory: 'קבועות', displayTitle: 'קבועות'))); }),
                    _buildSubMenuTile('מנמיכות', Icons.trending_down, () { Navigator.pop(ctx); PremiumService.requirePremium(context, () { Navigator.push(context, MaterialPageRoute(builder: (_) => const ReducingScreen())); }); }, isPremium: true),
                    _buildSubMenuTile('משתנות', Icons.shopping_bag_outlined, () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryDrilldownScreen(mainCategory: 'משתנות', displayTitle: 'משתנות'))); }),
                    _buildSubMenuTile('עתידיות', Icons.savings_outlined, () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryDrilldownScreen(mainCategory: 'עתידיות', displayTitle: 'עתידיות'))); }),
                    _buildSubMenuTile('פיננסיות', Icons.trending_up, () { Navigator.pop(ctx); PremiumService.requirePremium(context, () { Navigator.push(context, MaterialPageRoute(builder: (_) => const AssetsScreen())); }); }, isPremium: true),
                  ]
                ),
                _buildMenuTile(icon: Icons.shopping_cart_outlined, color: Colors.blueGrey[900]!, title: 'רשימת קניות', onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingScreen())); }),
                if (showSavings) _buildMenuTile(icon: Icons.savings_outlined, color: Colors.green, title: 'מרכז החסכונות', onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const SinkingFundsScreen())); }),
                _buildMenuTile(icon: Icons.account_balance_wallet_outlined, color: Colors.blueGrey, title: 'מעקב עו"ש', onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckingHistoryScreen())); }),
                _buildMenuTile(icon: Icons.insights, color: Colors.orange, title: 'ממוצע שכר', isPremium: true, onTap: () { Navigator.pop(ctx); PremiumService.requirePremium(context, () { Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryEngineScreen())); }); }),
                
                // 🔔 שורת ההתראות החדשה
                _buildMenuTile(icon: Icons.notifications_active_outlined, color: Colors.blueAccent, title: 'ניהול התראות', onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())); }),

                const Divider(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
                  child: _buildMenuTile(icon: Icons.school, color: Colors.amber[800]!, title: 'אקדמיית Fintel - פרקטיקת השימוש', isPremium: true, onTap: () { Navigator.pop(ctx); PremiumService.requirePremium(context, () { Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademyScreen())); }); }),
                ),
                _buildMenuTile(icon: Icons.content_copy, color: Colors.deepPurple, title: 'ייצוא דוח פיננסי (טקסט)', isPremium: true, onTap: () { Navigator.pop(ctx); PremiumService.requirePremium(context, () async { await AiExportService.generateAndCopy(context); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('הנתונים הועתקו בהצלחה! ניתן להדביק בצ\'אט עם ה-AI או במסמך.'), backgroundColor: Colors.green)); } }); }),
                _buildMenuTile(icon: Icons.settings, color: Colors.grey.shade700, title: 'הגדרות מערכת', onTap: () { Navigator.pop(ctx); _showMainSettingsBottomSheet(context, budget, showSavings); }),
                _buildMenuTile(icon: Icons.shield_outlined, color: Colors.teal, title: 'תמיכה ומשפטי', onTap: () { Navigator.pop(ctx); _showSupportBottomSheet(context, budget, showSavings); }),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40, width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          String versionText = snapshot.hasData ? 'v${snapshot.data!.version}' : '';
                          return Text('© 2026 Fintel - כל הזכויות שמורות\n$versionText', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.5));
                        }
                      ),
                      Positioned(right: 20, top: 0, bottom: 0, width: 60, child: GestureDetector(onTap: () => _handleAdminTap(context), behavior: HitTestBehavior.opaque, child: Container(color: Colors.transparent))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMenuTile({required IconData icon, required Color color, required String title, required VoidCallback onTap, bool isPremium = false, Widget? trailing}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 22)),
    title: Row(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)), if (isPremium) ...[const SizedBox(width: 8), const Icon(Icons.workspace_premium, color: Colors.amber, size: 18)]]),
    trailing: trailing, onTap: onTap,
  );
}

Widget _buildExpansionMenuTile({required IconData icon, required Color color, required String title, required List<Widget> children}) {
  return Theme(
    data: ThemeData(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
      childrenPadding: const EdgeInsets.only(right: 56, left: 24, bottom: 8),
      children: children,
    ),
  );
}

Widget _buildSubMenuTile(String title, IconData icon, VoidCallback onTap, {bool isPremium = false}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [Icon(icon, size: 18, color: Colors.blueGrey[600]), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)), if (isPremium) ...[const SizedBox(width: 8), const Icon(Icons.workspace_premium, color: Colors.amber, size: 16)]]),
    ),
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
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.chat_bubble_outline, color: Colors.green)),
                  title: const Text('פנו אלינו ב-WhatsApp', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  onTap: () async { Navigator.pop(ctx); const String waUrl = 'https://wa.me/972559323615'; try { await launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication); } catch (e) { Clipboard.setData(const ClipboardData(text: '+972-55-932-3615')); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('לא הצלחנו לפתוח את WhatsApp, המספר הועתק ללוח!'), backgroundColor: Colors.blueGrey, duration: Duration(seconds: 4))); } } },
                ),
                const Divider(height: 1, indent: 70),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.mail_outline, color: Colors.blue)),
                  title: const Text('פנו אלינו באימייל', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  onTap: () async { Navigator.pop(ctx); final String emailUrl = 'mailto:fintel.app.info@gmail.com?subject=${Uri.encodeComponent("פידבק על אפליקציית דוחכם")}'; try { await launchUrl(Uri.parse(emailUrl), mode: LaunchMode.externalApplication); } catch (e) { Clipboard.setData(const ClipboardData(text: 'fintel.app.info@gmail.com')); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('לא הצלחנו לפתוח את אפליקציית הדואר, הכתובת הועתקה ללוח!'), backgroundColor: Colors.blueGrey, duration: Duration(seconds: 4))); } } },
                ),
                const Divider(height: 1, indent: 70),
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.orange.shade50, child: Icon(Icons.description_outlined, color: Colors.orange.shade700)),
                  title: const Text('תנאי שימוש', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  onTap: () { Navigator.pop(ctx); _showLegalBottomSheet(context: context, budget: budget, showSavings: showSavings, title: 'תנאי שימוש', icon: Icons.description_outlined, iconColor: Colors.orange.shade700, content: '''1. הסכמה לתנאים: השימוש באפליקציית Fintel ("האפליקציה") מהווה את הסכמתך המלאה לתנאים המפורטים להלן ולמדיניות הפרטיות...'''); },
                ),
                const Divider(height: 1, indent: 70),
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: Icon(Icons.lock_outline, color: Colors.green.shade700)),
                  title: const Text('מדיניות פרטיות', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  onTap: () { Navigator.pop(ctx); _showLegalBottomSheet(context: context, budget: budget, showSavings: showSavings, title: 'מדיניות פרטיות', icon: Icons.lock_outline, iconColor: Colors.green.shade700, content: '''1. איסוף מידע וסנכרון ענן: המערכת פועלת באמצעות טכנולוגיית סנכרון ענן...'''); },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showLegalBottomSheet({required BuildContext context, required BudgetProvider budget, required bool showSavings, required String title, required IconData icon, required Color iconColor, required String content}) {
  showModalBottomSheet(
    context: context, backgroundColor: Colors.white, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomSheetHeader(ctx, title, () => _showSupportBottomSheet(context, budget, showSavings)),
            Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Icon(icon, color: iconColor, size: 28), const SizedBox(width: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87))]), const SizedBox(height: 16), Text(content, style: const TextStyle(height: 1.6, fontSize: 14, color: Colors.black87), textAlign: TextAlign.right, textDirection: TextDirection.rtl), const SizedBox(height: 32), const Center(child: Text('© 2026 Fintel - כל הזכויות שמורות.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)))]))),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildUserProfileCard(context, user)),
                  if (!kIsWeb) Consumer<BudgetProvider>(builder: (context, budgetProv, child) { return _buildMenuTile(icon: Icons.fingerprint, color: Colors.teal, title: 'כניסה ביומטרית', trailing: Switch(value: budgetProv.useBiometric, activeThumbColor: Colors.teal, onChanged: (val) { budgetProv.toggleBiometric(val); }), onTap: () { budgetProv.toggleBiometric(!budgetProv.useBiometric); }); }),
                  _buildMenuTile(icon: Icons.family_restroom_rounded, color: Colors.blue, title: 'הגדרות משפחה וסטטוס', onTap: () { Navigator.pop(ctx); _showFamilySettingsBottomSheet(context, budget, showSavings); }),
                  _buildMenuTile(icon: Icons.pie_chart_outline, color: Colors.orange, title: 'אחוז משתנות (רמת חיים)', onTap: () { Navigator.pop(ctx); _showRatioSettingsBottomSheet(context, budget, showSavings); }),
                  _buildMenuTile(icon: Icons.balance, color: Colors.purple, title: 'חלוקת שארית (עתידיות/פיננסיות)', onTap: () { Navigator.pop(ctx); _showFutureVsFinancialBottomSheet(context, budget, showSavings); }),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                  _buildMenuTile(icon: Icons.restore, color: Colors.red, title: 'איפוס כל הנתונים', onTap: () { Navigator.pop(ctx); _showFactoryResetConfirm(context, budget); }),
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
        Row(children: [CircleAvatar(radius: 24, backgroundColor: Colors.blueGrey.shade200, backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null, child: user.photoURL == null ? const Icon(Icons.person, size: 30, color: Colors.white) : null), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.displayName ?? 'משתמש דוחכם', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), const SizedBox(height: 4), Text(user.email ?? '', style: TextStyle(fontSize: 13, color: Colors.blueGrey[700]))]))]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), icon: const Icon(Icons.logout, size: 18), label: const Text('התנתקות מהחשבון', style: TextStyle(fontWeight: FontWeight.bold)), onPressed: () async { Navigator.pop(context); try { await GoogleSignIn().disconnect(); } catch (_) {} try { await GoogleSignIn().signOut(); } catch (_) {} await FirebaseAuth.instance.signOut(); if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false); })),
      ],
    ),
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
              child: Column(children: [const Text('קבע איך תחולק השארית לאחר המשתנות.', style: TextStyle(fontSize: 14, color: Colors.grey)), const SizedBox(height: 20), Row(children: [Expanded(child: TextField(controller: futureController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold), decoration: _customInputDecoration('עתידיות'), onChanged: (val) { final num = double.tryParse(val) ?? 0; if (num >= 0 && num <= 100) { financialController.text = (100 - num).toStringAsFixed(0); } })), const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.compare_arrows)), Expanded(child: TextField(controller: financialController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold), decoration: _customInputDecoration('פיננסיות'), onChanged: (val) { final num = double.tryParse(val) ?? 0; if (num >= 0 && num <= 100) { futureController.text = (100 - num).toStringAsFixed(0); } }))]), const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { final val = double.tryParse(futureController.text); if (val != null) { budget.setAllocationRatios(future: val / 100); Navigator.pop(ctx); _showMainSettingsBottomSheet(context, budget, showSavings); } }, child: const Text('עדכן חלוקה', style: TextStyle(fontSize: 16))))]),
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
              child: Column(children: [const Text('אחוז מההכנסה הפנויה להוצאות משתנות.', style: TextStyle(fontSize: 14, color: Colors.grey)), const SizedBox(height: 20), TextField(controller: controller, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _customInputDecoration('אחוז הקצאה')), const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { final val = double.tryParse(controller.text); if (val != null && val > 0 && val <= 100) { budget.setAllocationRatios(variable: val / 100); Navigator.pop(ctx); _showMainSettingsBottomSheet(context, budget, showSavings); } }, child: const Text('שמור', style: TextStyle(fontSize: 16))))]),
            ),
          ],
        ),
      ),
    ),
  );
}

InputDecoration _customInputDecoration(String label) { return InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.black87), suffixText: '%', filled: true, fillColor: Colors.white, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)); }

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
              child: Consumer<BudgetProvider>(builder: (context, budgetProvider, child) {
                final adults = budgetProvider.familyMembers.where((m) => m.role != FamilyRole.child).toList();
                return Column(children: [
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueGrey.shade100)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('המגדר שלי:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)), const SizedBox(height: 8), SegmentedButton<String>(style: SegmentedButton.styleFrom(selectedForegroundColor: Colors.blue[900], selectedBackgroundColor: Colors.blue[100], foregroundColor: Colors.blueGrey[400]), segments: const [ButtonSegment(value: 'male', label: Text('זכר')), ButtonSegment(value: 'female', label: Text('נקבה'))], selected: {budgetProvider.gender}, onSelectionChanged: (val) { budgetProvider.updateFamilyStructure(gender: val.first); }), const SizedBox(height: 20), const Text('סטטוס אישי:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)), const SizedBox(height: 8), SegmentedButton<String>(style: SegmentedButton.styleFrom(selectedForegroundColor: Colors.blue[900], selectedBackgroundColor: Colors.blue[100], foregroundColor: Colors.blueGrey[400]), segments: const [ButtonSegment(value: 'single', icon: Icon(Icons.person), label: Text('רווק/ה')), ButtonSegment(value: 'married', icon: Icon(Icons.people), label: Text('נשוי/אה'))], selected: {budgetProvider.maritalStatus}, onSelectionChanged: (val) { budgetProvider.updateFamilyStructure(maritalStatus: val.first); })])),
                  const SizedBox(height: 24),
                  if (adults.isNotEmpty) ...[const Align(alignment: Alignment.centerRight, child: Text('הורים / מנהלי תקציב:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16))), const SizedBox(height: 12), ...adults.map((member) => Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.shade200)), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.person, color: Colors.blue)), title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), subtitle: Text('שנת לידה: ${member.birthYear}', style: const TextStyle(color: Colors.black54)), trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20), onPressed: () { Navigator.pop(ctx); _showEditMemberBottomSheet(context, budgetProvider, member, showSavings); }))))],
                  const SizedBox(height: 16), const Divider(), const SizedBox(height: 16),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('סה"כ ילדים רשומים:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)), Text('${budgetProvider.childCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue))])),
                  const SizedBox(height: 16),
                  if (budgetProvider.childCount > 0) ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: budgetProvider.familyMembers.where((m) => m.role == FamilyRole.child).length, itemBuilder: (context, index) { final childrenList = budgetProvider.familyMembers.where((m) => m.role == FamilyRole.child).toList(); final member = childrenList[index]; return Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.purple[50], child: const Icon(Icons.child_care, color: Colors.purple)), title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), subtitle: Text('שנת לידה: ${member.birthYear}', style: const TextStyle(color: Colors.black54)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20), onPressed: () { Navigator.pop(ctx); _showEditMemberBottomSheet(context, budgetProvider, member, showSavings); }), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () async { if (member.id != null) { await budgetProvider.removeFamilyMember(member.id!); } })]))); }),
                  const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.blueGrey[900], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: const Icon(Icons.person_add, size: 20), label: const Text('הוסף ילד/ה', style: TextStyle(fontSize: 16)), onPressed: () { Navigator.pop(ctx); _showEditMemberBottomSheet(context, budgetProvider, null, showSavings); })),
                ]);
              }),
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
              child: Column(children: [TextField(controller: nameController, style: const TextStyle(color: Colors.black87), decoration: InputDecoration(labelText: nameLabel, labelStyle: const TextStyle(color: Colors.black87), border: const OutlineInputBorder())), const SizedBox(height: 16), TextField(controller: yearController, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'שנת לידה (למשל 1990)', labelStyle: TextStyle(color: Colors.black87), border: OutlineInputBorder()), keyboardType: TextInputType.number), const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { if (nameController.text.isNotEmpty) { final birthYear = int.tryParse(yearController.text) ?? DateTime.now().year; if (member == null) { await budget.addFamilyMember(nameController.text, birthYear, roleToSave); } else { await budget.updateFamilyMember(FamilyMember(id: member.id, name: nameController.text, birthYear: birthYear, role: roleToSave)); } if (ctx.mounted) { Navigator.pop(ctx); _showFamilySettingsBottomSheet(context, budget, showSavings); } } }, child: const Text('שמור שינויים', style: TextStyle(fontSize: 16))))]),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showFactoryResetConfirm(BuildContext context, BudgetProvider budget) {
  showDialog(
    context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), backgroundColor: Colors.white,
      title: const Text('⚠️ אזהרה: איפוס נתונים', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      content: const Text('פעולה זו תמחק הכל ותחזיר את האפליקציה למצב התחלתי. לא ניתן לבטל!', style: TextStyle(color: Colors.black87)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(color: Colors.blueGrey))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async { await budget.fullAppReset(); if (ctx.mounted) { Navigator.pop(ctx); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const OnboardingScreen()), (route) => false); } }, child: const Text('אפס הכל', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))],
    ),
  );
}