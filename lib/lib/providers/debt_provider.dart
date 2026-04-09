import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/database_helper.dart';
import '../data/debt_model.dart';

/// אובייקט עזר המייצג שורת נתונים בלוח הסילוקין
class DebtScheduleMonth {
  final DateTime month;
  final Map<int, double> debtBalances; 
  final double totalRemaining;

  DebtScheduleMonth({
    required this.month,
    required this.debtBalances,
    required this.totalRemaining,
  });
}

class DebtProvider with ChangeNotifier {
  List<Debt> _debts = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  DebtProvider() {
    _initNotificationsSafe();
  }

  // --- אתחול והגדרות ---
  Future<void> _initNotificationsSafe() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
        );
        await _notificationsPlugin.initialize(initializationSettings);
        _notificationsInitialized = true;
      }
    } catch (e) {
      debugPrint('Notification initialization bypassed: $e');
    }
  }

  // מחזיר את כל החובות ממוינים (היה בשימוש ב-main.dart)
  List<Debt> get debts {
    final sortedList = List<Debt>.from(_debts);
    sortedList.sort((a, b) => a.timeFactor.compareTo(b.timeFactor));
    return sortedList;
  }

  // מחזיר רק חובות פעילים (לשימוש בטבלאות וסימולציות כפי שביקשת)
  List<Debt> get activeDebts {
    return _debts.where((d) => d.currentBalance > 0).toList()
      ..sort((a, b) => a.timeFactor.compareTo(b.timeFactor));
  }

  // --- מאפיינים פיננסיים (Getters) עבור הסנכרון ---
  double get totalMonthlyPayment => activeDebts.fold(0.0, (sum, item) => sum + item.monthlyPayment);
  
  double get totalDebt => _debts.fold(0.0, (sum, item) => sum + item.currentBalance);

  double get freedUpPayments => _debts.where((d) => d.currentBalance <= 0).fold(0.0, (sum, d) => sum + d.monthlyPayment);

  // --- פעולות (Methods) ---
  Future<void> loadDebts() async {
    _debts = await DatabaseHelper.instance.getDebts();
    notifyListeners();
  }

  Future<void> addDebt(Debt debt) async {
    await DatabaseHelper.instance.insertDebt(debt);
    await loadDebts();
  }

  Future<void> updateDebt(Debt debt) async {
    final oldDebt = _debts.firstWhere((d) => d.id == debt.id, orElse: () => debt);
    await DatabaseHelper.instance.updateDebt(debt);
    await loadDebts();
    if (oldDebt.currentBalance > 0 && debt.currentBalance <= 0) {
      _showLiquidationNotificationSafe(debt.name, debt.monthlyPayment);
    }
  }

  Future<void> deleteDebt(int id) async {
    await DatabaseHelper.instance.deleteDebt(id);
    await loadDebts();
  }

  // --- מנוע כדור השלג המעודכן ששלחת ---
  List<DebtScheduleMonth> generatePayoffSchedule(double monthlyDiversion) {
    List<DebtScheduleMonth> schedule = [];
    final filteredDebts = activeDebts;
    if (filteredDebts.isEmpty) return schedule;

    List<Map<String, dynamic>> simulatedDebts = filteredDebts.map((d) => {
      'id': d.id,
      'balance': d.currentBalance,
      'payment': d.monthlyPayment,
    }).toList();

    DateTime currentMonth = DateTime.now();
    Map<int, double> initialBalances = {};
    double initialTotal = 0;
    for (var d in simulatedDebts) {
      initialBalances[d['id']] = d['balance'];
      initialTotal += d['balance'];
    }
    
    schedule.add(DebtScheduleMonth(
      month: currentMonth,
      debtBalances: initialBalances,
      totalRemaining: initialTotal,
    ));

    bool allPaid = initialTotal <= 0;
    int safetyCounter = 0;

    while (!allPaid && safetyCounter < 360) {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
      Map<int, double> monthlyBalances = {};
      double extraMoney = monthlyDiversion;
      double monthTotal = 0;

      for (var d in simulatedDebts) {
        if (d['balance'] > 0) {
          double payment = d['payment'];
          if (d['balance'] < payment) {
            extraMoney += (payment - d['balance']);
            d['balance'] = 0.0;
          } else {
            d['balance'] -= payment;
          }
        }
      }

      for (var d in simulatedDebts) {
        if (extraMoney <= 0) break;
        if (d['balance'] > 0) {
          if (d['balance'] <= extraMoney) {
            extraMoney -= d['balance'];
            d['balance'] = 0.0;
          } else {
            d['balance'] -= extraMoney;
            extraMoney = 0;
          }
        }
      }

      for (var d in simulatedDebts) {
        monthlyBalances[d['id']] = d['balance'];
        monthTotal += d['balance'];
      }

      schedule.add(DebtScheduleMonth(
        month: currentMonth,
        debtBalances: monthlyBalances,
        totalRemaining: monthTotal,
      ));

      if (monthTotal <= 0) allPaid = true;
      safetyCounter++;
    }
    return schedule;
  }

  // --- חישובי עזר למסכים ---
  DateTime get originalFinalPayoffDate {
    if (_debts.isEmpty) return DateTime.now();
    int maxMonths = 0;
    for (var debt in activeDebts) {
      if (debt.monthlyPayment > 0) {
        int months = (debt.currentBalance / debt.monthlyPayment).ceil();
        if (months > maxMonths) maxMonths = months;
      }
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month + maxMonths);
  }

  Map<int, DateTime> calculateAcceleratedDates(double monthlyDiversion) {
    final schedule = generatePayoffSchedule(monthlyDiversion);
    Map<int, DateTime> endDates = {};
    for (var debt in activeDebts) {
      try {
        final finishMonth = schedule.firstWhere((m) => (m.debtBalances[debt.id] ?? 0) <= 0);
        endDates[debt.id!] = finishMonth.month;
      } catch (_) {
        endDates[debt.id!] = DateTime.now();
      }
    }
    return endDates;
  }

  double getAcceleratedPaymentForDebt(int debtId, double monthlyDiversion) {
    double accumulatedBefore = 0;
    for (var debt in activeDebts) {
      if (debt.id == debtId) return debt.monthlyPayment + monthlyDiversion + accumulatedBefore;
      if (debt.currentBalance <= 0) accumulatedBefore += debt.monthlyPayment;
    }
    return 0;
  }

  DateTime getAcceleratedFinalPayoffDate(double monthlyDiversion) {
    final schedule = generatePayoffSchedule(monthlyDiversion);
    return schedule.isEmpty ? DateTime.now() : schedule.last.month;
  }

  double totalMonthlyMission(double monthlyDiversion) => monthlyDiversion + freedUpPayments;

  Debt? get nextTargetDebt {
    try {
      return activeDebts.first;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showLiquidationNotificationSafe(String name, double payment) async {
    if (!_notificationsInitialized) return;
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'liquidation_channel', 'חיסול חובות',
        importance: Importance.max, priority: Priority.high, color: Color(0xFF00C853),
      );
      const NotificationDetails details = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(DateTime.now().millisecond, 'חיסול בוצע! 🎉',
        'החוב "$name" חוסל רשמית.', details);
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }
}