class OrphanSponsorship {
  final String id;
  final int? requestId;
  final int? orphanId;
  final String childName;
  final double monthlyAmount;
  final String currency;
  final int totalMonths;
  final int paidMonths;
  final DateTime startedAt;
  final DateTime nextChargeAt;
  final String status;
  final bool needsDecision;

  const OrphanSponsorship({
    required this.id,
    this.requestId,
    this.orphanId,
    required this.childName,
    required this.monthlyAmount,
    required this.currency,
    this.totalMonths = 0,
    this.paidMonths = 0,
    required this.startedAt,
    required this.nextChargeAt,
    this.status = 'active',
    this.needsDecision = false,
  });

  bool get isActive => status == 'active';

  bool get isComplete =>
      status == 'completed' || (totalMonths > 0 && paidMonths >= totalMonths);

  int get apiOrphanId => orphanId ?? (int.tryParse(id) ?? 0);

  factory OrphanSponsorship.fromJson(Map<String, dynamic> json) {
    return OrphanSponsorship(
      id: json['id']?.toString() ?? '',
      requestId: _toInt(json['requestId'] ?? json['request_id']),
      orphanId: _toInt(json['orphanId'] ?? json['orphan_id'] ?? json['id']),
      childName:
          json['childName']?.toString() ?? json['child_name']?.toString() ?? '',
      monthlyAmount: _readDouble(
        json['monthlyAmount'] ?? json['sponsorship_amount'],
      ),
      currency: json['currency']?.toString() ?? 'USD',
      totalMonths: (_toInt(json['totalMonths']) ?? 0),
      paidMonths: (_toInt(json['paidMonths']) ?? 0),
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.tryParse(json['sponsored_at']?.toString() ?? '') ??
          DateTime.now(),
      nextChargeAt:
          DateTime.tryParse(json['nextChargeAt']?.toString() ?? '') ??
          DateTime.tryParse(
            json['next_monthly_deduction_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'active',
      needsDecision: json['needsDecision'] == true,
    );
  }

  factory OrphanSponsorship.fromApi(Map<String, dynamic> json) {
    final request = json['request'] is Map
        ? Map<String, dynamic>.from(json['request'] as Map)
        : const <String, dynamic>{};
    final beneficiary = request['beneficiary'] is Map
        ? Map<String, dynamic>.from(request['beneficiary'] as Map)
        : const <String, dynamic>{};

    final orphanId = _toInt(json['id']) ?? 0;
    final donations = json['donations'];
    final paid = donations is List ? donations.length : 0;

    final name = _firstNonEmpty([
      request['title']?.toString(),
      beneficiary['full_name']?.toString(),
      json['child_name']?.toString(),
    ]);

    final amount = _readDouble(
      json['sponsorship_amount'] ?? request['required_amount'],
    );

    return OrphanSponsorship(
      id: '$orphanId',
      orphanId: orphanId,
      requestId: _toInt(json['request_id'] ?? request['id']),
      childName: name,
      monthlyAmount: amount,
      currency: 'USD',
      paidMonths: paid,
      startedAt:
          DateTime.tryParse(json['sponsored_at']?.toString() ?? '') ??
          DateTime.now(),
      nextChargeAt:
          DateTime.tryParse(
            json['next_monthly_deduction_at']?.toString() ?? '',
          ) ??
          DateTime.tryParse(json['next_monthly_deduction']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      status: json['is_sponsored'] == false ? 'cancelled' : 'active',
    );
  }

  factory OrphanSponsorship.fromInfoApi(
    Map<String, dynamic> json, {
    required int orphanId,
  }) {
    return OrphanSponsorship(
      id: '$orphanId',
      orphanId: orphanId,
      childName: _firstNonEmpty([
        json['child_name']?.toString(),
        json['orphan_name']?.toString(),
      ]),
      monthlyAmount: _readDouble(json['sponsorship_amount']),
      currency: 'USD',
      startedAt:
          DateTime.tryParse(json['sponsored_at']?.toString() ?? '') ??
          DateTime.now(),
      nextChargeAt:
          DateTime.tryParse(json['next_monthly_deduction']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      status: json['is_sponsored'] == false ? 'cancelled' : 'active',
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'requestId': requestId,
    'orphanId': orphanId,
    'childName': childName,
    'monthlyAmount': monthlyAmount,
    'currency': currency,
    'totalMonths': totalMonths,
    'paidMonths': paidMonths,
    'startedAt': startedAt.toIso8601String(),
    'nextChargeAt': nextChargeAt.toIso8601String(),
    'status': status,
    'needsDecision': needsDecision,
  };

  OrphanSponsorship copyWith({
    double? monthlyAmount,
    String? currency,
    int? totalMonths,
    int? paidMonths,
    DateTime? nextChargeAt,
    String? status,
    bool? needsDecision,
    String? childName,
  }) {
    return OrphanSponsorship(
      id: id,
      requestId: requestId,
      orphanId: orphanId,
      childName: childName ?? this.childName,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      currency: currency ?? this.currency,
      totalMonths: totalMonths ?? this.totalMonths,
      paidMonths: paidMonths ?? this.paidMonths,
      startedAt: startedAt,
      nextChargeAt: nextChargeAt ?? this.nextChargeAt,
      status: status ?? this.status,
      needsDecision: needsDecision ?? this.needsDecision,
    );
  }
}
