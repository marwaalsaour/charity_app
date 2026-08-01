import 'models/app_notification_model.dart';
import 'repositories/notification_repository.dart';

class NotificationHelper {
  static final _repository = NotificationRepository();

  static Future<void> notifyDonationSuccess({
    required double amount,
    required String currency,
    required String causeTitle,
  }) async {
    final userId = await _repository.getOrCreateUserId();
    await _repository.addNotification(
      AppNotificationModel(
        id: '',
        userId: userId,
        type: AppNotificationType.donationSuccess,
        titleKey: 'notification_donation_title',
        bodyKey: 'notification_donation_body',
        bodyArgs: {
          'amount': amount.toStringAsFixed(0),
          'currency': currency,
          'cause': causeTitle,
        },
        createdAt: DateTime.now(),
      ),
    );
  }
}
