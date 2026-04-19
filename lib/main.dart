// 🔒 STATUS: EDITED (Added forceUSNotifier to AppGlobals for Admin Sandbox testing)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:local_auth/local_auth.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:google_sign_in/google_sign_in.dart'; 
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
import 'services/notification_service.dart'; 

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await HybridBillingEngine.init();

  if (!kIsWeb) {
    await NotificationService.instance.init();
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

class AppGlobals {
  static bool hasCompletedColdBoot = false;
  static bool hasAuthenticatedSession = false;
  
  // Dev Sandbox State
  static final ValueNotifier<bool> forceUSNotifier = ValueNotifier(false);
  
  static void resetSession() {
    hasAuthenticatedSession = false;
  }
}

class FintelApp extends StatelessWidget {
  const FintelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppGlobals.forceUSNotifier,
      builder: (context, forceUS, child) {
        return MaterialApp(
          title: 'Fintel - דוחכם',
          debugShowCheckedModeBanner: false,
          
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('he', 'IL'), 
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          
          // Force locale if switch is on, otherwise use resolution callback
          locale: forceUS ? const Locale('en', 'US') : null,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale != null) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == deviceLocale.languageCode) {
                  return deviceLocale;
                }
              }
            }
            return const Locale('he', 'IL'); // Default fallback to Hebrew
          },

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
    );
  }
}

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
  bool _needsLegalConsent = false; 
  late bool _isInitialAuthRun; 

  @override
  void initState() {
    super.initState();
    _isInitialAuthRun = !AppGlobals.hasAuthenticatedSession;
    _processLogin();
  }

  Future<void> _processLogin() async {
    try {
      setState(() {
        _isProcessing = true;
        _authFailed = false;
        _needsLegalConsent = false;
      });

      final hasAcceptedTerms = await DatabaseHelper.instance.hasAcceptedTerms();
      if (!hasAcceptedTerms) {
        if (mounted) {
          setState(() {
            _needsLegalConsent = true;
            _isProcessing = false;
          });
        }
        return; 
      }

      final expenses = await DatabaseHelper.instance.getExpenses();
      _needsOnboarding = expenses.isEmpty;

      if (_isInitialAuthRun) {
        try {
          double useBioNum = await DatabaseHelper.instance.getSetting('use_biometric') ?? 0.0;
          bool useBiometric = useBioNum == 1.0;

          if (!kIsWeb && useBiometric) {
            await Future.delayed(const Duration(milliseconds: 1500));
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
        } catch (e) {
          debugPrint('Settings error during login: $e');
        }
        AppGlobals.hasAuthenticatedSession = true;
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
      }

      PremiumService.startSnapshotListener();
      
    } catch (e) {
      debugPrint('CRITICAL: Login process failed safely. Error: $e');
      _needsOnboarding = false; // שחרור במקרה חירום
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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

    if (_needsLegalConsent) {
      return const FullLegalGateScreen();
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

class FullLegalGateScreen extends StatefulWidget {
  const FullLegalGateScreen({super.key});

  @override
  State<FullLegalGateScreen> createState() => _FullLegalGateScreenState();
}

class _FullLegalGateScreenState extends State<FullLegalGateScreen> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            margin: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'תנאי שימוש ומדיניות פרטיות',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
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
                            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: CheckboxListTile(
                        value: isChecked,
                        activeColor: const Color(0xFF00A3FF),
                        title: const Text(
                          'קראתי ואני מסכים/ה לתנאי השימוש ולמדיניות הפרטיות',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (val) {
                          setState(() => isChecked = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () async {
                            AppGlobals.resetSession();
                            try { await GoogleSignIn().disconnect(); } catch (_) {}
                            await FirebaseAuth.instance.signOut();
                          },
                          child: const Text('סרב והתנתק', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isChecked ? const Color(0xFF00A3FF) : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isChecked ? () async {
                            await DatabaseHelper.instance.updateUserMetric('hasAcceptedTerms', true);
                            
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const AppBootstrapper()),
                                (Route<dynamic> route) => false,
                              );
                            }
                          } : null,
                          child: const Text('אשר והמשך', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ],
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