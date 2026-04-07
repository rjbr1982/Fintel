// 🔒 STATUS: FINAL (Admin God-Mode Dashboard - Clickable Macro Stats & Smart CTAs)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  bool _isCommercial = false;
  List<AdminUserRecord> _users = [];
  
  // Advanced Screener Filters
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Mailing Protocol (Section 13.5) ---
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
        content: SingleChildScrollView(
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

  // --- Master Switch Logic ---
  void _confirmCommercialLaunch() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ אזהרה: השקה מסחרית', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        content: const Text('האם אתה בטוח? פעולה זו תגרום לכך שכל משתמש חדש מעתה יסומן כ-Regular וייתקל בחומת תשלום. לא ניתן לבטל פעולה זו.', style: TextStyle(color: Colors.black87)),
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

  // --- Fintel Brain Extractor ---
  Future<void> _extractBrainCapsule(BuildContext context) async {
    try {
      final String capsuleData = await rootBundle.loadString('assets/fintel_brain_capsule.txt');
      await Clipboard.setData(ClipboardData(text: capsuleData));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ קפסולת הקוד הועתקה ללוח בהצלחה!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ שגיאה בחילוץ הקוד: $e\nהאם הרצת את pack_code.dart?'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Smart CTA Drilldown ---
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('אין משתמשים בסטטוס זה כרגע', style: TextStyle(color: Colors.blueGrey))),
                )
              else
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: emails.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(emails[index], style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87, side: const BorderSide(color: Colors.black26),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('העתק רשימה', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        if (emails.isEmpty) return;
                        Clipboard.setData(ClipboardData(text: emails.join(',')));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('רשימת המיילים הועתקה ללוח')));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.mail, size: 18),
                      label: const Text('דיוור מיידי', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _triggerMail(emails, defaultSubject, defaultBody);
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- Simple List Drilldown (For Countries) ---
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
    uniqueCountries.remove('Unknown');
    uniqueCountries.insert(0, 'הכל');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(child: Text('מסנן קהלים מתקדם', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.blueGrey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  
                  _buildDropdownRow('דור:', _filterGeneration, ['הכל', 'Alpha', 'Beta', 'Regular'], (v) {
                    if (v != null) {
                      setModalState(() => _filterGeneration = v);
                      setState(() => _filterGeneration = v);
                    }
                  }),
                  
                  _buildDropdownRow('מדינה:', _filterCountry, uniqueCountries, (v) {
                    if (v != null) {
                      setModalState(() => _filterCountry = v);
                      setState(() => _filterCountry = v);
                    }
                  }),

                  _buildDropdownRow('שכר:', _filterSalary, ['הכל', 'כן', 'לא'], (v) {
                    if (v != null) {
                      setModalState(() => _filterSalary = v);
                      setState(() => _filterSalary = v);
                    }
                  }),

                  _buildDropdownRow('קופות:', _filterSinking, ['הכל', 'יש', 'אין'], (v) {
                    if (v != null) {
                      setModalState(() => _filterSinking = v);
                      setState(() => _filterSinking = v);
                    }
                  }),

                  _buildDropdownRow('חירות:', _filterFreedom, ['הכל', 'כן', 'לא'], (v) {
                    if (v != null) {
                      setModalState(() => _filterFreedom = v);
                      setState(() => _filterFreedom = v);
                    }
                  }),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () {
                      setState(() {
                        _showScreenerResults = true; // הדלקת הרשימה התחתונה
                      });
                      Navigator.pop(ctx);
                    },
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
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(currentValue) ? currentValue : items.first,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.blue),
              underline: Container(height: 1, color: Colors.blue.withValues(alpha: 0.3)),
              items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.black87), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFF121212), body: Center(child: CircularProgressIndicator(color: Colors.amber)));
    }

    final activeUsers = _users.where((u) => u.lastActive != null && DateTime.now().difference(u.lastActive!).inDays <= 7).toList();
    final active7Days = activeUsers.length;
    
    final uniqueCountriesList = _users.map((e) => e.country).where((c) => c != 'Unknown').toSet().toList();
    final uniqueCountriesCount = uniqueCountriesList.length;

    // חישוב הרשימות עבור הטריגרים החכמים
    final bottleneckUsers = _users.where((u) => u.createdAt != null && DateTime.now().difference(u.createdAt!).inHours > 48 && !(u.metrics['hasSalary'] ?? false)).map((u) => u.email).toList();
    final churnUsers = _users.where((u) => u.lastActive != null && DateTime.now().difference(u.lastActive!).inDays > 7).map((u) => u.email).toList();
    final successAUsers = _users.where((u) => (u.metrics['hasSinkingFunds'] ?? false)).map((u) => u.email).toList();
    final successBUsers = _users.where((u) => (u.metrics['hasViewedFreedom'] ?? false)).map((u) => u.email).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('פאנל ניהול - Fintel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_rows_outlined, color: Colors.grey),
            tooltip: 'נתונים גולמיים',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminRawDataScreen(users: _users))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- TOP DASHBOARD ---
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildMacroStat(
                  label: 'משתמשים', 
                  value: '${_users.length}',
                  onTap: () => _showSmartCTADrilldown(
                    title: 'כלל המשתמשים', emails: _users.map((u) => u.email).toList(), themeColor: Colors.blueGrey,
                    defaultSubject: 'עדכון מ-Fintel', defaultBody: ''
                  ),
                ),
                _buildMacroStat(
                  label: 'פעילים', 
                  value: '$active7Days',
                  onTap: () => _showSmartCTADrilldown(
                    title: 'פעילים (7 ימים)', emails: activeUsers.map((u) => u.email).toList(), themeColor: Colors.blueGrey,
                    defaultSubject: 'עדכון למשתמשים פעילים', defaultBody: ''
                  ),
                ),
                _buildMacroStat(
                  label: 'מדינות', 
                  value: '$uniqueCountriesCount',
                  onTap: () => _showSimpleListDrilldown(
                    title: 'מדינות פעילות', items: uniqueCountriesList, themeColor: Colors.blueGrey
                  ),
                ),
                if (!_isCommercial)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(horizontal: 12)),
                    icon: const Icon(Icons.rocket_launch, size: 14),
                    label: const Text('השקה', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: _confirmCommercialLaunch,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text('סטטוס: Live', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // --- FINTEL BRAIN EXTRACTOR (Section 13.2.1) ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _extractBrainCapsule(context),
                icon: const Icon(Icons.memory),
                label: const Text('חילוץ קוד מערכת (Brain)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[800], 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SMART CTAs ---
            const Text('טריגרים חכמים', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildSmartCTA(
                  title: 'צוואר בקבוק',
                  desc: 'ללא שכר > 48 שעות',
                  count: bottleneckUsers.length,
                  color: Colors.orange,
                  icon: Icons.hourglass_empty,
                  onTap: () => _showSmartCTADrilldown(
                    title: 'צוואר בקבוק', emails: bottleneckUsers, themeColor: Colors.orange,
                    defaultSubject: 'צריכים עזרה עם השכר?', defaultBody: 'שמנו לב שנרשמתם אבל טרם הזנתם שכר. נשמח לעזור!'
                  ),
                ),
                _buildSmartCTA(
                  title: 'נטישה',
                  desc: 'לא פעילים > 7 ימים',
                  count: churnUsers.length,
                  color: Colors.redAccent,
                  icon: Icons.person_off,
                  onTap: () => _showSmartCTADrilldown(
                    title: 'נטישה', emails: churnUsers, themeColor: Colors.redAccent,
                    defaultSubject: 'התגעגענו אליכם!', defaultBody: 'חלף שבוע מאז שבדקתם את התזרים. בואו נחזור למסלול.'
                  ),
                ),
                _buildSmartCTA(
                  title: 'הצלחה א\'',
                  desc: 'פתחו קופה צוברת',
                  count: successAUsers.length,
                  color: Colors.green,
                  icon: Icons.savings,
                  onTap: () => _showSmartCTADrilldown(
                    title: 'פתחו קופה צוברת', emails: successAUsers, themeColor: Colors.green,
                    defaultSubject: 'כל הכבוד על הקופה החדשה!', defaultBody: 'צעד ראשון בניהול אנטי-הפתעות. מעולה!'
                  ),
                ),
                _buildSmartCTA(
                  title: 'הצלחה ב\'',
                  desc: 'הגיעו למסך החירות',
                  count: successBUsers.length,
                  color: Colors.teal,
                  icon: Icons.flag,
                  onTap: () => _showSmartCTADrilldown(
                    title: 'נחשפו למנוע החירות', emails: successBUsers, themeColor: Colors.teal,
                    defaultSubject: 'איך החוויה שלכם?', defaultBody: 'ראיתם את שנת החירות שלכם! נשמח לפידבק על האפליקציה.'
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- THE SCREENER ---
            const Text('מסנן קהלים חכם', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87, side: const BorderSide(color: Colors.blueGrey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.tune, size: 20),
                    label: const Text('הגדרות סינון מתקדם', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _showAdvancedScreener,
                  ),
                ),
                if (_showScreenerResults) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('סגור', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() {
                        _showScreenerResults = false;
                        _filterGeneration = 'הכל';
                        _filterCountry = 'הכל';
                        _filterSalary = 'הכל';
                        _filterSinking = 'הכל';
                        _filterFreedom = 'הכל';
                      });
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (_showScreenerResults) _buildScreenerResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroStat({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartCTA({required String title, required String desc, required int count, required Color color, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: color),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                ),
              ]
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 10, color: Colors.blueGrey), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenerResults() {
    List<AdminUserRecord> filtered = _users.where((u) {
      if (_filterGeneration != 'הכל' && u.generation != _filterGeneration) return false;
      if (_filterCountry != 'הכל' && u.country != _filterCountry) return false;
      if (_filterSalary != 'הכל') {
        final hasVal = u.metrics['hasSalary'] ?? false;
        if (_filterSalary == 'כן' && !hasVal) return false;
        if (_filterSalary == 'לא' && hasVal) return false;
      }
      if (_filterSinking != 'הכל') {
        final hasVal = u.metrics['hasSinkingFunds'] ?? false;
        if (_filterSinking == 'יש' && !hasVal) return false;
        if (_filterSinking == 'אין' && hasVal) return false;
      }
      if (_filterFreedom != 'הכל') {
        final hasVal = u.metrics['hasViewedFreedom'] ?? false;
        if (_filterFreedom == 'כן' && !hasVal) return false;
        if (_filterFreedom == 'לא' && hasVal) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24), 
        child: Center(child: Text('לא נמצאו משתמשים התואמים להגדרות הסינון', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)))
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_filterGeneration != 'הכל') _buildFilterChip('דור: $_filterGeneration'),
            if (_filterCountry != 'הכל') _buildFilterChip('מדינה: $_filterCountry'),
            if (_filterSalary != 'הכל') _buildFilterChip('שכר: ${_filterSalary == 'כן' ? 'הוזן' : 'לא הוזן'}'),
            if (_filterSinking != 'הכל') _buildFilterChip('קופות: ${_filterSinking == 'יש' ? 'נפתחו' : 'אין'}'),
            if (_filterFreedom != 'הכל') _buildFilterChip('חירות: ${_filterFreedom == 'כן' ? 'ראו' : 'לא ראו'}'),
          ],
        ),
        if (_filterGeneration != 'הכל' || _filterCountry != 'הכל' || _filterSalary != 'הכל' || _filterSinking != 'הכל' || _filterFreedom != 'הכל')
          const SizedBox(height: 12),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900, foregroundColor: Colors.white),
          icon: const Icon(Icons.copy, size: 16),
          label: Text('העתק רשימת תפוצה (${filtered.length})', overflow: TextOverflow.ellipsis),
          onPressed: () {
            if (filtered.isEmpty) return;
            final emails = filtered.map((e) => e.email).join(',');
            Clipboard.setData(ClipboardData(text: emails));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('הרשימה הועתקה ללוח')));
          },
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final u = filtered[index];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Text(u.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis),
                subtitle: Text('${u.country} | ${u.lastActive != null ? u.lastActive!.toString().split(' ')[0] : 'טרם'}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (u.generation != 'Regular') const Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(u.generation, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withValues(alpha: 0.3))),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
    );
  }
}

