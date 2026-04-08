// 🔒 STATUS: EDITED (Admin God-Mode Engine - Rethrowing Errors for Debugging)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// מודל נתונים רזה למשתמש (Metadata בלבד, ללא חשיפה פיננסית)
class AdminUserRecord {
  final String id;
  final String email;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final String generation;
  final String country;
  final Map<String, dynamic> metrics;

  AdminUserRecord({
    required this.id,
    required this.email,
    this.createdAt,
    this.lastActive,
    required this.generation,
    required this.country,
    required this.metrics,
  });

  // פונקציית עזר לפענוח תאריכים בטוח מכל סוג של נתון ישן/חדש
  static DateTime? _parseDateSafely(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }

  factory AdminUserRecord.fromMap(String id, Map<String, dynamic> map) {
    return AdminUserRecord(
      id: id,
      email: map['email']?.toString() ?? 'Unknown',
      createdAt: _parseDateSafely(map['createdAt']),
      lastActive: _parseDateSafely(map['lastActive']),
      generation: map['generation']?.toString() ?? 'Alpha',
      country: map['country']?.toString() ?? 'Unknown',
      metrics: map['metrics'] is Map ? Map<String, dynamic>.from(map['metrics']) : {},
    );
  }
}

class AdminService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. אימות הרשאת מנהל מול השרת (מנעול כפול)
  static Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _db.collection('admins').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // 2. בדיקת סטטוס השקה מסחרית
  static Future<bool> isCommercialLaunch() async {
    try {
      final doc = await _db.collection('system_settings').doc('global').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['isCommercialLaunch'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error fetching commercial status: $e');
      return false;
    }
  }

  // 3. הפעלת השקה מסחרית (כפתור השמדה עצמית)
  static Future<void> toggleCommercialLaunch() async {
    try {
      await _db.collection('system_settings').doc('global').set({
        'isCommercialLaunch': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating commercial status: $e');
      rethrow;
    }
  }

  // 4. שאיבת כלל המשתמשים עבור מסנן המניות (Screener)
  static Future<List<AdminUserRecord>> fetchAllUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) => AdminUserRecord.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      debugPrint('🚨 CRITICAL ERROR FETCHING USERS: $e');
      rethrow; // <--- התיקון: מעביר את השגיאה למסך כדי שהקובייה האדומה תתעורר!
    }
  }
}