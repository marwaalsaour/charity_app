import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../features/notifications/data/repositories/notification_repository.dart';
import 'notification_service.dart';

/// تهيئة Firebase — يعمل تلقائياً مع google-services.json على Android.
Future<bool> initializeFirebaseApp() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      NotificationRepository.firebaseReady = true;
      return true;
    }
    await Firebase.initializeApp();
    NotificationRepository.firebaseReady = true;
    return true;
  } catch (e, stack) {
    NotificationRepository.firebaseReady = false;
    debugPrint(
      'Firebase not configured yet. Using local notifications.\n'
      'Add google-services.json then run flutterfire configure.\n$e\n$stack',
    );
    return false;
  }
}

Future<void> bootstrapFirebase({required String role}) async {
  try {
    // Always init local notifications; FCM runs only when Firebase is ready.
    await NotificationService.instance.init(role: role);
  } catch (e, stack) {
    debugPrint('NotificationService init failed: $e\n$stack');
  }
}