// ----------------------------------------------------------------------
// HIDDEN MATRIX SCREEN (Raw Data)
// ----------------------------------------------------------------------
class AdminRawDataScreen extends StatelessWidget {
  final List<AdminUserRecord> users;
  const AdminRawDataScreen({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('טבלת נתונים גולמיים (Audit)', style: TextStyle(color: Colors.white, fontSize: 16)), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('אימייל', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('דור', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('מדינה', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('שכר', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('קופות', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('חירות', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text('פעילות אחרונה', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: users.map((u) => DataRow(cells: [
              DataCell(Text(u.email, style: const TextStyle(color: Colors.black87, fontSize: 12))),
              DataCell(Text(u.generation, style: const TextStyle(color: Colors.black87, fontSize: 12))),
              DataCell(Text(u.country == 'Unknown' ? 'לא ידוע' : u.country, style: const TextStyle(color: Colors.black87, fontSize: 12))),
              DataCell(Icon(u.metrics['hasSalary'] == true ? Icons.check : Icons.close, color: u.metrics['hasSalary'] == true ? Colors.green : Colors.red, size: 16)),
              DataCell(Icon(u.metrics['hasSinkingFunds'] == true ? Icons.check : Icons.close, color: u.metrics['hasSinkingFunds'] == true ? Colors.green : Colors.red, size: 16)),
              DataCell(Icon(u.metrics['hasViewedFreedom'] == true ? Icons.check : Icons.close, color: u.metrics['hasViewedFreedom'] == true ? Colors.green : Colors.red, size: 16)),
              DataCell(Text(u.lastActive?.toString().split(' ')[0] ?? 'טרם', style: const TextStyle(color: Colors.black87, fontSize: 12))),
            ])).toList(),
          ),
        ),
      ),
    );
  }
}