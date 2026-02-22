// 🔒 STATUS: EDITED (Fixed deprecated initialValue and async gap mounted check)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/asset_provider.dart';
import '../../providers/budget_provider.dart';
import '../../data/asset_model.dart';
import '../../utils/app_localizations.dart';
import '../widgets/global_header.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<AssetProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalHeader(
        title: loc.get('assets_portfolio'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey[900],
        onPressed: () => _showAssetForm(context, loc),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  loc.get('net_worth'),
                  style: TextStyle(fontSize: 16, color: Colors.green[800], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '${loc.get('currency_symbol')}${provider.totalAssetsValue.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'לחץ לעריכה | גרור למחיקה',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey[300]),
              ),
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
                      return ListTile(
                        onTap: () => _showAssetForm(context, loc, asset: asset),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text(
                          asset.name, 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${asset.type} | ${asset.yieldPercentage}% תשואה',
                          style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
                        ),
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
                                if (confirm == true) {
                                  await provider.deleteAsset(asset.id!);
                                  if (context.mounted) {
                                    await context.read<BudgetProvider>().syncCapitalFromAssets();
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAssetForm(BuildContext context, AppLocalizations loc, {Asset? asset}) {
    final nameCtrl = TextEditingController(text: asset?.name ?? '');
    final valueCtrl = TextEditingController(text: asset?.value.toStringAsFixed(0) ?? '');
    final yieldCtrl = TextEditingController(text: asset?.yieldPercentage.toString() ?? '4.0');
    String assetType = asset?.type ?? 'השקעה';

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
                TextField(
                  controller: nameCtrl, 
                  decoration: InputDecoration(labelText: loc.get('asset_name'), prefixIcon: const Icon(Icons.label_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueCtrl, 
                  decoration: InputDecoration(labelText: loc.get('asset_value'), prefixIcon: const Icon(Icons.attach_money)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yieldCtrl, 
                  decoration: const InputDecoration(labelText: 'תשואה שנתית (%)', prefixIcon: Icon(Icons.trending_up)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: assetType, // תיקון שגיאת Deprecation (החלפת value ב-initialValue)
                  decoration: const InputDecoration(labelText: 'סוג נכס', prefixIcon: Icon(Icons.category_outlined)),
                  items: ['השקעה', 'נדל"ן', 'חיסכון', 'אחר'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => assetType = val!),
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
                  );
                  
                  if (asset == null) {
                    await Provider.of<AssetProvider>(context, listen: false).addAsset(newAsset);
                  } else {
                    await Provider.of<AssetProvider>(context, listen: false).updateAsset(newAsset);
                  }
                  
                  // תיקון שגיאת use_build_context_synchronously ע"י בדיקת mounted
                  if (context.mounted) {
                    await Provider.of<BudgetProvider>(context, listen: false).syncCapitalFromAssets();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
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