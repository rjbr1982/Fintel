// 🔒 STATUS: EDITED (Added UID, isPremium tracking, and Golden Key toggle method)
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserRecord {
  final String uid;
  final String email;
  final String generation;
  final String country;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final Map<String, dynamic> metrics;
  final bool isPremium;

  AdminUserRecord({
    required this.uid,
    required this.email,
    required this.generation,
    required this.country,
    this.createdAt,
    this.lastActive,
    required this.metrics,
    required this.isPremium,
  });
}

class AdminService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> isCommercialLaunch() async {
    final doc = await _db.collection('system').doc('config').get();
    if (doc.exists) {
      return doc.data()?['commercial_launch'] == true;
    }
    return false;
  }

  static Future<void> toggleCommercialLaunch() async {
    final doc = await _db.collection('system').doc('config').get();
    bool current = doc.exists ? (doc.data()?['commercial_launch'] == true) : false;
    await _db.collection('system').doc('config').set({
      'commercial_launch': !current,
    }, SetOptions(merge: true));
  }

  static Future<List<AdminUserRecord>> fetchAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return AdminUserRecord(
        uid: doc.id,
        email: data['email'] ?? 'Unknown',
        generation: data['generation'] ?? 'Regular',
        country: data['country'] ?? 'Unknown',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
        metrics: data['metrics'] is Map ? Map<String, dynamic>.from(data['metrics']) : {},
        isPremium: data['isPremium'] == true,
      );
    }).toList();
  }

  // 🔑 הפונקציה לשדרוג משתמש ידנית (מפתח הזהב)
  static Future<void> toggleUserPremium(String uid, bool newStatus) async {
    await _db.collection('users').doc(uid).set({
      'isPremium': newStatus,
    }, SetOptions(merge: true));
  }
}