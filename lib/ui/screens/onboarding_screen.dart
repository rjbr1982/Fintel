// 🔒 STATUS: EDITED (Implemented 4-Step Onboarding Flow per Rule 4.18)
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

  // --- משתני סטטוס אישי ---
  String _maritalStatus = 'married'; // 'single', 'married'
  
  // --- משתני משפחה דינמיים ---
  final List<Map<String, TextEditingController>> _adults = [
    {
      'name': TextEditingController(text: 'אבא'),
      'year': TextEditingController(text: (DateTime.now().year - 30).toString()),
    },
    {
      'name': TextEditingController(text: 'אמא'),
      'year': TextEditingController(text: (DateTime.now().year - 30).toString()),
    }
  ];
  
  final List<Map<String, TextEditingController>> _children = [];

  // --- רכבים ---
  String _vehicleType = 'car'; // 'none', 'car', 'motorcycle'
  final _leasingCtrl = TextEditingController(text: '0'); 

  // --- מגורים והוצאות עוגן ---
  String _housingType = 'rent'; // 'rent', 'mortgage'
  final _housingCtrl = TextEditingController(text: '3500'); // מחליף את _rentCtrl
  final _supermarketCtrl = TextEditingController(text: '2500');
  final _electricityCtrl = TextEditingController(text: '350'); 
  final _waterCtrl = TextEditingController(text: '110'); 

  @override
  void dispose() {
    for (var adult in _adults) {
      adult['name']?.dispose();
      adult['year']?.dispose();
    }
    for (var child in _children) {
      child['name']?.dispose();
      child['year']?.dispose();
    }
    _housingCtrl.dispose();
    _supermarketCtrl.dispose();
    _electricityCtrl.dispose();
    _waterCtrl.dispose();
    _leasingCtrl.dispose();
    super.dispose();
  }

  void _updateMaritalStatus(String status) {
    setState(() {
      _maritalStatus = status;
      if (status == 'single') {
        // שמירת מבוגר אחד בלבד ("אישי")
        if (_adults.length > 1) {
          _adults.removeRange(1, _adults.length);
        }
        _adults[0]['name']!.text = 'אישי';
      } else {
        // הוספת מבוגר שני ("אבא" ו"אמא")
        if (_adults.length < 2) {
          _adults.add({
            'name': TextEditingController(text: 'אמא'),
            'year': TextEditingController(text: (DateTime.now().year - 30).toString()),
          });
        }
        _adults[0]['name']!.text = 'אבא';
        _adults[1]['name']!.text = 'אמא';
      }
    });
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
    final housingCost = double.tryParse(_housingCtrl.text) ?? 3500;
    final supermarket = double.tryParse(_supermarketCtrl.text) ?? 2500;
    final electricity = double.tryParse(_electricityCtrl.text) ?? 350;
    final water = double.tryParse(_waterCtrl.text) ?? 110;
    final leasing = double.tryParse(_leasingCtrl.text) ?? 0;

    // 1. הפעלת מנוע האתחול הבסיסי (יציג שגיאה עד שנעדכן את seed_service.dart)
    await SeedService.generateInitialData(
      maritalStatus: _maritalStatus, // חדש
      vehicleType: _vehicleType,
      housingType: _housingType,     // חדש
      leasingCost: leasing,
      housingAmount: housingCost,    // שונה מ-rentAmount
      supermarketAmount: supermarket,
      electricityAmount: electricity,
      waterAmount: water,
      childrenCount: _children.length, // חדש: לצורך חישוב אחוזים ראשוני
    );

    if (!mounted) return;

    // 2. שמירת בני המשפחה
    final budget = Provider.of<BudgetProvider>(context, listen: false);
    
    // הוספת מבוגרים
    for (var adult in _adults) {
      final name = adult['name']!.text.trim();
      if (name.isNotEmpty) {
        await budget.addFamilyMember(name, int.tryParse(adult['year']!.text) ?? (DateTime.now().year - 30));
      }
    }
    
    // הוספת ילדים
    int validChildrenCount = 0;
    for (var child in _children) {
      final name = child['name']!.text.trim();
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
              if (_currentStep < 3) { // הוגדל ל-3 (4 שלבים)
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
              final isLastStep = _currentStep == 3;
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
              // שלב 0: סטטוס אישי
              Step(
                title: const Text('סטטוס אישי', style: TextStyle(fontSize: 18)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('מהו הסטטוס הזוגי שלך?', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'single', icon: Icon(Icons.person), label: Text('רווק/ה (יחיד)')),
                        ButtonSegment(value: 'married', icon: Icon(Icons.people), label: Text('בזוגיות / נשוי/ה')),
                      ],
                      selected: {_maritalStatus},
                      onSelectionChanged: (Set<String> newSelection) {
                        _updateMaritalStatus(newSelection.first);
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('מבוגרים אחראיים:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A3FF))),
                    const SizedBox(height: 12),
                    ..._adults.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildFamilyRow(
                          entry.value['name']!, 
                          entry.value['year']!, 
                          'שם פרטי', 
                          showDelete: false, // לא מאפשרים מחיקה ידנית, זה נשלט ע"י הסטטוס
                        ),
                      );
                    }),
                  ],
                ),
                isActive: _currentStep >= 0,
              ),

              // שלב 1: ילדים ותלויים
              Step(
                title: const Text('ילדים ותלויים', style: TextStyle(fontSize: 18)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('כמה ילדים יש לך?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A3FF))),
                    const SizedBox(height: 12),
                    if (_children.isEmpty)
                      const Text('ללא ילדים.', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                isActive: _currentStep >= 1,
              ),

              // שלב 2: כלי רכב
              Step(
                title: const Text('כלי רכב וניידות', style: TextStyle(fontSize: 18)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('איזה כלי רכב עיקרי ברשותך?', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'none', icon: Icon(Icons.directions_walk), label: Text('תחב"צ')),
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
                isActive: _currentStep >= 2,
              ),

              // שלב 3: מגורים והוצאות עוגן
              Step(
                title: const Text('מגורים והוצאות בסיס', style: TextStyle(fontSize: 18)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('מהו סטטוס המגורים שלך?', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'rent', icon: Icon(Icons.vpn_key_outlined), label: Text('שכירות')),
                        ButtonSegment(value: 'mortgage', icon: Icon(Icons.home_outlined), label: Text('משכנתא')),
                      ],
                      selected: {_housingType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() { _housingType = newSelection.first; });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('כוונן את ההוצאות הבסיסיות (ניתן לשנות תמיד):', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    _buildSetupField(_housingType == 'rent' ? 'שכירות (חודשי)' : 'משכנתא (חודשי)', _housingCtrl),
                    _buildSetupField('קניות בסופר (חודשי)', _supermarketCtrl),
                    _buildSetupField('חשמל (דו-חודשי)', _electricityCtrl),
                    _buildSetupField('מים (דו-חודשי)', _waterCtrl),
                  ],
                ),
                isActive: _currentStep >= 3,
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