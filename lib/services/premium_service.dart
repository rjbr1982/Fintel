// 🔒 STATUS: EDITED (Removed Sinking Funds from Paywall feature list per Constitution v12.90)
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/database_helper.dart';
import '../main.dart'; 

class HybridBillingEngine {
  static const String makeWebhookUrl = 'https://hook.eu1.make.com/n7rixsg12pj31b19lh8dxqu7kn49dof6';

  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint('HybridBillingEngine: Web Gateway initialized');
    } else {
      debugPrint('HybridBillingEngine: Native RevenueCat initialized');
    }
  }

  static Future<bool> purchasePro() async {
    try {
      if (kIsWeb) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not logged in');

        final payload = {
          'uid': user.uid,
          'email': user.email ?? '',
          'action': 'create_checkout'
        };

        final response = await http.post(
          Uri.parse(makeWebhookUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final String? checkoutUrl = responseData['checkoutUrl'];

          if (checkoutUrl != null) {
            final Uri paymentUri = Uri.parse(checkoutUrl);
            if (await canLaunchUrl(paymentUri)) {
              await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
              return true; 
            } else {
              throw Exception('Could not launch Stripe URL');
            }
          }
        }
        throw Exception('Failed to get checkout session from Webhook');
      } else {
        await Future.delayed(const Duration(seconds: 2)); 
        return true;
      }
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }
}

class PremiumService {
  static final ValueNotifier<int> stateNotifier = ValueNotifier(0);
  static void notifyStateChanged() => stateNotifier.value++;

  static bool _forceFreeMode = false;
  static StreamSubscription<DocumentSnapshot>? _premiumSubscription;
  
  static bool get forceFreeMode => _forceFreeMode;
  static set forceFreeMode(bool val) {
    _forceFreeMode = val;
    notifyStateChanged(); 
  }

