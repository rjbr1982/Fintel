// 🔒 STATUS: EDITED (Added Local_Auth Biometric barrier for Mobile users)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // הוסף כדי לזהות Web
import 'package:local_auth/local_auth.dart'; // הוסף את ספריית הביומטריה
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

// 🎬 שער 1: ניהול האתחול הראשוני עם מעבר רך
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
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _isBooting = false);
    });
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

        return const LoginScreen(key: ValueKey('login_screen'));
      },
    );
  }
}

// 🏦 שער 3: חוויית הבנק - אנימציה שנייה + ביומטריה
class PostLoginRouter extends StatefulWidget {
  final User user;
  const PostLoginRouter({super.key, required this.user});

  @override
  State<PostLoginRouter> createState() => _PostLoginRouterState();
}

class _PostLoginRouterState extends State<PostLoginRouter> {
  bool _isProcessing = true;
  bool _needsOnboarding = false;
  bool _authFailed = false; // מצב לאימות ביומטרי שנכשל

  @override
  void initState() {
    super.initState();
    _processLogin();
  }

  Future<void> _processLogin() async {
    setState(() {
      _isProcessing = true;
      _authFailed = false;
    });

    final expenses = await DatabaseHelper.instance.getExpenses();
    _needsOnboarding = expenses.isEmpty;

    // שליפת הגדרת הביומטריה (רלוונטי רק למובייל)
    double useBioNum = await DatabaseHelper.instance.getSetting('use_biometric') ?? 0.0;
    bool useBiometric = useBioNum == 1.0;

    await Future.delayed(const Duration(milliseconds: 2500));

    // אם אנחנו לא ב-Web והמשתמש הדליק ביומטריה - הקפץ זיהוי
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
            // המשתמש ביטל או נכשל בזיהוי
            if (mounted) setState(() => _authFailed = true);
            return;
          }
        } catch (e) {
          debugPrint('Authentication error: $e');
        }
      }
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
                onPressed: _processLogin, // חזרה לתהליך
                child: const Text('נסה שוב'),
              )
            ]
          )
        )
      );
    }

    Widget currentScreen;
    if (_isProcessing) {
      currentScreen = PostLoginSplashScreen(key: const ValueKey('splash_post'), user: widget.user);
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

// 🎬 רכיב תצוגה: אנימציית פתיחה נקייה לחלוטין (רקע בהיר)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // רקע לבן פרימיום
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

// 🎬 רכיב תצוגה: אנימציית כניסה המציגה תאריך התחברות (רקע בהיר)
class PostLoginSplashScreen extends StatelessWidget {
  final User user;
  const PostLoginSplashScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final lastSignIn = user.metadata.lastSignInTime;
    String timeText = '';
    
    if (lastSignIn != null) {
      timeText = DateFormat('dd/MM/yyyy HH:mm').format(lastSignIn.toLocal());
    }

    return Scaffold(
      backgroundColor: Colors.white, // רקע לבן פרימיום
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
                color: Colors.black87, // טקסט כהה על רקע בהיר
              ),
            ),
            const SizedBox(height: 12),
            if (timeText.isNotEmpty)
              Text(
                'כניסה אחרונה למערכת:\n$timeText',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey, // צבע משני אלגנטי
                  height: 1.5,
                  fontWeight: FontWeight.w500
                ),
              ),
          ],
        ),
      ),
    );
  }
}