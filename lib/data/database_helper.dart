// 🔒 STATUS: EDITED (Added Checking Account History CRUD & Streams)
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'expense_model.dart';
import 'debt_model.dart';
import 'asset_model.dart'; 
import 'shopping_model.dart';
import 'checking_model.dart'; // <--- הייבוא החדש

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'unauthenticated';

  CollectionReference _userCollection(String collectionName) {
    return _db.collection('users').doc(_uid).collection(collectionName);
  }

  int _generateId() => DateTime.now().millisecondsSinceEpoch;

  // ==========================================
  // 🔄 REAL-TIME STREAMS (SaaS Sync)
  // ==========================================
  
  Stream<List<Expense>> streamExpenses() {
    return _userCollection('expenses').snapshots().map((snap) =>
        snap.docs.map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<Debt>> streamDebts() {
    return _userCollection('debts').snapshots().map((snap) =>
        snap.docs.map((doc) => Debt.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<Asset>> streamAssets() {
    return _userCollection('assets').snapshots().map((snap) =>
        snap.docs.map((doc) => Asset.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<ShoppingItem>> streamShoppingItems() {
    return _userCollection('shopping_items').snapshots().map((snap) =>
        snap.docs.map((doc) => ShoppingItem.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<FamilyMember>> streamFamilyMembers() {
    return _userCollection('family_members').snapshots().map((snap) =>
        snap.docs.map((doc) => FamilyMember.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  Stream<QuerySnapshot> streamSettings() {
    return _userCollection('app_settings').snapshots();
  }

  // זרם עו"ש
  Stream<List<CheckingEntry>> streamCheckingHistory() {
    return _userCollection('checking_history').orderBy('date', descending: true).snapshots().map((snap) =>
        snap.docs.map((doc) => CheckingEntry.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  // ==========================================
  // הגדרות
  // ==========================================
  
  Future<void> saveSetting(String key, double value) async {
    await _userCollection('app_settings').doc(key).set({
      'key': key, 
      'value': value
    });
  }

  Future<double?> getSetting(String key) async {
    final doc = await _userCollection('app_settings').doc(key).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['value'] as num).toDouble();
    }
    return null;
  }

  Future<void> deleteSetting(String key) async {
    await _userCollection('app_settings').doc(key).delete();
  }

  Future<void> saveSniperBalance(double balance) async => await saveSetting('sniper_balance', balance);
  Future<double> getSniperBalance() async => await getSetting('sniper_balance') ?? 0.0;

  // ==========================================
  // איפוס נתונים
  // ==========================================
  
  Future<void> _deleteCollection(String collectionName) async {
    final snapshot = await _userCollection(collectionName).get();
    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> clearAllData() async {
    await _deleteCollection('expenses');
    await _deleteCollection('debts');
    await _deleteCollection('app_settings');
    await _deleteCollection('assets');
    await _deleteCollection('shopping_items');
    await _deleteCollection('family_members');
    await _deleteCollection('withdrawals'); 
    await _deleteCollection('checking_history'); 
  }

  // ==========================================
  // CRUD פעולות חד פעמיות
  // ==========================================

  Future<int> insertFamilyMember(FamilyMember fm) async {
    final id = fm.id ?? _generateId();
    final map = fm.toMap();
    map['id'] = id;
    await _userCollection('family_members').doc(id.toString()).set(map);
    return id;
  }
  
  Future<List<FamilyMember>> getFamilyMembers() async {
    final snap = await _userCollection('family_members').get();
    return snap.docs.map((doc) => FamilyMember.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }
  
  Future<int> updateFamilyMember(FamilyMember fm) async {
    await _userCollection('family_members').doc(fm.id.toString()).update(fm.toMap());
    return fm.id ?? 0;
  }
  
  Future<int> deleteFamilyMember(int id) async {
    await _userCollection('family_members').doc(id.toString()).delete();
    return id;
  }

  Future<int> insertExpense(Expense e) async {
    final id = e.id ?? _generateId();
    final map = e.toMap();
    map['id'] = id;
    await _userCollection('expenses').doc(id.toString()).set(map);
    return id;
  }

  Future<List<Expense>> getExpenses() async {
    final snap = await _userCollection('expenses').get();
    return snap.docs.map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<int> updateExpense(Expense e) async {
    await _userCollection('expenses').doc(e.id.toString()).update(e.toMap());
    return e.id ?? 0;
  }

  Future<int> deleteExpense(int id) async {
    await _userCollection('expenses').doc(id.toString()).delete();
    return id;
  }

  Future<List<Debt>> getDebts() async {
    final snap = await _userCollection('debts').get();
    return snap.docs.map((doc) => Debt.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<int> insertDebt(Debt d) async {
    final id = d.id ?? _generateId();
    final map = d.toMap();
    map['id'] = id;
    await _userCollection('debts').doc(id.toString()).set(map);
    return id;
  }

  Future<int> updateDebt(Debt d) async {
    await _userCollection('debts').doc(d.id.toString()).update(d.toMap());
    return d.id ?? 0;
  }

  Future<int> deleteDebt(int id) async {
    await _userCollection('debts').doc(id.toString()).delete();
    return id;
  }

  Future<List<Asset>> getAssets() async {
    final snap = await _userCollection('assets').get();
    return snap.docs.map((doc) => Asset.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<int> insertAsset(Asset a) async {
    final id = a.id ?? _generateId();
    final map = a.toMap();
    map['id'] = id;
    await _userCollection('assets').doc(id.toString()).set(map);
    return id;
  }

  Future<int> updateAsset(Asset a) async {
    await _userCollection('assets').doc(a.id.toString()).update(a.toMap());
    return a.id ?? 0;
  }

  Future<int> deleteAsset(int id) async {
    await _userCollection('assets').doc(id.toString()).delete();
    return id;
  }

  Future<List<ShoppingItem>> getShoppingItems() async {
    final snap = await _userCollection('shopping_items').get();
    return snap.docs.map((doc) => ShoppingItem.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<int> insertShoppingItem(ShoppingItem i) async {
    final id = i.id ?? _generateId();
    final map = i.toMap();
    map['id'] = id;
    await _userCollection('shopping_items').doc(id.toString()).set(map);
    return id;
  }

  Future<int> updateShoppingItem(ShoppingItem i) async {
    await _userCollection('shopping_items').doc(i.id.toString()).update(i.toMap());
    return i.id ?? 0;
  }

  Future<int> deleteShoppingItem(int id) async {
    await _userCollection('shopping_items').doc(id.toString()).delete();
    return id;
  }

  Future<int> insertWithdrawal(Withdrawal w) async {
    final id = w.id ?? _generateId();
    final map = w.toMap();
    map['id'] = id;
    await _userCollection('withdrawals').doc(id.toString()).set(map);
    return id;
  }

  Future<List<Withdrawal>> getWithdrawals(int expenseId) async {
    final snap = await _userCollection('withdrawals')
        .where('expenseId', isEqualTo: expenseId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((doc) => Withdrawal.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<int> deleteWithdrawal(int id) async {
    await _userCollection('withdrawals').doc(id.toString()).delete();
    return id;
  }

  // ==========================================
  // CRUD לעו"ש
  // ==========================================
  Future<int> insertCheckingEntry(CheckingEntry entry) async {
    final id = entry.id ?? _generateId();
    final map = entry.toMap();
    map['id'] = id;
    await _userCollection('checking_history').doc(id.toString()).set(map);
    return id;
  }

  Future<int> deleteCheckingEntry(int id) async {
    await _userCollection('checking_history').doc(id.toString()).delete();
    return id;
  }
}