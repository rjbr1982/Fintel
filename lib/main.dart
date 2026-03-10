// 🔒 STATUS: EDITED (Implemented Premium Banking UX - Double Splash & Last Login Time)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // הוספת ספריה לעיצוב תאריכים

import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 אתחול מנוע הענן של Firebase (מותאם ל-Web/SaaS)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

// 🎬 שער 1: ניהול האתחול הראשוני (Pre-Login Splash)
class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _isBooting = true;

  @override
  void initState() {
    super.initState();
    // השהיית מינימום קשיחה של 2.5 שניות לחשיפת המותג
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _isBooting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBooting) {
      return const SplashScreen();
    }
    return const AuthStreamGate();
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
          return const SplashScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // המשתמש מחובר - נעביר אותו לשער הכניסה הפנימי (אנימציה שנייה)
          return PostLoginRouter(user: snapshot.data!);
        }

        // המשתמש לא מחובר
        return const LoginScreen();
      },
    );
  }
}

// 🏦 שער 3: חוויית הבנק - אנימציה שנייה ובדיקת משתמש חדש
class PostLoginRouter extends StatefulWidget {
  final User user;
  const PostLoginRouter({super.key, required this.user});

  @override
  State<PostLoginRouter> createState() => _PostLoginRouterState();
}

class _PostLoginRouterState extends State<PostLoginRouter> {
  bool _isProcessing = true;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _processLogin();
  }

  Future<void> _processLogin() async {
    // 1. נבדוק אם יש צורך בהגדרות משתמש חדש
    final expenses = await DatabaseHelper.instance.getExpenses();
    _needsOnboarding = expenses.isEmpty;

    // 2. השהיה נוספת של 2 שניות להצגת "מאמת נתונים" וזמן כניסה אחרון
    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return PostLoginSplashScreen(user: widget.user);
    }

    if (_needsOnboarding) {
      return const OnboardingScreen();
    }

    return const MainScreen();
  }
}

// 🎬 רכיב תצוגה: אנימציית פתיחה נקייה
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/icon/splash.gif',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const CircularProgressIndicator(color: Color(0xFF00A3FF));
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fintel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 2.0
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🎬 רכיב תצוגה: אנימציית כניסה (Banking Style) המציגה תאריך התחברות
class PostLoginSplashScreen extends StatelessWidget {
  final User user;
  const PostLoginSplashScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // שליפת זמן ההתחברות האחרון ממטא-דאטה של גוגל
    final lastSignIn = user.metadata.lastSignInTime;
    String timeText = '';
    
    if (lastSignIn != null) {
      // עיצוב תאריך בסגנון ישראלי: dd/MM/yyyy HH:mm
      timeText = DateFormat('dd/MM/yyyy HH:mm').format(lastSignIn.toLocal());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/icon/splash.gif',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const CircularProgressIndicator(color: Color(0xFF00FF85));
                },
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'מאמת נתונים מאובטחים...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (timeText.isNotEmpty)
              Text(
                'כניסה אחרונה למערכת:\n$timeText',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey[400],
                  height: 1.5
                ),
              ),
          ],
        ),
      ),
    );
  }
}