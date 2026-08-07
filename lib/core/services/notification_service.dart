import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/data/repositories/notification_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

typedef NotificationOpenCallback = void Function(Map<String, dynamic> data);

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Lazy — avoid touching Firebase before `Firebase.initializeApp()`.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _repository = NotificationRepository.instance;

  static const _channelId = 'ataa_default_channel';
  static const _channelName = 'ATAA Notifications';

  bool _initialized = false;
  bool _localReady = false;
  bool _interactionSetup = false;
  NotificationOpenCallback? onNotificationOpened;

  Future<void> init({required String role}) async {
    if (_initialized) return;

    await _setupLocalNotifications();

    if (NotificationRepository.firebaseReady) {
      await _requestPermission();
      await _setupFcmHandlers();

      try {
        final token = await _messaging.getToken();
        if (token != null) {
          await _repository.saveFcmToken(
            userId: role,
            token: token,
            role: role,
          );
        }

        _messaging.onTokenRefresh.listen((token) async {
          await _repository.saveFcmToken(
            userId: role,
            token: token,
            role: role,
          );
        });
      } catch (e, stack) {
        debugPrint('FCM token setup failed: $e\n$stack');
      }
    }

    _initialized = true;
  }

  /// Shows a system-tray notification on the device (works in background shade).
  Future<void> showSystemNotification({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    if (!_localReady) {
      await _setupLocalNotifications();
    }
    await _showLocalNotification(
      title: title,
      body: body,
      payload: jsonEncode(data),
    );
  }

  /// Handles taps that open the app from terminated / background FCM messages.
  Future<void> setupInteractedMessage() async {
    if (_interactionSetup || !NotificationRepository.firebaseReady) return;
    _interactionSetup = true;

    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _dispatchOpen(initialMessage.data);
      }

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _dispatchOpen(message.data);
      });
    } catch (e, stack) {
      debugPrint('setupInteractedMessage failed: $e\n$stack');
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  Future<void> _setupLocalNotifications() async {
    if (_localReady) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
      );
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.createNotificationChannel(channel);
    }

    _localReady = true;
  }

  Future<void> _setupFcmHandlers() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _showLocalNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    });
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _dispatchOpen(const {});
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _dispatchOpen(decoded);
      } else if (decoded is Map) {
        _dispatchOpen(Map<String, dynamic>.from(decoded));
      } else {
        _dispatchOpen(const {});
      }
    } catch (_) {
      _dispatchOpen(const {});
    }
  }

  void _dispatchOpen(Map<String, dynamic> data) {
    onNotificationOpened?.call(data);
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
