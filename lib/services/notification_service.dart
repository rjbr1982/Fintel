// 🔒 STATUS: NEW (Fintel Smart Notification Engine - 3 Layer Strategy)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService instance = NotificationService._();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._();

  Future<void> init() async {
    // 1. אתחול אזורי זמן
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Jerusalem')); // Fallback למקרה שגיאה
    }

    // 2. אתחול הגדרות ה-OS (Android & iOS)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(initSettings);
    
    // 3. בקשת הרשאות מפורשת (קריטי לאנדרואיד 13+ ול-iOS)
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  NotificationDetails _getDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'fintel_smart_alerts',
        'Fintel Alerts',
        channelDescription: 'Smart financial triggers and reminders',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF00A3FF),
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ==========================================
  // שכבה 1: תפעול שוטף (Operational Layer)
  // ==========================================

  /// מתזמן התראת ה-1 לחודש (Auto-Rollover)
  Future<void> scheduleMonthlyRollover() async {
    await _notificationsPlugin.cancel(101); // ביטול קודם כדי למנוע כפילויות
    
    final now = tz.TZDateTime.now(tz.local);
    int nextMonth = now.month == 12 ? 1 : now.month + 1;
    int year = now.month == 12 ? now.year + 1 : now.year;
    
    var scheduledDate = tz.TZDateTime(tz.local, year, nextMonth, 1, 9, 0); // 1 לחודש ב-09:00 בבוקר

    await _notificationsPlugin.zonedSchedule(
      101,
      'ה-1 לחודש הגיע! 🗓️',
      'Fintel ביצעה עבורך את גלגול החסכונות והתקציב. היכנס לבדוק שהכל תקין.',
      scheduledDate,
      _getDetails(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, // יחזור על עצמו כל 1 לחודש
    );
  }

  /// מתזמן את יום המשיכות המרוכז שהמשתמש הגדיר
  Future<void> scheduleWithdrawalDay(int dayOfMonth) async {
    await _notificationsPlugin.cancel(102); 
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, dayOfMonth, 10, 0); // בשעה 10:00
    
    if (scheduledDate.isBefore(now)) {
      int nextMonth = now.month == 12 ? 1 : now.month + 1;
      int year = now.month == 12 ? now.year + 1 : now.year;
      scheduledDate = tz.TZDateTime(tz.local, year, nextMonth, dayOfMonth, 10, 0);
    }

    await _notificationsPlugin.zonedSchedule(
      102,
      'תחנת יציאה: ריכוז משיכות 🏦',
      'היום ה-$dayOfMonth לחודש. זה הזמן לרכז ולבצע את כל המשיכות שתיעדת מול הפיקדונות בבנק.',
      scheduledDate,
      _getDetails(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, 
    );
  }

  /// תזכורת רמזור קניות (מופעל 6 ימים מהקנייה האחרונה)
  Future<void> scheduleShoppingReminder() async {
    await _notificationsPlugin.cancel(103); 
    
    // קובע התראה לעוד 6 ימים מהיום, בשעה 18:00
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = now.add(const Duration(days: 6));
    scheduledDate = tz.TZDateTime(tz.local, scheduledDate.year, scheduledDate.month, scheduledDate.day, 18, 0);

    await _notificationsPlugin.zonedSchedule(
      103,
      'קנייה מרוכזת שבועית 🛒',
      'מכינים רשימה לסופר? אל תשכחו לבדוק את מדד ה"דלתא" באפליקציה כדי להגן על התקציב.',
      scheduledDate,
      _getDetails(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ==========================================
  // שכבה 2: המרה חכמה - פרימיום (Conversion Layer)
  // ==========================================

  /// מתזמן "טפטוף" שיווקי עדין למשתמשים חינמיים. אם משדרגים -> מבטלים.
  Future<void> setupPremiumTeasers(bool isPremium) async {
    if (isPremium) {
      // אם הוא בפרימיום, מבטלים את כל הטיזרים השיווקיים
      await _notificationsPlugin.cancel(301);
      await _notificationsPlugin.cancel(302);
      await _notificationsPlugin.cancel(303);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    // טיזר 1: בעוד 14 ימים (מנוע החירות)
    await _notificationsPlugin.zonedSchedule(
      301,
      'הכסף שלך עובד בשבילך? 💸',
      'חבר את הנכסים וההשקעות שלך למנוע החירות (Premium) וגלה באיזו שנה תוכל להפסיק לעבוד.',
      now.add(const Duration(days: 14)),
      _getDetails(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // טיזר 2: בעוד 30 ימים (מכונת הזמן לחובות)
    await _notificationsPlugin.zonedSchedule(
      302,
      'סיימת לשלם הלוואה? 🎯',
      'אל תיתן לכסף להיבלע בעו"ש. הפעל את "מכונת הזמן" (Premium) וראה איך לחסל את החובות שנים קודם.',
      now.add(const Duration(days: 30)),
      _getDetails(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // טיזר 3: בעוד 60 ימים (ייצוב שכר)
    await _notificationsPlugin.zonedSchedule(
      303,
      'הכנסה תנודתית = גירעון סמוי 📉',
      'הפעל את מנוע השכר (Premium) וייצב את התזרים שלך אחת ולתמיד, בלי הפתעות.',
      now.add(const Duration(days: 60)),
      _getDetails(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ==========================================
  // שכבה 3: התראות מיידיות (Immediate Actions)
  // ==========================================

  Future<void> showImmediateVictory(String title, String body) async {
    await _notificationsPlugin.show(
      999, // מזהה שרירותי חד פעמי
      title,
      body,
      _getDetails(),
    );
  }
}