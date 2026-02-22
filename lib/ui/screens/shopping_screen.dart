// 🔒 STATUS: EDITED (Added Delete Item functionality with Confirmation Dialog)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/budget_provider.dart'; 
import '../../data/shopping_model.dart';
import '../widgets/global_header.dart';

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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ShoppingProvider>().loadItems();
      }
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
    
    final groceryExpense = budgetProvider.expenses.firstWhere(
      (e) => e.name == 'קניות',
      orElse: () => budgetProvider.expenses.first,
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
        
        // אם נמצא הבדל בשכבה הנוכחית, אנחנו מחזירים אותו. 
        // אם הם שווים, הלולאה ממשיכה לשכבת המיון הבאה!
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
      appBar: const GlobalHeader(
        title: 'רשימת קניות',
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
                    const Icon(Icons.layers, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      "$_selectedCategory | מיון: $sortDisplay",
                      style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
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
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = displayedItems[index];
                          final bool wasPurchased = _wasItemPurchasedInWeek(item, _comparisonOffset);
                          Widget tile = _buildComparisonTile(item, shoppingProvider, wasPurchased);

                          // הזרקת כותרות קבוצה - מתרחש רק אם המיון *הראשון* בעדיפות הוא "סיווג"
                          if (_activeSorts.isNotEmpty && _activeSorts.first == 'סיווג' && _selectedCategory == 'הכל') {
                            bool isFirst = index == 0;
                            bool isNewCat = isFirst || displayedItems[index - 1].category != item.category;
                            
                            if (isNewCat) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12, bottom: 6, right: 4),
                                    child: Text(
                                      item.category,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
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
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF00A3FF) : Colors.black54)),
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
          child: Text(_getWeekLabel(offset), style: const TextStyle(fontSize: 13, color: Colors.black87)),
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
                  fontSize: 11, 
                  fontWeight: isExtraSelected ? FontWeight.bold : FontWeight.normal,
                  color: isExtraSelected ? const Color(0xFF00A3FF) : Colors.black54
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 16, color: isExtraSelected ? const Color(0xFF00A3FF) : Colors.black54),
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
        leading: Checkbox(
          value: checked,
          activeColor: const Color(0xFF121212),
          side: const BorderSide(color: Colors.black45, width: 1.5),
          onChanged: (_) => provider.toggleItem(item.id!),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w500, fontSize: 14,
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
                      size: 12, 
                      color: wasPurchasedInHistory ? Colors.green : Colors.black12
                    ),
                    const SizedBox(width: 4),
                    Text(
                      wasPurchasedInHistory ? "נקנה" : "לא נקנה",
                      style: TextStyle(fontSize: 9, color: wasPurchasedInHistory ? Colors.green[700] : Colors.black26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text(
          "₪${item.price.toStringAsFixed(1)} | ${_formatFrequency(item)}${item.lastPurchaseDate != null ? ' | נקנה לפני ${item.daysSinceLastPurchase} ימים' : ''}",
          style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
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
              child: Text("תיעוד קנייה למפרע: ${item.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.today, color: Colors.blue),
              title: const Text("נקנה השבוע (מחוץ לסל המרכזי)", style: TextStyle(color: Colors.black87)),
              onTap: () {
                _applyRetroactivePurchase(item, 0, provider);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text("נקנה בשבוע שעבר", style: TextStyle(color: Colors.black87)),
              onTap: () {
                _applyRetroactivePurchase(item, -1, provider);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_repeat, color: Colors.blueGrey),
              title: const Text("נקנה במועד אחר...", style: TextStyle(color: Colors.black87)),
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
      icon: const Icon(Icons.tune, color: Color(0xFF121212)),
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
        const PopupMenuItem(
          value: 'manage_cats', 
          child: Row(
            children: [
              Icon(Icons.category_outlined, size: 18, color: Colors.blue), 
              SizedBox(width: 8), 
              Text("ניהול קטגוריות", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
            ]
          )
        ),
        const PopupMenuItem(
          value: 'multi_sort', 
          child: Row(
            children: [
              Icon(Icons.layers, size: 18, color: Colors.orange), 
              SizedBox(width: 8), 
              Text("מיון רב-שכבתי...", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
            ]
          )
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(enabled: false, child: Text("סינון קטגוריה", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue))),
        ...provider.availableCategories.map((cat) => PopupMenuItem(value: cat, child: Row(children: [Icon(Icons.check, size: 16, color: _selectedCategory == cat ? Colors.blue : Colors.transparent), const SizedBox(width: 8), Text(cat, style: const TextStyle(color: Colors.black87))]))),
      ],
    );
  }
  
  // --- ממשק מיון מתקדם (Bottom Sheet לניהול השכבות) ---
  void _showAdvancedSortSheet(BuildContext context) {
    List<String> currentOrder = List.from(_allSortOptions);
    List<String> currentActive = List.from(_activeSorts);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("ניהול סדר מיון (רב-שכבתי)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text("המיון יתבצע מלמעלה למטה.\nגרור באמצעות הפסים כדי לשנות עדיפות, וסמן V כדי להפעיל.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Divider(),
                  SizedBox(
                    height: 280,
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
                              title: Text(option, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: Colors.black87)),
                              secondary: const Icon(Icons.drag_handle, color: Colors.grey),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    child: const Text("החל מיון"),
                  )
                ],
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
              Expanded(child: _buildStatDetail("הפרש (דלתא)", delta.abs(), delta >= 0 ? Colors.green : Colors.red)),
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
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)), 
        FittedBox(fit: BoxFit.scaleDown, child: Text("₪${value.toStringAsFixed(0)}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)))
      ]
    );
  }

  Widget _buildActiveBasketBar(double total, ShoppingProvider provider) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 15)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("סכום הקנייה הנוכחית", style: TextStyle(color: Colors.white60, fontSize: 10)), Text("₪${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
            ElevatedButton(onPressed: () => _confirmFinalize(provider), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A3FF), foregroundColor: Colors.white, shape: const StadiumBorder()), child: const Text("סיום ותיעוד")),
          ],
        ),
      ),
    );
  }

  void _confirmFinalize(ShoppingProvider provider) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("סיום קנייה", style: TextStyle(color: Colors.black87)), content: const Text("האם לעדכן את תאריכי הקנייה עבור כל המוצרים שבסל ולאפס את הרשימה?", style: TextStyle(color: Colors.black87)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ביטול")), TextButton(onPressed: () { provider.finalizePurchase(); Navigator.pop(ctx); }, child: const Text("כן, בצע", style: TextStyle(fontWeight: FontWeight.bold)))],
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
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey[300]), const SizedBox(height: 16), const Text('הרשימה ריקה', style: TextStyle(color: Colors.grey))]));
  }

  // --- אישור מחיקת מוצר ---
  void _confirmDelete(BuildContext context, ShoppingProvider provider, ShoppingItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text("מחיקת מוצר", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Text("האם אתה בטוח שברצונך למחוק את '${item.name}' לצמיתות?", style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ביטול", style: TextStyle(color: Colors.black54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteItem(item.id!);
              Navigator.pop(ctx); // סגירת דיאלוג המחיקה
              Navigator.pop(context); // סגירת דיאלוג העריכה
            },
            child: const Text("מחק"),
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

    const labelStyle = TextStyle(color: Colors.black54, fontSize: 14);
    const contentStyle = TextStyle(color: Colors.black87, fontSize: 16);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(item == null ? 'הוספת מוצר חדש' : 'עריכת מוצר', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, style: contentStyle, decoration: const InputDecoration(labelText: 'שם המוצר', labelStyle: labelStyle)),
              const SizedBox(height: 10),
              
              if (!isAddingNewCat)
                DropdownButtonFormField<String>(
                  initialValue: selectedCat, 
                  dropdownColor: Colors.white, 
                  style: contentStyle, 
                  decoration: const InputDecoration(labelText: 'קטגוריה', labelStyle: labelStyle),
                  items: [
                    ...categoriesForDialog.map((c) => DropdownMenuItem(value: c, child: Text(c, style: contentStyle))),
                    const DropdownMenuItem(value: 'NEW', child: Text("+ קטגוריה חדשה...", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
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
                    suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () => setDialogState(() => isAddingNewCat = false))
                  )
                ),

              TextField(controller: priceController, keyboardType: TextInputType.number, style: contentStyle, decoration: const InputDecoration(labelText: 'מחיר משוער', prefixText: '₪ ', labelStyle: labelStyle)),
              
              if (item == null) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('מועד קנייה:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    TextButton.icon(
                      onPressed: () {
                        _showHistoryPicker(context, (selectedOffset) {
                          setDialogState(() => historyOffset = selectedOffset);
                        });
                      },
                      icon: Icon(Icons.history, size: 16, color: historyOffset == 0 ? Colors.blue : Colors.orange),
                      label: Text(_getWeekLabel(historyOffset), style: TextStyle(color: historyOffset == 0 ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(),
              ] else ...[
                const SizedBox(height: 20),
              ],
              
              const Text('תדירות קנייה:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 10), 
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildCounter(label: 'חודשים', value: months, onChanged: (val) => setDialogState(() => months = val)), _buildCounter(label: 'שבועות', value: weeks, max: 3, onChanged: (val) => setDialogState(() => weeks = val))]),
            ]),
          ),
          actionsAlignment: item != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
          actions: [
            if (item != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: "מחק מוצר",
                onPressed: () => _confirmDelete(context, provider, item),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(color: Colors.black54))), 
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
                  child: const Text("שמור")
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
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("בחר שבוע לתיעוד", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          ListTile(title: const Text("השבוע", style: TextStyle(color: Colors.black87)), onTap: () { onSelected(0); Navigator.pop(ctx); }),
          ListTile(title: const Text("שבוע שעבר", style: TextStyle(color: Colors.black87)), onTap: () { onSelected(-1); Navigator.pop(ctx); }),
          ..._getWeekOptions().map((offset) => ListTile(
            title: Text(_getWeekLabel(offset), style: const TextStyle(color: Colors.black87)),
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
        title: const Text("ניהול קטגוריות", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: provider.availableCategories.where((c) => c != 'הכל').map((cat) => ListTile(
              title: Text(cat, style: const TextStyle(fontSize: 15, color: Colors.black87)),
              trailing: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameCategoryDialog(context, provider, cat);
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("סגור")),
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
        title: Text("שינוי שם: $oldName", style: const TextStyle(color: Colors.black87)),
        content: TextField(
          controller: controller, 
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(labelText: 'שם חדש'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ביטול")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty && controller.text != oldName) {
                provider.renameCategory(oldName, controller.text);
                Navigator.pop(ctx);
              }
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF121212), foregroundColor: Colors.white),
            child: const Text("עדכן")
          ),
        ],
      ),
    );
  }

  Widget _buildCounter({required String label, required int value, required Function(int) onChanged, int max = 99}) {
    return Column(children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)), Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.black45), onPressed: value > 0 ? () => onChanged(value - 1) : null), Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)), IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.black45), onPressed: value < max ? () => onChanged(value + 1) : null)])]);
  }
}