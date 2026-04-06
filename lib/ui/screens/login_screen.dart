// 🔒 STATUS: EDITED (Robust Google Auth, Deep Clean Session & Legal Onboarding - Checkbox Visibility Fix)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _termsAccepted = false; // דגל לאישור תנאי השימוש והפרטיות

  @override
  void initState() {
    super.initState();
    // נוהל 5.10.8: אבטחת ניקיון מטמון - ניתוק עמוק במקרה שמשתמש הגיע לכאן בטעות עם סשן פתוח
    _forceDeepSignOut();
  }

  Future<void> _forceDeepSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!kIsWeb) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      }
    } catch (_) {}
  }

  Future<void> _signInWithGoogle() async {
    // וידוא שהמשתמש אישר את תנאי השימוש לפני תחילת תהליך ההזדהות (איסוף המייל)
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש לאשר את תנאי השימוש ומדיניות הפרטיות כדי להמשיך.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ניתוק מקדים לפני ניסיון התחברות כדי להבטיח בחירת חשבון נקייה
      await _forceDeepSignOut();

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        // הגדרה זו מכריחה את גוגל להציג את חלונית בחירת החשבונות תמיד
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        
        // ניקוי טוקנים ישנים מהמכשיר ב-Native
        try { await googleSignIn.disconnect(); } catch (_) {}
        
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          // המשתמש סגר את חלונית ההתחברות (ביטול טבעי)
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        // התעלמות משגיאה שבה המשתמש סגר את החלונית בעצמו או שהדפדפן חסם פופאפ
        if (e.code == 'popup-closed-by-user') return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאת אימות: ${e.message ?? e.code}'), 
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('התרחשה שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLegalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'תנאי שימוש ומדיניות פרטיות',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const SingleChildScrollView(
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
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A3FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() => _termsAccepted = true);
                    Navigator.of(context).pop();
                  },
                  child: const Text('קראתי ואני מאשר/ת', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('סגור ללא אישור', style: TextStyle(color: Colors.blueGrey)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // רקע לבן נקי ויוקרתי
      body: SafeArea(
        child: Stack(
          children: [
            // הדר (Header) עם לוגו סטטי וטקסט - למעלה מימין
            Positioned(
              top: 24,
              right: 24,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icon/Fintel_Icon.png', // אייקון סטטי
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, color: Colors.blue, size: 36),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Fintel',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
            // מרכז המסך - קריאה לפעולה וכפתור התחברות
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'כניסה מאובטחת',
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.black87
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      'התחבר/י לחשבון שלך כדי לגשת למערכת הניהול הפיננסי החכמה. הנתונים שלך מגובים ומאובטחים בענן בכל עת.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.blueGrey, 
                        height: 1.6,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    const SizedBox(height: 40),

                    // רכיב אישור תנאי השימוש (Legal Onboarding) הבהרה וצבע כהה
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _termsAccepted ? Colors.grey.shade300 : Colors.red.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _termsAccepted,
                            activeColor: const Color(0xFF00A3FF),
                            side: const BorderSide(color: Colors.black87, width: 2.0), // עיבוי וצביעה לכהה לבולטות
                            onChanged: (bool? value) {
                              setState(() => _termsAccepted = value ?? false);
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showLegalDialog,
                              child: const Text.rich(
                                TextSpan(
                                  text: 'אני מאשר/ת את ',
                                  style: TextStyle(color: Colors.black87, fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'תנאי השימוש ומדיניות הפרטיות',
                                      style: TextStyle(
                                        color: Color(0xFF00A3FF),
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF00A3FF))
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A), // כפתור פרימיום שחור
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 4,
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                            ),
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                                height: 18,
                              ),
                            ),
                            label: const Text(
                              'המשך עם Google',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _signInWithGoogle,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}