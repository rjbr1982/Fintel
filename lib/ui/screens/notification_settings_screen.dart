// 🔒 STATUS: EDITED (Fixed RoundedRectangleBorder parameter and Deprecated Switch color)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../widgets/global_header.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlobalHeader(title: 'ניהול התראות', showSavingsIcon: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'בחר אילו עדכונים תרצה לקבל מהמערכת ישירות למכשיר או לדפדפן שלך.',
            style: TextStyle(color: Colors.blueGrey, height: 1.5, fontSize: 14),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 24),
          
          _buildToggleCard(
            title: 'סיכום גלגול חודשי',
            subtitle: 'עדכון ב-1 לחודש על ביצוע ה-Rollover האוטומטי וסטטוס החסכונות.',
            icon: Icons.calendar_month,
            value: budget.notifMonthlyRollover,
            onChanged: (val) => budget.updateNotificationSetting('notif_monthly', val),
          ),
          
          _buildToggleCard(
            title: 'תזכורת יום משיכות',
            subtitle: 'התראה ביום הקבוע שהגדרת לביצוע משיכות פיזיות מהבנק.',
            icon: Icons.account_balance,
            value: budget.notifWithdrawalDay,
            onChanged: (val) => budget.updateNotificationSetting('notif_withdrawal', val),
          ),

          _buildToggleCard(
            title: 'רמזור קניות שבועי',
            subtitle: 'תזכורת להכנת רשימה (6 ימים מהקנייה האחרונה) והגנה על הדלתא.',
            icon: Icons.shopping_cart_checkout,
            value: budget.notifShoppingReminder,
            onChanged: (val) => budget.updateNotificationSetting('notif_shopping', val),
          ),

          _buildToggleCard(
            title: 'טיפים ועדכוני פרימיום',
            subtitle: 'מידע על פיצ\'רים חדשים וטיפים להאצת הדרך לחירות פיננסית.',
            icon: Icons.auto_awesome,
            value: budget.notifPremiumTeasers,
            onChanged: (val) => budget.updateNotificationSetting('notif_premium', val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({required String title, required String subtitle, required IconData icon, required bool value, required Function(bool) onChanged}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Colors.grey.shade200) // תוקן מ-border ל-side
      ),
      child: SwitchListTile(
        secondary: CircleAvatar(
          backgroundColor: const Color(0xFF00A3FF).withValues(alpha: 0.1), 
          child: Icon(icon, color: const Color(0xFF00A3FF), size: 22)
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        value: value,
        activeThumbColor: const Color(0xFF00A3FF), // תוקן מ-activeColor ל-activeThumbColor
        onChanged: onChanged,
      ),
    );
  }
}