// 🔒 STATUS: FIXED (Strict Aliasing & Cache reset)
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 📱 כינוי הרמטי למובייל (הכל מתחיל ב- mobile_auth)
import 'package:google_sign_in/google_sign_in.dart' as mobile_auth;

// 💻 כינוי הרמטי למחשב (הכל מתחיל ב- desktop_auth)
import 'package:desktop_webview_auth/desktop_webview_auth.dart' as desktop_auth;
import 'package:desktop_webview_auth/google.dart' as desktop_google;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        
        // 💻 שימוש אקסקלוסיבי בחבילת המחשב
        final args = desktop_google.GoogleSignInArgs(
          clientId: 'הכנס-כאן-את-ה-CLIENT-ID-שהעתקת-מגוגל', 
          redirectUri: 'https://fintel-app-2e01e.firebaseapp.com/__/auth/handler',
          scope: 'email profile',
        );
        
        final result = await desktop_auth.DesktopWebviewAuth.signIn(args);
        
        if (result == null) {
          if (mounted) setState(() => _isLoading = false);
          return; 
        }
        
        final credential = GoogleAuthProvider.credential(
          accessToken: result.accessToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);

      } else {
        // 📱 שימוש אקסקלוסיבי בחבילת המובייל דרך הכינוי "mobile_auth"
        final mobile_auth.GoogleSignIn googleSignIn = mobile_auth.GoogleSignIn();
        final mobile_auth.GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        
        // עטיפה מאובטחת המונעת התראות על גרסאות ישנות/חדשות של החבילה
        final mobile_auth.GoogleSignInAuthentication googleAuth = await Future.value(googleUser.authentication);
        
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בהתחברות: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A3FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Color(0xFF00A3FF)),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'Fintel - דוחכם',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                
                Text(
                  'התחבר באמצעות Google כדי לסנכרן ולשמור את הנתונים שלך בענן בצורה מאובטחת.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[400], height: 1.5),
                ),
                const SizedBox(height: 48),

                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF00A3FF))
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 2,
                        ),
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                          height: 24,
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
      ),
    );
  }
}