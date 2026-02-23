// 🔒 STATUS: EDITED (Added Full Family Members Input - Names & Birth Years)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../services/seed_service.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // --- משתני משפחה דינמיים ---
  final _parent1NameCtrl = TextEditingController(text: 'אבא');
  final _parent1YearCtrl = TextEditingController(text: '1980');
  final _parent2NameCtrl = TextEditingController(text: 'אמא');
  final _parent2YearCtrl = TextEditingController(text: '1982');
  
  final List<Map<String, TextEditingController>> _children = [];

  // --- רכבים והוצאות עוגן ---
  String _vehicleType = 'car'; // 'none', 'car', 'motorcycle'
  final _leasingCtrl = TextEditingController(text: '0'); 
  final _rentCtrl = TextEditingController(text: '3500');
  final _supermarketCtrl = TextEditingController(text: '2500');
  final _electricityCtrl = TextEditingController(text: '350'); 
  final _waterCtrl = TextEditingController(text: '110'); 

  @override
  void dispose() {
    _parent1NameCtrl.dispose();
    _parent1YearCtrl.dispose();
    _parent2NameCtrl.dispose();
    _parent2YearCtrl.dispose();
    for (var child in _children) {
      child['name']?.dispose();
      child['year']?.dispose();
    }
    _rentCtrl.dispose();
    _supermarketCtrl.dispose();
    _electricityCtrl.dispose();
    _waterCtrl.dispose();
    _leasingCtrl.dispose();
    super.dispose();
  }

  void _addChildField() {
    setState(() {
      _children.add({
        'name': TextEditingController(),
        'year': TextEditingController(text: DateTime.now().year.toString()),
      });
    });
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    
    // קליטת הערכים
    final rent = double.tryParse(_rentCtrl.text) ?? 3500;
    final supermarket = double.tryParse(_supermarketCtrl.text) ?? 2500;
    final electricity = double.tryParse(_electricityCtrl.text) ?? 350;
    final water = double.tryParse(_waterCtrl.text) ?? 110;
    final leasing = double.tryParse(_leasingCtrl.text) ?? 0;

    // 1. הפעלת מנוע האתחול הבסיסי
    await SeedService.generateInitialData(
      vehicleType: _vehicleType,
      leasingCost: leasing,
      rentAmount: rent,
      supermarketAmount: supermarket,
      electricityAmount: electricity,
      waterAmount: water,
    );

    if (!mounted) return;

    // 2. שמירת בני המשפחה באופן מדויק
    final budget = Provider.of<BudgetProvider>(context, listen: false);
    
    if (_parent1NameCtrl.text.isNotEmpty) {
      await budget.addFamilyMember(_parent1NameCtrl.text, int.tryParse(_parent1YearCtrl.text) ?? 1980);
    }
    if (_parent2NameCtrl.text.isNotEmpty) {
      await budget.addFamilyMember(_parent2NameCtrl.text, int.tryParse(_parent2YearCtrl.text) ?? 1980);
    }
    
    int validChildrenCount = 0;
    for (var child in _children) {
      final name = child['name']!.text;
      if (name.isNotEmpty) {
        validChildrenCount++;
        await budget.addFamilyMember(name, int.tryParse(child['year']!.text) ?? DateTime.now().year);
      }
    }

    // עדכון כמות הילדים הרשמית במערכת
    await budget.setChildCount(validChildrenCount);
    
    // רענון המידע כדי להציג מיד במסך הראשי
    await budget.loadData();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('ברוכים הבאים לדוחכם', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A3FF)))
        : Stepper(
            currentStep: _currentStep,
            physics: const BouncingScrollPhysics(),
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep += 1);
              } else {
                _completeOnboarding();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == 2;
              return Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLastStep ? Colors.green : const Color(0xFF00A3FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: details.onStepContinue,
                        child: Text(isLastStep ? 'התחל לעבוד!' : 'המשך', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('חזור', style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              );
            },
            steps: [
              // שלב 1: משפחה (שודרג למלא)
              Step(
                title: const Text('הגדרות משפחה', style: TextStyle(fontSize: 18)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('הורים:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A3FF))),
                    const SizedBox(height: 12),
                    _buildFamilyRow(_parent1NameCtrl, _parent1YearCtrl, 'שם הורה 1', showDelete: false),
                    const SizedBox(height: 8),
                    _buildFamilyRow(_parent2NameCtrl, _parent2YearCtrl, 'שם הורה 2 (אופציונלי)', showDelete: false),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(),
                    ),
                    
                    const Text('ילדים:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A3FF))),
                    const SizedBox(height: 12),
                    if (_children.isEmpty)
                      const Text('אין ילדים מוגדרים.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ..._children.asMap().entries.map((entry) {
                      int idx = entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildFamilyRow(
                          entry.value['name']!, 
                          entry.value['year']!, 
                          'שם ילד ${idx + 1}', 
                          showDelete: true,
                          onDelete: () => setState(() => _children.removeAt(idx)),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addChildField,
                      icon: const Icon(Icons.add),
                      label: const Text('הוסף ילד'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00A3FF)),
                    ),
                  ],
                ),
                isActive: _currentStep >= 0,
              ),

              // שלב 2: רכבים
              Step(
                title: const Text('כלי רכב', style: TextStyle(fontSize: 18)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('איזה כלי רכב עיקרי ברשותך?', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'none', icon: Icon(Icons.directions_walk), label: Text('ללא')),
                        ButtonSegment(value: 'motorcycle', icon: Icon(Icons.motorcycle), label: Text('אופנוע')),
                        ButtonSegment(value: 'car', icon: Icon(Icons.directions_car), label: Text('רכב פרטי')),
                      ],
                      selected: {_vehicleType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() { _vehicleType = newSelection.first; });
                      },
                    ),
                    if (_vehicleType == 'car') ...[
                      const SizedBox(height: 20),
                      TextField(
                        controller: _leasingCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'הלוואה/ליסינג חודשי (השאר 0 אם אין)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.monetization_on_outlined),
                        ),
                      ),
                    ],
                  ],
                ),
                isActive: _currentStep >= 1,
              ),

              // שלב 3: הוצאות עוגן
              Step(
                title: const Text('הוצאות עוגן', style: TextStyle(fontSize: 18)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('כוונן את ההוצאות הבסיסיות (ניתן לשנות מאוחר יותר):', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    _buildSetupField('שכירות/משכנתא (חודשי)', _rentCtrl),
                    _buildSetupField('קניות בסופר (חודשי)', _supermarketCtrl),
                    _buildSetupField('חשמל (דו-חודשי)', _electricityCtrl),
                    _buildSetupField('מים (דו-חודשי)', _waterCtrl),
                    
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(child: Text('הלוואות ומשכנתאות ניתן להוסיף באופן מרוכז תחת לשונית "הלוואות" לאחר סיום ההגדרה.', style: TextStyle(fontSize: 13, color: Colors.blue))),
                        ],
                      ),
                    ),
                  ],
                ),
                isActive: _currentStep >= 2,
              ),
            ],
          ),
    );
  }

  Widget _buildSetupField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixText: '₪',
        ),
      ),
    );
  }

  Widget _buildFamilyRow(TextEditingController nameCtrl, TextEditingController yearCtrl, String nameLabel, {required bool showDelete, VoidCallback? onDelete}) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: nameCtrl,
            decoration: InputDecoration(labelText: nameLabel, isDense: true, border: const OutlineInputBorder()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: yearCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'שנת לידה', isDense: true, border: OutlineInputBorder()),
          ),
        ),
        if (showDelete) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ] else
          const SizedBox(width: 48), // כדי לשמור על יישור עם השורות שיש בהן פח אשפה
      ],
    );
  }
}