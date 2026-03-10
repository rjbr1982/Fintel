// 🔒 STATUS: EDITED (Fixed Const Warnings in Freedom Card Row)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../services/premium_service.dart';
import '../widgets/global_header.dart';
import 'category_drilldown_screen.dart'; 
import 'reducing_screen.dart'; 
import 'assets_screen.dart'; 

class PnLScreen extends StatelessWidget {
  const PnLScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();

    final isFutureMode = budget.isFutureMode;
    final income = budget.totalIncome;
    final fixed = budget.totalFixedExpenses;
    final reducing = budget.totalReducingExpenses; 
    
    final flowToLiving = budget.disposableIncome; 
    final futureAllocated = budget.totalFutureExpenses;
    final flowToFreedom = budget.totalFinancialExpenses;
    final diversionAmount = budget.financialDiversionAmount;

    final variableAllocated = budget.totalVariableExpenses;
    final variableDeficit = budget.variableDeficit;
    
    final displayVariableAmount = variableDeficit > 0 ? (variableAllocated + variableDeficit) : variableAllocated;

    return Scaffold(
      backgroundColor: isFutureMode ? const Color(0xFFF0FDF4) : Colors.white,
      appBar: const GlobalHeader(
        title: 'תזרים', 
      ),
      body: Column(
        children: [
          _buildFutureToggle(context, budget, isFutureMode),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (isFutureMode) _buildFutureBadge(),

                _buildRow(context, 'הכנסות', income, Colors.green[900]!, isHeader: true),
                const Divider(thickness: 2, height: 30, color: Colors.black12),

                _buildSectionLabel('שלב א: בסיס'),
                _buildRow(context, 'קבועות', fixed, Colors.black),
                _buildDebtRow(context, reducing, isFutureMode), 
                
                const SizedBox(height: 15),
                _buildSummaryCard(
                  isFutureMode ? 'תזרים פנוי (ללא חובות!)' : 'תזרים לרמת חיים וחירות פיננסית', 
                  flowToLiving, 
                  isFutureMode ? const Color(0xFF00C853) : Colors.blue[900]!
                ),
                const SizedBox(height: 25),

                _buildSectionLabel('שלב ב: רמת חיים'),
                
                _buildRow(
                  context, 
                  'משתנות', 
                  displayVariableAmount, 
                  variableDeficit > 0 ? Colors.red[900]! : Colors.black, 
                  onLongPress: () => _showRatioDialog(context, budget, isVariable: true)
                ),
                
                if (variableDeficit > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'התקציב נמצא בגירעון של ₪${variableDeficit.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  
                _buildRow(context, 'עתידיות', futureAllocated, Colors.black, 
                  onLongPress: () => _showRatioDialog(context, budget, isVariable: false)),

                const SizedBox(height: 25),
                
                _buildSectionLabel('שלב ג: חירות'),
                _buildFreedomCard(context, flowToFreedom, diversionAmount, isFutureMode, budget),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureToggle(BuildContext context, BudgetProvider budget, bool isFutureMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: isFutureMode ? const Color(0xFFDCFCE7) : Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isFutureMode ? Icons.auto_awesome : Icons.visibility_outlined,
                color: isFutureMode ? const Color(0xFF166534) : Colors.black54,
              ),
              const SizedBox(width: 10),
              const Text(
                'הצצה לעולם ללא חובות',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          Switch(
            value: isFutureMode,
            activeThumbColor: const Color(0xFF00C853),
            activeTrackColor: const Color(0xFF00C853).withValues(alpha: 0.3),
            onChanged: (val) {
              budget.toggleFutureMode(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFutureBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00C853),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'סימולציה: כך ייראה התזרים שלך ביום שאחרי החובות',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, right: 4.0),
      child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRow(BuildContext context, String title, double amount, Color color, {bool isHeader = false, VoidCallback? onLongPress}) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => CategoryDrilldownScreen(mainCategory: title, displayTitle: title)
        ));
      },
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: isHeader ? 22 : 17, fontWeight: isHeader ? FontWeight.bold : FontWeight.w600, color: Colors.black)),
            Row(
              children: [
                Text('₪${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: isHeader ? 22 : 17, fontWeight: FontWeight.bold, color: color)),
                if (!isHeader) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtRow(BuildContext context, double amount, bool isFutureMode) {
    return InkWell(
      onTap: () {
        PremiumService.requirePremium(context, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ReducingScreen()));
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'מנמיכות',
                  style: TextStyle(
                    fontSize: 17, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.black,
                    decoration: isFutureMode ? TextDecoration.lineThrough : null
                  )
                ),
                const SizedBox(width: 6),
                const Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
              ],
            ),
            Row(
              children: [
                Text(
                  '₪${amount.toStringAsFixed(0)}', 
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isFutureMode ? Colors.grey : Colors.red[900])
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
          Text('₪${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFreedomCard(BuildContext context, double amount, double diversion, bool isFutureMode, BudgetProvider budget) {
    const color = Color(0xFF00C853); 
    bool isDiverting = diversion > 0 && !isFutureMode;

    return InkWell(
      onTap: () => _showFreedomSettingsDialog(context, budget),
      onLongPress: () {
        PremiumService.requirePremium(context, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AssetsScreen()));
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // הוספת Const מפורש למניעת אזהרות Linter
                const Row(
                  children: [
                    Text('תזרים לחירות פיננסית', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(width: 6),
                    Icon(Icons.workspace_premium, color: Colors.amberAccent, size: 20),
                  ],
                ),
                Text('₪${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            const Row(
              children: [
                Icon(Icons.calculate_outlined, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'לחיצה: מחשבון צמיחה | ארוכה: פירוט נכסים',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),

            if (isDiverting) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'מוסט כרגע לחיסול מנמיכות (₪${diversion.toStringAsFixed(0)})',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRatioDialog(BuildContext context, BudgetProvider budget, {required bool isVariable}) {
    double currentVal = isVariable ? budget.variableAllocationRatio : budget.futureAllocationRatio;
    final controller = TextEditingController(text: (currentVal * 100).toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isVariable ? 'אחוז הקצאה למשתנות' : 'אחוז הקצאה לעתידיות'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('הגדר איזה אחוז מהיתרה יוקצה לקטגוריה זו:'),
            TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: '%')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                budget.setAllocationRatios(variable: isVariable ? val / 100 : null, future: isVariable ? null : val / 100);
                Navigator.pop(ctx);
              }
            },
            child: const Text('שמור'),
          )
        ],
      ),
    );
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('הגדרות מנוע החירות', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'יעד הכנסה פסיבית (ריק = אוטומטי)',
                        hintText: budget.autoTargetIncome.toStringAsFixed(0),
                        prefixIcon: const Icon(Icons.track_changes),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: capitalCtrl,
                      readOnly: true, 
                      decoration: const InputDecoration(
                        labelText: 'הון עצמי נוכחי (נשאב מהנכסים)',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: yieldCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'תשואה שנתית נטו (%)',
                        prefixIcon: Icon(Icons.trending_up),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('תדירות צבירת ריבית:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: freq,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          items: const <DropdownMenuItem<int>>[
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
}