import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification_model.dart';

class NotificationRepository {
  static const _localKey = 'local_notifications_v2';
  static const _legacyLocalKey = 'local_notifications';
  static const _seededKey = 'notifications_demo_seeded';
  static const _clearedDemoKey = 'notifications_demo_cleared_v2';
  static const _collection = 'notifications';

  static bool firebaseReady = false;

  /// Shared instance so helpers and UI listen to the same local stream.
  static final NotificationRepository instance = NotificationRepository._();

  factory NotificationRepository({FirebaseFirestore? firestore}) {
    if (firestore != null && firebaseReady) {
      return NotificationRepository._(firestore: firestore);
    }
    return instance;
  }

  NotificationRepository._({FirebaseFirestore? firestore})
      : _firestore = firebaseReady
            ? (firestore ?? FirebaseFirestore.instance)
            : null;

  final FirebaseFirestore? _firestore;
  static final _localStream =
      StreamController<List<AppNotificationModel>>.broadcast();


  bool get _useFirestore => firebaseReady && _firestore != null;

  /// One-time wipe of old demo notifications so inboxes start empty.
  Future<void> ensureCleanStart() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_clearedDemoKey) == true) return;
    await prefs.remove(_legacyLocalKey);
    await prefs.remove(_localKey);
    await prefs.remove(_seededKey);
    await prefs.setBool(_clearedDemoKey, true);
  }

  Stream<List<AppNotificationModel>> watchNotifications(
    NotificationAudience audience,
  ) async* {
    await ensureCleanStart();

    if (_useFirestore) {
      yield* _firestore!
          .collection(_collection)
          .where('userId', isEqualTo: audience.storageId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) =>
                      AppNotificationModel.fromFirestore(doc.id, doc.data()),
                )
                .where((n) => n.audience == audience)
                .toList(),
          );
      return;
    }

    yield await _getLocalNotifications(audience);
    yield* _localStream.stream.map(
      (all) => all.where((n) => n.audience == audience).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Future<List<AppNotificationModel>> _getLocalNotifications(
    NotificationAudience audience,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localKey) ?? [];
    return raw
        .map(
          (e) => AppNotificationModel.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .where((n) => n.audience == audience)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveLocalNotifications(
    List<AppNotificationModel> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _localKey,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _localStream.add(
      List<AppNotificationModel>.from(items)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Future<void> addNotification(AppNotificationModel notification) async {
    final withAudience = AppNotificationModel(
      id: notification.id.isEmpty
          ? 'n_${DateTime.now().millisecondsSinceEpoch}'
          : notification.id,
      userId: notification.audience.storageId,
      audience: notification.audience,
      type: notification.type,
      titleKey: notification.titleKey,
      bodyKey: notification.bodyKey,
      bodyArgs: notification.bodyArgs,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
    );

    if (_useFirestore) {
      await _firestore!.collection(_collection).add(withAudience.toFirestore());
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localKey) ?? [];
    final all = raw
        .map(
          (e) => AppNotificationModel.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .toList();

    all.insert(0, withAudience);
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
        .map(
          (e) => AppNotificationModel.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    await _saveLocalNotifications(all);
  }

  Future<void> markAllAsRead(NotificationAudience audience) async {
    if (_useFirestore) {
      final snapshot = await _firestore!
          .collection(_collection)
          .where('userId', isEqualTo: audience.storageId)
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
        .map(
          (e) => AppNotificationModel.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .map(
          (n) => n.audience == audience ? n.copyWith(isRead: true) : n,
        )
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

  void dispose() {
    // Shared stream — do not close from individual callers.
  }
}
