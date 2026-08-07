enum AppNotificationType {
  donationSuccess,
  volunteerSubmitted,
  volunteerApproved,
  volunteerRejected,
  requestSubmitted,
  beneficiaryApproved,
  beneficiaryRejected,
  general,
}

extension AppNotificationTypeX on AppNotificationType {
  String get firestoreValue => name;

  static AppNotificationType fromString(String? value) {
    return AppNotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppNotificationType.general,
    );
  }
}

/// Inbox bucket: donor and beneficiary notifications stay separate.
enum NotificationAudience {
  donor,
  beneficiary;

  String get storageId => name;

  static NotificationAudience fromRoleName(String? value) {
    return value == 'beneficiary'
        ? NotificationAudience.beneficiary
        : NotificationAudience.donor;
  }
}

class AppNotificationModel {
  final String id;
  final String userId;
  final NotificationAudience audience;
  final AppNotificationType type;
  final String titleKey;
  final String bodyKey;
  final Map<String, String> bodyArgs;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.audience,
    required this.type,
    required this.titleKey,
    required this.bodyKey,
    this.bodyArgs = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotificationModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AppNotificationModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      audience: NotificationAudience.fromRoleName(
        data['audience'] as String? ?? data['userId'] as String?,
      ),
      type: AppNotificationTypeX.fromString(data['type'] as String?),
      titleKey: data['titleKey'] as String? ?? 'notification_general_title',
      bodyKey: data['bodyKey'] as String? ?? 'notification_general_body',
      bodyArgs: Map<String, String>.from(
        (data['bodyArgs'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      ),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _parseDate(data['createdAt']),
    );
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      audience: NotificationAudience.fromRoleName(
        json['audience'] as String? ?? json['userId'] as String?,
      ),
      type: AppNotificationTypeX.fromString(json['type'] as String?),
      titleKey: json['titleKey'] as String? ?? 'notification_general_title',
      bodyKey: json['bodyKey'] as String? ?? 'notification_general_body',
      bodyArgs: Map<String, String>.from(
        (json['bodyArgs'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      ),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'audience': audience.storageId,
        'type': type.firestoreValue,
        'titleKey': titleKey,
        'bodyKey': bodyKey,
        'bodyArgs': bodyArgs,
        'isRead': isRead,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'audience': audience.storageId,
        'type': type.firestoreValue,
        'titleKey': titleKey,
        'bodyKey': bodyKey,
        'bodyArgs': bodyArgs,
        'isRead': isRead,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  AppNotificationModel copyWith({bool? isRead}) {
    return AppNotificationModel(
      id: id,
      userId: userId,
      audience: audience,
      type: type,
      titleKey: titleKey,
      bodyKey: bodyKey,
      bodyArgs: bodyArgs,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
