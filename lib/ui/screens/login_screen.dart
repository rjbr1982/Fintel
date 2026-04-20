// 🔒 STATUS: EDITED (Removed wallet fallback icon to enforce brand identity, Implemented Bulletproof Legal Layout & L10n)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/database_helper.dart';
import '../../utils/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

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
    setState(() => _isLoading = true);

    try {
      // ניתוק מקדים לפני ניסיון התחברות כדי להבטיח בחירת חשבון נקייה
      await _forceDeepSignOut();

      UserCredential? userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        // הגדרה זו מכריחה את גוגל להציג את חלונית בחירת החשבונות תמיד
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
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
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      
      if (userCredential.user != null) {
        // המשתמש אומת מול גוגל. כעת נבדוק אם הוא אישר בעבר את התנאים
        bool hasAccepted = await DatabaseHelper.instance.hasAcceptedTerms();
        
        if (!hasAccepted) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showUnifiedConsentDialog(); // הקפצת מסך אישור ה-Bulletproof
          }
          return;
        }
        // במידה וכבר אישר בעבר, מנוע הניווט הראשי (main.dart) יעביר אותו אוטומטית לדשבורד
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
      // אנחנו לא מסיימים את טעינת המסך אם אנחנו מחכים לחלונית האישור
      if (mounted && FirebaseAuth.instance.currentUser == null) {
        setState(() => _isLoading = false);
      }
    }
  }

  // חלונית משפטית חסינת-קריסות (Bulletproof Layout) משולבת עם Checkbox
  void _showUnifiedConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool isChecked = false;
        final l10n = AppLocalizations.of(context);
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  l10n.translate('legal_terms'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 350, // גובה קשיח למניעת קריסות גלילה (Bulletproof Layout)
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              l10n.translate('terms_full_text'),
                              style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              activeColor: const Color(0xFF00A3FF),
                              onChanged: (val) {
                                setDialogState(() => isChecked = val ?? false);
                              },
                            ),
                            Expanded(
                              child: Text(
                                l10n.translate('accept_terms_link'),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    onPressed: () async {
                      await _forceDeepSignOut();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text(
                      l10n.translate('close'), 
                      style: const TextStyle(color: Colors.redAccent)
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isChecked ? const Color(0xFF00A3FF) : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isChecked ? () async {
                      await DatabaseHelper.instance.updateUserMetric('hasAcceptedTerms', true);
                      if (context.mounted) Navigator.of(context).pop();
                    } : null,
                    child: const Text('המשך לדשבורד', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 24,
              right: 24,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icon/fintel_icon.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.translate('app_title'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
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

                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF00A3FF))
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A),
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
                            label: Text(
                              l10n.translate('login_with_google'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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