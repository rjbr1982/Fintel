import 'package:flutter/material.dart';

class PremiumService {
  static bool _hasSeenFoundersGift = false;

  /// עוטף פעולות הדורשות מנוי פרימיום. 
  /// כרגע, מקפיץ הודעת "מתנת מייסדים" בפעם הראשונה ומאפשר גישה חינמית.
  static void requirePremium(BuildContext context, VoidCallback onGranted) {
    if (_hasSeenFoundersGift) {
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
            onPressed: () {
              _hasSeenFoundersGift = true;
              Navigator.pop(ctx);
              onGranted();
            },
            child: const Text("תודה, המשך", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}