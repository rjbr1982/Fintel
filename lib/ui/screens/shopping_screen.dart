// 🔒 STATUS: EDITED (Enhanced Delta Tooltip, Contextual Onboarding, and Mobile Sort Sheet Fix)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/budget_provider.dart'; 
import '../../data/shopping_model.dart';
import '../../data/expense_model.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  String _selectedCategory = 'הכל';
  
  // מנוע המיון הרב-שכבתי
  List<String> _allSortOptions = ['סיווג', 'שם', 'מחיר', 'תדירות', 'קנייה אחרונה'];
  List<String> _activeSorts = ['סיווג', 'שם']; // ברירת המחדל: סיווג, ואז שם
  
  int _comparisonOffset = 0; 

  // מנגנון זום מקומי למסך קניות (רספונסיביות למחשב)
  double _textScale = 1.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ShoppingProvider>().loadItems();
      }
    });
  }

  void _zoomIn() {
    setState(() {
      if (_textScale < 2.0) _textScale += 0.1;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_textScale > 0.8) _textScale -= 0.1;
    });
  }

  bool _wasItemPurchasedInWeek(ShoppingItem item, int offset) {
    if (item.lastPurchaseDateTime == null || offset == 0) {
      return false;
    }
    
    final now = DateTime.now();
    final startOfCurrentWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
    final startOfTargetWeek = startOfCurrentWeek.add(Duration(days: offset * 7));
    final endOfTargetWeek = startOfTargetWeek.add(const Duration(days: 7));

    return item.lastPurchaseDateTime!.isAfter(startOfTargetWeek.subtract(const Duration(seconds: 1))) && 
           item.lastPurchaseDateTime!.isBefore(endOfTargetWeek);
  }

  List<int> _getWeekOptions() {
    return List.generate(25, (index) => -(index + 2)); 
  }

  String _getWeekLabel(int offset) {
    if (offset == 0) {
      return "השבוע";
    }
    if (offset == -1) {
      return "שבוע שעבר";
    }
    int weeksAgo = offset.abs();
    if (weeksAgo % 4 == 0) {
      return "לפני ${weeksAgo ~/ 4} חודשים";
    }
    return "לפני $weeksAgo שבועות";
  }

  @override
  Widget build(BuildContext context) {
    final shoppingProvider = context.watch<ShoppingProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    
    // שאיבה בטוחה של עוגן הקניות ללא קריסה למשכורת
    final groceryExpense = budgetProvider.expenses.firstWhere(
      (e) => e.name.trim() == 'קניות' || (e.category == 'משתנות' && e.parentCategory == 'קניות'),
      orElse: () => Expense(
        name: 'קניות',
        category: 'משתנות',
        parentCategory: 'קניות',
        monthlyAmount: 0,
        originalAmount: 0,
        date: DateTime.now().toIso8601String(),
        frequency: Frequency.MONTHLY,
      ),
    );
    
    final double budgetLimit = groceryExpense.isLocked 
        ? (groceryExpense.manualAmount ?? 0) 
        : groceryExpense.originalAmount;

    final double plannedMonthly = shoppingProvider.totalMonthlyPlannedCost;
    final double actualMonthly = shoppingProvider.actualMonthlySpent;
    final double currentBasket = shoppingProvider.currentBasketTotal;

    // הגנה במידה והקטגוריה שנבחרה נמחקה
    if (!shoppingProvider.availableCategories.contains(_selectedCategory)) {
      _selectedCategory = 'הכל';
    }

    List<ShoppingItem> displayedItems = _selectedCategory == 'הכל'
        ? List.from(shoppingProvider.items)
        : shoppingProvider.items.where((i) => i.category == _selectedCategory).toList();

    // --- לוגיקת המיון הרב-שכבתית (Multi-Level Sort Engine) ---
    displayedItems.sort((a, b) {
      for (String sort in _activeSorts) {
        int result = 0;
        if (sort == 'מחיר') {
          result = b.price.compareTo(a.price); // מהיקר לזול
        } else if (sort == 'תדירות') {
          result = a.frequencyWeeks.compareTo(b.frequencyWeeks); // תדירות גבוהה (מעט שבועות) קודם
        } else if (sort == 'קנייה אחרונה') {
          final ad = a.lastPurchaseDateTime ?? DateTime(2000);
          final bd = b.lastPurchaseDateTime ?? DateTime(2000);
          result = bd.compareTo(ad); // קנייה חדשה יותר קודם
        } else if (sort == 'סיווג') {
          result = a.category.compareTo(b.category);
        } else if (sort == 'שם') {
          result = a.name.compareTo(b.name);
        }
        
        if (result != 0) {
          return result;
        }
      }
      return a.name.compareTo(b.name); // Fallback אחרון
    });

    String sortDisplay = _activeSorts.take(2).join(' > ');
    if (_activeSorts.length > 2) {
      sortDisplay += '...';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('רשימת קניות', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Text('A-', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 16)),
            tooltip: 'הקטן טקסט',
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: const Text('A+', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
            tooltip: 'הגדל טקסט',
            onPressed: _zoomIn,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: currentBasket > 0 
          ? null 
          : FloatingActionButton(
              backgroundColor: const Color(0xFF121212),
              onPressed: () => _showItemEditor(context, shoppingProvider),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: Column(
        children: [
          _buildEnhancedBudgetCard(budgetLimit, plannedMonthly, actualMonthly),
          _buildComparisonNavigator(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers, size: 18 * _textScale, color: Colors.blueGrey),
                    SizedBox(width: 8 * _textScale),
                    Text(
                      "$_selectedCategory | מיון: $sortDisplay",
                      style: TextStyle(fontSize: 13 * _textScale, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                _buildControlMenu(shoppingProvider),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              children: [
                displayedItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: displayedItems.length,
                        separatorBuilder: (context, index) => SizedBox(height: 8 * _textScale),
                        itemBuilder: (context, index) {
                          final item = displayedItems[index];
                          final bool wasPurchased = _wasItemPurchasedInWeek(item, _comparisonOffset);
                          Widget tile = _buildComparisonTile(item, shoppingProvider, wasPurchased);

                          if (_activeSorts.isNotEmpty && _activeSorts.first == 'סיווג' && _selectedCategory == 'הכל') {
                            bool isFirst = index == 0;
                            bool isNewCat = isFirst || displayedItems[index - 1].category != item.category;
                            
                            if (isNewCat) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 12 * _textScale, bottom: 6 * _textScale, right: 4),
                                    child: Text(
                                      item.category,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * _textScale, color: Colors.blueGrey),
                                    ),
                                  ),
                                  tile,
                                ],
                              );
                            }
                          }
                          
                          return tile;
                        },
                      ),
                if (currentBasket > 0) _buildActiveBasketBar(currentBasket, shoppingProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonNavigator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black.withAlpha(8), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildWeekTab("השבוע", 0),
          _buildWeekTab("שבוע שעבר", -1),
          _buildDynamicWeekPicker(),
        ],
      ),
    );
  }

  Widget _buildWeekTab(String label, int offset) {
    final bool isSelected = _comparisonOffset == offset;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _comparisonOffset = offset),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)] : null,
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 11 * _textScale, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF00A3FF) : Colors.black54)),
        ),
      ),
    );
  }

  Widget _buildDynamicWeekPicker() {
    final bool isExtraSelected = _comparisonOffset < -1;
    return Expanded(
      child: PopupMenuButton<int>(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        onSelected: (val) => setState(() => _comparisonOffset = val),
        itemBuilder: (context) => _getWeekOptions().map((offset) => PopupMenuItem(
          value: offset,
          child: Text(_getWeekLabel(offset), style: TextStyle(fontSize: 13 * _textScale, color: Colors.black87)),
        )).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isExtraSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isExtraSelected ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isExtraSelected ? _getWeekLabel(_comparisonOffset) : "עוד שבועות...",
                style: TextStyle(
                  fontSize: 11 * _textScale, 
                  fontWeight: isExtraSelected ? FontWeight.bold : FontWeight.normal,
                  color: isExtraSelected ? const Color(0xFF00A3FF) : Colors.black54
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 16 * _textScale, color: isExtraSelected ? const Color(0xFF00A3FF) : Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTile(ShoppingItem item, ShoppingProvider provider, bool wasPurchasedInHistory) {
    final bool checked = provider.isChecked(item.id ?? -1);
    final bool isViolation = item.isFrequencyViolation;

    return Container(
      decoration: BoxDecoration(
        color: checked ? const Color(0xFFF1F8E9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: (isViolation && checked) ? Border.all(color: Colors.orange.withAlpha(100), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        dense: true,
        onLongPress: () => _showQuickHistoryAction(context, item, provider),
        leading: Transform.scale(
          scale: _textScale,
          child: Checkbox(
            value: checked,
            activeColor: const Color(0xFF121212),
            side: const BorderSide(color: Colors.black45, width: 1.5),
            onChanged: (_) => provider.toggleItem(item.id!),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w500, fontSize: 14 * _textScale,
                ),
              ),
            ),
            if (_comparisonOffset != 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: wasPurchasedInHistory ? Colors.green.withAlpha(20) : Colors.red.withAlpha(10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      wasPurchasedInHistory ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 12 * _textScale, 
                      color: wasPurchasedInHistory ? Colors.green : Colors.black12
                    ),
                    const SizedBox(width: 4),
                    Text(
                      wasPurchasedInHistory ? "נקנה" : "לא נקנה",
                      style: TextStyle(fontSize: 9 * _textScale, color: wasPurchasedInHistory ? Colors.green[700] : Colors.black26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text(
          "₪${item.price.toStringAsFixed(1)} | ${_formatFrequency(item)}${item.lastPurchaseDate != null ? ' | נקנה לפני ${item.daysSinceLastPurchase} ימים' : ''}",
          style: TextStyle(fontSize: 10 * _textScale, color: Colors.blueGrey),
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, size: 18 * _textScale, color: Colors.black54),
          onPressed: () => _showItemEditor(context, provider, item: item),
        ),
      ),
    );
  }

  void _showQuickHistoryAction(BuildContext context, ShoppingItem item, ShoppingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("תיעוד קנייה למפרע: ${item.name}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * _textScale, color: Colors.black87)),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.today, color: Colors.blue, size: 24 * _textScale),
              title: Text("נקנה השבוע (מחוץ לסל המרכזי)", style: TextStyle(color: Colors.black87, fontSize: 14 * _textScale)),
              onTap: () {
                _applyRetroactivePurchase(item, 0, provider);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.orange, size: 24 * _textScale),
              title: Text("נקנה בשבוע שעבר", style: TextStyle(color: Colors.black87, fontSize: 14 * _textScale)),
              onTap: () {
                _applyRetroactivePurchase(item, -1, provider);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.event_repeat, color: Colors.blueGrey, size: 24 * _textScale),
              title: Text("נקנה במועד אחר...", style: TextStyle(color: Colors.black87, fontSize: 14 * _textScale)),
              onTap: () {
                Navigator.pop(ctx);
                _showHistoryPicker(context, (offset) => _applyRetroactivePurchase(item, offset, provider));
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _applyRetroactivePurchase(ShoppingItem item, int offset, ShoppingProvider provider) {
    DateTime purchaseDate = DateTime.now();
    if (offset != 0) {
      purchaseDate = purchaseDate.subtract(Duration(days: offset.abs() * 7));
    }
    
    final updatedItem = item.copyWith(
      lastPurchaseDate: purchaseDate.toIso8601String().split('T')[0],
    );
    
    provider.updateItem(updatedItem);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("עודכן: ${item.name} נקנה ${_getWeekLabel(offset)}"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildControlMenu(ShoppingProvider provider) {
    return PopupMenuButton<dynamic>(
      icon: Icon(Icons.tune, color: const Color(0xFF121212), size: 24 * _textScale),
      color: Colors.white, 
      surfaceTintColor: Colors.white, 
      onSelected: (value) {
        if (value == 'manage_cats') {
          _showCategoryManager(context, provider);
        } else if (value == 'multi_sort') {
          _showAdvancedSortSheet(context);
        } else {
          setState(() => _selectedCategory = value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'manage_cats', 
          child: Row(
            children: [
              Icon(Icons.category_outlined, size: 18 * _textScale, color: Colors.blue), 
              SizedBox(width: 8 * _textScale), 
              Text("ניהול קטגוריות", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14 * _textScale))
            ]
          )
        ),
        PopupMenuItem(
          value: 'multi_sort', 
          child: Row(
            children: [
              Icon(Icons.layers, size: 18 * _textScale, color: Colors.orange), 
              SizedBox(width: 8 * _textScale), 
              Text("מיון רב-שכבתי...", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14 * _textScale))
            ]
          )
        ),
        const PopupMenuDivider(),
        PopupMenuItem(enabled: false, child: Text("סינון קטגוריה", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12 * _textScale, color: Colors.blue))),
        ...provider.availableCategories.map((cat) => PopupMenuItem(value: cat, child: Row(children: [Icon(Icons.check, size: 16 * _textScale, color: _selectedCategory == cat ? Colors.blue : Colors.transparent), SizedBox(width: 8 * _textScale), Text(cat, style: TextStyle(color: Colors.black87, fontSize: 14 * _textScale))]))),
      ],
    );
  }
  
  // --- ממשק מיון מתקדם (Bottom Sheet לניהול השכבות) ---
  void _showAdvancedSortSheet(BuildContext context) {
    List<String> currentOrder = List.from(_allSortOptions);
    List<String> currentActive = List.from(_activeSorts);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // חובה למסכים קטנים כדי לאפשר גלילה חופשית מעל מקלדת/שטח מסך
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          // מחושב גובה מקסימלי כדי למנוע חריגה מהמסך במובייל
          final maxSheetHeight = MediaQuery.of(context).size.height * 0.75;
          
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // תופס את המינימום האפשרי, אבל לא יותר מ-maxSheetHeight
                  children: [
                    Text("ניהול סדר מיון (רב-שכבתי)", style: TextStyle(fontSize: 18 * _textScale, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text("המיון יתבצע מלמעלה למטה.\nגרור באמצעות הפסים כדי לשנות עדיפות, וסמן V כדי להפעיל.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12 * _textScale, color: Colors.grey)),
                    const Divider(),
                    // הרשימה הנגררת מתרחבת (Expanded) בתוך הגובה הנותר ולא חורגת מהמסך
                    Expanded(
                      child: ReorderableListView(
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) {
                          setSheetState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = currentOrder.removeAt(oldIndex);
                            currentOrder.insert(newIndex, item);
                          });
                        },
                        children: currentOrder.map((option) {
                          final isActive = currentActive.contains(option);
                          return ReorderableDragStartListener(
                            key: ValueKey(option),
                            index: currentOrder.indexOf(option),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.blue.withValues(alpha: 0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.2))
                              ),
                              child: CheckboxListTile(
                                value: isActive,
                                activeColor: Colors.blue,
                                side: const BorderSide(color: Colors.black54, width: 1.5),
                                onChanged: (val) {
                                  setSheetState(() {
                                    if (val == true) {
                                      currentActive.add(option);
                                    } else {
                                      currentActive.remove(option);
                                    }
                                  });
                                },
                                title: Text(option, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: Colors.black87, fontSize: 14 * _textScale)),
                                secondary: Icon(Icons.drag_handle, color: Colors.grey, size: 24 * _textScale),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // כפתור תמיד נשאר למטה
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF121212), 
                        foregroundColor: Colors.white, 
                        minimumSize: const Size(double.infinity, 48)
                      ),
                      onPressed: () {
                        List<String> newSorts = currentOrder.where((opt) => currentActive.contains(opt)).toList();
                        if (newSorts.isEmpty) {
                          newSorts = ['שם'];
                        }
                        
                        setState(() {
                          _activeSorts = newSorts;
                          _allSortOptions = List.from(currentOrder); 
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text("החל מיון", style: TextStyle(fontSize: 14 * _textScale)),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      )
    );
  }

  Widget _buildEnhancedBudgetCard(double anchor, double planned, double actual) {
    double delta = anchor - planned;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)], border: Border.all(color: Colors.black.withAlpha(10))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatDetail("תקציב עוגן", anchor, Colors.blueGrey)), 
              Expanded(child: _buildStatDetail("תכנון חודשי", planned, Colors.black87)), 
              Expanded(child: _buildDeltaDetail(delta)), // Modified to include the tooltip
              Expanded(child: _buildStatDetail("ביצוע בפועל", actual, actual > anchor ? Colors.red : Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: (anchor > 0) ? (actual / anchor).clamp(0.0, 1.0) : 0, backgroundColor: Colors.grey[200], color: actual > anchor ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10 * _textScale, color: Colors.grey, fontWeight: FontWeight.bold)), 
        FittedBox(fit: BoxFit.scaleDown, child: Text("₪${value.toStringAsFixed(0)}", style: TextStyle(fontSize: 15 * _textScale, fontWeight: FontWeight.bold, color: color)))
      ]
    );
  }
  
  // CONTEXTUAL ONBOARDING: Delta Tooltip
  Widget _buildDeltaDetail(double delta) {
    final valueColor = delta >= 0 ? Colors.green : Colors.red;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("הפרש (דלתא)", textAlign: TextAlign.center, style: TextStyle(fontSize: 10 * _textScale, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(width: 2),
            Tooltip(
              message: "הדלתא מחשבת את הפער בין תקציב ה'עוגן' לעלות החודשית התיאורטית של הרשימה.",
              triggerMode: TooltipTriggerMode.tap,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.info, size: 16 * _textScale, color: Colors.blue),
              ),
            )
          ],
        ),
        FittedBox(fit: BoxFit.scaleDown, child: Text("₪${delta.abs().toStringAsFixed(0)}", style: TextStyle(fontSize: 15 * _textScale, fontWeight: FontWeight.bold, color: valueColor)))
      ]
    );
  }

  Widget _buildActiveBasketBar(double total, ShoppingProvider provider) {
    // CONTEXTUAL ONBOARDING: Frequency Violation Warning
    bool hasViolationsInBasket = false;
    for (var item in provider.items) {
      if (provider.isChecked(item.id ?? -1) && item.isFrequencyViolation) {
        hasViolationsInBasket = true;
        break;
      }
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasViolationsInBasket)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: Colors.orange.withAlpha(50)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14 * _textScale, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "שים לב: סימנת מוצרים מוקדם מדי מתדירות הקנייה שהגדרת להם.",
                      style: TextStyle(fontSize: 11 * _textScale, color: Colors.orange[900], fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: hasViolationsInBasket ? 0 : 16), 
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF121212), 
              borderRadius: hasViolationsInBasket 
                ? const BorderRadius.vertical(bottom: Radius.circular(30), top: Radius.circular(8))
                : BorderRadius.circular(30), 
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 15)]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text("סכום הקנייה הנוכחית", style: TextStyle(color: Colors.white60, fontSize: 10 * _textScale)), Text("₪${total.toStringAsFixed(2)}", style: TextStyle(color: Colors.white, fontSize: 18 * _textScale, fontWeight: FontWeight.bold))]),
                ElevatedButton(onPressed: () => _confirmFinalize(provider), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A3FF), foregroundColor: Colors.white, shape: const StadiumBorder()), child: Text("סיום ותיעוד", style: TextStyle(fontSize: 14 * _textScale))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmFinalize(ShoppingProvider provider) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text("סיום קנייה", style: TextStyle(color: Colors.black87, fontSize: 18 * _textScale)), 
      content: Text("האם לעדכן את תאריכי הקנייה עבור כל המוצרים שבסל ולאפס את הרשימה?", style: TextStyle(color: Colors.black87, fontSize: 14 * _textScale)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("ביטול", style: TextStyle(fontSize: 14 * _textScale))), TextButton(onPressed: () { provider.finalizePurchase(); Navigator.pop(ctx); }, child: Text("כן, בצע", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * _textScale)))],
    ));
  }

  String _formatFrequency(ShoppingItem item) {
    List<String> parts = [];
    if (item.displayMonths > 0) {
      parts.add('${item.displayMonths}ח\'');
    }
    if (item.displayWeeks > 0) {
      parts.add('${item.displayWeeks}ש\'');
    }
    return parts.isEmpty ? 'חד פעמי' : parts.join(' ');
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_basket_outlined, size: 48 * _textScale, color: Colors.grey[300]), SizedBox(height: 16 * _textScale), Text('הרשימה ריקה', style: TextStyle(color: Colors.grey, fontSize: 14 * _textScale))]));
  }

  // --- אישור מחיקת מוצר ---
  void _confirmDelete(BuildContext context, ShoppingProvider provider, ShoppingItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text("מחיקת מוצר", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18 * _textScale)),
        content: Text("האם אתה בטוח שברצונך למחוק את '${item.name}' לצמיתות?", style: TextStyle(color: Colors.black87, fontSize: 14 * _textScale)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("ביטול", style: TextStyle(color: Colors.black54, fontSize: 14 * _textScale))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteItem(item.id!);
              Navigator.pop(ctx); // סגירת דיאלוג המחיקה
              Navigator.pop(context); // סגירת דיאלוג העריכה
            },
            child: Text("מחק", style: TextStyle(fontSize: 14 * _textScale)),
          ),
        ],
      ),
    );
  }

  // --- דיאלוג מאוחד להוספה ועריכה ---
  void _showItemEditor(BuildContext context, ShoppingProvider provider, {ShoppingItem? item}) {
    final nameController = TextEditingController(text: item?.name);
    final priceController = TextEditingController(text: item?.price.toString());
    final newCatController = TextEditingController();
    
    Set<String> categoriesForDialog = provider.availableCategories.toSet();
    categoriesForDialog.remove('הכל'); 
    categoriesForDialog.add('כללי'); 
    
    String selectedCat = item?.category ?? 'כללי'; 
    bool isAddingNewCat = false;
    int months = item != null ? (item.frequencyWeeks ~/ 4) : 0; 
    int weeks = item != null ? (item.frequencyWeeks % 4) : 1;
    int historyOffset = 0;

    final labelStyle = TextStyle(color: Colors.black54, fontSize: 14 * _textScale);
    final contentStyle = TextStyle(color: Colors.black87, fontSize: 16 * _textScale);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(item == null ? 'הוספת מוצר חדש' : 'עריכת מוצר', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18 * _textScale)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, style: contentStyle, decoration: InputDecoration(labelText: 'שם המוצר', labelStyle: labelStyle)),
              const SizedBox(height: 10),
              
              if (!isAddingNewCat)
                DropdownButtonFormField<String>(
                  initialValue: selectedCat, 
                  dropdownColor: Colors.white, 
                  style: contentStyle, 
                  decoration: InputDecoration(labelText: 'קטגוריה', labelStyle: labelStyle),
                  items: [
                    ...categoriesForDialog.map((c) => DropdownMenuItem(value: c, child: Text(c, style: contentStyle))),
                    DropdownMenuItem(value: 'NEW', child: Text("+ קטגוריה חדשה...", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16 * _textScale))),
                  ], 
                  onChanged: (val) {
                    if (val == 'NEW') {
                      setDialogState(() => isAddingNewCat = true);
                    } else {
                      selectedCat = val!;
                    }
                  }, 
                )
              else
                TextField(
                  controller: newCatController, 
                  style: contentStyle, 
                  decoration: InputDecoration(
                    labelText: 'שם קטגוריה חדשה', 
                    labelStyle: labelStyle,
                    suffixIcon: IconButton(icon: Icon(Icons.close, size: 24 * _textScale), onPressed: () => setDialogState(() => isAddingNewCat = false))
                  )
                ),

              TextField(controller: priceController, keyboardType: TextInputType.number, style: contentStyle, decoration: InputDecoration(labelText: 'מחיר משוער', prefixText: '₪ ', labelStyle: labelStyle)),
              
              if (item == null) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('מועד קנייה:', style: TextStyle(fontSize: 13 * _textScale, color: Colors.black54)),
                    TextButton.icon(
                      onPressed: () {
                        _showHistoryPicker(context, (selectedOffset) {
                          setDialogState(() => historyOffset = selectedOffset);
                        });
                      },
                      icon: Icon(Icons.history, size: 16 * _textScale, color: historyOffset == 0 ? Colors.blue : Colors.orange),
                      label: Text(_getWeekLabel(historyOffset), style: TextStyle(color: historyOffset == 0 ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold, fontSize: 14 * _textScale)),
                    ),
                  ],
                ),
                const Divider(),
              ] else ...[
                const SizedBox(height: 20),
              ],
              
              Text('תדירות קנייה:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13 * _textScale, color: Colors.black87)),
              const SizedBox(height: 10), 
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildCounter(label: 'חודשים', value: months, onChanged: (val) => setDialogState(() => months = val)), _buildCounter(label: 'שבועות', value: weeks, max: 3, onChanged: (val) => setDialogState(() => weeks = val))]),
            ]),
          ),
          actionsAlignment: item != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
          actions: [
            if (item != null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red, size: 24 * _textScale),
                tooltip: "מחק מוצר",
                onPressed: () => _confirmDelete(context, provider, item),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: TextStyle(color: Colors.black54, fontSize: 14 * _textScale))), 
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF121212), foregroundColor: Colors.white), 
                  onPressed: () { 
                    final finalCat = isAddingNewCat ? newCatController.text : selectedCat;
                    if (nameController.text.isNotEmpty && finalCat.isNotEmpty) {
                      
                      String? finalPurchaseDateString = item?.lastPurchaseDate;
                      
                      if (item == null && historyOffset != 0) {
                        DateTime calcDate = DateTime.now().subtract(Duration(days: historyOffset.abs() * 7));
                        finalPurchaseDateString = calcDate.toIso8601String().split('T')[0];
                      }

                      final newItem = ShoppingItem(
                        id: item?.id,
                        name: nameController.text, 
                        category: finalCat, 
                        price: double.tryParse(priceController.text) ?? 0.0, 
                        quantity: item?.quantity ?? 1, 
                        frequencyWeeks: (months * 4) + weeks,
                        lastPurchaseDate: finalPurchaseDateString,
                      ); 
                      
                      if (item == null) {
                        provider.addItem(newItem);
                      } else {
                        provider.updateItem(newItem);
                      }
                      
                      Navigator.pop(ctx); 
                    } 
                  }, 
                  child: Text("שמור", style: TextStyle(fontSize: 14 * _textScale))
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showHistoryPicker(BuildContext context, Function(int) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("בחר שבוע לתיעוד", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16 * _textScale)),
          ),
          ListTile(title: Text("השבוע", style: TextStyle(color: Colors.black87, fontSize: 14 * _textScale)), onTap: () { onSelected(0); Navigator.pop(ctx); }),
          ListTile(title: Text("שבוע שעבר", style: TextStyle(color: Colors.black87, fontSize: 14 * _textScale)), onTap: () { onSelected(-1); Navigator.pop(ctx); }),
          ..._getWeekOptions().map((offset) => ListTile(
            title: Text(_getWeekLabel(offset), style: TextStyle(color: Colors.black87, fontSize: 14 * _textScale)),
            onTap: () { onSelected(offset); Navigator.pop(ctx); },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- ניהול קטגוריות גלובלי ---
  void _showCategoryManager(BuildContext context, ShoppingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text("ניהול קטגוריות", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18 * _textScale, color: Colors.black87)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: provider.availableCategories.where((c) => c != 'הכל').map((cat) => ListTile(
              title: Text(cat, style: TextStyle(fontSize: 15 * _textScale, color: Colors.black87)),
              trailing: Icon(Icons.edit, size: 18 * _textScale, color: Colors.blueGrey),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameCategoryDialog(context, provider, cat);
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("סגור", style: TextStyle(fontSize: 14 * _textScale))),
        ],
      ),
    );
  }

  void _showRenameCategoryDialog(BuildContext context, ShoppingProvider provider, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text("שינוי שם: $oldName", style: TextStyle(color: Colors.black87, fontSize: 18 * _textScale)),
        content: TextField(
          controller: controller, 
          style: TextStyle(color: Colors.black87, fontSize: 16 * _textScale),
          decoration: InputDecoration(labelText: 'שם חדש', labelStyle: TextStyle(fontSize: 14 * _textScale)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("ביטול", style: TextStyle(fontSize: 14 * _textScale))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty && controller.text != oldName) {
                provider.renameCategory(oldName, controller.text);
                Navigator.pop(ctx);
              }
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF121212), foregroundColor: Colors.white),
            child: Text("עדכן", style: TextStyle(fontSize: 14 * _textScale))
          ),
        ],
      ),
    );
  }

  Widget _buildCounter({required String label, required int value, required Function(int) onChanged, int max = 99}) {
    return Column(children: [Text(label, style: TextStyle(fontSize: 11 * _textScale, fontWeight: FontWeight.bold, color: Colors.black54)), Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(Icons.remove_circle_outline, color: Colors.black45, size: 24 * _textScale), onPressed: value > 0 ? () => onChanged(value - 1) : null), Text('$value', style: TextStyle(fontSize: 16 * _textScale, fontWeight: FontWeight.bold, color: Colors.black87)), IconButton(icon: Icon(Icons.add_circle_outline, color: Colors.black45, size: 24 * _textScale), onPressed: value < max ? () => onChanged(value + 1) : null)])]);
  }
}