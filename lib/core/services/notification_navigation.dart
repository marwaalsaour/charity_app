import 'package:firebase_messaging/firebase_messaging.dart';

import '../auth/user_role.dart';
import '../router/app_routes.dart';

/// Resolves where to navigate when the user opens an FCM / local notification.
class NotificationNavigation {
  NotificationNavigation._();

  /// Supported [RemoteMessage.data] keys:
  /// - `route`: absolute app path (highest priority)
  /// - `type`: notification business type
  /// - `role`: `donor` | `beneficiary`
  static String resolveRoute(
    Map<String, dynamic> data, {
    UserRole? fallbackRole,
  }) {
    final explicitRoute = data['route']?.toString().trim();
    if (explicitRoute != null && explicitRoute.isNotEmpty) {
      return explicitRoute;
    }

    final role = UserRole.fromString(data['role']?.toString()) ?? fallbackRole;
    final type = data['type']?.toString();

    switch (type) {
      case 'donationSuccess':
        return AppRoutes.myDonations;
      case 'volunteerSubmitted':
      case 'volunteerApproved':
      case 'volunteerRejected':
        return AppRoutes.myActivities;
      case 'requestSubmitted':
      case 'beneficiaryApproved':
      case 'beneficiaryRejected':
        return AppRoutes.beneficiaryRequests;
      default:
        return role == UserRole.beneficiary
            ? AppRoutes.beneficiaryNotifications
            : AppRoutes.donorNotifications;
    }
  }

  static String resolveFromRemoteMessage(
    RemoteMessage message, {
    UserRole? fallbackRole,
  }) {
    return resolveRoute(message.data, fallbackRole: fallbackRole);
  }
}
