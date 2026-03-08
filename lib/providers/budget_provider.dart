// 🔒 STATUS: EDITED (Ironclad Kids Allocation logic & Centralized Chronological Sorting Engine)
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
  
  bool _isFatherActive = true;
  bool _isMotherActive = true;
  bool _isKidsActive = true;

  double _variableAllocationRatio = defaultVariableRatio; 
  double _futureAllocationRatio = defaultFutureRatio;    

  double _initialCapital = 0.0;
  double _expectedYield = 4.0;
  int _compoundingFrequency = 12;
  double? _manualTargetIncome;

  List<SalaryRecord> _salaryRecords = [];
  final Map<String, bool> _unifiedCategories = {}; 

  StreamSubscription? _expensesSub;
  StreamSubscription? _familySub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _assetsSub;
  StreamSubscription? _salaryRecordsSub; 
  bool _isListening = false;

  List<Expense> get expenses => _expenses;
  List<FamilyMember> get familyMembers => _familyMembers;
  List<SalaryRecord> get salaryRecords => _salaryRecords;
  
  int get childCount => _familyMembers.where((m) => m.role == FamilyRole.child).length;
  
  String get maritalStatus => _maritalStatus;
  
  bool get isFatherActive => _isFatherActive;
  bool get isMotherActive => _isMotherActive;
  bool get isKidsActive => _isKidsActive;

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

  bool isCategoryUnified(String cat) {
    if (_unifiedCategories.containsKey(cat)) {
      return _unifiedCategories[cat]!;
    }
    return ['ילדים - קבועות', 'אבא', 'אמא', 'חגים', 'רכב'].contains(cat);
  }

  Future<void> toggleCategoryUnified(String cat, bool value) async {
    _unifiedCategories[cat] = value;
    await DatabaseHelper.instance.saveSetting('unified_cat_$cat', value ? 1.0 : 0.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _expensesSub?.cancel();
    _familySub?.cancel();
    _settingsSub?.cancel();
    _assetsSub?.cancel();
    _salaryRecordsSub?.cancel(); 
    super.dispose();
  }

  Future<void> syncCapitalFromAssets() async {
    final assets = await DatabaseHelper.instance.getAssets();
    _initialCapital = assets.fold(0.0, (sum, item) => sum + item.value);
    notifyListeners();
  }

  // מנוע מיון מרכזי: שומר על סדר כרונולוגי גורף לילדים (מהגדול לקטן) בכל המערכת
  void _sortInMemoryData() {
    // 1. מיון בני המשפחה: הורים קודם, ואז ילדים לפי שנת לידה (הבוגר מופיע קודם = שנת לידה קטנה יותר)
    _familyMembers.sort((a, b) {
      if (a.role == FamilyRole.parent && b.role != FamilyRole.parent) return -1;
      if (b.role == FamilyRole.parent && a.role != FamilyRole.parent) return 1;
      return a.birthYear.compareTo(b.birthYear);
    });

    // 2. חילוץ שמות הילדים הממוינים כרונולוגית לצורך סידור ההוצאות
    final kidNames = _familyMembers.where((m) => m.role == FamilyRole.child).map((m) {
      String n = m.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
      if (n == 'אבא' || n == 'אמא' || n == 'אישי') n = '$n (ילד)';
      return n;
    }).toList();

    // 3. מיון ההוצאות כך שהוצאות הילדים יסודרו לפי גיל הילד באופן גורף בכל האפליקציה
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
      
      // שמירה על יציבות (Stable Sort) לשאר ההוצאות על בסיס ה-ID המקורי מהמסד
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
  }

  Future<void> loadData() async {
    try {
      _expenses = await DatabaseHelper.instance.getExpenses();
      _familyMembers = await DatabaseHelper.instance.getFamilyMembers();
      
      _sortInMemoryData(); // הפעלת המיון המרכזי

      await syncCapitalFromAssets(); 
      _expectedYield = await DatabaseHelper.instance.getSetting('expected_yield') ?? 4.0;
      _compoundingFrequency = (await DatabaseHelper.instance.getSetting('comp_freq') ?? 12.0).toInt();
      _manualTargetIncome = await DatabaseHelper.instance.getSetting('manual_target_income');
      
      _variableAllocationRatio = await DatabaseHelper.instance.getSetting('variable_ratio') ?? defaultVariableRatio;
      _futureAllocationRatio = await DatabaseHelper.instance.getSetting('future_ratio') ?? defaultFutureRatio;
      
      double msVal = await DatabaseHelper.instance.getSetting('marital_status') ?? 2.0;
      _maritalStatus = msVal == 1.0 ? 'single' : 'married';

      _isFatherActive = (await DatabaseHelper.instance.getSetting('father_active') ?? 1.0) == 1.0;
      _isMotherActive = (await DatabaseHelper.instance.getSetting('mother_active') ?? 1.0) == 1.0;
      _isKidsActive = (await DatabaseHelper.instance.getSetting('kids_active') ?? 1.0) == 1.0;

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
      _sortInMemoryData(); // הפעלת המיון המרכזי
      _recalculateAll();
      notifyListeners();
    });

    _familySub = DatabaseHelper.instance.streamFamilyMembers().listen((data) async {
      _familyMembers = data;
      _sortInMemoryData(); // הפעלת המיון המרכזי
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

    _settingsSub = DatabaseHelper.instance.streamSettings().listen((snap) {
      bool changed = false;
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final key = data['key'];
        final val = (data['value'] as num?)?.toDouble();

        if (key != null && key.startsWith('unified_cat_') && val != null) {
          String catName = key.substring(12);
          bool isU = val == 1.0;
          if (_unifiedCategories[catName] != isU) {
            _unifiedCategories[catName] = isU;
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
        if (key == 'father_active' && val != null) {
          bool active = val == 1.0;
          if (_isFatherActive != active) { _isFatherActive = active; changed = true; }
        }
        if (key == 'mother_active' && val != null) {
          bool active = val == 1.0;
          if (_isMotherActive != active) { _isMotherActive = active; changed = true; }
        }
        if (key == 'kids_active' && val != null) {
          bool active = val == 1.0;
          if (_isKidsActive != active) { _isKidsActive = active; changed = true; }
        }
      }
      if (changed) {
        _recalculateAll();
        notifyListeners();
      }
    });
  }

  Future<void> updateFamilyStructure({String? maritalStatus}) async {
    if (maritalStatus != null) {
      await DatabaseHelper.instance.saveSetting('marital_status', maritalStatus == 'single' ? 1.0 : 2.0);
      _maritalStatus = maritalStatus;
    }
    await _forceCategorySync();
    _recalculateAll();
    notifyListeners();
  }

  Future<void> toggleEntityActive(String entityType, bool isActive) async {
    double val = isActive ? 1.0 : 0.0;
    if (entityType == 'father') {
      await DatabaseHelper.instance.saveSetting('father_active', val);
      _isFatherActive = isActive;
    } else if (entityType == 'mother') {
      await DatabaseHelper.instance.saveSetting('mother_active', val);
      _isMotherActive = isActive;
    } else if (entityType == 'kids') {
      await DatabaseHelper.instance.saveSetting('kids_active', val);
      _isKidsActive = isActive;
    }
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

  Map<String, double> _getDynamicVariableRatios() {
    int cCount = childCount;
    final kids = _familyMembers.where((m) => m.role == FamilyRole.child).toList();
    
    Map<String, double> ratios = {};
    if (_maritalStatus == 'single' && cCount > 0) {
      ratios = { 'בגדים אישי': 0.28, 'בילויים אישי': 0.33, 'טיפוח אישי': 0.15 };
    } else if (_maritalStatus == 'married' && cCount == 0) {
      ratios = { 'בגדים אבא': 0.25, 'בילויים אבא': 0.20, 'בגדים אמא': 0.15, 'בילויים אמא': 0.25, 'טיפוח אמא': 0.15 };
    } else if (_maritalStatus == 'single' && cCount == 0) {
      ratios = { 'בגדים אישי': 0.40, 'בילויים אישי': 0.45, 'טיפוח אישי': 0.15 };
    } else {
      ratios = { 'בגדים אבא': 0.19, 'בילויים אבא': 0.14, 'בגדים אמא': 0.09, 'בילויים אמא': 0.19, 'טיפוח אמא': 0.15 };
    }

    if (cCount > 0) {
      double clothesRatio = 0.12 / cCount;
      double funRatio = 0.12 / cCount;
      for (var kid in kids) {
        String safeName = kid.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
        if (safeName == 'אבא' || safeName == 'אמא' || safeName == 'אישי') {
          safeName = '$safeName (ילד)';
        }
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

    // הגנה נוקשה לשחזור הקצאת ילדים
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
    if (_expenses.isEmpty) return;

    bool changed = false;
    final now = DateTime.now().toIso8601String();

    if (childCount == 0) {
      for (int i = _expenses.length - 1; i >= 0; i--) {
        final e = _expenses[i];
        if (e.parentCategory == 'ילדים - משתנות' || e.parentCategory == 'ילדים - קבועות') {
          await DatabaseHelper.instance.deleteExpense(e.id!);
          _expenses.removeAt(i);
          changed = true;
        }
      }
    }

    final validChildNames = _familyMembers.where((m) => m.role == FamilyRole.child).map((m) {
      String n = m.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
      if (n == 'אבא' || n == 'אמא' || n == 'אישי') n = '$n (ילד)';
      return n;
    }).toList();

    final Set<String> seenKidsExpenses = {};
    for (int i = _expenses.length - 1; i >= 0; i--) {
      final e = _expenses[i];
      if (e.parentCategory == 'ילדים - משתנות' && e.name != 'בגדים ילדים' && e.name != 'בילויים ילדים') {
        String eNameForMatch = e.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
        
        if (seenKidsExpenses.contains(eNameForMatch)) {
          await DatabaseHelper.instance.deleteExpense(e.id!);
          _expenses.removeAt(i);
          changed = true;
          continue;
        }
        seenKidsExpenses.add(eNameForMatch);

        bool isValid = validChildNames.any((childName) => eNameForMatch == 'בגדים $childName' || eNameForMatch == 'בילויים $childName');
        if (!isValid) {
          await DatabaseHelper.instance.deleteExpense(e.id!);
          _expenses.removeAt(i);
          changed = true;
        }
      }
    }

    if (childCount > 0) {
      final kidsFixed = ['שכר לימוד', 'ציוד בית ספר', 'חוגים', 'מתנות לימי הולדת', 'קייטנות'];
      for (String kf in kidsFixed) {
        if (!_expenses.any((e) => e.name == kf || (kf == 'מתנות לימי הולדת' && e.name == 'מתנות ימי הולדת'))) {
           await DatabaseHelper.instance.insertExpense(Expense(
               name: kf, category: 'קבועות', parentCategory: 'ילדים - קבועות',
               monthlyAmount: 0, originalAmount: 0, isSinking: true, isPerChild: true,
               frequency: (kf == 'ציוד בית ספר' || kf == 'קייטנות') ? Frequency.YEARLY : Frequency.MONTHLY,
               date: now, isDynamicSalary: false, isCustom: false,
           ));
           changed = true;
        }
      }
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

    final Map<String, double> targetVariableRatios = _getDynamicVariableRatios();
    
    List<String> allKidsVarExpenses = [];
    for(var n in validChildNames) {
       allKidsVarExpenses.add('בגדים $n');
       allKidsVarExpenses.add('בילויים $n');
    }

    for (int i = 0; i < _expenses.length; i++) {
      final e = _expenses[i];
      
      if (e.name == 'פארם וניקיון' || e.name == 'בגדים ילדים' || e.name == 'בילויים ילדים') {
        await DatabaseHelper.instance.deleteExpense(e.id!);
        changed = true;
        continue;
      }

      bool needsUpdate = false;
      String newCat = e.category;
      String newParent = e.parentCategory;
      bool newIsPerChild = e.isPerChild;
      String newName = e.name;
      bool newIsCustom = e.isCustom;
      String nameForMatch = e.name.trim().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');

      final oldVehicleNames = ['טסט', 'ביטוח', 'טיפול', 'תיקונים', 'דלק', 'ליסינג', 'נסיעות'];
      if (e.parentCategory == 'רכב' && !e.name.contains('(') && oldVehicleNames.contains(e.name.trim())) {
        newName = '${e.name} (אופנוע יסוד)';
        newIsCustom = true; 
        needsUpdate = true;
      }

      if (syncRules.containsKey(nameForMatch)) {
        final rule = syncRules[nameForMatch]!;
        if (e.category != rule['cat'] || e.parentCategory != rule['parent']) {
          newCat = rule['cat']!;
          newParent = rule['parent']!;
          newIsPerChild = (rule['parent']!.startsWith('ילדים - קבועות') || e.isPerChild);
          needsUpdate = true;
        }
      }

      double? newRatio = e.allocationRatio;

      // Ironclad Logic for Kids Allocation: Bypasses string matching and forces ratio based strictly on childCount
      if (e.parentCategory == 'ילדים - משתנות') {
        double expectedRatio = childCount > 0 ? (0.12 / childCount) : 0.0;
        if (newRatio == null || (newRatio - expectedRatio).abs() > 0.0001) {
            newRatio = expectedRatio;
            needsUpdate = true;
        }
        if (e.isPerChild) {
            newIsPerChild = false;
            needsUpdate = true;
        }
        if (e.name != nameForMatch) {
            newName = nameForMatch;
            needsUpdate = true;
        }
      } 
      // Regular matching for everything else
      else if (requiredRatios.containsKey(nameForMatch)) {
        if (newRatio != requiredRatios[nameForMatch]) {
          newRatio = requiredRatios[nameForMatch];
          needsUpdate = true;
        }
      } 
      else if (targetVariableRatios.containsKey(nameForMatch)) {
        double targetRatio = targetVariableRatios[nameForMatch] ?? 0.0;
        if (newRatio != targetRatio) {
          if (targetRatio == 0.0 || newRatio == 0 || newRatio == null || (newRatio * 100).round() == 10) {
              newRatio = targetRatio;
              needsUpdate = true;
          }
        }
      }

      bool newIsSinking = e.isSinking;

      if (needsUpdate) {
        final updated = Expense(
          id: e.id, name: newName, category: newCat, parentCategory: newParent,
          monthlyAmount: e.monthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency,
          isSinking: newIsSinking, isPerChild: newIsPerChild,
          targetAmount: e.targetAmount, currentBalance: e.currentBalance, allocationRatio: newRatio,
          lastUpdateDate: e.lastUpdateDate, isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
          isDynamicSalary: e.isDynamicSalary, salaryStartDate: e.salaryStartDate,
          isCustom: newIsCustom,
        );
        await DatabaseHelper.instance.updateExpense(updated);
        changed = true;
      }
    }

    for (var entry in targetVariableRatios.entries) {
      if (entry.value > 0 && !_expenses.any((e) => e.name == entry.key)) {
        String parentCat;
        if (allKidsVarExpenses.contains(entry.key)) {
           parentCat = 'ילדים - משתנות';
        } else if (entry.key.contains('אישי')) {
           parentCat = 'אישי';
        } else if (entry.key.contains('אבא')) {
           parentCat = 'אבא';
        } else {
           parentCat = 'אמא';
        }
        
        await DatabaseHelper.instance.insertExpense(Expense(
          name: entry.key, category: 'משתנות', parentCategory: parentCat,
          monthlyAmount: 0, originalAmount: 0, isSinking: true,
          isPerChild: false,
          allocationRatio: entry.value,
          date: now, isDynamicSalary: false, isCustom: false,
        ));
        changed = true;
      }
    }
    
    if (changed) {
      _expenses = await DatabaseHelper.instance.getExpenses();
      _sortInMemoryData(); // מיון מחדש לאחר הוספות או שינויים
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
    _isFatherActive = true;
    _isMotherActive = true;
    _isKidsActive = true;
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
      bool isFatherEntity = e.parentCategory == 'אבא' || e.name.contains('אבא') || e.name.contains('אישי');
      bool isMotherEntity = e.parentCategory == 'אמא' || e.name.contains('אמא');
      bool isKidsEntity = e.parentCategory == 'ילדים - משתנות';

      if ((isFatherEntity && !_isFatherActive) || 
          (isMotherEntity && !_isMotherActive) || 
          (isKidsEntity && !_isKidsActive)) {
        continue;
      }

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
      bool isFatherEntity = e.parentCategory == 'אבא' || e.name.contains('אבא') || e.name.contains('אישי');
      bool isMotherEntity = e.parentCategory == 'אמא' || e.name.contains('אמא');
      bool isKidsEntity = e.parentCategory == 'ילדים - משתנות';

      if ((isFatherEntity && !_isFatherActive) || 
          (isMotherEntity && !_isMotherActive) || 
          (isKidsEntity && !_isKidsActive)) {
        calculatedAmount = 0; 
      } else {
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
    );
    await DatabaseHelper.instance.updateExpense(updated);
  }
}