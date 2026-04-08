// 🔒 STATUS: EDITED (Added forceFreeMode, Gamma Billing Infrastructure, Fixed Linter Warnings)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/database_helper.dart';

/// מנוע החיוב ההיברידי (מפריד בין רכישות מובייל לרכישות דפדפן)
class HybridBillingEngine {
  // PENDING: Replace with the actual payment gateway link for Gamma phase
  static const String webPaymentUrl = 'https://meshulam.co.il/or/YOUR_PAYMENT_LINK';

  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint('HybridBillingEngine: Web Gateway initialized');
    } else {
      // PENDING: Initialize RevenueCat (purchases_flutter)
      // await Purchases.setLogLevel(LogLevel.debug);
      // await Purchases.configure(PurchasesConfiguration("YOUR_PUBLIC_KEY"));
      debugPrint('HybridBillingEngine: Native RevenueCat initialized');
    }
  }

  static Future<bool> purchasePro(BuildContext context) async {
    try {
      if (kIsWeb) {
        // עקיפת סליקה לדפדפן (Web Billing Bypass - סעיף 13.7)
        final Uri paymentUri = Uri.parse(webPaymentUrl);
        
        if (await canLaunchUrl(paymentUri)) {
          // מציג הודעת הסבר למשתמש לפני המעבר לעמוד התשלום
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
          
          // בדפדפן התשלום מבוצע מחוץ לאפליקציה, לכן נחזיר false בינתיים
          // ה-Webhook בשרת יערוך את מסד הנתונים ברקע.
          return false; 
        } else {
          throw Exception('Could not launch payment URL');
        }
      } else {
        // PENDING: Trigger RevenueCat native bottom sheet for Mobile
        // final purchaserInfo = await Purchases.purchasePackage(package);
        // return purchaserInfo.entitlements.all["pro"]?.isActive == true;
        
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
  /// מתג מפתחים: כופה על המערכת להתייחס למשתמש כ"חינמי" לצורכי בדיקות (QA)
  static bool forceFreeMode = false;

  /// עוטף פעולות הדורשות מנוי פרימיום.
  /// בודק מול בסיס הנתונים: משלמים או מייסדים עוברים, רגילים מקבלים מסך חומת התשלום (Paywall).
  static Future<void> requirePremium(BuildContext context, VoidCallback onGranted) async {
    // עקיפת מפתחים: אם המתג דלוק, מתעלמים מכל הנתונים ומקפיצים חומת תשלום
    if (forceFreeMode) {
      _showPaywall(context, onGranted);
      return;
    }

    // משיכת נתוני סטטוס מהירה (שקופה)
    final userData = await DatabaseHelper.instance.getUserRootData();
    
    // בדיקת תקינות הקשר (Context) לאחר המתנה לפעולה אסינכרונית
    if (!context.mounted) return;

    final generation = userData?['generation'] ?? 'Regular';
    final isPremium = userData?['isPremium'] ?? false;
    
    // משיכת זיכרון הפופ-אפ מהענן כדי לא להטריד את המשתמש פעמיים
    final metrics = userData?['metrics'] as Map<String, dynamic>? ?? {};
    final hasSeenFoundersGift = metrics['hasSeenFoundersGift'] == true;

    // אם המשתמש הוא משלם (או שלחץ על 'התחל ניסיון' בסימולציה)
    if (isPremium) {
      onGranted();
      return;
    }

    // ניווט לפי דורות: מתנת המייסדים ל-Alpha / Beta
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
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber, size: 56),
              SizedBox(height: 16),
              Text(
                "פיצ'ר פרימיום פתוח! 👑",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 20),
              ),
            ],
          ),
          content: const Text(
            "זיהינו שאתה מהמשתמשים הראשונים של דוחכם.\n\nלאות תודה, כל פיצ'רי הפרימיום (מנוע החירות, מכונת הזמן לחובות וסטטיסטיקות שכר) פתוחים עבורך כרגע בחינם לחלוטין. תהנה!",
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
                // רישום בענן שהמשתמש קיבל את המתנה (כדי שלא יקפוץ שוב בחיים)
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
      // אם זה משתמש רגיל (Regular) ואינו משלם - הצג את חומת התשלום הממירה
      _showPaywall(context, onGranted);
    }
  }

  // =========================================================
  // מסך חומת התשלום (Paywall) - UI שיווקי וממיר
  // =========================================================
  static void _showPaywall(BuildContext context, VoidCallback onGranted) {
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false, // מכריח אותו לקבל החלטה
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header כהה ויוקרתי
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF121212), // Deep Slate
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.amber, size: 56),
                    SizedBox(height: 12),
                    Text(
                      'Fintel Pro',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              
              // תוכן שיווקי
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
                    _buildBullet("בניית מפת דרכים מדויקת לחירות פיננסית."),
                    
                    const SizedBox(height: 32),
                    
                    // כפתור הנעה לפעולה אסינכרוני
                    SizedBox(
                      width: double.infinity,
                      child: isProcessing 
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A3FF)))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A3FF), // Electric Blue
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              setState(() => isProcessing = true);
                              
                              // הפעלת מנוע החיוב ההיברידי (Web / Native)
                              bool success = await HybridBillingEngine.purchasePro(ctx);
                              
                              if (!ctx.mounted) return;
                              
                              if (success) {
                                Navigator.pop(ctx);
                                await DatabaseHelper.instance.setPremiumStatus(true);
                                
                                // אם מצב מפתחים דולק - מכבים אותו אוטומטית כדי לא להיתקע
                                if (PremiumService.forceFreeMode) {
                                  PremiumService.forceFreeMode = false;
                                }
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('מצב פיתוח: המנוי הופעל בהצלחה. ברוך הבא ל-Pro! 👑'), 
                                      backgroundColor: Colors.green
                                    ),
                                  );
                                }
                                onGranted();
                              } else {
                                setState(() => isProcessing = false);
                                // הסרת השגיאה כאן כי בדפדפן הוא הועבר לקישור חיצוני, זה לא בהכרח "נכשל"
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
                    
                    // יציאה (Opt-out)
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

  // רכיב ויזואלי להצגת היתרונות (V)
  static Widget _buildBullet(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF00FF85), size: 20), // Emerald Green
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ),
      ],
    );
  }
}