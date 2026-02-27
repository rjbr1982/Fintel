// 🔒 STATUS: EDITED (Integrated Salary Math Engine & Dynamic Support - Finalized Streams)
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../data/database_helper.dart';
import '../data/expense_model.dart';

class BudgetProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  List<FamilyMember> _familyMembers = [];
  
  double _externalDebtPayment = 0;
  bool _hasActiveDebts = false;
  
  bool _isFutureMode = false;
  
  double _variableDeficit = 0.0;

  static const double defaultVariableRatio = 0.833; 
  static const double defaultFutureRatio = 0.85;    
  static const int defaultChildCount = 3;

  // --- משתני משפחה דינמיים ---
  String _maritalStatus = 'married'; 
  int _childCount = defaultChildCount; 
  
  double _variableAllocationRatio = defaultVariableRatio; 
  double _futureAllocationRatio = defaultFutureRatio;    

  // --- משתני מנוע החירות ---
  double _initialCapital = 0.0;
  double _expectedYield = 4.0;
  int _compoundingFrequency = 12;
  double? _manualTargetIncome;

  // --- מנועי שכר (NEW) ---
  List<SalaryRecord> _salaryRecords = [];

  // --- מנויי האזנה לענן ---
  StreamSubscription? _expensesSub;
  StreamSubscription? _familySub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _assetsSub;
  StreamSubscription? _salaryRecordsSub; // <-- נוסף כאן
  bool _isListening = false;

  List<Expense> get expenses => _expenses;
  List<FamilyMember> get familyMembers => _familyMembers;
  List<SalaryRecord> get salaryRecords => _salaryRecords;
  int get childCount => _childCount;
  String get maritalStatus => _maritalStatus;
  
  double get variableAllocationRatio => _variableAllocationRatio;
  double get futureAllocationRatio => _futureAllocationRatio;
  bool get isFutureMode => _isFutureMode;
  
  double get variableDeficit => _variableDeficit;

  double get initialCapital => _initialCapital;
  double get expectedYield => _expectedYield;
  int get compoundingFrequency => _compoundingFrequency;
  double? get manualTargetIncome => _manualTargetIncome;

  double get autoTargetIncome => totalFixedExpenses + totalVariableExpenses + totalFutureExpenses;
  double get targetPassiveIncome => _manualTargetIncome ?? autoTargetIncome;

  @override
  void dispose() {
    _expensesSub?.cancel();
    _familySub?.cancel();
    _settingsSub?.cancel();
    _assetsSub?.cancel();
    _salaryRecordsSub?.cancel(); // <-- נוסף כאן
    super.dispose();
  }

  Future<void> syncCapitalFromAssets() async {
    final assets = await DatabaseHelper.instance.getAssets();
    _initialCapital = assets.fold(0.0, (sum, item) => sum + item.value);
    notifyListeners();
  }

  Future<void> loadData() async {
    try {
      _expenses = await DatabaseHelper.instance.getExpenses();
      _familyMembers = await DatabaseHelper.instance.getFamilyMembers();
      
      // Data load for Salary Records will be hooked up after DatabaseHelper is updated
      
      await syncCapitalFromAssets(); 
      _expectedYield = await DatabaseHelper.instance.getSetting('expected_yield') ?? 4.0;
      _compoundingFrequency = (await DatabaseHelper.instance.getSetting('comp_freq') ?? 12.0).toInt();
      _manualTargetIncome = await DatabaseHelper.instance.getSetting('manual_target_income');
      
      _variableAllocationRatio = await DatabaseHelper.instance.getSetting('variable_ratio') ?? defaultVariableRatio;
      _futureAllocationRatio = await DatabaseHelper.instance.getSetting('future_ratio') ?? defaultFutureRatio;
      
      _childCount = (await DatabaseHelper.instance.getSetting('child_count') ?? defaultChildCount.toDouble()).toInt();
      double msVal = await DatabaseHelper.instance.getSetting('marital_status') ?? 2.0;
      _maritalStatus = msVal == 1.0 ? 'single' : 'married';

      await _forceCategorySync();
      await _performAutoRollover();
      _recalculateAll();
      notifyListeners();

      if (!_isListening) {
        _setupStreams();
        _isListening = true;
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  void _setupStreams() {
    _expensesSub = DatabaseHelper.instance.streamExpenses().listen((data) {
      _expenses = data;
      _recalculateAll();
      notifyListeners();
    });

    _familySub = DatabaseHelper.instance.streamFamilyMembers().listen((data) {
      _familyMembers = data;
      notifyListeners();
    });

    _assetsSub = DatabaseHelper.instance.streamAssets().listen((data) {
      double newCapital = data.fold(0.0, (sum, item) => sum + item.value);
      if (_initialCapital != newCapital) {
        _initialCapital = newCapital;
        notifyListeners();
      }
    });

    // ההאזנה למנוע השכר בזמן אמת <-- נוסף כאן
    _salaryRecordsSub = DatabaseHelper.instance.streamSalaryRecords().listen((data) {
      _salaryRecords = data;
      _recalculateAll();
      notifyListeners();
    });

    _settingsSub = DatabaseHelper.instance.streamSettings().listen((snap) {
      bool changed = false;
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final key = data['key'];
        final val = (data['value'] as num?)?.toDouble();

        if (key == 'expected_yield' && val != null && _expectedYield != val) { _expectedYield = val; changed = true; }
        if (key == 'comp_freq' && val != null && _compoundingFrequency != val.toInt()) { _compoundingFrequency = val.toInt(); changed = true; }
        if (key == 'manual_target_income' && _manualTargetIncome != val) { _manualTargetIncome = val; changed = true; }
        if (key == 'variable_ratio' && val != null && _variableAllocationRatio != val) { _variableAllocationRatio = val; changed = true; }
        if (key == 'future_ratio' && val != null && _futureAllocationRatio != val) { _futureAllocationRatio = val; changed = true; }
        if (key == 'child_count' && val != null && _childCount != val.toInt()) { _childCount = val.toInt(); changed = true; }
        if (key == 'marital_status' && val != null) { 
          String newStatus = val == 1.0 ? 'single' : 'married';
          if (_maritalStatus != newStatus) { _maritalStatus = newStatus; changed = true; }
        }
      }
      if (changed) {
        _recalculateAll();
        notifyListeners();
      }
    });
  }

  Future<void> updateFamilyStructure({String? maritalStatus, int? childrenCount}) async {
    if (maritalStatus != null) {
      await DatabaseHelper.instance.saveSetting('marital_status', maritalStatus == 'single' ? 1.0 : 2.0);
      _maritalStatus = maritalStatus;
    }
    if (childrenCount != null) {
      await DatabaseHelper.instance.saveSetting('child_count', childrenCount.toDouble());
      _childCount = childrenCount;
    }
    await _forceCategorySync();
    _recalculateAll();
    notifyListeners();
  }

  Future<void> setChildCount(int count) async {
    await updateFamilyStructure(childrenCount: count);
  }

  Future<void> setFreedomSettings({
    double? manualTarget,
    required double yieldRate,
    required int frequency,
  }) async {
    _manualTargetIncome = manualTarget;
    _expectedYield = yieldRate;
    _compoundingFrequency = frequency;
    notifyListeners();

    if (manualTarget != null) {
      await DatabaseHelper.instance.saveSetting('manual_target_income', manualTarget);
    } else {
      await DatabaseHelper.instance.deleteSetting('manual_target_income');
    }
    await DatabaseHelper.instance.saveSetting('expected_yield', yieldRate);
    await DatabaseHelper.instance.saveSetting('comp_freq', frequency.toDouble());
  }

  int? calculateMonthsToFreedom() {
    double cap = _initialCapital;
    double monthlyDeposit = totalFinancialExpenses; 
    double yieldRate = _expectedYield / 100.0;
    double targetAnnual = targetPassiveIncome * 12;

    if (yieldRate <= 0 && targetAnnual > 0) return null; 
    if ((cap * yieldRate) >= targetAnnual) return 0; 

    int months = 0;
    while (months < 1200) { 
      cap += monthlyDeposit;
      
      if (_compoundingFrequency == 1) { 
        if (months > 0 && months % 12 == 0) cap += cap * yieldRate;
      } else if (_compoundingFrequency == 12) { 
        cap += cap * (yieldRate / 12);
      } else if (_compoundingFrequency == 52) { 
        cap *= math.pow(1 + yieldRate / 52, 52 / 12).toDouble();
      }

      if ((cap * yieldRate) >= targetAnnual) return months;
      months++;
    }
    return null; 
  }

  Map<String, double> _getDynamicVariableRatios() {
    if (_maritalStatus == 'single' && _childCount > 0) {
      return { 'בגדים אישי': 0.28, 'בילויים אישי': 0.33, 'טיפוח אישי': 0.15, 'בגדים ילדים': 0.12, 'בילויים ילדים': 0.12 };
    } else if (_maritalStatus == 'married' && _childCount == 0) {
      return { 'בגדים אבא': 0.25, 'בילויים אבא': 0.20, 'בגדים אמא': 0.15, 'בילויים אמא': 0.25, 'טיפוח אמא': 0.15 };
    } else if (_maritalStatus == 'single' && _childCount == 0) {
      return { 'בגדים אישי': 0.40, 'בילויים אישי': 0.45, 'טיפוח אישי': 0.15 };
    } else {
      return { 'בגדים אבא': 0.19, 'בילויים אבא': 0.14, 'בגדים אמא': 0.09, 'בילויים אמא': 0.19, 'טיפוח אמא': 0.15, 'בגדים ילדים': 0.12, 'בילויים ילדים': 0.12 };
    }
  }

  Future<void> resetExpenseToDefault(int expenseId) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;
    
    final name = _expenses[index].name;
    String nameForMatch = name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');

    final Map<String, double> defaultRatios = {
      ..._getDynamicVariableRatios(), 
      'מקדמה לבית': 0.67, 
      'בר מצווה אליעזר': 0.11,
      'חופשה שנתית': 0.11,
      'תנור גז': 0.07, 
      'הדברה': 0.02, 
      'רפואי': 0.02,
    };

    double defaultRatio = defaultRatios[nameForMatch] ?? 0.0;

    final old = _expenses[index];
    final updated = Expense(
      id: old.id, name: old.name, category: old.category, parentCategory: old.parentCategory,
      monthlyAmount: 0, originalAmount: old.originalAmount, frequency: old.frequency,
      isSinking: old.isSinking, isPerChild: old.isPerChild, targetAmount: old.targetAmount,
      currentBalance: old.currentBalance, allocationRatio: defaultRatio,
      lastUpdateDate: old.lastUpdateDate, isLocked: false, manualAmount: null, date: old.date,
      isDynamicSalary: old.isDynamicSalary, salaryStartDate: old.salaryStartDate,
    );

    await DatabaseHelper.instance.updateExpense(updated);
  }

  Future<void> _forceCategorySync() async {
    if (_expenses.isEmpty) return;

    bool changed = false;
    final now = DateTime.now().toIso8601String();

    if (_childCount > 0) {
      final kidsFixed = ['שכר לימוד', 'ציוד בית ספר', 'חוגים', 'מתנות לימי הולדת', 'קייטנות'];
      for (String kf in kidsFixed) {
        if (!_expenses.any((e) => e.name == kf || (kf == 'מתנות לימי הולדת' && e.name == 'מתנות ימי הולדת'))) {
           await DatabaseHelper.instance.insertExpense(Expense(
               name: kf, category: 'קבועות', parentCategory: 'ילדים - קבועות',
               monthlyAmount: 0, originalAmount: 0, isSinking: true, isPerChild: true,
               frequency: (kf == 'ציוד בית ספר' || kf == 'קייטנות') ? Frequency.YEARLY : Frequency.MONTHLY,
               date: now, isDynamicSalary: false,
           ));
           changed = true;
        }
      }
    }

    final Map<String, Map<String, String>> syncRules = {
      'בגדים ילדים': {'cat': 'משתנות', 'parent': 'ילדים - משתנות'},
      'בילויים ילדים': {'cat': 'משתנות', 'parent': 'ילדים - משתנות'},
      'שכר לימוד': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'},
      'ציוד בית ספר': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'},
      'חוגים': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'},
      'מתנות לימי הולדת': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'}, 
      'מתנות ימי הולדת': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'}, 
      'קייטנות': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'},
      'תספורת': {'cat': 'קבועות', 'parent': 'תספורת'},
      'קטנות לבית': {'cat': 'קבועות', 'parent': 'קטנות לבית'},
    };

    final Map<String, double> requiredRatios = {
      'מקדמה לבית': 0.67, 'בר מצווה אליעזר': 0.11, 'חופשה שנתית': 0.11,
      'תנור גז': 0.07, 'הדברה': 0.02, 'רפואי': 0.02,
    };

    final Map<String, double> targetVariableRatios = _getDynamicVariableRatios();
    final List<String> allPossibleVariableNames = [
      'בגדים אבא', 'בילויים אבא', 'בגדים אמא', 'בילויים אמא', 'טיפוח אמא',
      'בגדים ילדים', 'בילויים ילדים', 'בגדים אישי', 'בילויים אישי', 'טיפוח אישי'
    ];

    final sinkingNames = [
      'הובלה ותיקונים', 'טסט', 'ביטוח', 'טיפול', 'תיקונים', 'מייקרוסופט',
      'שכר לימוד', 'ציוד בית ספר', 'חוגים', 'מתנות ימי הולדת', 'מתנות לימי הולדת', 'קייטנות',
      'נסיעות', 'קטנות לבית', 'בילויים'
    ];

    for (int i = 0; i < _expenses.length; i++) {
      final e = _expenses[i];
      if (e.name == 'פארם וניקיון') {
        await DatabaseHelper.instance.deleteExpense(e.id!);
        changed = true;
        continue;
      }

      bool needsUpdate = false;
      String newCat = e.category;
      String newParent = e.parentCategory;
      bool newIsPerChild = e.isPerChild;
      String nameForMatch = e.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');

      if (syncRules.containsKey(nameForMatch)) {
        final rule = syncRules[nameForMatch]!;
        if (e.category != rule['cat'] || e.parentCategory != rule['parent']) {
          newCat = rule['cat']!;
          newParent = rule['parent']!;
          newIsPerChild = (rule['parent']!.startsWith('ילדים') || e.isPerChild);
          needsUpdate = true;
        }
      }

      double? newRatio = e.allocationRatio;
      
      if (requiredRatios.containsKey(nameForMatch)) {
        if (newRatio != requiredRatios[nameForMatch]) {
          newRatio = requiredRatios[nameForMatch];
          needsUpdate = true;
        }
      } 
      else if (allPossibleVariableNames.contains(nameForMatch)) {
        double targetRatio = targetVariableRatios[nameForMatch] ?? 0.0;
        if (newRatio != targetRatio) {
          if (targetRatio == 0.0 || newRatio == 0 || newRatio == null || (newRatio * 100).round() == 10) {
              newRatio = targetRatio;
              needsUpdate = true;
          }
        }
      }

      bool shouldBeSinking = newCat == 'עתידיות' || 
                             newParent == 'חגים' || 
                             (newCat == 'משתנות' && newParent != 'קניות') ||
                             sinkingNames.contains(e.name);

      if (e.name == 'דלק') shouldBeSinking = false;

      bool newIsSinking = e.isSinking;
      if (e.isSinking != shouldBeSinking) {
        newIsSinking = shouldBeSinking;
        needsUpdate = true;
      }

      if (needsUpdate) {
        final updated = Expense(
          id: e.id, name: e.name, category: newCat, parentCategory: newParent,
          monthlyAmount: e.monthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency,
          isSinking: newIsSinking, isPerChild: newIsPerChild,
          targetAmount: e.targetAmount, currentBalance: e.currentBalance, allocationRatio: newRatio,
          lastUpdateDate: e.lastUpdateDate, isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
          isDynamicSalary: e.isDynamicSalary, salaryStartDate: e.salaryStartDate,
        );
        await DatabaseHelper.instance.updateExpense(updated);
        changed = true;
      }
    }

    for (var entry in targetVariableRatios.entries) {
      if (entry.value > 0 && !_expenses.any((e) => e.name == entry.key)) {
        String parentCat = entry.key.contains('ילדים') ? 'ילדים - משתנות' : (entry.key.contains('אישי') ? 'אישי' : (entry.key.contains('אבא') ? 'אבא' : 'אמא'));
        await DatabaseHelper.instance.insertExpense(Expense(
          name: entry.key, category: 'משתנות', parentCategory: parentCat,
          monthlyAmount: 0, originalAmount: 0, isSinking: true,
          isPerChild: entry.key.contains('ילדים'), allocationRatio: entry.value,
          date: now, isDynamicSalary: false,
        ));
        changed = true;
      }
    }
    
    if (changed) {
      _expenses = await DatabaseHelper.instance.getExpenses();
    }
  }

  void updateExternalDebtPayment(double amount) {
    if (_externalDebtPayment != amount) {
      _externalDebtPayment = amount;
      _recalculateAll();
      notifyListeners();
    }
  }

  void updateHasActiveDebts(bool hasDebts) {
    if (_hasActiveDebts != hasDebts) {
      _hasActiveDebts = hasDebts;
      notifyListeners();
    }
  }

  void toggleFutureMode(bool isOn) {
    if (_isFutureMode != isOn) {
      _isFutureMode = isOn;
      _recalculateAll(); 
      notifyListeners();
    }
  }

  Future<void> resetVariableRatio() async {
    await DatabaseHelper.instance.saveSetting('variable_ratio', defaultVariableRatio);
  }

  Future<void> resetFutureRatio() async {
    await DatabaseHelper.instance.saveSetting('future_ratio', defaultFutureRatio);
  }

  Future<void> fullAppReset() async {
    await DatabaseHelper.instance.clearAllData();
    _childCount = defaultChildCount;
    _maritalStatus = 'married';
    _manualTargetIncome = null;
    _initialCapital = 0.0;
    _expectedYield = 4.0;
    _compoundingFrequency = 12;
    _variableAllocationRatio = defaultVariableRatio;
    _futureAllocationRatio = defaultFutureRatio;
    _externalDebtPayment = 0;
    _isFutureMode = false;
    _expenses = [];
    _familyMembers = [];
    _salaryRecords = [];
    notifyListeners();
  }

  Future<void> _performAutoRollover() async {
    bool wasUpdated = false;
    final now = DateTime.now();
    for (int i = 0; i < _expenses.length; i++) {
      final e = _expenses[i];
      if (e.isSinking && e.lastUpdateDate != null) {
        DateTime lastUpdate = DateTime.parse(e.lastUpdateDate!);
        int monthsDiff = (now.year - lastUpdate.year) * 12 + now.month - lastUpdate.month;
        if (monthsDiff > 0) {
          double monthlyDeposit = e.monthlyAmount;
          if (e.isPerChild) monthlyDeposit *= _childCount;
          double addedAmount = monthlyDeposit * monthsDiff;
          
          final updatedExpense = Expense(
            id: e.id, name: e.name, category: e.category, parentCategory: e.parentCategory,
            monthlyAmount: e.monthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency, isSinking: e.isSinking, isPerChild: e.isPerChild,
            targetAmount: e.targetAmount, currentBalance: (e.currentBalance ?? 0) + addedAmount,
            allocationRatio: e.allocationRatio, lastUpdateDate: now.toIso8601String(),
            isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
            isDynamicSalary: e.isDynamicSalary, salaryStartDate: e.salaryStartDate,
          );
          await DatabaseHelper.instance.updateExpense(updatedExpense);
          _expenses[i] = updatedExpense;
          wasUpdated = true;
        }
      }
    }
    if (wasUpdated) notifyListeners();
  }

  // --- מנוע ממוצע שכר (Salary Engine Logic) ---
  
  int getActiveWorkingMonths(Expense expense) {
    if (expense.salaryStartDate == null) return 1;
    try {
      DateTime start = DateTime.parse(expense.salaryStartDate!);
      DateTime now = DateTime.now();
      int months = (now.year - start.year) * 12 + now.month - start.month + 1;
      return months > 0 ? months : 1;
    } catch (e) {
      return 1;
    }
  }

  double getAverageSalary(int expenseId, {bool calendarYear = false}) {
    final records = _salaryRecords.where((r) => r.expenseId == expenseId).toList();
    if (records.isEmpty) return 0.0;
    
    double totalNet = records.fold(0.0, (sum, r) => sum + r.netAmount);
    
    if (calendarYear) {
       return totalNet / DateTime.now().month;
    } else {
       final index = _expenses.indexWhere((e) => e.id == expenseId);
       if (index == -1) return 0.0;
       int active = getActiveWorkingMonths(_expenses[index]);
       return totalNet / active;
    }
  }

  double getAverageHourlyRate(int expenseId) {
    final records = _salaryRecords.where((r) => r.expenseId == expenseId).toList();
    if (records.isEmpty) return 0.0;
    double totalNet = records.fold(0.0, (sum, r) => sum + r.netAmount);
    double totalHours = records.fold(0.0, (sum, r) => sum + r.hours);
    if (totalHours <= 0) return 0.0;
    return totalNet / totalHours;
  }

  Future<void> toggleDynamicSalary(int expenseId, bool isDynamic, {String? startDate}) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final old = _expenses[index];
      final updated = Expense(
        id: old.id, name: old.name, category: old.category, parentCategory: old.parentCategory,
        monthlyAmount: old.monthlyAmount, originalAmount: old.originalAmount, frequency: old.frequency,
        isSinking: old.isSinking, isPerChild: old.isPerChild, targetAmount: old.targetAmount,
        currentBalance: old.currentBalance, allocationRatio: old.allocationRatio,
        lastUpdateDate: old.lastUpdateDate, isLocked: old.isLocked, manualAmount: old.manualAmount, date: old.date,
        isDynamicSalary: isDynamic, salaryStartDate: startDate ?? old.salaryStartDate,
      );
      await DatabaseHelper.instance.updateExpense(updated);
    }
  }

  void _recalculateDynamicSalaries() {
    for (int i = 0; i < _expenses.length; i++) {
      final e = _expenses[i];
      if (e.category == 'הכנסות' && e.isDynamicSalary && e.id != null) {
        double avg = getAverageSalary(e.id!);
        if (e.monthlyAmount != avg) {
          _updateExpenseInMemory(i, avg);
        }
      }
    }
  }

  // --- סוף מנוע ממוצע שכר ---

  void _recalculateAll() {
    _recalculateDynamicSalaries(); // NEW: מתעדכן תמיד לפני כל התקציב
    _recalculateVariableExpenses();
    _recalculateFutureExpenses();
  }

  Future<void> lockExpenseAmount(int expenseId, double amount) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final old = _expenses[index];
      final updated = Expense(
        id: old.id, name: old.name, category: old.category, parentCategory: old.parentCategory,
        monthlyAmount: amount, originalAmount: old.originalAmount, frequency: old.frequency, isSinking: old.isSinking, isPerChild: old.isPerChild,
        targetAmount: old.targetAmount, currentBalance: old.currentBalance, allocationRatio: old.allocationRatio,
        lastUpdateDate: DateTime.now().toIso8601String(),
        isLocked: true, manualAmount: amount, date: old.date,
        isDynamicSalary: old.isDynamicSalary, salaryStartDate: old.salaryStartDate,
      );
      await DatabaseHelper.instance.updateExpense(updated);
    }
  }

  Future<void> updateExpenseRatio(int expenseId, double newRatio) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final old = _expenses[index];
      final updated = Expense(
        id: old.id, name: old.name, category: old.category, parentCategory: old.parentCategory,
        monthlyAmount: 0, originalAmount: old.originalAmount, frequency: old.frequency, isSinking: old.isSinking, isPerChild: old.isPerChild,
        targetAmount: old.targetAmount, currentBalance: old.currentBalance,
        allocationRatio: newRatio, 
        lastUpdateDate: DateTime.now().toIso8601String(),
        isLocked: false, manualAmount: null, date: old.date,
        isDynamicSalary: old.isDynamicSalary, salaryStartDate: old.salaryStartDate,
      );
      await DatabaseHelper.instance.updateExpense(updated);
    }
  }

  Future<void> unlockExpenseAmount(int expenseId) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final old = _expenses[index];
      final updated = Expense(
        id: old.id, name: old.name, category: old.category, parentCategory: old.parentCategory,
        monthlyAmount: 0, originalAmount: old.originalAmount, frequency: old.frequency, isSinking: old.isSinking, isPerChild: old.isPerChild,
        targetAmount: old.targetAmount, currentBalance: old.currentBalance, allocationRatio: old.allocationRatio,
        lastUpdateDate: DateTime.now().toIso8601String(),
        isLocked: false, manualAmount: null, date: old.date,
        isDynamicSalary: old.isDynamicSalary, salaryStartDate: old.salaryStartDate,
      );
      await DatabaseHelper.instance.updateExpense(updated);
    }
  }

  Future<void> updateFutureExpenseDetails(int expenseId, {String? name, double? target, double? balance, double? ratio, bool? isLocked, double? manualAmount}) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final old = _expenses[index];
      final updated = Expense(
        id: old.id, name: name ?? old.name, category: old.category, parentCategory: old.parentCategory,
        monthlyAmount: (isLocked == true && manualAmount != null) ? manualAmount : 0, 
        originalAmount: old.originalAmount, frequency: old.frequency, isSinking: old.isSinking, isPerChild: old.isPerChild,
        targetAmount: target ?? old.targetAmount, currentBalance: balance ?? old.currentBalance,
        allocationRatio: ratio ?? old.allocationRatio, lastUpdateDate: DateTime.now().toIso8601String(),
        isLocked: isLocked ?? old.isLocked, manualAmount: manualAmount ?? old.manualAmount, date: old.date,
        isDynamicSalary: old.isDynamicSalary, salaryStartDate: old.salaryStartDate,
      );
      await DatabaseHelper.instance.updateExpense(updated);
    }
  }

  void _recalculateVariableExpenses() {
    final totalPot = totalVariableExpenses; 
    final variableIndices = <int>[];
    for (int i = 0; i < _expenses.length; i++) {
      if (_expenses[i].category == 'משתנות') variableIndices.add(i);
    }
    if (variableIndices.isEmpty) return;
    
    double usedBudget = 0;
    double totalActiveRatios = 0;
    for (var i in variableIndices) {
      final e = _expenses[i];
      bool isAnchor = (e.allocationRatio == null || e.allocationRatio == 0);
      if (e.isLocked && e.manualAmount != null) {
        usedBudget += e.manualAmount!;
      } else if (isAnchor) {
        usedBudget += e.originalAmount; 
      } else {
        totalActiveRatios += (e.allocationRatio ?? 0);
      }
    }
    
    double remainingBudget = totalPot - usedBudget;
    if (remainingBudget < 0) {
      _variableDeficit = remainingBudget.abs();
      remainingBudget = 0;
    } else {
      _variableDeficit = 0.0;
    }
    
    for (var i in variableIndices) {
      final e = _expenses[i];
      double calculatedAmount = 0;
      bool isAnchor = (e.allocationRatio == null || e.allocationRatio == 0);
      if (e.isLocked && e.manualAmount != null) {
        calculatedAmount = e.manualAmount!;
      } else if (isAnchor) {
        calculatedAmount = e.originalAmount;
      } else {
        if (totalActiveRatios > 0) {
          double ratioShare = (e.allocationRatio!) / totalActiveRatios;
          calculatedAmount = remainingBudget * ratioShare;
        }
      }
      _updateExpenseInMemory(i, calculatedAmount);
    }
  }

  void _recalculateFutureExpenses() {
    final totalPot = totalFutureExpenses; 
    final futureIndices = <int>[];
    for (int i = 0; i < _expenses.length; i++) {
      if (_expenses[i].category == 'עתידיות') futureIndices.add(i);
    }
    if (futureIndices.isEmpty) return;
    
    double usedBudget = 0;
    double totalActiveRatios = 0;
    for (var i in futureIndices) {
      final e = _expenses[i];
      if (e.isLocked && e.manualAmount != null) {
        usedBudget += e.manualAmount!;
      } else {
        totalActiveRatios += (e.allocationRatio ?? 0);
      }
    }
    
    double remainingBudget = totalPot - usedBudget;
    if (remainingBudget < 0) remainingBudget = 0;
    
    for (var i in futureIndices) {
      final e = _expenses[i];
      double calculatedAmount = 0;
      if (e.isLocked && e.manualAmount != null) {
        calculatedAmount = e.manualAmount!;
      } else {
        if (totalActiveRatios > 0) {
          double ratioShare = (e.allocationRatio!) / totalActiveRatios;
          calculatedAmount = remainingBudget * ratioShare;
        }
      }
      _updateExpenseInMemory(i, calculatedAmount);
    }
  }

  void _updateExpenseInMemory(int index, double newMonthlyAmount) {
    final e = _expenses[index];
    _expenses[index] = Expense(
      id: e.id, name: e.name, category: e.category, parentCategory: e.parentCategory,
      monthlyAmount: newMonthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency,
      isSinking: e.isSinking, isPerChild: e.isPerChild, targetAmount: e.targetAmount,
      currentBalance: e.currentBalance, allocationRatio: e.allocationRatio,
      lastUpdateDate: e.lastUpdateDate, isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
      isDynamicSalary: e.isDynamicSalary, salaryStartDate: e.salaryStartDate,
    );
  }

  Future<void> addFamilyMember(String name, int birthYear) async {
    final newMember = FamilyMember(name: name, birthYear: birthYear);
    await DatabaseHelper.instance.insertFamilyMember(newMember);
  }

  Future<void> removeFamilyMember(int id) async {
    await DatabaseHelper.instance.deleteFamilyMember(id);
  }

  Future<void> updateFamilyMember(FamilyMember member) async {
    if (member.id != null) await DatabaseHelper.instance.updateFamilyMember(member);
  }

  Future<void> addExpense(Expense expense) async {
    await DatabaseHelper.instance.insertExpense(expense);
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.id != null) await DatabaseHelper.instance.updateExpense(expense);
  }

  Future<void> deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
  }
  
  Future<void> renameParentCategory(String oldName, String newName) async {
    if (oldName == newName || newName.trim().isEmpty) return;
    for (int i = 0; i < _expenses.length; i++) {
      if (_expenses[i].parentCategory == oldName) {
        final e = _expenses[i];
        final updated = Expense(
          id: e.id, name: e.name, category: e.category, parentCategory: newName.trim(),
          monthlyAmount: e.monthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency,
          isSinking: e.isSinking, isPerChild: e.isPerChild, targetAmount: e.targetAmount,
          currentBalance: e.currentBalance, allocationRatio: e.allocationRatio,
          lastUpdateDate: e.lastUpdateDate, isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
          isDynamicSalary: e.isDynamicSalary, salaryStartDate: e.salaryStartDate,
        );
        await DatabaseHelper.instance.updateExpense(updated);
      }
    }
  }

  Future<void> setAllocationRatios({double? variable, double? future}) async {
    if (variable != null) await DatabaseHelper.instance.saveSetting('variable_ratio', variable);
    if (future != null) await DatabaseHelper.instance.saveSetting('future_ratio', future);
  }

  double get totalIncome => _expenses.where((e) => e.category == 'הכנסות').fold(0.0, (sum, e) => sum + e.monthlyAmount);
  double get totalFixedExpenses => _expenses.where((e) => e.category == 'קבועות').fold(0.0, (sum, e) => sum + (e.monthlyAmount * (e.isPerChild ? _childCount : 1)));
  double get totalReducingExpenses => _isFutureMode ? 0.0 : _externalDebtPayment;
  double get disposableIncome => totalIncome - totalFixedExpenses - totalReducingExpenses;
  double get totalVariableExpenses => disposableIncome * _variableAllocationRatio;
  double get _savingsBucket => disposableIncome - totalVariableExpenses;
  double get totalFutureExpenses => _savingsBucket * _futureAllocationRatio;
  double get totalFinancialExpenses {
    final bucket = _savingsBucket;
    final future = totalFutureExpenses;
    return bucket - future;
  }
  double get financialDiversionAmount {
    if (_isFutureMode || !_hasActiveDebts) return 0.0;
    return totalFinancialExpenses;
  }

  // --- משיכות מהוצאות צוברות ---
  
  Future<List<Withdrawal>> getWithdrawalsForExpense(int expenseId) async {
    return await DatabaseHelper.instance.getWithdrawals(expenseId);
  }

  Future<void> addWithdrawal(int expenseId, double amount, String note) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;
    
    final expense = _expenses[index];
    final newBalance = (expense.currentBalance ?? 0) - amount;

    final w = Withdrawal(expenseId: expenseId, amount: amount, date: DateTime.now().toIso8601String(), note: note);
    await DatabaseHelper.instance.insertWithdrawal(w);

    _updateExpenseCurrentBalance(index, newBalance);
  }

  Future<void> deleteWithdrawal(Withdrawal w) async {
    if (w.id == null) return;
    await DatabaseHelper.instance.deleteWithdrawal(w.id!);
    
    final index = _expenses.indexWhere((e) => e.id == w.expenseId);
    if (index != -1) {
      final expense = _expenses[index];
      final newBalance = (expense.currentBalance ?? 0) + w.amount;
      _updateExpenseCurrentBalance(index, newBalance);
    }
  }

  Future<void> setExpenseCurrentBalance(int expenseId, double newBalance) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      _updateExpenseCurrentBalance(index, newBalance, updateDate: true);
    }
  }

  void _updateExpenseCurrentBalance(int index, double newBalance, {bool updateDate = false}) async {
    final expense = _expenses[index];
    final updated = Expense(
      id: expense.id, name: expense.name, category: expense.category, parentCategory: expense.parentCategory,
      monthlyAmount: expense.monthlyAmount, originalAmount: expense.originalAmount, frequency: expense.frequency,
      isSinking: expense.isSinking, isPerChild: expense.isPerChild, targetAmount: expense.targetAmount,
      currentBalance: newBalance, allocationRatio: expense.allocationRatio,
      lastUpdateDate: updateDate ? DateTime.now().toIso8601String() : expense.lastUpdateDate, 
      isLocked: expense.isLocked, manualAmount: expense.manualAmount, date: expense.date,
      isDynamicSalary: expense.isDynamicSalary, salaryStartDate: expense.salaryStartDate,
    );
    await DatabaseHelper.instance.updateExpense(updated);
  }
}