  static void startSnapshotListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _premiumSubscription?.cancel();
    _premiumSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        notifyStateChanged();
      }
    }, onError: (error) => debugPrint('Premium snapshot listener error: $error'));
  }

  static void stopSnapshotListener() {
    _premiumSubscription?.cancel();
  }

  static Future<bool> isUserPremium() async {
    if (_forceFreeMode) return false;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email == 'freeuser.fintelapp.test@gmail.com') {
      return false; // Force Free for test user
    }

    final userData = await DatabaseHelper.instance.getUserRootData();
    
    if (userData == null) return false; 
    
    final isPremium = userData['isPremium'] == true;
    
    final rootGen = (userData['generation'] ?? '').toString().toLowerCase();
    final metrics = userData['metrics'] as Map<String, dynamic>? ?? {};
    final metricsGen = (metrics['generation'] ?? '').toString().toLowerCase();

    final isFounders = rootGen == 'alpha' || rootGen == 'beta' || 
                       metricsGen == 'alpha' || metricsGen == 'beta';

    return isPremium || isFounders;
  }

  static Future<void> requirePremium(BuildContext context, VoidCallback onGranted) async {
    if (_forceFreeMode) {
      _showPaywall(context, onGranted);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final isTestUser = user != null && user.email == 'freeuser.fintelapp.test@gmail.com';

    final userData = await DatabaseHelper.instance.getUserRootData();
    
    if (!context.mounted) return;

    if (userData == null || isTestUser) {
      _showPaywall(context, onGranted);
      return;
    }

    final isPremium = userData['isPremium'] == true;
    final rootGen = (userData['generation'] ?? '').toString().toLowerCase();
    final metrics = userData['metrics'] as Map<String, dynamic>? ?? {};
    final metricsGen = (metrics['generation'] ?? '').toString().toLowerCase();
    
    final isFounders = rootGen == 'alpha' || rootGen == 'beta' || metricsGen == 'alpha' || metricsGen == 'beta';
    final hasSeenFoundersGift = metrics['hasSeenFoundersGift'] == true;

    if (isPremium) {
      onGranted();
      return;
    }

    if (isFounders) {
      if (hasSeenFoundersGift) {
        onGranted();
        return;
      }
      _showFoundersDialog(context, onGranted);
    } else {
      _showPaywall(context, onGranted);
    }
  }

  static void _showFoundersDialog(BuildContext context, VoidCallback onGranted) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Image.asset('assets/icon/crown_icon.png', width: 64, height: 64, errorBuilder: (_,__,___) => const Icon(Icons.workspace_premium, color: Colors.amber, size: 64)),
            const SizedBox(height: 16),
            const Text("פיצ'ר פרימיום פתוח!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 20)),
          ],
        ),
        content: const Text("זיהינו שאתה מהמשתמשים הראשונים. כל פיצ'רי הפרימיום פתוחים עבורך בחינם. תהנה!", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontSize: 15, height: 1.4)),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateUserMetric('hasSeenFoundersGift', true);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              onGranted();
            },
            child: const Text("תודה, המשך"),
          ),
        ],
      ),
    );
  }

  static void _showPaywall(BuildContext context, VoidCallback onGranted) {
    bool isProcessing = false;
    final isHebrew = Localizations.localeOf(context).languageCode == 'he';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed Header Banner
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.asset('assets/icon/fintel_pro_banner.jpg', width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24), color: const Color(0xFF121212),
                      child: Column(children: [Image.asset('assets/icon/premium_icon.png', width: 72, height: 72, errorBuilder: (_,__,___) => const Icon(Icons.workspace_premium, color: Colors.amber, size: 72)), const SizedBox(height: 12), const Text('Fintel Pro', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2))]))),
                ),
                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isHebrew ? "שדרג ל-Fintel Pro\nשליטה מוחלטת בתזרים" : "Upgrade to Fintel Pro\nUltimate Cashflow Control", 
                            textAlign: TextAlign.center, 
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)
                          ),
                          const SizedBox(height: 24),
                          // Feature List reordered strategically
                          _buildBullet(isHebrew ? "מערכת חיסול חובות חכמה, לחיסול כל החובות בחצי זמן." : "Smart Debt Elimination - Settle all debts in half the time."),
                          _buildBullet(isHebrew ? "ייצוב שכר תנודתי - מנוע ממוצע שכר חכם." : "Income Stabilizer - Smart Salary Average."),
                          _buildBullet(isHebrew ? "אקדמיית Fintel - גישה מלאה לשיעורי פרקטיקה וניהול פיננסי." : "Fintel Academy - Full access to practical financial management lessons."),
                          _buildBullet(isHebrew ? "ניהול נכסים והשקעות מתקדם." : "Advanced Asset & Investment Management."),
                          _buildBullet(isHebrew ? "ניהול עוסק פטור - תיעוד תקבולים ותשלומים עם העתקה מהירה לרו\"ח." : "Exempt Dealer Management - Ledger tracking with quick copy for accountant."),
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: isProcessing 
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A3FF)))
                              : (AppGlobals.forceUSNotifier.value && kIsWeb)
                                  ? Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blueGrey.shade200)
                                      ),
                                      child: const Text(
                                        "Web checkout is not available in your region.\nPlease download our Android app from the Google Play Store to subscribe.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A3FF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                          onPressed: () async {
                                            setState(() => isProcessing = true);
                                            bool success = await HybridBillingEngine.purchasePro();
                                            
                                            if (!ctx.mounted) return;
                                            
                                            if (success) {
                                              Navigator.pop(ctx);
                                              if (kIsWeb) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isHebrew ? 'ממתין לאישור תשלום. המסך יתרענן אוטומטית.' : 'Waiting for payment confirmation. The screen will refresh automatically.'), backgroundColor: Colors.blueGrey));
                                              } else {
                                                await DatabaseHelper.instance.setPremiumStatus(true);
                                                PremiumService.notifyStateChanged();
                                                onGranted();
                                              }
                                            } else {
                                              setState(() => isProcessing = false);
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isHebrew ? 'שגיאה בתקשורת עם השרת. נסה שוב.' : 'Server communication error. Please try again.'), backgroundColor: Colors.redAccent));
                                            }
                                          },
                                          child: Center(child: Text(isHebrew ? "רכישת מנוי לכל החיים (Lifetime)" : "Get Lifetime Access", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                        ),
                                        if (isHebrew && kIsWeb) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            "מעדיף מנוי חודשי גמיש?\nהורד את האפליקציה מחנות ה-Google Play",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ],
                                    ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: isProcessing ? null : () => Navigator.pop(ctx), 
                            child: Text(isHebrew ? "לא תודה, אמשיך בגרסה הבסיסית" : "No thanks, I'll stick to the basic version", style: const TextStyle(color: Colors.grey, fontSize: 13))
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.check_circle, color: Color(0xFF00FF85), size: 20), 
        const SizedBox(width: 12), 
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)))
      ]),
    );
  }
}