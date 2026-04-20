// 🔒 STATUS: EDITED (Added adminNotes field, update method, and Double-Lock Admin Security)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

class AdminUserRecord {
  final String uid;
  final String email;
  final String? displayName;
  final String? adminNotes; // 📝 שדה חדש להערות מנהל
  final String generation;
  final String country;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final Map<String, dynamic> metrics;
  final bool isPremium;

  AdminUserRecord({
    required this.uid,
    required this.email,
    this.displayName,
    this.adminNotes,
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

  // 🛡️ מנעול אדמין כפול (הובא מארגז החול - סעיף 13.1.2 לחוקה)
  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final adminDoc = await _db.collection('admins').doc(user.uid).get();
      return adminDoc.exists;
    } catch (e) {
      dev.log("Admin Check Error: $e");
      return false;
    }
  }

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
    
    final users = await Future.wait(snap.docs.map((doc) async {
      final data = doc.data();
      
      final familySnap = await _db.collection('users')
          .doc(doc.id)
          .collection('family_members')
          .orderBy('birthYear', descending: false)
          .limit(1)
          .get();

      String? name;
      if (familySnap.docs.isNotEmpty) {
        name = familySnap.docs.first.data()['name'];
      }

      return AdminUserRecord(
        uid: doc.id,
        email: data['email'] ?? 'Unknown',
        displayName: name ?? 'לא הוגדר שם',
        adminNotes: data['adminNotes'] as String?, // שליפת ההערה
        generation: data['generation'] ?? 'Regular',
        country: data['country'] ?? 'Unknown',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
        metrics: data['metrics'] is Map ? Map<String, dynamic>.from(data['metrics']) : {},
        isPremium: data['isPremium'] == true,
      );
    }));

    return users;
  }

  // 📝 פונקציה חדשה לעדכון הערות מנהל
  static Future<void> updateAdminNotes(String uid, String notes) async {
    await _db.collection('users').doc(uid).set({
      'adminNotes': notes,
    }, SetOptions(merge: true));
  }

  static Future<void> toggleUserPremium(String uid, bool newStatus) async {
    await _db.collection('users').doc(uid).set({
      'isPremium': newStatus,
    }, SetOptions(merge: true));
  }
}