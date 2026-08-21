import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../models/app_notification_model.dart';

class NotificationRepository {
  static const _localKey = 'local_notifications_v2';
  static const _legacyLocalKey = 'local_notifications';
  static const _seededKey = 'notifications_demo_seeded';
  static const _clearedDemoKey = 'notifications_demo_cleared_v2';
  static const _collection = 'notifications';

  static bool firebaseReady = false;

  static final NotificationRepository instance = NotificationRepository._();

  factory NotificationRepository({FirebaseFirestore? firestore, Dio? dio}) {
    if (firestore != null && firebaseReady) {
      return NotificationRepository._(firestore: firestore, dio: dio);
    }
    return instance;
  }

  NotificationRepository._({FirebaseFirestore? firestore, Dio? dio})
      : _firestore =
            firebaseReady ? (firestore ?? FirebaseFirestore.instance) : null,
        _dio = dio ?? ApiClient.instance.dio;

  final FirebaseFirestore? _firestore;
  final Dio _dio;
  static final _localStream =
      StreamController<List<AppNotificationModel>>.broadcast();

  bool get _useFirestore => firebaseReady && _firestore != null;

  static const _firestoreTimeout = Duration(seconds: 2);

  Future<T?> _tryFirestore<T>(Future<T> Function() action) async {
    if (!_useFirestore) return null;
    try {
      return await action().timeout(_firestoreTimeout);
    } catch (_) {
      return null;
    }
  }

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
    await syncFromServer(audience);

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

  Future<void> syncFromServer(NotificationAudience audience) async {
    try {
      final response = await _dio.get('/mynotifications');
      final data = response.data;
      if (data is! Map || data['success'] != true) return;
      final list = data['data'];
      if (list is! List) return;

      for (final item in list) {
        if (item is! Map) continue;
        final remote = AppNotificationModel.fromLaravel(
          Map<String, dynamic>.from(item),
          audience: audience,
        );
        await _upsertLocal(remote);
      }
    } catch (_) {}
  }

  Future<void> _upsertLocal(AppNotificationModel notification) async {
    if (_useFirestore) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localKey) ?? [];
    final all = raw
        .map(
          (e) => AppNotificationModel.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .toList();

    final index = all.indexWhere((n) => n.id == notification.id);
    if (index >= 0) {
      all[index] = notification.copyWith(isRead: all[index].isRead);
    } else {
      all.insert(0, notification);
    }
    await _saveLocalNotifications(all);
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
      titleText: notification.titleText,
      bodyText: notification.bodyText,
    );

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

    await _tryFirestore(
      () => _firestore!.collection(_collection).add(withAudience.toFirestore()),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.startsWith('srv_')) {
      final serverId = notificationId.substring(4);
      try {
        await _dio.put('/mynotifications/$serverId/read');
      } catch (_) {}
    }

    if (_useFirestore) {
      await _tryFirestore(
        () => _firestore!.collection(_collection).doc(notificationId).update({
          'isRead': true,
        }),
      );
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
        .toList();

    for (final n in all.where((n) => n.audience == audience && !n.isRead)) {
      if (n.id.startsWith('srv_')) {
        try {
          await _dio.put('/mynotifications/${n.id.substring(4)}/read');
        } catch (_) {}
      }
    }

    await _saveLocalNotifications(
      all
          .map(
            (n) => n.audience == audience ? n.copyWith(isRead: true) : n,
          )
          .toList(),
    );
  }

  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localKey);
    await prefs.remove(_legacyLocalKey);
    await prefs.remove(_seededKey);
    _localStream.add(const []);
  }

  Future<void> saveFcmToken({
    required String userId,
    required String token,
    required String role,
  }) async {
    if (!_useFirestore) return;
    await _tryFirestore(
      () => _firestore!.collection('users').doc(userId).set({
        'fcmToken': token,
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  void dispose() {}
}
