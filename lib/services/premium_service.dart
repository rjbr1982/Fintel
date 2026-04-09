// 🔒 STATUS: EDITED (Replaced text emoji crowns with image assets: crown_icon.png & premium_icon.png)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/database_helper.dart';

/// מנוע החיוב ההיברידי (מפריד בין רכישות מובייל לרכישות דפדפן)
class HybridBillingEngine {
  // PENDING: Replace with the actual payment gateway link for Gamma phase
  // כרגע מוגדר לקישור דמה כדי למנוע שגיאת 404 עד שיוקם עמוד תשלום אמיתי
  static const String webPaymentUrl = 'https://example.com/fintel-pro-checkout';

  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint('HybridBillingEngine: Web Gateway initialized');
    } else {
      // PENDING: Initialize RevenueCat (purchases_flutter)
      debugPrint('HybridBillingEngine: Native RevenueCat initialized');
    }
  }

  static Future<bool> purchasePro(BuildContext context) async {
    try {
      if (kIsWeb) {
        final Uri paymentUri = Uri.parse(webPaymentUrl);
        
        if (await canLaunchUrl(paymentUri)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('מעביר לעמוד תשלום מאובטח... לאחר התשלום המערכת תתעדכן אוטומטית.'),
                backgroundColor: Colors.blueGrey,
                duration: Duration(seconds: 4),
              ),
            );
          }
          
          await Future.delayed(const Duration(seconds: 1));
          await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
          return false; 
        } else {
          throw Exception('Could not launch payment URL');
        }
      } else {
        // סימולציה זמנית למובייל בארגז החול
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
  /// מנגנון האזנה גלובלי - מודיע לרכיבי UI מתי סטטוס הפרימיום השתנה בזמן אמת
  static final ValueNotifier<int> stateNotifier = ValueNotifier(0);
  static void notifyStateChanged() => stateNotifier.value++;

  static bool _forceFreeMode = false;
  
  /// מתג מפתחים: כופה על המערכת להתייחס למשתמש כ"חינמי" לצורכי בדיקות (QA)
  static bool get forceFreeMode => _forceFreeMode;
  static set forceFreeMode(bool val) {
    _forceFreeMode = val;
    notifyStateChanged(); // עדכון מיידי של כל הכותרות באפליקציה
  }

  /// בודק באופן אסינכרוני האם המשתמש זכאי לפרימיום (משמש לתצוגות UI כמו הכתר בכותרת)
  static Future<bool> isUserPremium() async {
    if (_forceFreeMode) return false;
    final userData = await DatabaseHelper.instance.getUserRootData();
    if (userData == null) return false;
    
    final isPremium = userData['isPremium'] == true;
    final generation = userData['generation'] ?? 'Regular';
    return isPremium || generation == 'Alpha' || generation == 'Beta';
  }

  /// עוטף פעולות הדורשות מנוי פרימיום.
  static Future<void> requirePremium(BuildContext context, VoidCallback onGranted) async {
    if (_forceFreeMode) {
      _showPaywall(context, onGranted);
      return;
    }

    final userData = await DatabaseHelper.instance.getUserRootData();
    if (!context.mounted) return;

    final generation = userData?['generation'] ?? 'Regular';
    final isPremium = userData?['isPremium'] ?? false;
    final metrics = userData?['metrics'] as Map<String, dynamic>? ?? {};
    final hasSeenFoundersGift = metrics['hasSeenFoundersGift'] == true;

    if (isPremium) {
      onGranted();
      return;
    }

    if (generation == 'Alpha' || generation == 'Beta') {
      if (hasSeenFoundersGift) {
        onGranted();
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icon/crown_icon.png', 
                width: 64, 
                height: 64,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.workspace_premium, color: Colors.amber, size: 64),
              ),
              const SizedBox(height: 16),
              const Text(
                "פיצ'ר פרימיום פתוח!",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 20),
              ),
            ],
          ),
          content: const Text(
            "זיהינו שאתה מהמשתמשים הראשונים של דוחכם.\n\nלאות תודה, כל פיצ'רי הפרימיום (מנוע החירות, מכונת הזמן לחובות, אקדמיה וסטטיסטיקות שכר) פתוחים עבורך כרגע בחינם לחלוטין. תהנה!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, fontSize: 15, height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                elevation: 2,
              ),
              onPressed: () async {
                await DatabaseHelper.instance.updateUserMetric('hasSeenFoundersGift', true);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                onGranted();
              },
              child: const Text("תודה, המשך", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      );
    } else {
      _showPaywall(context, onGranted);
    }
  }

  static void _showPaywall(BuildContext context, VoidCallback onGranted) {
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/icon/premium_icon.png', 
                      width: 72, 
                      height: 72,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.workspace_premium, color: Colors.amber, size: 72),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fintel Pro',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      "שדרג ל-Fintel Pro\nשליטה מוחלטת בתזרים",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildBullet("ייצוב שכר תנודתי."),
                    const SizedBox(height: 12),
                    _buildBullet("מערכת 'אנטי-הפתעות' מתקדמת."),
                    const SizedBox(height: 12),
                    _buildBullet("מכונת זמן לחיסול חובות מואץ (הצלף)."),
                    const SizedBox(height: 12),
                    _buildBullet("גישה מלאה לאקדמיית Fintel."),
                    const SizedBox(height: 12),
                    _buildBullet("בניית מפת דרכים לחירות פיננסית."),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: isProcessing 
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A3FF)))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A3FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              setState(() => isProcessing = true);
                              bool success = await HybridBillingEngine.purchasePro(ctx);
                              
                              if (!ctx.mounted) return;
                              
                              if (success) {
                                Navigator.pop(ctx);
                                await DatabaseHelper.instance.setPremiumStatus(true);
                                
                                if (PremiumService.forceFreeMode) {
                                  PremiumService.forceFreeMode = false;
                                } else {
                                  PremiumService.notifyStateChanged();
                                }
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Text('מצב פיתוח: המנוי הופעל בהצלחה!  '),
                                          Image.asset('assets/icon/crown_icon.png', width: 16, height: 16, errorBuilder: (_,__,___) => const SizedBox.shrink()),
                                        ]
                                      ), 
                                      backgroundColor: Colors.green
                                    ),
                                  );
                                }
                                onGranted();
                              } else {
                                setState(() => isProcessing = false);
                                if (!kIsWeb) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('התשלום בוטל או נכשל. נסה שוב.'), 
                                      backgroundColor: Colors.redAccent
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text("התחל 30 ימי ניסיון חינם", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                      child: const Text(
                        "לא תודה, אמשיך בגרסה החינמית הבסיסית",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildBullet(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF00FF85), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
      ],
    );
  }
}