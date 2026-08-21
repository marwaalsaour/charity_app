import 'package:easy_localization/easy_localization.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/services/notification_service.dart';
import 'models/app_notification_model.dart';
import 'repositories/notification_repository.dart';

class NotificationHelper {
  static final _repository = NotificationRepository.instance;

  static NotificationAudience _audienceFor(UserRole role) {
    return role == UserRole.beneficiary
        ? NotificationAudience.beneficiary
        : NotificationAudience.donor;
  }

  static Future<void> _pushToDevice({
    required AppNotificationModel notification,
  }) async {
    await NotificationService.instance.showSystemNotification(
      title: notification.titleKey.tr(),
      body: notification.bodyKey.tr(namedArgs: notification.bodyArgs),
      data: {
        'type': notification.type.firestoreValue,
        'role': notification.audience.storageId,
        if (notification.type == AppNotificationType.caseFullyFunded)
          'route': '/beneficiary/home',
      },
    );
  }

  static Future<void> notifyDonationSuccess({
    required double amount,
    required String currency,
    required String causeTitle,
  }) async {
    final audience = NotificationAudience.donor;
    final notification = AppNotificationModel(
      id: '',
      userId: audience.storageId,
      audience: audience,
      type: AppNotificationType.donationSuccess,
      titleKey: 'notification_donation_title',
      bodyKey: 'notification_donation_body',
      bodyArgs: {
        'amount': amount.toStringAsFixed(0),
        'currency': currency,
        'cause': causeTitle,
      },
      createdAt: DateTime.now(),
    );
    await _repository.addNotification(notification);
    await _pushToDevice(notification: notification);
  }

  static Future<void> notifyVolunteerSubmitted({
    String? campaignTitle,
  }) async {
    final audience = NotificationAudience.donor;
    final notification = AppNotificationModel(
      id: '',
      userId: audience.storageId,
      audience: audience,
      type: AppNotificationType.volunteerSubmitted,
      titleKey: 'notification_volunteer_submitted_title',
      bodyKey: 'notification_volunteer_submitted_body',
      bodyArgs: {
        if (campaignTitle != null && campaignTitle.isNotEmpty)
          'title': campaignTitle,
      },
      createdAt: DateTime.now(),
    );
    await _repository.addNotification(notification);
    await _pushToDevice(notification: notification);
  }

  static Future<void> notifyRequestSubmitted({
    required String requestTitle,
  }) async {
    final audience = NotificationAudience.beneficiary;
    final notification = AppNotificationModel(
      id: '',
      userId: audience.storageId,
      audience: audience,
      type: AppNotificationType.requestSubmitted,
      titleKey: 'notification_request_submitted_title',
      bodyKey: 'notification_request_submitted_body',
      bodyArgs: {'title': requestTitle},
      createdAt: DateTime.now(),
    );
    await _repository.addNotification(notification);
    await _pushToDevice(notification: notification);
  }

  static Future<void> notifyBeneficiaryDecision({
    required bool approved,
    required String requestTitle,
  }) async {
    final audience = NotificationAudience.beneficiary;
    final notification = AppNotificationModel(
      id: '',
      userId: audience.storageId,
      audience: audience,
      type: approved
          ? AppNotificationType.beneficiaryApproved
          : AppNotificationType.beneficiaryRejected,
      titleKey: approved
          ? 'notification_beneficiary_approved_title'
          : 'notification_beneficiary_rejected_title',
      bodyKey: approved
          ? 'notification_beneficiary_approved_body'
          : 'notification_beneficiary_rejected_body',
      bodyArgs: {'title': requestTitle},
      createdAt: DateTime.now(),
    );
    await _repository.addNotification(notification);
    await _pushToDevice(notification: notification);
  }

  static Future<void> notifyCaseFullyFunded({
    required String requestTitle,
    double? amount,
    String? currency,
  }) async {
    final audience = NotificationAudience.beneficiary;
    final notification = AppNotificationModel(
      id: '',
      userId: audience.storageId,
      audience: audience,
      type: AppNotificationType.caseFullyFunded,
      titleKey: 'notification_case_funded_title',
      bodyKey: 'notification_case_funded_body',
      bodyArgs: {
        'title': requestTitle,
        'amount': ?amount?.toStringAsFixed(0),
        'currency': ?currency,
      },
      createdAt: DateTime.now(),
    );
    await _repository.addNotification(notification);
    await _pushToDevice(notification: notification);
  }

  static Future<void> notifySponsorshipWalletEmpty({
    required String childName,
    required String sponsorshipId,
  }) async {
    final audience = NotificationAudience.donor;
    final notification = AppNotificationModel(
      id: '',
      userId: audience.storageId,
      audience: audience,
      type: AppNotificationType.general,
      titleKey: 'notification_sponsorship_empty_title',
      bodyKey: 'notification_sponsorship_empty_body',
      bodyArgs: {'name': childName, 'id': sponsorshipId},
      createdAt: DateTime.now(),
    );
    await _repository.addNotification(notification);
    await _pushToDevice(notification: notification);
  }

  /// Optional helper if a caller has a [UserRole] and a generic message.
  static Future<void> notifyForRole({
    required UserRole role,
    required AppNotificationType type,
    required String titleKey,
    required String bodyKey,
    Map<String, String> bodyArgs = const {},
  }) async {
    final audience = _audienceFor(role);
    final notification = AppNotificationModel(
      id: '',
      userId: audience.storageId,
      audience: audience,
      type: type,
      titleKey: titleKey,
      bodyKey: bodyKey,
      bodyArgs: bodyArgs,
      createdAt: DateTime.now(),
    );
    await _repository.addNotification(notification);
    await _pushToDevice(notification: notification);
  }
}
