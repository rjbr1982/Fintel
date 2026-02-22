import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/asset_model.dart';

class AssetProvider with ChangeNotifier {
  List<Asset> _assets = [];

  List<Asset> get assets => _assets;

  Future<void> fetchAssets() async {
    // תיקון כירורגי: שימוש ב-instance של ה-Singleton
    final db = DatabaseHelper.instance;
    _assets = await db.getAssets();
    notifyListeners();
  }

  Future<void> addAsset(Asset asset) async {
    final db = DatabaseHelper.instance;
    await db.insertAsset(asset);
    await fetchAssets();
  }

  Future<void> deleteAsset(int id) async {
    final db = DatabaseHelper.instance;
    await db.deleteAsset(id);
    await fetchAssets();
  }

  Future<void> updateAsset(Asset asset) async {
    final db = DatabaseHelper.instance;
    await db.updateAsset(asset);
    await fetchAssets();
  }

  // סה"כ שווי הנכסים
  double get totalAssetsValue {
    return _assets.fold(0.0, (sum, item) => sum + item.value);
  }

  // הכנסה פסיבית חודשית תיאורטית (לפי תשואה שהוזנה בנכס או ברירת מחדל)
  double get totalPassiveIncomeMonthly {
    return _assets.fold(0.0, (sum, item) {
      // תשואה שנתית לחלק ל-12
      double monthlyYield = (item.yieldPercentage / 100) / 12;
      return sum + (item.value * monthlyYield);
    });
  }
}