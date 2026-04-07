// 🔒 STATUS: EDITED (Hybrid Architecture: FCM for Web, Local for Mobile)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../data/database_helper.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService instance = NotificationService._();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._();

  Future<void> init() async {
    // 1. אתחול Firebase Cloud Messaging (רלוונטי לכולם, קריטי ל-Web)
    final messaging = FirebaseMessaging.instance;
    
    // בקשת הרשאות מהמשתמש (יקפיץ חלונית בדפדפן או ב-iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted push permission');
      // משיכת הטוקן הייחודי של המכשיר/דפדפן ושמירתו ב-Firestore תחת המשתמש
      try {
        String? token = await messaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          await DatabaseHelper.instance.updateUserMetric('fcmToken', token);
        }
      } catch (e) {
        debugPrint('Error fetching FCM token: $e');
      }

      // האזנה לרענון טוקנים (במקרה שהדפדפן מחליף טוקן)
      messaging.onTokenRefresh.listen((newToken) async {
        await DatabaseHelper.instance.updateUserMetric('fcmToken', newToken);
      });
    }

    // 2. אתחול התראות מקומיות (רק עבור מובייל, נחסם ב-Web)
    if (!kIsWeb) {
      tz.initializeTimeZones();
      try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        tz.setLocalLocation(tz.getLocation('Asia/Jerusalem')); // Fallback
      }

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // כבר טיפלנו בזה דרך FCM
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _notificationsPlugin.initialize(initSettings);
    }
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
    if (kIsWeb) return; // ב-Web התזמון מנוהל בשרת

    await _notificationsPlugin.cancel(101);
    
    final now = tz.TZDateTime.now(tz.local);
    int nextMonth = now.month == 12 ? 1 : now.month + 1;
    int year = now.month == 12 ? now.year + 1 : now.year;
    
    var scheduledDate = tz.TZDateTime(tz.local, year, nextMonth, 1, 9, 0);

    await _notificationsPlugin.zonedSchedule(
      101,
      'ה-1 לחודש הגיע! 🗓️',
      'Fintel ביצעה עבורך את גלגול החסכונות והתקציב. היכנס לבדוק שהכל תקין.',
      scheduledDate,
      _getDetails(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, 
    );
  }

  /// מתזמן את יום המשיכות המרוכז שהמשתמש הגדיר
  Future<void> scheduleWithdrawalDay(int dayOfMonth) async {
    if (kIsWeb) return; // ב-Web התזמון מנוהל בשרת

    await _notificationsPlugin.cancel(102); 
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, dayOfMonth, 10, 0); 
    
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
    if (kIsWeb) return; // ב-Web התזמון מנוהל בשרת

    await _notificationsPlugin.cancel(103); 
    
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

  /// מתזמן "טפטוף" שיווקי עדין למשתמשים חינמיים
  Future<void> setupPremiumTeasers(bool isPremium) async {
    if (kIsWeb) return; // ב-Web התזמון מנוהל בשרת

    if (isPremium) {
      await _notificationsPlugin.cancel(301);
      await _notificationsPlugin.cancel(302);
      await _notificationsPlugin.cancel(303);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    await _notificationsPlugin.zonedSchedule(
      301,
      'הכסף שלך עובד בשבילך? 💸',
      'חבר את הנכסים וההשקעות שלך למנוע החירות (Premium) וגלה באיזו שנה תוכל להפסיק לעבוד.',
      now.add(const Duration(days: 14)),
      _getDetails(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    await _notificationsPlugin.zonedSchedule(
      302,
      'סיימת לשלם הלוואה? 🎯',
      'אל תיתן לכסף להיבלע בעו"ש. הפעל את "מכונת הזמן" (Premium) וראה איך לחסל את החובות שנים קודם.',
      now.add(const Duration(days: 30)),
      _getDetails(),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

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
    if (kIsWeb) {
      // ב-Web נציג התראה מקומית בדפדפן אם פתוח, כרגע נשאיר לוג בלבד
      debugPrint('Victory Web Push: $title - $body');
      return;
    }

    await _notificationsPlugin.show(
      999, 
      title,
      body,
      _getDetails(),
    );
  }
}