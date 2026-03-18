// 🔒 STATUS: EDITED (Fixed Render Flash, Upgraded Reveal UI with Material & Glow, Zero Warnings)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/debt_provider.dart';
import '../../utils/app_localizations.dart';
import '../../services/premium_service.dart';
import '../widgets/global_header.dart'; 
import 'pnl_screen.dart'; 
import 'shopping_screen.dart';
import 'salary_engine_screen.dart';
import 'sinking_funds_screen.dart';

enum RevealState { expectation, reveal, dashboard }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  RevealState _currentState = RevealState.dashboard;
  late AnimationController _pulseController;
  bool _showPulse = false;
  bool _isRevealCompleting = false;

  @override
  void initState() {
    super.initState();
    
    // קריאה סינכרונית כדי למנוע הבהוב של הדשבורד
    final budget = Provider.of<BudgetProvider>(context, listen: false);
    if (!budget.hasCompletedGrandReveal) {
      _currentState = RevealState.expectation;
      _showPulse = true;
    }
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await budget.loadData();
      if (mounted) {
        await context.read<DebtProvider>().loadDebts();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showFreedomSettingsDialog(BuildContext context, BudgetProvider budget) {
    final targetCtrl = TextEditingController(
      text: budget.manualTargetIncome != null ? budget.manualTargetIncome!.toStringAsFixed(0) : ''
    );
    final capitalCtrl = TextEditingController(text: budget.initialCapital.toStringAsFixed(0));
    final yieldCtrl = TextEditingController(text: budget.expectedYield.toStringAsFixed(1));
    int freq = budget.compoundingFrequency;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('הגדרות מנוע החירות', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'יעד הכנסה פסיבית (ריק = אוטומטי)',
                        labelStyle: const TextStyle(color: Colors.blueGrey),
                        hintText: budget.autoTargetIncome.toStringAsFixed(0),
                        hintStyle: const TextStyle(color: Colors.black38),
                        prefixIcon: const Icon(Icons.track_changes, color: Colors.blueGrey),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: capitalCtrl,
                      readOnly: true, 
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'הון עצמי נוכחי (נשאב מהנכסים)',
                        labelStyle: TextStyle(color: Colors.blueGrey),
                        prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.blueGrey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: yieldCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'תשואה שנתית נטו (%)',
                        labelStyle: TextStyle(color: Colors.blueGrey),
                        prefixIcon: Icon(Icons.trending_up, color: Colors.blueGrey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('תדירות צבירת ריבית:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: freq,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black87, fontSize: 16),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                          items: const [
                            DropdownMenuItem<int>(value: 1, child: Text('שנתית (1)')),
                            DropdownMenuItem<int>(value: 12, child: Text('חודשית (12)')),
                            DropdownMenuItem<int>(value: 52, child: Text('שבועית (52)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => freq = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ביטול', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                  onPressed: () {
                    double? target = double.tryParse(targetCtrl.text);
                    double yld = double.tryParse(yieldCtrl.text) ?? 4.0;
                    
                    budget.setFreedomSettings(
                      manualTarget: target,
                      yieldRate: yld,
                      frequency: freq,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('שמור הגדרות', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showFamilyDrilldown(BuildContext context, BudgetProvider budget, int? targetYear) {
    if (targetYear == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('גילאי המשפחה בשנת $targetYear', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(color: Colors.black12),
              ...budget.familyMembers.map((fm) {
                int age = targetYear - fm.birthYear;
                return ListTile(
                  leading: const Icon(Icons.person, color: Colors.blueGrey),
                  title: Text(fm.name, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  trailing: Text('גיל $age', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00C853))),
                );
              }),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('סגור', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900]),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PnLScreen()));
              },
              child: const Text('עבור לתזרים (PnL)', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap, {bool isPremium = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(18),
              backgroundColor: color.withValues(alpha: 0.1),
              foregroundColor: color,
              elevation: 0,
            ),
            onPressed: onTap,
            child: Icon(icon, size: 28),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (isPremium) ...[
                const SizedBox(width: 4),
                const Icon(Icons.workspace_premium, color: Colors.amber, size: 14),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevealOverlay(int? targetYear, BudgetProvider budget) {
    if (_currentState == RevealState.expectation) {
      return Material(
        color: const Color(0xFF121212),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, color: Color(0xFF00A3FF), size: 60),
              const SizedBox(height: 20),
              const Text('התקציב שלך מאוזן ויציב.', style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 10),
              const Text(
                'המערכת מוכנה לחשב\nאת העתיד שלך.', 
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), 
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A3FF), 
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                ),
                onPressed: () => setState(() => _currentState = RevealState.reveal),
                child: const Text('חשב את שנת החירות שלי', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentState == RevealState.reveal) {
      return Material(
        color: const Color(0xFF121212),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: DateTime.now().year.toDouble(), end: (targetYear ?? DateTime.now().year + 10).toDouble()),
            duration: const Duration(seconds: 3),
            builder: (animContext, value, child) {
              if (value.toInt() == targetYear && !_isRevealCompleting) {
                _isRevealCompleting = true;
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted && _currentState == RevealState.reveal) {
                    setState(() => _currentState = RevealState.dashboard);
                    budget.completeGrandReveal();
                  }
                });
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('שנת החירות שלך היא:', style: TextStyle(color: Colors.white70, fontSize: 18)),
                  const SizedBox(height: 10),
                  Text(
                    '${value.toInt()}', 
                    style: TextStyle(
                      color: const Color(0xFF00FF85), 
                      fontSize: 90, 
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: const Color(0xFF00FF85).withValues(alpha: 0.5), blurRadius: 30),
                      ]
                    )
                  ),
                  const SizedBox(height: 30),
                  AnimatedOpacity(
                    opacity: _isRevealCompleting ? 1.0 : 0.0,
                    duration: const Duration(seconds: 1),
                    child: const Text('כעת, בוא ננהל את זה.', style: TextStyle(color: Colors.white54, fontSize: 18)),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final budget = context.watch<BudgetProvider>();

    int? monthsToFreedom = budget.calculateMonthsToFreedom();
    
    String yearText = "∞";
    int? targetYear;

    if (monthsToFreedom != null) {
      if (monthsToFreedom == 0) {
        yearText = "הושג!";
        targetYear = DateTime.now().year;
      } else {
        targetYear = DateTime.now().year + (monthsToFreedom / 12).ceil();
        yearText = targetYear.toString();
      }
    }

    return Stack(
      children: [
        // הדשבורד המקורי (יוצג תמיד מתחת לשכבת המעבר)
        Scaffold(
          backgroundColor: Colors.white,
          appBar: const GlobalHeader(),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.blueGrey[900],
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ShoppingScreen()));
            },
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    
                    // הליבה של מסך הבית: שנת החירות הפיננסית והכפתורים סביבה
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // הכרטיס המרכזי של שנת החירות
                        Container(
                          width: 280,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF00C853).withValues(alpha: 0.1), blurRadius: 25, spreadRadius: 5),
                            ],
                            border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.4), width: 2),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('שנת החירות הפיננסית', style: TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              Text(
                                yearText,
                                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Color(0xFF121212), height: 1.1),
                              ),
                            ],
                          ),
                        ),
                        
                        // כפתור המשפחה - ימין למעלה (עטוף בפעימה)
                        Positioned(
                          top: -15,
                          right: -15,
                          child: ScaleTransition(
                            scale: _showPulse 
                              ? Tween(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut))
                              : const AlwaysStoppedAnimation(1.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(14),
                                backgroundColor: Colors.blueGrey[900],
                                foregroundColor: Colors.white,
                                elevation: 4,
                              ),
                              onPressed: () {
                                if (_showPulse) {
                                  setState(() => _showPulse = false);
                                }
                                if (targetYear != null) _showFamilyDrilldown(context, budget, targetYear);
                              },
                              child: const Icon(Icons.family_restroom, size: 24),
                            ),
                          ),
                        ),
                        
                        // כפתור יעד הכנסה פסיבית - שמאל למעלה
                        Positioned(
                          top: -15,
                          left: -25,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              backgroundColor: Colors.amber[600],
                              foregroundColor: Colors.black87,
                              elevation: 4,
                            ),
                            onPressed: () => _showFreedomSettingsDialog(context, budget),
                            icon: const Icon(Icons.track_changes, size: 18),
                            label: Text(
                              '${loc?.get('currency_symbol') ?? '₪'}${budget.targetPassiveIncome.toStringAsFixed(0)}', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50),

                    // שורת כפתורי הניווט התחתונה
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickAction(
                          context, 
                          'תזרים', 
                          Icons.account_balance_wallet, 
                          Colors.blue, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PnLScreen()))
                        ),
                        _buildQuickAction(
                          context, 
                          'ממוצע שכר', 
                          Icons.insights, 
                          Colors.orange, 
                          () {
                            PremiumService.requirePremium(context, () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const SalaryEngineScreen()));
                            });
                          },
                          isPremium: true,
                        ),
                        _buildQuickAction(
                          context, 
                          'מרכז חסכונות', 
                          Icons.savings, 
                          Colors.green, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SinkingFundsScreen()))
                        ),
                      ],
                    ),

                    if (budget.expectedYield <= 4.0)
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "התחזית מבוססת על ריבית חסרת סיכון. מומלץ לבחון אפיקי השקעה עם תשואה גבוהה יותר.",
                                  style: TextStyle(color: Colors.orange[800], fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // שכבת החשיפה העליונה
        if (_currentState != RevealState.dashboard) 
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: _buildRevealOverlay(targetYear, budget),
          ),
      ],
    );
  }
}