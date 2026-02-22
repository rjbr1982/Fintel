// 🔒 STATUS: EDITED (SaaS/Web Transition - Removed Windows/Desktop dependencies)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'firebase_options.dart';                    

import 'providers/budget_provider.dart';
import 'providers/asset_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/shopping_provider.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/login_screen.dart'; 
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
      
      home: const AuthGate(),
    );
  }
}

// 🛡️ שומר הסף: בודק אם המשתמש מחובר בענן
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00A3FF)),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}