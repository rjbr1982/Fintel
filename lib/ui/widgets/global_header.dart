// 🔒 STATUS: EDITED (Restored Backward Compatibility: title is optional, showBackButton restored)
import 'package:flutter/material.dart';
import '../screens/sinking_funds_screen.dart'; 

class GlobalHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title; // חזר להיות אופציונלי עבור המסך הראשי
  final bool showSavingsIcon; 
  final bool showBackButton; // הוחזר עבור checking_history_screen

  const GlobalHeader({
    super.key,
    this.title, // ללא required
    this.showSavingsIcon = true,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      automaticallyImplyLeading: showBackButton, // שימוש בפרמטר ההסתרה של כפתור החזור
      title: Text(
        title ?? '', // אם לא הועבר טקסט, יוצג ריק
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        if (showSavingsIcon)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: const Icon(Icons.savings_outlined, color: Colors.green, size: 28),
              tooltip: 'מרכז החסכונות והקופות',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SinkingFundsScreen()),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}