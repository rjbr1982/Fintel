// 🔒 STATUS: EDITED (Standardized Info Dialogs & Sinking-Growth Asset Toggle)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/asset_provider.dart';
import '../../providers/budget_provider.dart';
import '../../data/asset_model.dart';
import '../../utils/app_localizations.dart';
import '../widgets/global_header.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  @override
  void initState() {
    super.initState();
    // קריאה יזומה לטעינת נתונים מה-DB כדי למנוע רינדור עצל (מסך ריק בכניסה ראשונה)
    Future.microtask(() {
      if (mounted) {
        context.read<AssetProvider>().fetchAssets();
      }
    });
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(content, style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('הבנתי', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalHeader(title: loc.get('assets_portfolio')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey[900],
        onPressed: () => _showAssetForm(context, loc),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<AssetProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          loc.get('net_worth'),
                          style: TextStyle(fontSize: 16, color: Colors.green[800], fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showInfoDialog('חישוב נכסים', 'חישוב המאקרו: מנוע החירות סוכם את שווי הנכסים ומפעיל עליהם את התשואה הכללית מהדשבורד. התשואות הפרטניות כאן נועדו למעקב אישי בלבד.'),
                          child: Icon(Icons.info_outline, size: 18, color: Colors.green[800]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${loc.get('currency_symbol')}${provider.totalAssetsValue.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
              
              if (provider.assets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('לחץ לעריכה | החלק למחיקה', style: TextStyle(fontSize: 11, color: Colors.blueGrey[300])),
                  ),
                ),

              Expanded(
                child: provider.assets.isEmpty
                    ? Center(child: Text(loc.get('no_assets'), style: TextStyle(color: Colors.grey[400])))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: provider.assets.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final asset = provider.assets[index];
                          
                          // עטיפת הנכס ב-Dismissible מאפשרת מחיקה בהחלקה
                          return Dismissible(
                            key: Key(asset.id?.toString() ?? UniqueKey().toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.delete_sweep, color: Colors.white),
                            ),
                            confirmDismiss: (direction) => _showDeleteConfirm(context),
                            onDismissed: (direction) async {
                              if (asset.id != null) {
                                await provider.deleteAsset(asset.id!);
                                if (context.mounted) {
                                  await context.read<BudgetProvider>().syncCapitalFromAssets();
                                }
                              }
                            },
                            child: ListTile(
                              onTap: () => _showAssetForm(context, loc, asset: asset),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ),
                                  if (asset.isPcfAccumulator)
                                    const Icon(Icons.bolt, color: Colors.amber, size: 18),
                                ],
                              ),
                              subtitle: Text('${asset.type} | ${asset.yieldPercentage}% תשואה', style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${loc.get('currency_symbol')}${asset.value.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () async {
                                      final confirm = await _showDeleteConfirm(context);
                                      if (confirm == true && asset.id != null) {
                                        await provider.deleteAsset(asset.id!);
                                        if (context.mounted) {
                                          await context.read<BudgetProvider>().syncCapitalFromAssets();
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssetForm(BuildContext context, AppLocalizations loc, {Asset? asset}) {
    final nameCtrl = TextEditingController(text: asset?.name ?? '');
    final valueCtrl = TextEditingController(text: asset?.value.toStringAsFixed(0) ?? '');
    final yieldCtrl = TextEditingController(text: asset?.yieldPercentage.toString() ?? '4.0');
    String assetType = asset?.type ?? 'השקעה';
    bool isPcfAccumulator = asset?.isPcfAccumulator ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(asset == null ? loc.get('add_asset') : 'עריכת נכס', 
                      textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: loc.get('asset_name'), prefixIcon: const Icon(Icons.label_outline))),
                const SizedBox(height: 12),
                TextField(controller: valueCtrl, decoration: InputDecoration(labelText: loc.get('asset_value'), prefixIcon: const Icon(Icons.attach_money)), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: yieldCtrl, decoration: const InputDecoration(labelText: 'תשואה שנתית (%)', prefixIcon: Icon(Icons.trending_up)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: assetType,
                  decoration: const InputDecoration(labelText: 'סוג נכס', prefixIcon: Icon(Icons.category_outlined)),
                  items: ['השקעה', 'נדל"ן', 'חיסכון', 'אחר'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => assetType = val!),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isPcfAccumulator ? Colors.blue.withValues(alpha: 0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isPcfAccumulator ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.shade300),
                  ),
                  child: SwitchListTile(
                    title: const Text('נכס צובר תזרים (חיסגור)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('התזרים הפנוי החודשי יתווסף אוטומטית ליתרת נכס זה.', style: TextStyle(fontSize: 12)),
                    value: isPcfAccumulator,
                    activeColor: const Color(0xFF00A3FF),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    onChanged: (val) => setState(() => isPcfAccumulator = val),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.get('cancel'), style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
              onPressed: () async {
                final val = double.tryParse(valueCtrl.text);
                final yld = double.tryParse(yieldCtrl.text) ?? 0.0;
                if (val != null && nameCtrl.text.isNotEmpty) {
                  final newAsset = Asset(
                    id: asset?.id, 
                    name: nameCtrl.text, 
                    value: val, 
                    type: assetType, 
                    yieldPercentage: yld,
                    isPcfAccumulator: isPcfAccumulator,
                    // מעדכנים תאריך בכל עריכה ידנית כדי למנוע כפל חישוב על חודשים שעברו
                    lastUpdateDate: DateTime.now().toIso8601String(),
                  );
                  if (asset == null) {
                    await Provider.of<AssetProvider>(context, listen: false).addAsset(newAsset);
                  } else {
                    await Provider.of<AssetProvider>(context, listen: false).updateAsset(newAsset);
                  }
                  if (context.mounted) {
                    await Provider.of<BudgetProvider>(context, listen: false).syncCapitalFromAssets();
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                }
              },
              child: Text(asset == null ? loc.get('add') : 'עדכן', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('מחיקת נכס'),
        content: const Text('האם אתה בטוח שברצונך למחוק נכס זה? הפעולה תשפיע מיידית על מנוע החירות.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ביטול')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('מחק', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}