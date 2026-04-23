// 🔒 STATUS: EDITED (Fixed TextField Text Color for Admin Notes to ensure high contrast)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; 
import '../../services/admin_service.dart';
import '../../services/premium_service.dart';
import '../../main.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  bool _isCommercial = false;
  List<AdminUserRecord> _users = [];
  
  bool _showScreenerResults = false;
  String _filterGeneration = 'הכל';
  String _filterCountry = 'הכל';
  String _filterSalary = 'הכל';
  String _filterSinking = 'הכל';
  String _filterFreedom = 'הכל';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final isComm = await AdminService.isCommercialLaunch();
      final users = await AdminService.fetchAllUsers();
      
      if (mounted) {
        setState(() {
          _isCommercial = isComm;
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('שגיאה בטעינת נתונים: $e')));
      }
    }
  }

  Future<void> _triggerMail(List<String> emails, String subject, String body) async {
    if (emails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('אין משתמשים בקבוצה זו')));
      return;
    }
    final bcc = emails.join(',');
    final uri = Uri.parse('mailto:?bcc=$bcc&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    try {
      final launched = await launchUrl(uri);
      if (!launched) throw Exception('Launch failed');
    } catch (e) {
      if (mounted) _showMailFallbackDialog(bcc, subject, body);
    }
  }

  void _showMailFallbackDialog(String bcc, String subject, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('דיוור ידני (עומס נמענים)', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCopyField('נמענים (BCC)', bcc),
                const SizedBox(height: 12),
                _buildCopyField('נושא ההודעה', subject),
                const SizedBox(height: 12),
                _buildCopyField('גוף ההודעה', body),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('סגור', style: TextStyle(color: Colors.blueGrey))),
        ],
      ),
    );
  }

  Widget _buildCopyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87))),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.blue),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label הועתק ללוח')));
                },
              )
            ],
          ),
        )
      ],
    );
  }

  Future<void> _handleGoldenKey(AdminUserRecord u) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(u.isPremium ? 'ביטול מנוי Pro' : 'שדרוג ל-Pro', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: Text('להעניק ל-${u.displayName ?? u.email} מנוי Pro בחינם?\n(השפעה מיידית באפליקציה שלו)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ביטול', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: u.isPremium ? Colors.red : Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('אשר', style: TextStyle(color: u.isPremium ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ]
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await AdminService.toggleUserPremium(u.uid, !u.isPremium);
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('סטטוס מנוי עודכן בהצלחה!'), backgroundColor: Colors.green));
    }
  }

  void _confirmCommercialLaunch() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ אזהרה: השקה מסחרית', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        content: const Text('האם אתה בטוח? פעולה זו תגרום לכך שכל משתמש חדש מעתה יסומן כ-Regular וייתקל בחומת תשלום.', style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ביטול', style: TextStyle(color: Colors.blueGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await AdminService.toggleCommercialLaunch();
              await _loadData();
            },
            child: const Text('אשר השקה', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _extractBrainCapsule(BuildContext context) async {
    try {
      final String capsuleData = await rootBundle.loadString('assets/fintel_brain_capsule.txt');
      await Clipboard.setData(ClipboardData(text: capsuleData));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ קפסולת הקוד הועתקה ללוח!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ שגיאה: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showSmartCTADrilldown({required String title, required List<String> emails, required String defaultSubject, required String defaultBody, required Color themeColor}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: themeColor.withValues(alpha: 0.1), radius: 16, child: Text('${emails.length}', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14))),
                      const SizedBox(width: 12),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.blueGrey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              if (emails.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('אין משתמשים בסטטוס זה', style: TextStyle(color: Colors.blueGrey))))
              else
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: emails.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) => ListTile(
                        title: Text(emails[index], style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, size: 16, color: Colors.blueGrey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: emails[index]));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('מייל הועתק'), duration: Duration(seconds: 1)));
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.mail), label: const Text('דיוור מיידי לכל הקבוצה', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () { Navigator.pop(ctx); _triggerMail(emails, defaultSubject, defaultBody); },
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSimpleListDrilldown({required String title, required List<String> items, required Color themeColor}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: themeColor.withValues(alpha: 0.1), radius: 16, child: Text('${items.length}', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14))),
                      const SizedBox(width: 12),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.blueGrey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('אין נתונים להצגה', style: TextStyle(color: Colors.blueGrey))),
                )
              else
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(items[index], style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdvancedScreener() {
    final uniqueCountries = _users.map((e) => e.country).toSet().toList();
    uniqueCountries.remove('Unknown'); uniqueCountries.insert(0, 'הכל');
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('מסנן קהלים מתקדם', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ]),
                  const Divider(),
                  _buildDropdownRow('דור:', _filterGeneration, ['הכל', 'Alpha', 'Beta', 'Regular'], (v) { if (v != null) { setModalState(() => _filterGeneration = v); setState(() => _filterGeneration = v); } }),
                  _buildDropdownRow('מדינה:', _filterCountry, uniqueCountries, (v) { if (v != null) { setModalState(() => _filterCountry = v); setState(() => _filterCountry = v); } }),
                  _buildDropdownRow('שכר:', _filterSalary, ['הכל', 'כן', 'לא'], (v) { if (v != null) { setModalState(() => _filterSalary = v); setState(() => _filterSalary = v); } }),
                  _buildDropdownRow('קופות:', _filterSinking, ['הכל', 'יש', 'אין'], (v) { if (v != null) { setModalState(() => _filterSinking = v); setState(() => _filterSinking = v); } }),
                  _buildDropdownRow('חירות:', _filterFreedom, ['הכל', 'כן', 'לא'], (v) { if (v != null) { setModalState(() => _filterFreedom = v); setState(() => _filterFreedom = v); } }),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () { setState(() => _showScreenerResults = true); Navigator.pop(ctx); },
                    child: const Text('החל סינון', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildDropdownRow(String label, String currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true, value: items.contains(currentValue) ? currentValue : items.first, dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.blue), underline: Container(height: 1, color: Colors.blue.withValues(alpha: 0.3)),
              items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.black87)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenerResults() {
    List<AdminUserRecord> filtered = _users.where((u) {
      if (_filterGeneration != 'הכל' && u.generation != _filterGeneration) return false;
      if (_filterCountry != 'הכל' && u.country != _filterCountry) return false;
      if (_filterSalary != 'הכל' && (u.metrics['hasSalary'] ?? false) != (_filterSalary == 'כן')) return false;
      if (_filterSinking != 'הכל' && (u.metrics['hasSinkingFunds'] ?? false) != (_filterSinking == 'יש')) return false;
      if (_filterFreedom != 'הכל' && (u.metrics['hasViewedFreedom'] ?? false) != (_filterFreedom == 'כן')) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('תוצאות סינון (${filtered.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          TextButton.icon(onPressed: () => setState(() => _showScreenerResults = false), icon: const Icon(Icons.close, size: 16), label: const Text('נקה')),
        ]),
        const SizedBox(height: 12),
        if (filtered.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('לא נמצאו משתמשים')))
        else ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final u = filtered[i];
            return Card(
              color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Text(u.displayName?[0] ?? '?', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                      title: SelectableText(u.displayName ?? 'לא הוגדר שם', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.email),
                          const SizedBox(height: 4),
                          // 📊 שורת סטטוס חכמה בתוך הכרטיס
                          Row(
                            children: [
                              _buildMetricStatus(Icons.monetization_on, u.metrics['hasSalary'] == true),
                              const SizedBox(width: 8),
                              _buildMetricStatus(Icons.account_balance_wallet, u.metrics['hasSinkingFunds'] == true),
                              const SizedBox(width: 8),
                              _buildMetricStatus(Icons.flag, u.metrics['hasViewedFreedom'] == true),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(u.isPremium ? Icons.workspace_premium : Icons.key, color: u.isPremium ? Colors.amber : Colors.grey), onPressed: () => _handleGoldenKey(u)),
                          IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: u.email)); }),
                          const SizedBox(width: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: u.generation == 'Regular' ? Colors.grey.shade100 : Colors.amber.shade50, borderRadius: BorderRadius.circular(8)), child: Text(u.generation, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: u.generation == 'Regular' ? Colors.black54 : Colors.amber.shade900))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _AdminNoteField(uid: u.uid, initialNotes: u.adminNotes),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricStatus(IconData icon, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isActive ? Colors.green : Colors.grey.shade300),
        Icon(isActive ? Icons.check : Icons.close, size: 10, color: isActive ? Colors.green : Colors.red.withValues(alpha: 0.3)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF121212), body: Center(child: CircularProgressIndicator(color: Colors.amber)));

    final activeUsers = _users.where((u) => u.lastActive != null && DateTime.now().difference(u.lastActive!).inDays <= 7).toList();
    final active7Days = activeUsers.length;
    final uniqueCountriesList = _users.map((e) => e.country).where((c) => c != 'Unknown').toSet().toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('פאנל ניהול - Fintel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_rows_outlined, color: Colors.grey), tooltip: 'נתונים גולמיים',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminRawDataScreen(users: _users, onTogglePremium: _handleGoldenKey))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220, 
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                  ),
                  children: [
                    _buildMacroStat(label: 'משתמשים', value: '${_users.length}', onTap: () => _showSmartCTADrilldown(title: 'כלל המשתמשים', emails: _users.map((u) => u.email).toList(), themeColor: Colors.blueGrey, defaultSubject: 'Fintel Update', defaultBody: '')),
                    _buildMacroStat(label: 'פעילים', value: '$active7Days', onTap: () => _showSmartCTADrilldown(title: 'פעילים (7 ימים)', emails: activeUsers.map((u) => u.email).toList(), themeColor: Colors.blueGrey, defaultSubject: 'Active User Update', defaultBody: '')),
                    _buildMacroStat(label: 'מדינות', value: '${uniqueCountriesList.length}', onTap: () => _showSimpleListDrilldown(title: 'מדינות פעילות', items: uniqueCountriesList, themeColor: Colors.blueGrey)),
                    if (!_isCommercial)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87),
                        icon: const Icon(Icons.rocket_launch, size: 14), label: const Text('השקה', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: _confirmCommercialLaunch,
                      )
                    else
                      _buildMacroStat(label: 'סטטוס', value: 'Live', onTap: () {}, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('ארגז חול (Sandbox)'),
                const SizedBox(height: 12),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 480, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 4),
                  children: [
                    _buildSandboxToggle(
                      title: 'בדיקת חומת תשלום', subtitle: 'כופה התנהגות משתמש חינמי',
                      value: PremiumService.forceFreeMode, color: Colors.red,
                      onChanged: (v) => setState(() => PremiumService.forceFreeMode = v),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: AppGlobals.forceUSNotifier,
                      builder: (context, forceUS, _) => _buildSandboxToggle(
                        title: 'תצוגת ארה"ב (אנגלית)', subtitle: 'כופה תצוגת חו"ל וחסימת Web',
                        value: forceUS, color: Colors.blue,
                        onChanged: (v) => AppGlobals.forceUSNotifier.value = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _extractBrainCapsule(context),
                  icon: const Icon(Icons.memory), label: const Text('חילוץ קוד מערכת (Brain)', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('טריגרים חכמים'),
                const SizedBox(height: 12),
                _buildSmartCTAGrid(),
                const SizedBox(height: 32),
                _buildSectionTitle('מסנן קהלים חכם'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.black87, side: const BorderSide(color: Colors.blueGrey), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.tune), label: const Text('הגדרות סינון מתקדם', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _showAdvancedScreener,
                ),
                if (_showScreenerResults) ...[
                  const SizedBox(height: 16),
                  _buildScreenerResults(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartCTAGrid() {
    final bottleneckUsers = _users.where((u) => u.createdAt != null && DateTime.now().difference(u.createdAt!).inHours > 48 && !(u.metrics['hasSalary'] ?? false)).map((u) => u.email).toList();
    final churnUsers = _users.where((u) => u.lastActive != null && DateTime.now().difference(u.lastActive!).inDays > 7).map((u) => u.email).toList();
    final successAUsers = _users.where((u) => (u.metrics['hasSinkingFunds'] ?? false)).map((u) => u.email).toList();
    final successBUsers = _users.where((u) => (u.metrics['hasViewedFreedom'] ?? false)).map((u) => u.email).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 240, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5),
      itemCount: 4,
      itemBuilder: (ctx, i) {
        final data = [
          {'t': 'צוואר בקבוק', 'd': 'ללא שכר > 48ש\'', 'c': bottleneckUsers.length, 'cl': Colors.orange, 'ic': Icons.hourglass_empty, 'e': bottleneckUsers},
          {'t': 'נטישה', 'd': 'לא פעילים > 7 ימים', 'c': churnUsers.length, 'cl': Colors.redAccent, 'ic': Icons.person_off, 'e': churnUsers},
          {'t': 'הצלחה א\'', 'd': 'פתחו קופה צוברת', 'c': successAUsers.length, 'cl': Colors.green, 'ic': Icons.savings, 'e': successAUsers},
          {'t': 'הצלחה ב\'', 'd': 'הגיעו למסך חירות', 'c': successBUsers.length, 'cl': Colors.teal, 'ic': Icons.flag, 'e': successBUsers},
        ][i];
        return _buildSmartCTA(
          title: data['t'] as String, desc: data['d'] as String, count: data['c'] as int, color: data['cl'] as Color, icon: data['ic'] as IconData,
          onTap: () => _showSmartCTADrilldown(title: data['t'] as String, emails: data['e'] as List<String>, themeColor: data['cl'] as Color, defaultSubject: 'Fintel Update', defaultBody: ''),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87));

  Widget _buildMacroStat({required String label, required String value, required VoidCallback onTap, Color? color}) {
    return Card(
      elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color ?? Colors.blueGrey)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _buildSandboxToggle({required String title, required String subtitle, required bool value, required Color color, required ValueChanged<bool> onChanged}) {
    return Container(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Center(
        child: SwitchListTile(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          value: value, activeThumbColor: color, activeTrackColor: color.withValues(alpha: 0.3),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSmartCTA({required String title, required String desc, required int count, required Color color, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withValues(alpha: 0.2))),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, size: 20, color: color),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12))),
            ]),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
            Text(desc, style: const TextStyle(fontSize: 10, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class AdminRawDataScreen extends StatelessWidget {
  final List<AdminUserRecord> users;
  final Function(AdminUserRecord) onTogglePremium;

  const AdminRawDataScreen({super.key, required this.users, required this.onTogglePremium});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 1, title: const Text('נתונים גולמיים', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dataRowMinHeight: 60,
              dataRowMaxHeight: double.infinity,
              headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade50),
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A3FF), fontSize: 14),
              columns: const [
                DataColumn(label: Text('שם משתמש')),
                DataColumn(label: Text('אימייל (Email)')),
                DataColumn(label: Text('הערות מנהל')),
                DataColumn(label: Text('דור')),
                DataColumn(label: Text('מדינה')),
                DataColumn(label: Text('הוזן שכר')), 
                DataColumn(label: Text('קופות')),     
                DataColumn(label: Text('חירות')),    
                DataColumn(label: Text('מפתח זהב 🔑')),
              ],
              rows: users.map((u) => DataRow(
                cells: [
                  DataCell(Text(u.displayName ?? 'לא הוגדר', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                  DataCell(Text(u.email)),
                  DataCell(Container(width: 300, padding: const EdgeInsets.symmetric(vertical: 8), child: _AdminNoteField(uid: u.uid, initialNotes: u.adminNotes))),
                  DataCell(Text(u.generation)),
                  DataCell(Text(u.country)),
                  DataCell(Icon(u.metrics['hasSalary'] == true ? Icons.check_circle : Icons.cancel, color: u.metrics['hasSalary'] == true ? Colors.green : Colors.redAccent)),
                  DataCell(Icon(u.metrics['hasSinkingFunds'] == true ? Icons.check_circle : Icons.cancel, color: u.metrics['hasSinkingFunds'] == true ? Colors.green : Colors.redAccent)),
                  DataCell(Icon(u.metrics['hasViewedFreedom'] == true ? Icons.check_circle : Icons.cancel, color: u.metrics['hasViewedFreedom'] == true ? Colors.green : Colors.redAccent)),
                  DataCell(IconButton(icon: Icon(u.isPremium ? Icons.workspace_premium : Icons.key, color: u.isPremium ? Colors.amber : Colors.grey), onPressed: () => onTogglePremium(u))),
                ],
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNoteField extends StatefulWidget {
  final String uid;
  final String? initialNotes;
  const _AdminNoteField({required this.uid, this.initialNotes});

  @override
  State<_AdminNoteField> createState() => _AdminNoteFieldState();
}

class _AdminNoteFieldState extends State<_AdminNoteField> {
  late TextEditingController _controller;
  Timer? _debounce;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() => _isSaving = true);
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      await AdminService.updateAdminNotes(widget.uid, text);
      if (mounted) setState(() => _isSaving = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontSize: 13, color: Colors.black87), // התיקון שביקשת
      decoration: InputDecoration(
        hintText: 'הוסף הערה...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        isDense: true,
        suffixIcon: _isSaving 
          ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)))
          : Icon(Icons.cloud_done, size: 16, color: _controller.text.isEmpty ? Colors.transparent : Colors.green.shade300),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue, width: 1)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onChanged: _onChanged,
    );
  }
}