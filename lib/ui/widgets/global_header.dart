// 🔒 STATUS: EDITED (Fixed showBackButton missing parameter and correctly handled Drawer action)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../main.dart'; 
import '../../data/database_helper.dart';
import '../screens/admin_dashboard_screen.dart';
import '../../services/premium_service.dart';

class GlobalHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showSavingsIcon;
  final bool showBackButton; // הוחזר הפרמטר שהיה חסר
  final List<Widget>? actions;

  const GlobalHeader({
    super.key, 
    this.title, 
    this.showSavingsIcon = false, 
    this.showBackButton = false, 
    this.actions
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showLegalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('תנאי שימוש ופרטיות', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Text(
            '''תנאי שימוש באפליקציית Fintel (דוחכם)

1. הסכמה לתנאים: השימוש באפליקציית Fintel ("האפליקציה") מהווה את הסכמתך המלאה לתנאים המפורטים להלן ולמדיניות הפרטיות. 
2. מהות השירות ואי-תלות (Disclaimer): האפליקציה מהווה כלי טכנולוגי לניהול תקציב, תכנון תזרים ומעקב אחר נכסים. המידע, הנתונים והתחזיות המופקים על ידי "מנוע החירות" או כל רכיב אחר במערכת ניתנים כמות שהם (AS IS). אין באמור באפליקציה משום ייעוץ פיננסי, פנסיוני, השקעות או מס, ואין בו כדי להחליף ייעוץ מקצועי ואישי. האחריות על כל החלטה כלכלית או השקעה חלה על המשתמש בלבד.
3. הגבלת אחריות: מפתחי האפליקציה אינם אחראים לכל נזק, הפסד או אובדן כספי, ישיר או עקיף, העלול להיגרם כתוצאה מהסתמכות על חישובי המערכת, שיבושים בקווי תקשורת, הפסקות זמניות בשירותי הענן (Firebase), או תקלות במערכת ההפעלה של המכשיר.
4. אבטחה אישית: על המשתמש לנקוט בכל האמצעים לשמירת אבטחת מכשירו (נעילת מסך, ביומטריה). מפתחי האפליקציה לא יהיו אחראים לחשיפת מידע פיננסי שנגרמה עקב מסירת פרטי ההזדהות (Google Auth) לצד ג' או גישה פיזית למכשיר פתוח.
5. קניין רוחני: מתודולוגיית "דוחכם", שפת המותג, אלגוריתם ה"צלף", ומנוע "הזרימה" הינם קניין רוחני בלעדי. אין להעתיק, לשכפל או להפיץ רכיבים אלו ללא אישור מראש ובכתב.

מדיניות פרטיות ואבטחת מידע

1. איסוף מידע וסנכרון ענן: המערכת פועלת באמצעות טכנולוגיית סנכרון ענן בזמן אמת (Firebase של חברת Google). המידע הפיננסי המוזן על ידך (הכנסות, הוצאות, נכסים) נשמר תחת מזהה המשתמש שלך, במטרה לאפשר סנכרון רציף בין מכשירים וגיבוי מלא.
2. הזדהות ללא סיסמאות: למען ביטחונך, האפליקציה אינה שומרת או מנהלת מאגר סיסמאות מקומי. ההזדהות מבוצעת באמצעות שרתי Google (OAuth), כך שפרטי ההתחברות שלך לעולם אינם חשופים למפתחי האפליקציה.
3. שימוש במידע אישי: האפליקציה אוספת את כתובת הדואר האלקטרוני, השם המלא ותמונת הפרופיל שלך המשויכים לחשבון ה-Google. נתונים אלו נועדו לזיהוי בעלי המידע ולמתן שירות אישי, וכן לצורך שליחת עדכונים מערכתיים או הצעות רלוונטיות, הניתנים להסרה בכל עת. המידע הפיננסי שלך פרטי ולעולם לא יימכר לצדדים שלישיים.
4. גלישה בטוחה והצפנה: התקשורת בין האפליקציה לשרתי הענן מאובטחת ומוצפנת בסטנדרטים בינלאומיים מתקדמים (HTTPS/TLS). הגישה למסד הנתונים חסומה ברמת השרת (Security Rules) ומורשית אך ורק לבעל החשבון המאומת.
5. הגנת המכשיר המקומי: האפליקציה מציעה מנגנון נעילה ביומטרית (טביעת אצבע/זיהוי פנים) כשכבת הגנה נוספת. באחריות המשתמש להפעיל מנגנון זה דרך מסך ההגדרות למניעת גישה לא מורשית.''',
            style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
            textDirection: TextDirection.rtl,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('סגור', style: TextStyle(color: Colors.blue))),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmCtrl = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('מחיקת חשבון לצמיתות', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'פעולה זו תמחק את החשבון שלך ואת כל הנתונים הפיננסיים (הוצאות, נכסים, חסכונות) ממסד הנתונים שלנו לצמיתות. לא ניתן יהיה לשחזר את המידע.',
                  style: TextStyle(color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text('כדי לאשר, הקלד "מחק":', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                  ),
                  onChanged: (val) => setState((){}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text('ביטול', style: TextStyle(color: Colors.blueGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: (confirmCtrl.text.trim() == 'מחק' && !isDeleting) ? () async {
                  setState(() => isDeleting = true);
                  try {
                    await DatabaseHelper.instance.deleteUserAccountAndData();
                    AppGlobals.resetSession();
                    try { await GoogleSignIn().disconnect(); } catch (_) {}
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AppBootstrapper()), (route) => false);
                    }
                  } catch (e) {
                    setState(() => isDeleting = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('שגיאה במחיקת החשבון. ייתכן ונדרשת התחברות מחדש.')));
                    }
                  }
                } : null,
                child: isDeleting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('מחק לצמיתות', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _openDrawerMenu(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user != null && (user.email == 'fintelappil@gmail.com' || user.email?.contains('admin') == true || user.email == 'freeuser.fintelapp.test@gmail.com');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueGrey.shade800,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'משתמש Fintel', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                        Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text('Fintel Pro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                PremiumService.requirePremium(context, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('מנוי ה-Pro שלך פעיל!'), backgroundColor: Colors.green));
                });
              },
            ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
                title: const Text('דשבורד מנהלים', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: Colors.blueGrey),
              title: const Text('תנאי שימוש ופרטיות', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                _showLegalDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('מחיקת חשבון לצמיתות', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black87),
              title: const Text('התנתק', style: TextStyle(color: Colors.black87)),
              onTap: () async {
                AppGlobals.resetSession();
                try { await GoogleSignIn().disconnect(); } catch (_) {}
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AppBootstrapper()), (route) => false);
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF121212),
      iconTheme: const IconThemeData(color: Colors.white),
      title: title != null 
          ? Text(title!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
          : Image.asset('assets/icon/fintel_logo_dark.png', height: 32, errorBuilder: (_,__,___) => const Text('Fintel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
      centerTitle: true,
      leading: showBackButton 
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))
          : IconButton(icon: const Icon(Icons.menu), onPressed: () => _openDrawerMenu(context)),
      actions: actions,
    );
  }
}