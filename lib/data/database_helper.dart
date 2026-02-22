// 🔒 STATUS: EDITED (Added Withdrawals Table & onUpgrade for Schema V2)
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'expense_model.dart';
import 'debt_model.dart';
import 'asset_model.dart'; 
import 'shopping_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fintel_v22.db'); 
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbFolder = join(appDocDir.path, 'Fintel');
    
    final dir = Directory(dbFolder);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    final path = join(dbFolder, filePath);
    // הועלה לגרסה 2 כדי ליצור את טבלת המשיכות החדשה (withdrawals)
    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // שדרוג מבנה הנתונים הקיים מבלי למחוק מידע
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS withdrawals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          expenseId INTEGER NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          note TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE expenses (
        id $idType, name $textType, category $textType, parentCategory $textType,
        monthlyAmount $realType, originalAmount $realType, frequency $intType, 
        isSinking $boolType, isPerChild $boolType, targetAmount REAL, currentBalance REAL, 
        allocationRatio REAL, lastUpdateDate TEXT, isLocked $boolType, manualAmount REAL, date $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id $idType, name $textType, originalBalance $realType, currentBalance $realType, 
        monthlyPayment $realType, date $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY, value REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE assets (
        id $idType, name $textType, value $realType, type $textType, yieldPercentage $realType
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_items (
        id $idType, name $textType, category $textType, price $realType, quantity $intType, 
        frequency_weeks $intType, last_purchase_date TEXT, status $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE family_members (
        id $idType, name $textType, birthYear $intType
      )
    ''');

    // הטבלה החדשה להוצאות צוברות
    await db.execute('''
      CREATE TABLE withdrawals (
        id $idType, expenseId $intType, amount $realType, date $textType, note $textType
      )
    ''');
  }

  // --- ניהול הגדרות ---
  Future<void> saveSetting(String key, double value) async {
    final db = await database;
    await db.insert('app_settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<double?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) return (maps.first['value'] as num).toDouble();
    return null;
  }
  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }

  // --- ניהול קופת צלף ---
  Future<void> saveSniperBalance(double balance) async => await saveSetting('sniper_balance', balance);
  Future<double> getSniperBalance() async => await getSetting('sniper_balance') ?? 0.0;

  // --- איפוס נתונים ---
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('debts');
    await db.delete('app_settings');
    await db.delete('assets');
    await db.delete('shopping_items');
    await db.delete('family_members');
    await db.delete('withdrawals'); 
  }

  // --- CRUD משפחה ---
  Future<int> insertFamilyMember(FamilyMember fm) async => (await database).insert('family_members', fm.toMap());
  Future<List<FamilyMember>> getFamilyMembers() async {
    final res = await (await database).query('family_members');
    return res.map((json) => FamilyMember.fromMap(json)).toList();
  }
  Future<int> updateFamilyMember(FamilyMember fm) async => (await database).update('family_members', fm.toMap(), where: 'id = ?', whereArgs: [fm.id]);
  Future<int> deleteFamilyMember(int id) async => (await database).delete('family_members', where: 'id = ?', whereArgs: [id]);

  // --- CRUD הוצאות ---
  Future<int> insertExpense(Expense e) async => (await database).insert('expenses', e.toMap());
  Future<List<Expense>> getExpenses() async {
    final res = await (await database).query('expenses');
    return res.map((json) => Expense.fromMap(json)).toList();
  }
  Future<int> updateExpense(Expense e) async => (await database).update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  Future<int> deleteExpense(int id) async => (await database).delete('expenses', where: 'id = ?', whereArgs: [id]);

  // --- CRUD חובות ---
  Future<List<Debt>> getDebts() async {
    final res = await (await database).query('debts');
    return res.map((json) => Debt.fromMap(json)).toList();
  }
  Future<int> insertDebt(Debt d) async => (await database).insert('debts', d.toMap());
  Future<int> updateDebt(Debt d) async => (await database).update('debts', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  Future<int> deleteDebt(int id) async => (await database).delete('debts', where: 'id = ?', whereArgs: [id]);

  // --- CRUD נכסים ---
  Future<List<Asset>> getAssets() async {
    final res = await (await database).query('assets');
    return res.map((json) => Asset.fromMap(json)).toList();
  }
  Future<int> insertAsset(Asset a) async => (await database).insert('assets', a.toMap());
  Future<int> updateAsset(Asset a) async => (await database).update('assets', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  Future<int> deleteAsset(int id) async => (await database).delete('assets', where: 'id = ?', whereArgs: [id]);

  // --- CRUD קניות ---
  Future<List<ShoppingItem>> getShoppingItems() async {
    final res = await (await database).query('shopping_items');
    return res.map((json) => ShoppingItem.fromMap(json)).toList();
  }
  Future<int> insertShoppingItem(ShoppingItem i) async => (await database).insert('shopping_items', i.toMap());
  Future<int> updateShoppingItem(ShoppingItem i) async => (await database).update('shopping_items', i.toMap(), where: 'id = ?', whereArgs: [i.id]);
  Future<int> deleteShoppingItem(int id) async => (await database).delete('shopping_items', where: 'id = ?', whereArgs: [id]);

  // --- CRUD משיכות (Withdrawals) ---
  Future<int> insertWithdrawal(Withdrawal w) async => (await database).insert('withdrawals', w.toMap());
  Future<List<Withdrawal>> getWithdrawals(int expenseId) async {
    final res = await (await database).query('withdrawals', where: 'expenseId = ?', whereArgs: [expenseId], orderBy: 'date DESC');
    return res.map((json) => Withdrawal.fromMap(json)).toList();
  }
  Future<int> deleteWithdrawal(int id) async => (await database).delete('withdrawals', where: 'id = ?', whereArgs: [id]);
}