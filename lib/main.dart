// 🔒 STATUS: EDITED (Integrated Local Notifications Engine & Centralized Post-Auth Legal Gate)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:local_auth/local_auth.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 🔔 תשתית התראות מקומיות

import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:google_sign_in/google_sign_in.dart'; // הוסף כדי לאפשר ניתוק כפוי
import 'firebase_options.dart';                    

import 'providers/budget_provider.dart';
import 'providers/asset_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/shopping_provider.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/login_screen.dart'; 
import 'ui/screens/onboarding_screen.dart'; 
import 'data/database_helper.dart'; 
import 'utils/app_localizations.dart';
import 'services/premium_service.dart';
import 'services/notification_service.dart'; // 🔔 הזרקת שירות ההתראות

// 🔔 מופע גלובלי של מנהל ההתראות
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // אתחול מנוע החיוב ההיברידי (Web/Native)
  await HybridBillingEngine.init();

  // 🔔 אתחול מערכת ההתראות המרכזית (כולל אזורי זמן והרשאות)
  if (!kIsWeb) {
    await NotificationService.instance.init();
    
    // קריאה ראשונית לתזמון התראות התפעול (1 לחודש)
    await NotificationService.instance.scheduleMonthlyRollover();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DebtProvider()), 
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingProvider()),
        
        ChangeNotifierProxyProvider<DebtProvider, BudgetProvider>(
          create: (context) => BudgetProvider(),
          update: (context, debt, budget) {
            if (budget != null) {
              budget.updateExternalDebtPayment(debt.totalMonthlyPayment);
              budget.updateHasActiveDebts(debt.debts.any((d) => d.currentBalance > 0));
            }
            return budget ?? BudgetProvider();
          },
        ),
      ],
      child: const FintelApp(),
    ),
  );
}

// 🧠 מנהל זיכרון גלובלי לסשן נוכחי (למניעת כפילויות בניווט פנימי)
class AppGlobals {
  static bool hasCompletedColdBoot = false;
  static bool hasAuthenticatedSession = false;
  
  static void resetSession() {
    hasAuthenticatedSession = false;
  }
}

class FintelApp extends StatelessWidget {
  const FintelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fintel - דוחכם',
      debugShowCheckedModeBanner: false,
      
      supportedLocales: const [
        Locale('he', 'IL'), 
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('he', 'IL'), 

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00A3FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00A3FF),
          secondary: Color(0xFF00FF85),
          error: Color(0xFFFF4B4B),
          surface: Color(0xFF1E1E1E),
        ),
        fontFamily: 'Heebo',
        useMaterial3: true,
      ),
      
      home: const AppBootstrapper(),
    );
  }
}

// 🎬 שער 1: ניהול האתחול הראשוני עם דילוג חכם בניווט פנימי
class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _isBooting = !AppGlobals.hasCompletedColdBoot;

  @override
  void initState() {
    super.initState();
    if (_isBooting) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        AppGlobals.hasCompletedColdBoot = true;
        if (mounted) setState(() => _isBooting = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _isBooting 
          ? const SplashScreen(key: ValueKey('splash_pre')) 
          : const AuthStreamGate(key: ValueKey('auth_gate')),
    );
  }
}

// 🔒 שער 2: מאזין לסטטוס ההתחברות מול הענן
class AuthStreamGate extends StatelessWidget {
  const AuthStreamGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(key: ValueKey('splash_auth'));
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return PostLoginRouter(key: const ValueKey('post_login_router'), user: snapshot.data!);
        }

        // המשתמש אכן מנותק, העבר למסך ההתחברות הנקי
        return const LoginScreen(key: ValueKey('login_screen'));
      },
    );
  }
}

// 🏦 שער 3: חוויית הבנק, סינון משפטי וניתוב פנימי
class PostLoginRouter extends StatefulWidget {
  final User user;
  const PostLoginRouter({super.key, required this.user});

  @override
  State<PostLoginRouter> createState() => _PostLoginRouterState();
}

class _PostLoginRouterState extends State<PostLoginRouter> {
  bool _isProcessing = true;
  bool _needsOnboarding = false;
  bool _authFailed = false; 
  bool _needsLegalConsent = false; // דגל הבוחן האם המשתמש טרם אישר תנאים
  late bool _isInitialAuthRun; 

  @override
  void initState() {
    super.initState();
    _isInitialAuthRun = !AppGlobals.hasAuthenticatedSession;
    _processLogin();
  }

