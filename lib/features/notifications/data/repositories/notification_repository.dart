import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification_model.dart';

class NotificationRepository {
  static const _userIdKey = 'firebase_user_id';
  static const _localKey = 'local_notifications';
  static const _seededKey = 'notifications_demo_seeded';
  static const _collection = 'notifications';

  static bool firebaseReady = false;

  final FirebaseFirestore? _firestore;
  final _localStream = StreamController<List<AppNotificationModel>>.broadcast();

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firebaseReady ? (firestore ?? FirebaseFirestore.instance) : null;

  Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_userIdKey);
    if (userId == null || userId.isEmpty) {
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_userIdKey, userId);
    }
    return userId;
  }

  Stream<List<AppNotificationModel>> watchNotifications(String userId) async* {
    if (_useFirestore) {
      yield* _firestore!
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AppNotificationModel.fromFirestore(doc.id, doc.data()))
                .toList(),
          );
      return;
    }

    yield await _getLocalNotifications(userId);
    yield* _localStream.stream;
  }

  bool get _useFirestore => firebaseReady && _firestore != null;

  Future<List<AppNotificationModel>> _getLocalNotifications(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localKey) ?? [];
    return raw
        .map((e) => AppNotificationModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .where((n) => n.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveLocalNotifications(List<AppNotificationModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _localKey,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _localStream.add(
      items..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Future<void> addNotification(AppNotificationModel notification) async {
    if (_useFirestore) {
      await _firestore!.collection(_collection).add(notification.toFirestore());
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localKey) ?? [];
    final all = raw
        .map((e) => AppNotificationModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();

    final withId = AppNotificationModel(
      id: notification.id.isEmpty
          ? 'n_${DateTime.now().millisecondsSinceEpoch}'
          : notification.id,
      userId: notification.userId,
      type: notification.type,
      titleKey: notification.titleKey,
      bodyKey: notification.bodyKey,
      bodyArgs: notification.bodyArgs,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
    );

    all.insert(0, withId);
    await _saveLocalNotifications(all);
  }

  Future<void> markAsRead(String notificationId) async {
    if (_useFirestore) {
      await _firestore!.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localKey) ?? [];
    final all = raw
        .map((e) => AppNotificationModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    await _saveLocalNotifications(all);
  }

  Future<void> markAllAsRead(String userId) async {
    if (_useFirestore) {
      final snapshot = await _firestore!
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localKey) ?? [];
    final all = raw
        .map((e) => AppNotificationModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .map((n) => n.userId == userId ? n.copyWith(isRead: true) : n)
        .toList();
    await _saveLocalNotifications(all);
  }

  Future<void> saveFcmToken({
    required String userId,
    required String token,
    required String role,
  }) async {
    if (!_useFirestore) return;
    await _firestore!.collection('users').doc(userId).set({
      'fcmToken': token,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> seedDemoNotifications(String userId) async {
    if (_useFirestore) {
      final existing = await _firestore!
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return;
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_seededKey) == true) return;
      await prefs.setBool(_seededKey, true);
    }

    for (final demo in _demoNotifications(userId)) {
      await addNotification(demo);
    }
  }

  List<AppNotificationModel> _demoNotifications(String userId) {
    return [
      AppNotificationModel(
        id: '',
        userId: userId,
        type: AppNotificationType.donationSuccess,
        titleKey: 'notification_donation_title',
        bodyKey: 'notification_donation_body',
        bodyArgs: const {'amount': '50', 'currency': 'USD'},
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotificationModel(
        id: '',
        userId: userId,
        type: AppNotificationType.volunteerApproved,
        titleKey: 'notification_volunteer_approved_title',
        bodyKey: 'notification_volunteer_approved_body',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppNotificationModel(
        id: '',
        userId: userId,
        type: AppNotificationType.volunteerRejected,
        titleKey: 'notification_volunteer_rejected_title',
        bodyKey: 'notification_volunteer_rejected_body',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      AppNotificationModel(
        id: '',
        userId: userId,
        type: AppNotificationType.beneficiaryApproved,
        titleKey: 'notification_beneficiary_approved_title',
        bodyKey: 'notification_beneficiary_approved_body',
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      ),
      AppNotificationModel(
        id: '',
        userId: userId,
        type: AppNotificationType.beneficiaryRejected,
        titleKey: 'notification_beneficiary_rejected_title',
        bodyKey: 'notification_beneficiary_rejected_body',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  void dispose() {
    _localStream.close();
  }
}
