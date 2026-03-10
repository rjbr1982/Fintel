// 🔒 STATUS: EDITED (Fixed SegmentedButton UI, Marital Status & Gender DB Saving, and Auto Parent/Child Logic)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../services/seed_service.dart';
import '../../data/expense_model.dart';
import '../../data/database_helper.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // --- שלב 1: זהות וסטטוס ---
  String _gender = 'male'; // 'male', 'female'
  String _maritalStatus = 'married'; // 'single', 'married'
  
  // --- שלב 2: משפחה ---
  bool _hasKids = false;
  final List<Map<String, TextEditingController>> _adults = [
    {'name': TextEditingController(text: ''), 'year': TextEditingController(text: (DateTime.now().year - 30).toString())},
    {'name': TextEditingController(text: ''), 'year': TextEditingController(text: (DateTime.now().year - 30).toString())}
  ];
  final List<Map<String, TextEditingController>> _children = [];

  // --- שלב 3: הכנסות ---
  final _income1Ctrl = TextEditingController(text: ''); 
  final _income2Ctrl = TextEditingController(text: ''); 

  // --- שלב 4: תשתית ומגורים ---
  String _housingType = 'rent'; // 'rent', 'mortgage', 'none'
  String _vehicleType = 'car'; // 'none', 'car', 'two_cars', 'motorcycle'

  // --- שלב 5: מאקרו ---
  bool _hasDebts = false;
  bool _includeReligion = true;

  @override
  void dispose() {
    for (var adult in _adults) { adult['name']?.dispose(); adult['year']?.dispose(); }
    for (var child in _children) { child['name']?.dispose(); child['year']?.dispose(); }
    _income1Ctrl.dispose();
    _income2Ctrl.dispose();
    super.dispose();
  }

  void _updateMaritalStatus(String status) {
    setState(() {
      _maritalStatus = status;
      if (status == 'single') {
        if (_adults.length > 1) { _adults.removeRange(1, _adults.length); }
      } else {
        if (_adults.length < 2) {
          _adults.add({'name': TextEditingController(text: ''), 'year': TextEditingController(text: (DateTime.now().year - 30).toString())});
        }
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
    
    final income1 = double.tryParse(_income1Ctrl.text) ?? 0.0;
    final income2 = _maritalStatus == 'married' ? (double.tryParse(_income2Ctrl.text) ?? 0.0) : 0.0;

    await SeedService.generateInitialData(
      gender: _gender, 
      maritalStatus: _maritalStatus, 
      vehicleType: _vehicleType,
      housingType: _housingType,    
      childrenCount: _hasKids ? _children.length : 0, 
      income1: income1,
      income2: income2,
      includeReligion: _includeReligion,
    );

    if (!mounted) return;

    final budget = Provider.of<BudgetProvider>(context, listen: false);
    
    // שמירת הסטטוס המשפחתי כדי שלא יאופס למצב ברירת מחדל
    await DatabaseHelper.instance.saveSetting('marital_status', _maritalStatus == 'single' ? 1.0 : 2.0);
    // שמירת המגדר (כדי שיזכור גם אחרי ריסטארט)
    await DatabaseHelper.instance.saveSetting('gender', _gender == 'male' ? 1.0 : 2.0);
    
    // שמירת מבוגרים (תמיד מוגדרים כהורים/בוגרים)
    for (var adult in _adults) {
      final name = adult['name']!.text.trim();
      if (name.isNotEmpty) {
        await budget.addFamilyMember(name, int.tryParse(adult['year']!.text) ?? (DateTime.now().year - 30), FamilyRole.parent);
      }
    }
    
    // שמירת ילדים
    if (_hasKids) {
      for (var child in _children) {
        final name = child['name']!.text.trim();
        if (name.isNotEmpty) {
          await budget.addFamilyMember(name, int.tryParse(child['year']!.text) ?? DateTime.now().year, FamilyRole.child);
        }
      }
    }

    // שמירת סטטוס חובות למנוע הצלף
    if (_hasDebts) {
      await DatabaseHelper.instance.saveSetting('has_active_debts', 1.0);
      budget.updateHasActiveDebts(true);
    }

    await budget.loadData();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(showWelcomeDialog: true, showDebtTask: _hasDebts)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMale = _gender == 'male';
    String welcomeText = isMale ? 'ברוך הבא לדוחכם' : 'ברוכה הבאה לדוחכם';
    String continueText = isMale ? 'המשך' : 'המשכי';
    String finishText = isMale ? 'מוכן! צור לי תקציב' : 'מוכנה! צור לי תקציב';

    // עיצוב קבוע לכפתורי הבחירה כדי שהטקסט לא יעלם
    final segmentedStyle = SegmentedButton.styleFrom(
      selectedForegroundColor: Colors.blue[900],
      selectedBackgroundColor: Colors.blue[100],
      foregroundColor: Colors.grey[400],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(welcomeText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00A3FF)),
              const SizedBox(height: 20),
              Text(
                isMale ? 'בונה את התקציב החכם שלך...' : 'בונה את התקציב החכם שלך...',
                style: const TextStyle(color: Colors.white, fontSize: 16)
              )
            ],
          ))
        : Stepper(
            currentStep: _currentStep,
            physics: const BouncingScrollPhysics(),
            onStepContinue: () {
              if (_currentStep < 4) { 
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
              final isLastStep = _currentStep == 4;
              return Padding(
                padding: const EdgeInsets.only(top: 30.0, bottom: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLastStep ? Colors.green : const Color(0xFF00A3FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: details.onStepContinue,
                        child: Text(isLastStep ? finishText : continueText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('חזור', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                  ],
                ),
              );
            },
            steps: [
              // --- שלב 1 ---
              Step(
                title: const Text('היכרות וסטטוס', style: TextStyle(fontSize: 18, color: Colors.white)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('איך תעדיף/י שאפנה אליך?', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      style: segmentedStyle,
                      segments: const [
                        ButtonSegment(value: 'male', label: Text('זכר')),
                        ButtonSegment(value: 'female', label: Text('נקבה')),
                      ],
                      selected: {_gender},
                      onSelectionChanged: (val) => setState(() => _gender = val.first),
                    ),
                    const SizedBox(height: 30),
                    Text(isMale ? 'מה הסטטוס האישי שלך?' : 'מה הסטטוס האישי שלך?', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      style: segmentedStyle,
                      segments: const [
                        ButtonSegment(value: 'single', icon: Icon(Icons.person), label: Text('רווק/ה')),
                        ButtonSegment(value: 'married', icon: Icon(Icons.people), label: Text('נשוי/אה')),
                      ],
                      selected: {_maritalStatus},
                      onSelectionChanged: (val) => _updateMaritalStatus(val.first),
                    ),
                  ],
                ),
                isActive: _currentStep >= 0,
              ),

              // --- שלב 2 ---
              Step(
                title: const Text('הרכב משפחתי', style: TextStyle(fontSize: 18, color: Colors.white)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('פרטי הבוגרים במשפחה', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A3FF))),
                    const SizedBox(height: 12),
                    _buildFamilyRow(
                      _adults[0]['name']!, 
                      _adults[0]['year']!, 
                      'השם שלך', 
                      showDelete: false
                    ),
                    if (_maritalStatus == 'married') ...[
                      const SizedBox(height: 12),
                      _buildFamilyRow(
                        _adults[1]['name']!, 
                        _adults[1]['year']!, 
                        'שם בן/בת הזוג', 
                        showDelete: false
                      ),
                    ],
                    const SizedBox(height: 30),
                    
                    Text(isMale ? 'האם יש לכם ילדים?' : 'האם יש לכם ילדים?', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A3FF))),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      style: segmentedStyle,
                      segments: const [
                        ButtonSegment(value: false, label: Text('לא')),
                        ButtonSegment(value: true, label: Text('כן')),
                      ],
                      selected: {_hasKids},
                      onSelectionChanged: (val) {
                        setState(() { 
                          _hasKids = val.first;
                          if (_hasKids && _children.isEmpty) _addChildField();
                        });
                      },
                    ),
                    if (_hasKids) ...[
                      const SizedBox(height: 20),
                      ..._children.asMap().entries.map((entry) {
                        int idx = entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildFamilyRow(
                            entry.value['name']!, 
                            entry.value['year']!, 
                            'שם הילד/ה', 
                            showDelete: true,
                            onDelete: () => setState(() => _children.removeAt(idx)),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _addChildField,
                        icon: const Icon(Icons.add),
                        label: const Text('הוסף ילד/ה'),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00A3FF), side: const BorderSide(color: Color(0xFF00A3FF))),
                      ),
                    ]
                  ],
                ),
                isActive: _currentStep >= 1,
              ),

              // --- שלב 3 ---
              Step(
                title: const Text('מקורות הכנסה', style: TextStyle(fontSize: 18, color: Colors.white)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('כדי שהתקציב יהיה מציאותי, נצטרך הערכה גסה של ההכנסות. אפשר לתקן זאת תמיד.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 20),
                    if (_maritalStatus == 'single') ...[
                      _buildSetupField('משכורת / הכנסה אישית (משוער)', _income1Ctrl),
                    ] else ...[
                      _buildSetupField('הכנסה שלך (משוער לחודש)', _income1Ctrl),
                      const SizedBox(height: 10),
                      _buildSetupField('הכנסת בן/בת הזוג (משוער לחודש)', _income2Ctrl),
                    ]
                  ],
                ),
                isActive: _currentStep >= 2,
              ),

              // --- שלב 4 ---
              Step(
                title: const Text('מגורים וניידות', style: TextStyle(fontSize: 18, color: Colors.white)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('מה מצב המגורים שלכם?', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _housingType,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'rent', child: Text('שכירות')),
                            DropdownMenuItem(value: 'mortgage', child: Text('בעלי נכס (משכנתא)')),
                            DropdownMenuItem(value: 'none', child: Text('ללא עלות דיור')),
                          ],
                          onChanged: (val) => setState(() => _housingType = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('איך אתם מתניידים ביומיום?', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _vehicleType,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'car', child: Text('רכב פרטי אחד')),
                            DropdownMenuItem(value: 'two_cars', child: Text('שני רכבים')),
                            DropdownMenuItem(value: 'motorcycle', child: Text('קטנוע / אופנוע')),
                            DropdownMenuItem(value: 'none', child: Text('תחבורה ציבורית בלבד')),
                          ],
                          onChanged: (val) => setState(() => _vehicleType = val!),
                        ),
                      ),
                    ),
                  ],
                ),
                isActive: _currentStep >= 3,
              ),

              // --- שלב 5 ---
              Step(
                title: const Text('הגדרות מאקרו', style: TextStyle(fontSize: 18, color: Colors.white)),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('האם יש לכם כיום חובות פעילים?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A3FF))),
                    const Text('(הלוואות, מינוס עמוק, או תשלומים באשראי)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      style: segmentedStyle,
                      segments: const [
                        ButtonSegment(value: false, label: Text('לא, נקיים')),
                        ButtonSegment(value: true, label: Text('כן, יש חובות')),
                      ],
                      selected: {_hasDebts},
                      onSelectionChanged: (val) => setState(() => _hasDebts = val.first),
                    ),
                    const SizedBox(height: 30),
                    const Text('האם לכלול הוצאות מסורת וחגי ישראל?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A3FF))),
                    const Text('(חגים ומועדים יוזנו אוטומטית לקופות חסכון שוטפות)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      style: segmentedStyle,
                      segments: const [
                        ButtonSegment(value: true, label: Text('כן, הוסף')),
                        ButtonSegment(value: false, label: Text('לא תודה')),
                      ],
                      selected: {_includeReligion},
                      onSelectionChanged: (val) => setState(() => _includeReligion = val.first),
                    ),
                  ],
                ),
                isActive: _currentStep >= 4,
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          isDense: true,
          suffixText: '₪',
          suffixStyle: const TextStyle(color: Colors.white),
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: nameLabel, labelStyle: const TextStyle(color: Colors.grey), isDense: true, border: const OutlineInputBorder(), enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: yearCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'שנת לידה', labelStyle: TextStyle(color: Colors.grey), isDense: true, border: OutlineInputBorder(), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
          ),
        ),
        if (showDelete) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ] else
          const SizedBox(width: 48), 
      ],
    );
  }
}