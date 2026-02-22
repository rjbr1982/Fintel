// 🔒 STATUS: FIXED (Corrected undefined variable 'index' to 'i' in loop)
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

  int _childCount = defaultChildCount; 
  double _variableAllocationRatio = defaultVariableRatio; 
  double _futureAllocationRatio = defaultFutureRatio;    

  // --- משתני מנוע החירות (Freedom Engine) ---
  double _initialCapital = 0.0;
  double _expectedYield = 4.0; // 4% default (Risk-free)
  int _compoundingFrequency = 12; // Monthly default
  double? _manualTargetIncome;

  List<Expense> get expenses => _expenses;
  List<FamilyMember> get familyMembers => _familyMembers;
  int get childCount => _childCount;
  
  double get variableAllocationRatio => _variableAllocationRatio;
  double get futureAllocationRatio => _futureAllocationRatio;
  bool get isFutureMode => _isFutureMode;
  
  double get variableDeficit => _variableDeficit;

  // חשיפת משתני המחשבון ל-UI
  double get initialCapital => _initialCapital;
  double get expectedYield => _expectedYield;
  int get compoundingFrequency => _compoundingFrequency;
  double? get manualTargetIncome => _manualTargetIncome;

  // יעד אוטומטי הנגזר מכלל ההוצאות התפעוליות
  double get autoTargetIncome => totalFixedExpenses + totalVariableExpenses + totalFutureExpenses;
  // יעד סופי (דרוס ידנית או אוטומטי)
  double get targetPassiveIncome => _manualTargetIncome ?? autoTargetIncome;

  // סנכרון דינמי של הון עצמי מתוך מסד הנכסים
  Future<void> syncCapitalFromAssets() async {
    final assets = await DatabaseHelper.instance.getAssets();
    _initialCapital = assets.fold(0.0, (sum, item) => sum + item.value);
    notifyListeners();
  }

  Future<void> loadData() async {
    try {
      _expenses = await DatabaseHelper.instance.getExpenses();
      _familyMembers = await DatabaseHelper.instance.getFamilyMembers();

      if (_expenses.isEmpty && _familyMembers.isEmpty) {
        await _seedInitialData();
        _expenses = await DatabaseHelper.instance.getExpenses();
        _familyMembers = await DatabaseHelper.instance.getFamilyMembers();
      }
      
      // טעינת הגדרות מנוע החירות והתקציב מזיכרון ה-DB
      await syncCapitalFromAssets(); 
      _expectedYield = await DatabaseHelper.instance.getSetting('expected_yield') ?? 4.0;
      _compoundingFrequency = (await DatabaseHelper.instance.getSetting('comp_freq') ?? 12.0).toInt();
      _manualTargetIncome = await DatabaseHelper.instance.getSetting('manual_target_income');
      
      _variableAllocationRatio = await DatabaseHelper.instance.getSetting('variable_ratio') ?? defaultVariableRatio;
      _futureAllocationRatio = await DatabaseHelper.instance.getSetting('future_ratio') ?? defaultFutureRatio;
      _childCount = (await DatabaseHelper.instance.getSetting('child_count') ?? defaultChildCount.toDouble()).toInt();

      await _forceCategorySync();
      await _performAutoRollover();
      _recalculateAll();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  Future<void> setFreedomSettings({
    double? manualTarget,
    required double yieldRate,
    required int frequency,
  }) async {
    _manualTargetIncome = manualTarget;
    _expectedYield = yieldRate;
    _compoundingFrequency = frequency;

    if (manualTarget != null) {
      await DatabaseHelper.instance.saveSetting('manual_target_income', manualTarget);
    } else {
      await DatabaseHelper.instance.deleteSetting('manual_target_income');
    }
    await DatabaseHelper.instance.saveSetting('expected_yield', yieldRate);
    await DatabaseHelper.instance.saveSetting('comp_freq', frequency.toDouble());

    notifyListeners();
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

  Future<void> resetExpenseToDefault(int expenseId) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;
    
    final name = _expenses[index].name;
    double defaultRatio = 0.0;

    final Map<String, double> defaultRatios = {
      'בגדים אבא': 0.19, 'בילויים אבא': 0.14, 'בגדים אמא': 0.09,
      'בילויים אמא': 0.19, 'טיפוח אמא': 0.15, 'בגדים ילדים': 0.12,
      'בילויים ילדים': 0.12, 'תנור גז': 0.2, 'בר מצווה אליעזר': 0.5,
      'הדברה': 0.15, 'רפואי': 0.15,
    };

    defaultRatio = defaultRatios[name] ?? 0.0;

    final old = _expenses[index];
    final updated = Expense(
      id: old.id, name: old.name, category: old.category, parentCategory: old.parentCategory,
      monthlyAmount: 0, originalAmount: old.originalAmount, frequency: old.frequency,
      isSinking: old.isSinking, isPerChild: old.isPerChild, targetAmount: old.targetAmount,
      currentBalance: old.currentBalance, allocationRatio: defaultRatio,
      lastUpdateDate: old.lastUpdateDate, isLocked: false, manualAmount: null, date: old.date,
    );

    await DatabaseHelper.instance.updateExpense(updated);
    _expenses[index] = updated;
    _recalculateAll();
    notifyListeners();
  }

  Future<void> _forceCategorySync() async {
    bool changed = false;
    final now = DateTime.now().toIso8601String();
    final Map<String, Map<String, String>> syncRules = {
      'בגדים ילדים': {'cat': 'משתנות', 'parent': 'ילדים - משתנות'},
      'בילויים ילדים': {'cat': 'משתנות', 'parent': 'ילדים - משתנות'},
      'שכר לימוד': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'},
      'ציוד בית ספר': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'},
      'חוגים': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'},
      'מתנות ימי הולדת': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'},
      'קייטנות': {'cat': 'קבועות', 'parent': 'ילדים - קבועות'},
      'תספורת': {'cat': 'קבועות', 'parent': 'תספורת'},
      'קטנות לבית': {'cat': 'קבועות', 'parent': 'קטנות לבית'},
    };

    final sinkingNames = [
      'הובלה ותיקונים', 'טסט', 'ביטוח', 'טיפול', 'תיקונים', 'מייקרוסופט',
      'שכר לימוד', 'ציוד בית ספר', 'חוגים', 'מתנות ימי הולדת', 'מתנות לימי הולדת', 'קייטנות',
      'נסיעות', 'קטנות לבית', 'בילויים'
    ];

    bool hasCamps = _expenses.any((e) => e.name == 'קייטנות');
    if (!hasCamps) {
      await DatabaseHelper.instance.insertExpense(Expense(
        name: 'קייטנות', category: 'קבועות', parentCategory: 'ילדים - קבועות',
        monthlyAmount: 0, isPerChild: true, isSinking: true, date: now
      ));
      changed = true;
    }

    for (int i = 0; i < _expenses.length; i++) {
      final e = _expenses[i];
      bool needsUpdate = false;
      
      String newCat = e.category;
      String newParent = e.parentCategory;
      bool newIsSinking = e.isSinking;
      bool newIsPerChild = e.isPerChild;

      if (syncRules.containsKey(e.name)) {
        final rule = syncRules[e.name]!;
        if (e.category != rule['cat'] || e.parentCategory != rule['parent']) {
          newCat = rule['cat']!;
          newParent = rule['parent']!;
          newIsPerChild = (rule['parent']!.startsWith('ילדים') || e.isPerChild);
          needsUpdate = true;
        }
      }

      bool shouldBeSinking = newCat == 'עתידיות' || 
                             newParent == 'חגים' || 
                             (newCat == 'משתנות' && newParent != 'קניות') ||
                             sinkingNames.contains(e.name);

      if (e.isSinking != shouldBeSinking) {
        newIsSinking = shouldBeSinking;
        needsUpdate = true;
      }

      if (needsUpdate) {
        final updated = Expense(
          id: e.id, name: e.name, category: newCat, parentCategory: newParent,
          monthlyAmount: e.monthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency,
          isSinking: newIsSinking, isPerChild: newIsPerChild,
          targetAmount: e.targetAmount, currentBalance: e.currentBalance, allocationRatio: e.allocationRatio,
          lastUpdateDate: e.lastUpdateDate, isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
        );
        await DatabaseHelper.instance.updateExpense(updated);
        _expenses[i] = updated;
        changed = true;
      }
    }
    if (changed) _expenses = await DatabaseHelper.instance.getExpenses();
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
    _variableAllocationRatio = defaultVariableRatio;
    await DatabaseHelper.instance.saveSetting('variable_ratio', defaultVariableRatio);
    _recalculateAll();
    notifyListeners();
  }

  Future<void> resetFutureRatio() async {
    _futureAllocationRatio = defaultFutureRatio;
    await DatabaseHelper.instance.saveSetting('future_ratio', defaultFutureRatio);
    _recalculateAll();
    notifyListeners();
  }

  Future<void> fullAppReset() async {
    await DatabaseHelper.instance.clearAllData();
    _childCount = defaultChildCount;
    _manualTargetIncome = null;
    _initialCapital = 0.0;
    _expectedYield = 4.0;
    _compoundingFrequency = 12;
    _variableAllocationRatio = defaultVariableRatio;
    _futureAllocationRatio = defaultFutureRatio;
    _externalDebtPayment = 0;
    _isFutureMode = false;
    await loadData();
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
          if (e.isPerChild) {
            monthlyDeposit *= _childCount;
          }
          double addedAmount = monthlyDeposit * monthsDiff;
          
          final updatedExpense = Expense(
            id: e.id, name: e.name, category: e.category, parentCategory: e.parentCategory,
            monthlyAmount: e.monthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency, isSinking: e.isSinking, isPerChild: e.isPerChild,
            targetAmount: e.targetAmount, currentBalance: (e.currentBalance ?? 0) + addedAmount,
            allocationRatio: e.allocationRatio, lastUpdateDate: now.toIso8601String(),
            isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
          );
          await DatabaseHelper.instance.updateExpense(updatedExpense);
          _expenses[i] = updatedExpense;
          wasUpdated = true;
        }
      }
    }
    if (wasUpdated) notifyListeners();
  }

  void _recalculateAll() {
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
      );
      await DatabaseHelper.instance.updateExpense(updated);
      _expenses[index] = updated;
      _recalculateAll(); 
      notifyListeners();
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
      );
      await DatabaseHelper.instance.updateExpense(updated);
      _expenses[index] = updated;
      _recalculateAll();
      notifyListeners();
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
      );
      await DatabaseHelper.instance.updateExpense(updated);
      _expenses[index] = updated;
      _recalculateAll();
      notifyListeners();
    }
  }

  Future<void> updateFutureExpenseDetails(int expenseId, {String? name, double? target, double? balance, double? ratio, bool? isLocked, double? manualAmount}) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final old = _expenses[index];
      final updated = Expense(
        id: old.id, 
        name: name ?? old.name, 
        category: old.category, 
        parentCategory: old.parentCategory,
        monthlyAmount: (isLocked == true && manualAmount != null) ? manualAmount : 0, 
        originalAmount: old.originalAmount, frequency: old.frequency, isSinking: old.isSinking, isPerChild: old.isPerChild,
        targetAmount: target ?? old.targetAmount,
        currentBalance: balance ?? old.currentBalance,
        allocationRatio: ratio ?? old.allocationRatio,
        lastUpdateDate: DateTime.now().toIso8601String(),
        isLocked: isLocked ?? old.isLocked,
        manualAmount: manualAmount ?? old.manualAmount,
        date: old.date,
      );
      await DatabaseHelper.instance.updateExpense(updated);
      _expenses[index] = updated;
      _recalculateAll();
      notifyListeners();
    }
  }

  void _recalculateVariableExpenses() {
    final totalPot = totalVariableExpenses; 
    final variableIndices = <int>[];
    for (int i = 0; i < _expenses.length; i++) {
      if (_expenses[i].category == 'משתנות') {
        variableIndices.add(i);
      }
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
      if (_expenses[i].category == 'עתידיות') {
        futureIndices.add(i);
      }
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
    if (remainingBudget < 0) {
      remainingBudget = 0;
    }
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
    );
  }

  Future<void> addFamilyMember(String name, int birthYear) async {
    final newMember = FamilyMember(name: name, birthYear: birthYear);
    await DatabaseHelper.instance.insertFamilyMember(newMember);
    await loadData();
  }

  Future<void> removeFamilyMember(int id) async {
    await DatabaseHelper.instance.deleteFamilyMember(id);
    await loadData();
  }

  Future<void> updateFamilyMember(FamilyMember member) async {
    if (member.id != null) {
      await DatabaseHelper.instance.updateFamilyMember(member);
      await loadData();
    }
  }

  Future<void> addExpense(Expense expense) async {
    await DatabaseHelper.instance.insertExpense(expense);
    await loadData();
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.id != null) {
      await DatabaseHelper.instance.updateExpense(expense);
      await loadData();
    }
  }

  Future<void> deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    await loadData();
  }
  
  Future<void> renameParentCategory(String oldName, String newName) async {
    if (oldName == newName || newName.trim().isEmpty) return;
    
    bool changed = false;
    for (int i = 0; i < _expenses.length; i++) {
      if (_expenses[i].parentCategory == oldName) {
        final e = _expenses[i];
        final updated = Expense(
          id: e.id, name: e.name, category: e.category, parentCategory: newName.trim(),
          monthlyAmount: e.monthlyAmount, originalAmount: e.originalAmount, frequency: e.frequency,
          isSinking: e.isSinking, isPerChild: e.isPerChild, targetAmount: e.targetAmount,
          currentBalance: e.currentBalance, allocationRatio: e.allocationRatio,
          lastUpdateDate: e.lastUpdateDate, isLocked: e.isLocked, manualAmount: e.manualAmount, date: e.date,
        );
        await DatabaseHelper.instance.updateExpense(updated);
        _expenses[i] = updated; // <-- תוקן כאן מ-index ל-i
        changed = true;
      }
    }
    
    if (changed) {
      _recalculateAll();
      notifyListeners();
    }
  }

  Future<void> setChildCount(int count) async {
    _childCount = count;
    await DatabaseHelper.instance.saveSetting('child_count', count.toDouble());
    _recalculateAll(); 
    notifyListeners();
  }

  Future<void> setAllocationRatios({double? variable, double? future}) async {
    if (variable != null) {
      _variableAllocationRatio = variable;
      await DatabaseHelper.instance.saveSetting('variable_ratio', variable);
    }
    if (future != null) {
      _futureAllocationRatio = future;
      await DatabaseHelper.instance.saveSetting('future_ratio', future);
    }
    _recalculateAll();
    notifyListeners();
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

  Future<void> _seedInitialData() async {
    final db = DatabaseHelper.instance;
    final now = DateTime.now().toIso8601String();
    final initialFamily = [
      FamilyMember(name: 'רפאל', birthYear: 1982),
      FamilyMember(name: 'קרן', birthYear: 1990),
      FamilyMember(name: 'אליעזר', birthYear: 2013),
      FamilyMember(name: 'מלכה', birthYear: 2015),
      FamilyMember(name: 'שרה', birthYear: 2017),
    ];
    for (var m in initialFamily) { await db.insertFamilyMember(m); }
    final incomes = [
      Expense(name: 'פלקס', category: 'הכנסות', parentCategory: 'הכנסות', monthlyAmount: 11000, date: now),
      Expense(name: 'מכון המקדש', category: 'הכנסות', parentCategory: 'הכנסות', monthlyAmount: 5570, date: now),
      Expense(name: 'קצבת ילדים', category: 'הכנסות', parentCategory: 'הכנסות', monthlyAmount: 590, date: now),
    ];
    final fixed = [
      Expense(name: 'צדקה', category: 'קבועות', parentCategory: 'צדקה', monthlyAmount: 50, date: now),
      Expense(name: 'שכירות', category: 'קבועות', parentCategory: 'דיור', monthlyAmount: 3300, date: now),
      Expense(name: 'וועד בית', category: 'קבועות', parentCategory: 'דיור', monthlyAmount: 170, date: now),
      Expense(name: 'ארנונה', category: 'קבועות', parentCategory: 'דיור', monthlyAmount: 350, date: now),
      Expense(name: 'הובלה ותיקונים', category: 'קבועות', parentCategory: 'דיור', monthlyAmount: 208, isSinking: true, date: now),
      Expense(name: 'חשמל', category: 'קבועות', parentCategory: 'מגורים', monthlyAmount: 750, date: now),
      Expense(name: 'מים', category: 'קבועות', parentCategory: 'מגורים', monthlyAmount: 250, date: now),
      Expense(name: 'גז', category: 'קבועות', parentCategory: 'מגורים', monthlyAmount: 50, date: now),
      Expense(name: 'טסט', category: 'קבועות', parentCategory: 'רכב', monthlyAmount: 21, isSinking: true, date: now),
      Expense(name: 'ביטוח', category: 'קבועות', parentCategory: 'רכב', monthlyAmount: 292, isSinking: true, date: now),
      Expense(name: 'טיפול', category: 'קבועות', parentCategory: 'רכב', monthlyAmount: 42, isSinking: true, date: now),
      Expense(name: 'תיקונים', category: 'קבועות', parentCategory: 'רכב', monthlyAmount: 50, isSinking: true, date: now),
      Expense(name: 'דלק', category: 'קבועות', parentCategory: 'רכב', monthlyAmount: 30, date: now),
      Expense(name: 'פרטנר', category: 'קבועות', parentCategory: 'מדיה', monthlyAmount: 220, date: now),
      Expense(name: 'גוגל AI פרו', category: 'קבועות', parentCategory: 'מדיה', monthlyAmount: 75, date: now),
      Expense(name: 'יוטיוב פרימיום', category: 'קבועות', parentCategory: 'מדיה', monthlyAmount: 48, date: now),
      Expense(name: 'מייקרוסופט', category: 'קבועות', parentCategory: 'מדיה', monthlyAmount: 38, isSinking: true, date: now),
      Expense(name: 'צ\'אט GPT', category: 'קבועות', parentCategory: 'מדיה', monthlyAmount: 74, date: now),
      Expense(name: 'שכר לימוד', category: 'קבועות', parentCategory: 'ילדים - קבועות', monthlyAmount: 174, isPerChild: true, isSinking: true, date: now),
      Expense(name: 'ציוד בית ספר', category: 'קבועות', parentCategory: 'ילדים - קבועות', monthlyAmount: 33, isPerChild: true, isSinking: true, date: now),
      Expense(name: 'חוגים', category: 'קבועות', parentCategory: 'ילדים - קבועות', monthlyAmount: 200, isPerChild: true, isSinking: true, date: now),
      Expense(name: 'מתנות ימי הולדת', category: 'קבועות', parentCategory: 'ילדים - קבועות', monthlyAmount: 21, isPerChild: true, isSinking: true, date: now),
      Expense(name: 'קייטנות', category: 'קבועות', parentCategory: 'ילדים - קבועות', monthlyAmount: 0, isPerChild: true, isSinking: true, date: now),
      Expense(name: 'ראש השנה', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 41.61, isSinking: true, date: now),
      Expense(name: 'יום כיפור', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 41.61, isSinking: true, date: now),
      Expense(name: 'סוכות', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 41.61, isSinking: true, date: now),
      Expense(name: 'שמחת תורה', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 41.61, isSinking: true, date: now),
      Expense(name: 'חנוכה', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 16.67, isSinking: true, date: now),
      Expense(name: 'ט"ו בשבט', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 16.67, isSinking: true, date: now),
      Expense(name: 'פורים', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 16.67, isSinking: true, date: now),
      Expense(name: 'פסח', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 125, isSinking: true, date: now),
      Expense(name: 'יום העצמאות', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 41.67, isSinking: true, date: now),
      Expense(name: 'ל"ג בעומר', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 41.67, isSinking: true, date: now),
      Expense(name: 'שבועות', category: 'קבועות', parentCategory: 'חגים', monthlyAmount: 41.67, isSinking: true, date: now),
      Expense(name: 'קופת חולים', category: 'קבועות', parentCategory: 'קופ"ח', monthlyAmount: 600, date: now),
      Expense(name: 'נסיעות', category: 'קבועות', parentCategory: 'נסיעות', monthlyAmount: 100, isSinking: true, date: now),
      Expense(name: 'תספורת', category: 'קבועות', parentCategory: 'תספורת', monthlyAmount: 130, date: now),
      Expense(name: 'קטנות לבית', category: 'קבועות', parentCategory: 'קטנות לבית', monthlyAmount: 100, isSinking: true, date: now),
      Expense(name: 'בילויים', category: 'קבועות', parentCategory: 'בילויים', monthlyAmount: 89, isSinking: true, date: now),
    ];
    final variables = [
      Expense(name: 'קניות', category: 'משתנות', parentCategory: 'קניות', monthlyAmount: 4936, date: now, lastUpdateDate: now),
      Expense(name: 'בגדים אבא', category: 'משתנות', parentCategory: 'אבא', monthlyAmount: 0, allocationRatio: 0.19, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'בילויים אבא', category: 'משתנות', parentCategory: 'אבא', monthlyAmount: 0, allocationRatio: 0.14, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'בגדים אמא', category: 'משתנות', parentCategory: 'אמא', monthlyAmount: 0, allocationRatio: 0.09, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'בילויים אמא', category: 'משתנות', parentCategory: 'אמא', monthlyAmount: 0, allocationRatio: 0.19, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'טיפוח אמא', category: 'משתנות', parentCategory: 'אמא', monthlyAmount: 0, allocationRatio: 0.15, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'בגדים ילדים', category: 'משתנות', parentCategory: 'ילדים - משתנות', monthlyAmount: 0, allocationRatio: 0.12, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'בילויים ילדים', category: 'משתנות', parentCategory: 'ילדים - משתנות', monthlyAmount: 0, allocationRatio: 0.12, isSinking: true, date: now, lastUpdateDate: now),
    ];
    final future = [
      Expense(name: 'רכישות גדולות', category: 'עתידיות', parentCategory: 'רכישות גדולות', monthlyAmount: 0, allocationRatio: 0.0, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'חופשה שנתית', category: 'עתידיות', parentCategory: 'חופשה שנתית', monthlyAmount: 0, allocationRatio: 0.0, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'תנור גז', category: 'עתידיות', parentCategory: 'רכישות קטנות', monthlyAmount: 0, allocationRatio: 0.2, targetAmount: 2500, currentBalance: 0, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'בר מצווה אליעזר', category: 'עתידיות', parentCategory: 'הפקת אירועים', monthlyAmount: 0, allocationRatio: 0.5, targetAmount: 10000, currentBalance: 5147, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'הדברה', category: 'עתידיות', parentCategory: 'תיקונים', monthlyAmount: 0, allocationRatio: 0.15, targetAmount: 450, currentBalance: 1298, isSinking: true, date: now, lastUpdateDate: now),
      Expense(name: 'רפואי', category: 'עתידיות', parentCategory: 'רפואי', monthlyAmount: 0, allocationRatio: 0.15, targetAmount: 1000, currentBalance: 318, isSinking: true, date: now, lastUpdateDate: now),
    ];
    
    for (var e in incomes) { await db.insertExpense(e); }
    for (var e in fixed) { await db.insertExpense(e); }
    for (var e in variables) { await db.insertExpense(e); }
    for (var e in future) { await db.insertExpense(e); }
  }

  // --- משיכות מהוצאות צוברות (Withdrawals) ---
  
  Future<List<Withdrawal>> getWithdrawalsForExpense(int expenseId) async {
    return await DatabaseHelper.instance.getWithdrawals(expenseId);
  }

  Future<void> addWithdrawal(int expenseId, double amount, String note) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) {
      return;
    }
    final expense = _expenses[index];
    final newBalance = (expense.currentBalance ?? 0) - amount;

    final w = Withdrawal(expenseId: expenseId, amount: amount, date: DateTime.now().toIso8601String(), note: note);
    await DatabaseHelper.instance.insertWithdrawal(w);

    _updateExpenseCurrentBalance(index, newBalance);
  }

  Future<void> deleteWithdrawal(Withdrawal w) async {
    if (w.id == null) {
      return;
    }
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
    );
    await DatabaseHelper.instance.updateExpense(updated);
    _expenses[index] = updated;
    notifyListeners();
  }
}