// 🔒 STATUS: EDITED (Robust Google Auth & Deep Clean Session)
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
                    const SizedBox(height: 50),

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