  Future<void> _processLogin() async {
    setState(() {
      _isProcessing = true;
      _authFailed = false;
      _needsLegalConsent = false;
    });

    // 1. קודם כל: בדיקת תנאי שימוש (Legal Consent)
    final hasAcceptedTerms = await DatabaseHelper.instance.hasAcceptedTerms();
    if (!hasAcceptedTerms) {
      if (mounted) {
        setState(() {
          _needsLegalConsent = true;
          _isProcessing = false;
        });
      }
      return; // עוצרים הכל עד שיאשר
    }

    // 2. רק אם אישר, ממשיכים לעיבוד הרגיל
    final expenses = await DatabaseHelper.instance.getExpenses();
    _needsOnboarding = expenses.isEmpty;

    if (_isInitialAuthRun) {
      double useBioNum = await DatabaseHelper.instance.getSetting('use_biometric') ?? 0.0;
      bool useBiometric = useBioNum == 1.0;

      await Future.delayed(const Duration(milliseconds: 2500));

      if (!kIsWeb && useBiometric) {
        final LocalAuthentication auth = LocalAuthentication();
        bool canCheckBiometrics = false;
        try {
          canCheckBiometrics = await auth.canCheckBiometrics || await auth.isDeviceSupported();
        } catch (e) {
          debugPrint('Biometric check error: $e');
        }

        if (canCheckBiometrics) {
          try {
            bool authenticated = await auth.authenticate(
              localizedReason: 'אנא אמת את זהותך כדי לגשת לנתונים הפיננסיים',
              options: const AuthenticationOptions(
                stickyAuth: true,
                biometricOnly: true,
              ),
            );
            if (!authenticated) {
              if (mounted) setState(() => _authFailed = true);
              return;
            }
          } catch (e) {
            debugPrint('Authentication error: $e');
          }
        }
      }
      
      AppGlobals.hasAuthenticatedSession = true;

    } else {
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authFailed) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text('האימות הביומטרי נכשל', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF121212), foregroundColor: Colors.white),
                onPressed: _processLogin, 
                child: const Text('נסה שוב'),
              )
            ]
          )
        )
      );
    }

    // אם טרם אישר תנאים, חסום אותו במסך ייעודי (Post-Auth Legal Gate)
    if (_needsLegalConsent) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gavel_rounded, size: 48, color: Colors.blueGrey),
                      const SizedBox(height: 16),
                      const Text(
                        'עדכון חשוב בנושא פרטיות',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'לפני שנתחיל להשתמש ב-Fintel, חשוב לנו לוודא שהפרטיות שלך והמידע הפיננסי שלך מוגנים כראוי.\n\nהאפליקציה אינה מהווה ייעוץ פיננסי, והמידע שלך מאובטח בענן (Google) ולא מועבר לאיש.',
                        style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A3FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await DatabaseHelper.instance.updateUserMetric('hasAcceptedTerms', true);
                          // חוזרים למסלול העיבוד הרגיל עכשיו כשיש אישור
                          _processLogin();
                        },
                        child: const Text('קראתי, ואני מאשר/ת את התנאים', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          AppGlobals.resetSession();
                          try { await GoogleSignIn().disconnect(); } catch (_) {}
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('סרב והתנתק מהחשבון', style: TextStyle(color: Colors.blueGrey)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget currentScreen;
    if (_isProcessing) {
      currentScreen = PostLoginSplashScreen(
        key: const ValueKey('splash_post'), 
        user: widget.user, 
        showText: _isInitialAuthRun 
      );
    } else if (_needsOnboarding) {
      currentScreen = const OnboardingScreen(key: ValueKey('onboarding'));
    } else {
      currentScreen = const MainScreen(key: ValueKey('dashboard'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: currentScreen,
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.asset(
            'assets/icon/splash.gif',
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const CircularProgressIndicator(color: Color(0xFF00A3FF));
            },
          ),
        ),
      ),
    );
  }
}

class PostLoginSplashScreen extends StatelessWidget {
  final User user;
  final bool showText; 
  const PostLoginSplashScreen({super.key, required this.user, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final lastSignIn = user.metadata.lastSignInTime;
    String timeText = '';
    
    if (lastSignIn != null) {
      timeText = DateFormat('dd/MM/yyyy HH:mm').format(lastSignIn.toLocal());
    }

    return Scaffold(
      backgroundColor: Colors.white, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/icon/splash.gif',
                width: showText ? 120 : 140, 
                height: showText ? 120 : 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const CircularProgressIndicator(color: Color(0xFF00FF85));
                },
              ),
            ),
            
            if (showText) ...[
              const SizedBox(height: 32),
              const Text(
                'מאמת נתונים מאובטחים...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, 
                ),
              ),
              const SizedBox(height: 12),
              if (timeText.isNotEmpty)
                Text(
                  'כניסה אחרונה למערכת:\n$timeText',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey, 
                    height: 1.5,
                    fontWeight: FontWeight.w500
                  ),
                ),
            ]
          ],
        ),
      ),
    );
  }
}