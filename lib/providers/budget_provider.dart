// 🔒 STATUS: EDITED (Integrated Business Net Profit and Passive Income Target Reduction)
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

  String _maritalStatus = 'married'; 
  String _gender = 'male'; 

  double? _customEntWarning;
  double? _customEntSuccess;

  double _variableAllocationRatio = defaultVariableRatio; 
  double _futureAllocationRatio = defaultFutureRatio;    

  double _initialCapital = 0.0;
  double _expectedYield = 4.0;
  int _compoundingFrequency = 12;
  double? _manualTargetIncome;
  
  bool _useBiometric = false;
  
  // דגל ניהול "שער החירות"
  bool _hasCompletedGrandReveal = true; // ברירת מחדל true למשתמשים קיימים

  List<SalaryRecord> _salaryRecords = [];
  
  // Smart Withdrawal Manager States
  List<PlannedWithdrawal> _plannedWithdrawals = [];
  final Map<String, int> _bucketWithdrawalDays = {}; 
  
  final Map<String, int> _unifiedCategoryModes = {}; 

  StreamSubscription? _expensesSub;
  StreamSubscription? _familySub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _assetsSub;
  StreamSubscription? _salaryRecordsSub; 
  StreamSubscription? _plannedWithdrawalsSub;
  
  bool _isListening = false;
  bool _isSyncing = false; 
  bool _syncQueued = false; 

  List<Expense> get expenses => _expenses;
  List<FamilyMember> get familyMembers => _familyMembers;
  List<SalaryRecord> get salaryRecords => _salaryRecords;
  List<PlannedWithdrawal> get plannedWithdrawals => _plannedWithdrawals;
  
  int get childCount => _familyMembers.where((m) => m.role == FamilyRole.child).length;
  String get maritalStatus => _maritalStatus;
  String get gender => _gender;

  double get entWarningLimit => _customEntWarning ?? (_maritalStatus == 'single' ? 80 : 150);
  double get entSuccessLimit => _customEntSuccess ?? (_maritalStatus == 'single' ? 250 : 500);

  double get variableAllocationRatio => _variableAllocationRatio;
  double get futureAllocationRatio => _futureAllocationRatio;
  bool get isFutureMode => _isFutureMode;
  bool get useBiometric => _useBiometric;
  bool get hasCompletedGrandReveal => _hasCompletedGrandReveal;
  
  double get variableDeficit => _variableDeficit;

  double get initialCapital => _initialCapital;
  double get expectedYield => _expectedYield;
  int get compoundingFrequency => _compoundingFrequency;
  double? get manualTargetIncome => _manualTargetIncome;

  double get autoTargetIncome => totalFixedExpenses + totalVariableExpenses + totalFutureExpenses;
  
  // סך ההכנסות מסווגות כ"פסיביות" אשר יקזזו את יעד המחייה
  double get totalPassiveIncome {
    double sum = 0;
    for (var e in _expenses.where((ex) => ex.category == 'הכנסות' && ex.isBusiness)) {
      if (e.isPassive) {
        sum += e.getBusinessNetProfit();
      }
    }
    return sum;
  }

  double get targetPassiveIncome {
    double baseTarget = _manualTargetIncome ?? autoTargetIncome;
    // הפחתת הכנסה פסיבית קיימת מעסקים מתוך היעד הנדרש מתיק ההשקעות
    double reducedTarget = baseTarget - totalPassiveIncome;
    return reducedTarget > 0 ? reducedTarget : 0;
  }

  int getCategoryUnifiedMode(String cat) {
    if (_unifiedCategoryModes.containsKey(cat)) return _unifiedCategoryModes[cat]!;
    if (cat == 'רכב' || cat == 'ילדים - קבועות') return 2;
    return 0; 
  }

  Future<void> setCategoryUnifiedMode(String cat, int mode) async {
    _unifiedCategoryModes[cat] = mode;
    await DatabaseHelper.instance.saveSetting('unified_mode_$cat', mode.toDouble());
    notifyListeners();
  }

  int getBucketWithdrawalDay(String bucketName) {
    return _bucketWithdrawalDays[bucketName] ?? 10; // ברירת מחדל: ב-10 לחודש
  }

  Future<void> setBucketWithdrawalDay(String bucketName, int day) async {
    _bucketWithdrawalDays[bucketName] = day;
    await DatabaseHelper.instance.saveSetting('bucket_day_$bucketName', day.toDouble());
    notifyListeners();
  }

  @override
  void dispose() {
    _expensesSub?.cancel();
    _familySub?.cancel();
    _settingsSub?.cancel();
    _assetsSub?.cancel();
    _salaryRecordsSub?.cancel(); 
    _plannedWithdrawalsSub?.cancel();
    super.dispose();
  }

  Future<void> syncCapitalFromAssets() async {
    final assets = await DatabaseHelper.instance.getAssets();
    _initialCapital = assets.fold(0.0, (sum, item) => sum + item.value);
    notifyListeners();
  }

  void _sortInMemoryData() {
    _familyMembers.sort((a, b) {
      if (a.role == FamilyRole.parent && b.role != FamilyRole.parent) return -1;
      if (b.role == FamilyRole.parent && a.role != FamilyRole.parent) return 1;
      return a.birthYear.compareTo(b.birthYear);
    });

    final kidNames = _familyMembers.where((m) => m.role == FamilyRole.child).map((m) {
      String n = m.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
      return n;
    }).toList();

    _expenses.sort((a, b) {
      bool aIsKid = a.parentCategory == 'ילדים - משתנות' || a.parentCategory == 'ילדים - קבועות';
      bool bIsKid = b.parentCategory == 'ילדים - משתנות' || b.parentCategory == 'ילדים - קבועות';
      
      if (aIsKid && bIsKid && a.parentCategory == b.parentCategory) {
        int idxA = kidNames.indexWhere((n) => a.name.contains(n));
        int idxB = kidNames.indexWhere((n) => b.name.contains(n));
        
        if (idxA != -1 && idxB != -1 && idxA != idxB) {
          return idxA.compareTo(idxB);
        }
      }
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
  }

  Future<void> loadData() async {
    try {
      _expenses = await DatabaseHelper.instance.getExpenses();
      _familyMembers = await DatabaseHelper.instance.getFamilyMembers();
      _salaryRecords = await DatabaseHelper.instance.getSalaryRecords(); 
      _plannedWithdrawals = await DatabaseHelper.instance.getPlannedWithdrawals();
      
      _sortInMemoryData();

      await syncCapitalFromAssets(); 
      _expectedYield = await DatabaseHelper.instance.getSetting('expected_yield') ?? 4.0;
      _compoundingFrequency = (await DatabaseHelper.instance.getSetting('comp_freq') ?? 12.0).toInt();
      _manualTargetIncome = await DatabaseHelper.instance.getSetting('manual_target_income');
      
      _variableAllocationRatio = await DatabaseHelper.instance.getSetting('variable_ratio') ?? defaultVariableRatio;
      _futureAllocationRatio = await DatabaseHelper.instance.getSetting('future_ratio') ?? defaultFutureRatio;
      
      double msVal = await DatabaseHelper.instance.getSetting('marital_status') ?? 2.0;
      _maritalStatus = msVal == 1.0 ? 'single' : 'married';

      double genderVal = await DatabaseHelper.instance.getSetting('gender') ?? 1.0;
      _gender = genderVal == 1.0 ? 'male' : 'female';
      
      _useBiometric = (await DatabaseHelper.instance.getSetting('use_biometric') ?? 0.0) == 1.0;
      
      _hasCompletedGrandReveal = (await DatabaseHelper.instance.getSetting('has_completed_reveal') ?? 1.0) == 1.0;

      _customEntWarning = await DatabaseHelper.instance.getSetting('ent_warning');
      _customEntSuccess = await DatabaseHelper.instance.getSetting('ent_success');

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
      if (_isSyncing) return; 
      _expenses = data;
      _sortInMemoryData();
      _recalculateAll();
      notifyListeners();
    });

    _familySub = DatabaseHelper.instance.streamFamilyMembers().listen((data) async {
      _familyMembers = data;
      _sortInMemoryData();
      await _forceCategorySync(); 
      _recalculateAll();
      notifyListeners();
    });

    _assetsSub = DatabaseHelper.instance.streamAssets().listen((data) {
      double newCapital = data.fold(0.0, (sum, item) => sum + item.value);
      if (_initialCapital != newCapital) {
        _initialCapital = newCapital;
        notifyListeners();
      }
    });

    _salaryRecordsSub = DatabaseHelper.instance.streamSalaryRecords().listen((data) {
      _salaryRecords = data;
      _recalculateAll();
      notifyListeners();
    });

    _plannedWithdrawalsSub = DatabaseHelper.instance.streamPlannedWithdrawals().listen((data) {
      _plannedWithdrawals = data;
      notifyListeners();
    });

    _settingsSub = DatabaseHelper.instance.streamSettings().listen((snap) {
      bool changed = false;
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final key = data['key'];
        final val = (data['value'] as num?)?.toDouble();

        if (key != null && key.startsWith('unified_mode_') && val != null) {
          String catName = key.substring(13);
          int mode = val.toInt();
          if (_unifiedCategoryModes[catName] != mode) {
            _unifiedCategoryModes[catName] = mode;
            changed = true;
          }
        }
        else if (key != null && key.startsWith('unified_cat_') && val != null) {
          String catName = key.substring(12);
          int mode = val == 1.0 ? 2 : 0; 
          if (_unifiedCategoryModes[catName] != mode) {
             _unifiedCategoryModes[catName] = mode;
             DatabaseHelper.instance.saveSetting('unified_mode_$catName', mode.toDouble());
             DatabaseHelper.instance.deleteSetting(key); 
             changed = true;
          }
        }
        
        if (key != null && key.startsWith('bucket_day_') && val != null) {
          String bucketName = key.substring(11);
          if (_bucketWithdrawalDays[bucketName] != val.toInt()) {
            _bucketWithdrawalDays[bucketName] = val.toInt();
            changed = true;
          }
        }

        if (key == 'expected_yield' && val != null && _expectedYield != val) { _expectedYield = val; changed = true; }
        if (key == 'comp_freq' && val != null && _compoundingFrequency != val.toInt()) { _compoundingFrequency = val.toInt(); changed = true; }
        if (key == 'manual_target_income' && _manualTargetIncome != val) { _manualTargetIncome = val; changed = true; }
        if (key == 'variable_ratio' && val != null && _variableAllocationRatio != val) { _variableAllocationRatio = val; changed = true; }
        if (key == 'future_ratio' && val != null && _futureAllocationRatio != val) { _futureAllocationRatio = val; changed = true; }
        
        if (key == 'marital_status' && val != null) { 
          String newStatus = val == 1.0 ? 'single' : 'married';
          if (_maritalStatus != newStatus) { _maritalStatus = newStatus; changed = true; }
        }

        if (key == 'gender' && val != null) { 
          String newGender = val == 1.0 ? 'male' : 'female';
          if (_gender != newGender) { _gender = newGender; changed = true; }
        }
        
        if (key == 'use_biometric' && val != null) {
          bool useBio = val == 1.0;
          if (_useBiometric != useBio) { _useBiometric = useBio; changed = true; }
        }
        
        if (key == 'has_completed_reveal' && val != null) {
          bool hasCompleted = val == 1.0;
          if (_hasCompletedGrandReveal != hasCompleted) { _hasCompletedGrandReveal = hasCompleted; changed = true; }
        }

        if (key == 'ent_warning' && _customEntWarning != val) { _customEntWarning = val; changed = true; }
        if (key == 'ent_success' && _customEntSuccess != val) { _customEntSuccess = val; changed = true; }
      }
      if (changed) {
        _forceCategorySync().then((_) {
          _recalculateAll();
          notifyListeners();
        });
      }
    });
  }
  
  Future<void> completeGrandReveal() async {
    _hasCompletedGrandReveal = true;
    await DatabaseHelper.instance.saveSetting('has_completed_reveal', 1.0);
    notifyListeners();
  }

  Future<void> toggleBiometric(bool val) async {
    _useBiometric = val;
    await DatabaseHelper.instance.saveSetting('use_biometric', val ? 1.0 : 0.0);
    notifyListeners();
  }

  Future<void> saveEntertainmentLimits(double warning, double success) async {
    _customEntWarning = warning;
    _customEntSuccess = success;
    notifyListeners();
    await DatabaseHelper.instance.saveSetting('ent_warning', warning);
    await DatabaseHelper.instance.saveSetting('ent_success', success);
  }

  Future<void> resetEntertainmentLimits() async {
    _customEntWarning = null;
    _customEntSuccess = null;
    notifyListeners();
    await DatabaseHelper.instance.deleteSetting('ent_warning');
    await DatabaseHelper.instance.deleteSetting('ent_success');
  }

  Future<void> updateFamilyStructure({String? maritalStatus, String? gender}) async {
    if (maritalStatus != null) _maritalStatus = maritalStatus;
    if (gender != null) _gender = gender;
    notifyListeners(); 

    if (maritalStatus != null) {
      await DatabaseHelper.instance.saveSetting('marital_status', maritalStatus == 'single' ? 1.0 : 2.0);
    }
    if (gender != null) {
      await DatabaseHelper.instance.saveSetting('gender', gender == 'male' ? 1.0 : 2.0);
    }

    await _forceCategorySync();
    _recalculateAll();
    notifyListeners();
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

  String get _parent1Name => _maritalStatus == 'single' 
      ? (childCount == 0 ? 'אישי' : (_gender == 'male' ? 'אבא' : 'אמא')) 
      : (childCount == 0 ? 'בעל' : 'אבא');

  String? get _parent2Name => _maritalStatus == 'single' 
      ? null 
      : (childCount == 0 ? 'אישה' : 'אמא');

  Map<String, double> _getDynamicVariableRatios() {
    int cCount = childCount;
    final kids = _familyMembers.where((m) => m.role == FamilyRole.child).toList();
    
    Map<String, double> ratios = {};
    String p1 = _parent1Name;
    String? p2 = _parent2Name;

    if (_maritalStatus == 'single') {
      if (cCount == 0) { 
        ratios['בגדים $p1'] = _gender == 'female' ? 0.40 : 0.45;
        ratios['בילויים $p1'] = _gender == 'female' ? 0.45 : 0.55;
        if (_gender == 'female') ratios['טיפוח $p1'] = 0.15;
      } else { 
        ratios['בגדים $p1'] = 0.28;
        ratios['בילויים $p1'] = 0.33;
        if (_gender == 'female') ratios['טיפוח $p1'] = 0.15;
      }
    } else { 
      if (cCount == 0) { 
        ratios['בגדים $p1'] = 0.25;
        ratios['בילויים $p1'] = 0.20;
        ratios['בגדים ${p2!}'] = 0.15;
        ratios['בילויים $p2'] = 0.25;
        ratios['טיפוח $p2'] = 0.15;
      } else { 
        ratios['בגדים $p1'] = 0.19;
        ratios['בילויים $p1'] = 0.14;
        ratios['בגדים ${p2!}'] = 0.09;
        ratios['בילויים $p2'] = 0.19;
        ratios['טיפוח $p2'] = 0.15;
      }
    }

    if (cCount > 0) {
      double clothesRatio = 0.12 / cCount;
      double funRatio = 0.12 / cCount;
      for (var kid in kids) {
        String safeName = kid.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
        ratios['בגדים $safeName'] = clothesRatio;
        ratios['בילויים $safeName'] = funRatio;
      }
    }
    return ratios;
  }

  Future<void> resetExpenseToDefault(int expenseId, {bool? isSinking}) async {
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

    if (_expenses[index].parentCategory == 'ילדים - משתנות') {
      defaultRatio = childCount > 0 ? (0.12 / childCount) : 0.0;
    }

    final old = _expenses[index];
    final updated = Expense(
      id: old.id, name: old.name, category: old.category, parentCategory: old.parentCategory,
      monthlyAmount: 0, originalAmount: old.originalAmount, frequency: old.frequency,
      isSinking: isSinking ?? old.isSinking, isPerChild: old.isPerChild, targetAmount: old.targetAmount,
      currentBalance: old.currentBalance, allocationRatio: defaultRatio,
      lastUpdateDate: old.lastUpdateDate, isLocked: false, manualAmount: null, date: old.date,
      isDynamicSalary: old.isDynamicSalary, salaryStartDate: old.salaryStartDate,
      isCustom: old.isCustom,
      isBusiness: old.isBusiness, businessIncomes: old.businessIncomes, businessExpenses: old.businessExpenses, businessWorkingHours: old.businessWorkingHours,
    );

    await DatabaseHelper.instance.updateExpense(updated);
  }

  Future<void> addVehicleTemplate(String vehicleName, String type) async {
    final now = DateTime.now().toIso8601String();
    String parentCat = 'רכב';

    if (type == 'car') {
      await addExpense(Expense(name: 'טסט ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 1250/12, frequency: Frequency.YEARLY, isSinking: true, isCustom: true, date: now));
      await addExpense(Expense(name: 'ביטוח ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 3500/12, frequency: Frequency.YEARLY, isSinking: true, isCustom: true, date: now));
      await addExpense(Expense(name: 'טיפול ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 2000/12, frequency: Frequency.YEARLY, isSinking: true, isCustom: true, date: now));
      await addExpense(Expense(name: 'תיקונים ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 500, frequency: Frequency.MONTHLY, isSinking: true, isCustom: true, date: now));
      await addExpense(Expense(name: 'ליסינג ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 600, frequency: Frequency.MONTHLY, isSinking: false, isCustom: true, date: now));
      await addExpense(Expense(name: 'דלק ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 500, frequency: Frequency.MONTHLY, isSinking: false, isCustom: true, date: now));
    } else {
      await addExpense(Expense(name: 'טסט ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 21, frequency: Frequency.MONTHLY, isSinking: true, isCustom: true, date: now));
      await addExpense(Expense(name: 'ביטוח ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 292, frequency: Frequency.MONTHLY, isSinking: true, isCustom: true, date: now));
      await addExpense(Expense(name: 'טיפול ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 42, frequency: Frequency.MONTHLY, isSinking: true, isCustom: true, date: now));
      await addExpense(Expense(name: 'תיקונים ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 50, frequency: Frequency.MONTHLY, isSinking: true, isCustom: true, date: now));
      await addExpense(Expense(name: 'דלק ($vehicleName)', category: 'קבועות', parentCategory: parentCat, monthlyAmount: 30, frequency: Frequency.MONTHLY, isSinking: false, isCustom: true, date: now));
    }
  }

  Future<void> _forceCategorySync() async {
    if (_isSyncing) {
      _syncQueued = true;
      return;
    }
    _isSyncing = true;
    
    try {
      do {
        _syncQueued = false;
        bool changed = false;
        final now = DateTime.now().toIso8601String();
        
        List<Expense> localExp = await DatabaseHelper.instance.getExpenses();
        if (localExp.isEmpty) continue;

        String p1 = _parent1Name;
        String? p2 = _parent2Name;

        final Map<String, double> targetVariableRatios = _getDynamicVariableRatios();
        final List<String> validVarNames = targetVariableRatios.keys.toList();
        final List<String> prefixes = ['בגדים', 'בילויים', 'טיפוח'];
        
        String preferredSuffix = _maritalStatus == 'single' ? p1 : (_gender == 'female' && p2 != null ? p2 : p1);

        for (int i = localExp.length - 1; i >= 0; i--) {
          final e = localExp[i];
          bool shouldDelete = false;
          String nameForMatch = e.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');

          bool isSystemGrooming = nameForMatch == 'טיפוח אישי' || nameForMatch == 'טיפוח אישה' || nameForMatch == 'טיפוח אמא';

          if (nameForMatch == 'פארם וניקיון' || nameForMatch == 'בגדים ילדים' || nameForMatch == 'בילויים ילדים') {
            shouldDelete = true;
          }
          else if (childCount == 0 && e.parentCategory == 'ילדים - קבועות') {
            shouldDelete = true;
          }
          else if (_maritalStatus == 'single' && _gender == 'male' && isSystemGrooming) {
            shouldDelete = true;
          }
          else if (e.category == 'משתנות' && e.parentCategory != 'קניות' && !e.isCustom) {
            
            bool isDynamicPrefix = prefixes.any((p) => nameForMatch.startsWith(p));
            
            if (isDynamicPrefix) {
              if (!validVarNames.contains(nameForMatch)) {
                bool salvaged = false;
                String ePrefix = prefixes.firstWhere((p) => nameForMatch.startsWith(p), orElse: () => '');
                
                if (ePrefix.isNotEmpty) {
                  String? targetName;
                  try {
                    targetName = validVarNames.firstWhere((v) => v.startsWith(ePrefix) && v.endsWith(preferredSuffix));
                  } catch (_) {
                    try {
                      targetName = validVarNames.firstWhere((v) => v.startsWith(ePrefix) && (v.endsWith(p1) || (p2 != null && v.endsWith(p2))));
                    } catch (_) {
                      targetName = null;
                    }
                  }

                  if (targetName != null && !localExp.any((ex) => ex.name == targetName)) {
                    String newParent = targetName.split(' ').skip(1).join(' ').trim();
                    if (_familyMembers.any((m) => m.role == FamilyRole.child && m.name.trim() == newParent)) {
                       newParent = 'ילדים - משתנות';
                    }

                    final updated = Expense(
                      id: e.id, name: targetName, category: e.category, parentCategory: newParent,
                      monthlyAmount: e.monthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency,
                      isSinking: e.isSinking, isPerChild: e.isPerChild, targetAmount: e.targetAmount,
                      currentBalance: e.currentBalance, allocationRatio: e.allocationRatio,
                      lastUpdateDate: e.lastUpdateDate, isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
                      isDynamicSalary: e.isDynamicSalary, salaryStartDate: e.salaryStartDate, isCustom: e.isCustom,
                      isBusiness: e.isBusiness, businessIncomes: e.businessIncomes, businessExpenses: e.businessExpenses, businessWorkingHours: e.businessWorkingHours,
                    );
                    await DatabaseHelper.instance.updateExpense(updated);
                    localExp[i] = updated; 
                    salvaged = true;
                    changed = true;
                  }
                }
                
                if (!salvaged) {
                  shouldDelete = true;
                }
              }
            } else if (!validVarNames.contains(nameForMatch)) {
              shouldDelete = true;
            }
          }

          if (shouldDelete) {
            await DatabaseHelper.instance.deleteExpense(e.id!);
            localExp.removeAt(i);
            changed = true;
          }
        }

        for (var entry in targetVariableRatios.entries) {
          if (!localExp.any((e) => e.name == entry.key)) {
            String parentCat = 'אחר';
            String personName = entry.key.split(' ').skip(1).join(' ').trim();
            
            if (_familyMembers.any((m) => m.role == FamilyRole.child && m.name.trim() == personName)) {
              parentCat = 'ילדים - משתנות';
            } else if (personName == p1) {
              parentCat = p1;
            } else if (p2 != null && personName == p2) {
              parentCat = p2;
            }

            final newE = Expense(
              name: entry.key, category: 'משתנות', parentCategory: parentCat,
              monthlyAmount: 0, originalAmount: 0, isSinking: true,
              isPerChild: false, allocationRatio: entry.value,
              date: now, isDynamicSalary: false, isCustom: false,
            );
            await DatabaseHelper.instance.insertExpense(newE);
            changed = true;
          }
        }

        if (childCount > 0) {
          final kidsFixed = ['שכר לימוד', 'ציוד בית ספר', 'חוגים', 'מתנות לימי הולדת', 'קייטנות'];
          for (String kf in kidsFixed) {
            if (!localExp.any((e) => e.name == kf || (kf == 'מתנות לימי הולדת' && e.name == 'מתנות ימי הולדת'))) {
               final newE = Expense(
                   name: kf, category: 'קבועות', parentCategory: 'ילדים - קבועות',
                   monthlyAmount: 0, originalAmount: 0, isSinking: true, isPerChild: true,
                   frequency: (kf == 'ציוד בית ספר' || kf == 'קייטנות') ? Frequency.YEARLY : Frequency.MONTHLY,
                   date: now, isDynamicSalary: false, isCustom: false,
               );
               await DatabaseHelper.instance.insertExpense(newE);
               changed = true;
            }
          }
        }

        if (changed) {
          localExp = await DatabaseHelper.instance.getExpenses();
        }

        final Map<String, Map<String, String>> syncRules = {
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

        for (int i = 0; i < localExp.length; i++) {
          final e = localExp[i];
          bool needsUpdate = false;
          String newCat = e.category;
          String newParent = e.parentCategory;
          bool newIsPerChild = e.isPerChild;
          String newName = e.name;
          bool newIsCustom = e.isCustom;
          double? newRatio = e.allocationRatio;
          bool newIsSinking = e.isSinking;
          String nameForMatch = e.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');

          if (syncRules.containsKey(nameForMatch)) {
            final rule = syncRules[nameForMatch]!;
            if (e.category != rule['cat'] || e.parentCategory != rule['parent']) {
              newCat = rule['cat']!;
              newParent = rule['parent']!;
              newIsPerChild = (rule['parent']!.startsWith('ילדים - קבועות') || e.isPerChild);
              needsUpdate = true;
            }
          }

          if (targetVariableRatios.containsKey(nameForMatch)) {
            double targetRatio = targetVariableRatios[nameForMatch]!;
            if (newRatio != targetRatio) {
              newRatio = targetRatio;
              needsUpdate = true;
            }
            
            String personName = nameForMatch.split(' ').skip(1).join(' ').trim();
            String expectedParent = 'אחר';
            if (_familyMembers.any((m) => m.role == FamilyRole.child && m.name.trim() == personName)) {
              expectedParent = 'ילדים - משתנות';
            } else if (personName == p1) {
              expectedParent = p1;
            } else if (p2 != null && personName == p2) {
              expectedParent = p2;
            }
            
            if (newParent != expectedParent) {
              newParent = expectedParent;
              needsUpdate = true;
            }
          } else if (requiredRatios.containsKey(nameForMatch)) {
            if (newRatio != requiredRatios[nameForMatch]) {
              newRatio = requiredRatios[nameForMatch];
              needsUpdate = true;
            }
          }

          if (newCat == 'עתידיות' || newParent == 'חגים') {
            if (!newIsSinking) { newIsSinking = true; needsUpdate = true; }
          }
          if (newParent == 'רכב') {
            String cleanVehicleName = newName.trim();
            if (!cleanVehicleName.startsWith('דלק') && !cleanVehicleName.startsWith('ליסינג')) {
              if (!newIsSinking) { newIsSinking = true; needsUpdate = true; }
            } else {
              if (newIsSinking) { newIsSinking = false; needsUpdate = true; }
            }
          }
          if (newName.trim() == 'הובלה ותיקונים' && !newIsSinking) {
            newIsSinking = true; needsUpdate = true;
          }

          final oldVehicleNames = ['טסט', 'ביטוח', 'טיפול', 'תיקונים', 'דלק', 'ליסינג', 'נסיעות'];
          if (e.parentCategory == 'רכב' && !e.name.contains('(') && oldVehicleNames.contains(e.name.trim())) {
            newName = '${e.name} (אופנוע יסוד)';
            newIsCustom = true; 
            needsUpdate = true;
          }

          if (needsUpdate) {
            final updated = Expense(
              id: e.id, name: newName, category: newCat, parentCategory: newParent,
              monthlyAmount: e.monthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency,
              isSinking: newIsSinking, isPerChild: newIsPerChild,
              targetAmount: e.targetAmount, currentBalance: e.currentBalance, allocationRatio: newRatio,
              lastUpdateDate: e.lastUpdateDate, isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
              isDynamicSalary: e.isDynamicSalary, salaryStartDate: e.salaryStartDate, isCustom: newIsCustom,
              isBusiness: e.isBusiness, businessIncomes: e.businessIncomes, businessExpenses: e.businessExpenses, businessWorkingHours: e.businessWorkingHours,
            );
            await DatabaseHelper.instance.updateExpense(updated);
            changed = true;
          }
        }

        if (changed) {
          _expenses = await DatabaseHelper.instance.getExpenses();
          _sortInMemoryData();
        }

      } while (_syncQueued);
    } finally {
      _isSyncing = false;
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
    _maritalStatus = 'married';
    _gender = 'male';
    _manualTargetIncome = null;
    _initialCapital = 0.0;
    _expectedYield = 4.0;
    _compoundingFrequency = 12;
    _variableAllocationRatio = defaultVariableRatio;
    _futureAllocationRatio = defaultFutureRatio;
    _externalDebtPayment = 0;
    _isFutureMode = false;
    _customEntWarning = null;
    _customEntSuccess = null;
    _unifiedCategoryModes.clear();
    _bucketWithdrawalDays.clear();
    _useBiometric = false;
    _hasCompletedGrandReveal = false; 
    _expenses = [];
    _familyMembers = [];
    _salaryRecords = [];
    _plannedWithdrawals = [];
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
          if (e.isPerChild) monthlyDeposit *= childCount;
          double addedAmount = monthlyDeposit * monthsDiff;
          
          final updatedExpense = Expense(
            id: e.id, name: e.name, category: e.category, parentCategory: e.parentCategory,
            monthlyAmount: e.monthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency, isSinking: e.isSinking, isPerChild: e.isPerChild,
            targetAmount: e.targetAmount, currentBalance: (e.currentBalance ?? 0) + addedAmount,
            allocationRatio: e.allocationRatio, lastUpdateDate: now.toIso8601String(),
            isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
            isDynamicSalary: e.isDynamicSalary, salaryStartDate: e.salaryStartDate,
            isCustom: e.isCustom,
            isBusiness: e.isBusiness, businessIncomes: e.businessIncomes, businessExpenses: e.businessExpenses, businessWorkingHours: e.businessWorkingHours,
          );
          await DatabaseHelper.instance.updateExpense(updatedExpense);
          _expenses[i] = updatedExpense;
          wasUpdated = true;
        }
      }
    }
    if (wasUpdated) notifyListeners();
  }

  double getAverageSalary(int expenseId, {bool calendarYear = false}) {
    final records = _salaryRecords.where((r) => r.expenseId == expenseId).toList();
    if (records.isEmpty) return 0.0;
    
    double totalNet = records.fold(0.0, (sum, r) => sum + r.netAmount);
    
    if (calendarYear) {
       return totalNet / 12.0;
    } else {
       return totalNet / records.length; 
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
        isCustom: old.isCustom,
        isBusiness: old.isBusiness, businessIncomes: old.businessIncomes, businessExpenses: old.businessExpenses, businessWorkingHours: old.businessWorkingHours,
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

  void _recalculateAll() {
    _recalculateDynamicSalaries();
    _recalculateVariableExpenses();
    _recalculateFutureExpenses();
  }

  Future<void> lockExpenseAmount(int expenseId, double amount, {bool? isSinking}) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final old = _expenses[index];
      final updated = Expense(
        id: old.id, name: old.name, category: old.category, parentCategory: old.parentCategory,
        monthlyAmount: amount, originalAmount: old.originalAmount, frequency: old.frequency, 
        isSinking: isSinking ?? old.isSinking, isPerChild: old.isPerChild,
        targetAmount: old.targetAmount, currentBalance: old.currentBalance, allocationRatio: old.allocationRatio,
        lastUpdateDate: DateTime.now().toIso8601String(),
        isLocked: true, manualAmount: amount, date: old.date,
        isDynamicSalary: old.isDynamicSalary, salaryStartDate: old.salaryStartDate,
        isCustom: old.isCustom,
        isBusiness: old.isBusiness, businessIncomes: old.businessIncomes, businessExpenses: old.businessExpenses, businessWorkingHours: old.businessWorkingHours,
      );
      await DatabaseHelper.instance.updateExpense(updated);
    }
  }

  Future<void> updateExpenseRatio(int expenseId, double newRatio, {bool? isSinking}) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final old = _expenses[index];
      final updated = Expense(
        id: old.id, name: old.name, category: old.category, parentCategory: old.parentCategory,
        monthlyAmount: 0, originalAmount: old.originalAmount, frequency: old.frequency, 
        isSinking: isSinking ?? old.isSinking, isPerChild: old.isPerChild,
        targetAmount: old.targetAmount, currentBalance: old.currentBalance,
        allocationRatio: newRatio, 
        lastUpdateDate: DateTime.now().toIso8601String(),
        isLocked: false, manualAmount: null, date: old.date,
        isDynamicSalary: old.isDynamicSalary, salaryStartDate: old.salaryStartDate,
        isCustom: old.isCustom,
        isBusiness: old.isBusiness, businessIncomes: old.businessIncomes, businessExpenses: old.businessExpenses, businessWorkingHours: old.businessWorkingHours,
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
        isCustom: old.isCustom,
        isBusiness: old.isBusiness, businessIncomes: old.businessIncomes, businessExpenses: old.businessExpenses, businessWorkingHours: old.businessWorkingHours,
      );
      await DatabaseHelper.instance.updateExpense(updated);
    }
  }

  Future<void> updateFutureExpenseDetails(int expenseId, {String? name, double? target, double? balance, double? ratio, bool? isLocked, double? manualAmount, bool? isSinking}) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final old = _expenses[index];
      final updated = Expense(
        id: old.id, name: name ?? old.name, category: old.category, parentCategory: old.parentCategory,
        monthlyAmount: (isLocked == true && manualAmount != null) ? manualAmount : 0, 
        originalAmount: old.originalAmount, frequency: old.frequency, 
        isSinking: isSinking ?? old.isSinking, isPerChild: old.isPerChild,
        targetAmount: target ?? old.targetAmount, currentBalance: balance ?? old.currentBalance,
        allocationRatio: ratio ?? old.allocationRatio, lastUpdateDate: DateTime.now().toIso8601String(),
        isLocked: isLocked ?? old.isLocked, manualAmount: manualAmount ?? old.manualAmount, date: old.date,
        isDynamicSalary: old.isDynamicSalary, salaryStartDate: old.salaryStartDate,
        isCustom: old.isCustom,
        isBusiness: old.isBusiness, businessIncomes: old.businessIncomes, businessExpenses: old.businessExpenses, businessWorkingHours: old.businessWorkingHours,
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
      isCustom: e.isCustom,
      isBusiness: e.isBusiness, businessIncomes: e.businessIncomes, businessExpenses: e.businessExpenses, businessWorkingHours: e.businessWorkingHours,
    );
  }

  Future<void> addFamilyMember(String name, int birthYear, FamilyRole role) async {
    String cleanName = name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
    final newMember = FamilyMember(name: cleanName, birthYear: birthYear, role: role);
    await DatabaseHelper.instance.insertFamilyMember(newMember);
  }

  Future<void> removeFamilyMember(int id) async {
    await DatabaseHelper.instance.deleteFamilyMember(id);
  }

  Future<void> updateFamilyMember(FamilyMember member) async {
    if (member.id != null) {
      String cleanName = member.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
      final updated = FamilyMember(id: member.id, name: cleanName, birthYear: member.birthYear, role: member.role);
      await DatabaseHelper.instance.updateFamilyMember(updated);
    }
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
          isCustom: e.isCustom,
          isBusiness: e.isBusiness, businessIncomes: e.businessIncomes, businessExpenses: e.businessExpenses, businessWorkingHours: e.businessWorkingHours,
        );
        await DatabaseHelper.instance.updateExpense(updated);
      }
    }
  }

  Future<void> setAllocationRatios({double? variable, double? future}) async {
    if (variable != null) await DatabaseHelper.instance.saveSetting('variable_ratio', variable);
    if (future != null) await DatabaseHelper.instance.saveSetting('future_ratio', future);
  }

  // שורת ההכנסות הראשית מתייחסת לעסקים בצורה חכמה (כולל הפסדים, לא כולל רווח פסיבי שכבר קוזז)
  double get totalIncome {
    double sum = 0;
    for (var e in _expenses.where((ex) => ex.category == 'הכנסות')) {
      if (e.isBusiness) {
        double net = e.getBusinessNetProfit();
        if (!e.isPassive) {
          sum += net; // הוספת רווח אקטיבי, או קיזוז במקרה של הפסד (net < 0)
        }
      } else {
        sum += e.monthlyAmount;
      }
    }
    return sum;
  }

  double get totalFixedExpenses => _expenses.where((e) => e.category == 'קבועות').fold(0.0, (sum, e) => sum + (e.monthlyAmount * (e.isPerChild ? childCount : 1)));
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

  // ==========================================
  // פעולות משיכה והוצאות צוברות
  // ==========================================

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
      isCustom: expense.isCustom,
      isBusiness: expense.isBusiness, businessIncomes: expense.businessIncomes, businessExpenses: expense.businessExpenses, businessWorkingHours: expense.businessWorkingHours,
    );
    await DatabaseHelper.instance.updateExpense(updated);
  }

  // ==========================================
  // מנהל משיכות חכם (Smart Withdrawal Manager)
  // ==========================================
  
  Future<void> addPlannedWithdrawal(PlannedWithdrawal pw) async {
    await DatabaseHelper.instance.insertPlannedWithdrawal(pw);
  }

  Future<void> updatePlannedWithdrawal(PlannedWithdrawal pw) async {
    await DatabaseHelper.instance.updatePlannedWithdrawal(pw);
  }

  Future<void> deletePlannedWithdrawal(int id) async {
    await DatabaseHelper.instance.deletePlannedWithdrawal(id);
  }

  Future<void> executePlannedWithdrawalsForBucket(String bucketName) async {
    final pending = _plannedWithdrawals.where((pw) => 
        pw.bucketName == bucketName && pw.status == PlannedWithdrawalStatus.pending).toList();
    
    if (pending.isEmpty) return;

    double totalAmount = pending.fold(0.0, (sum, item) => sum + item.amount);
    String note = "משיכה מאוחדת: ${pending.map((p) => p.name).join(', ')}";

    int? targetExpenseId;
    
    for (var e in _expenses.where((ex) => ex.isSinking)) {
      String groupName = '';
      if (e.parentCategory == 'רכב') {
        groupName = 'רכב';
      } else if (e.parentCategory == 'ילדים - משתנות') {
        String kName = e.name.replaceAll('בגדים', '').replaceAll('בילויים', '').trim();
        groupName = 'ילדים: $kName';
      } else if (['ילדים - קבועות', 'אבא', 'אמא', 'אישי', 'חגים'].contains(e.parentCategory)) {
        groupName = e.parentCategory;
      }

      if (groupName.isNotEmpty) {
        if (groupName == bucketName) {
          targetExpenseId = e.id;
          break; 
        }
      } else {
        bool isFuture = e.category == 'עתידיות';
        String displayTitle = isFuture ? e.parentCategory : e.name;
        if (displayTitle == bucketName) {
          targetExpenseId = e.id;
          break; 
        }
      }
    }

    if (targetExpenseId != null) {
      await addWithdrawal(targetExpenseId, totalAmount, note);
    }

    for (var pw in pending) {
      final updated = PlannedWithdrawal(
        id: pw.id,
        name: pw.name,
        amount: pw.amount,
        bucketName: pw.bucketName,
        targetDate: pw.targetDate,
        status: PlannedWithdrawalStatus.executed,
      );
      await DatabaseHelper.instance.updatePlannedWithdrawal(updated);
    }
  }
}