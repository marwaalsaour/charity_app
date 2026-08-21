class OrphanSponsorship {
  final String id;
  final int? requestId;
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
    required this.childName,
    required this.monthlyAmount,
    required this.currency,
    required this.totalMonths,
    required this.paidMonths,
    required this.startedAt,
    required this.nextChargeAt,
    this.status = 'active',
    this.needsDecision = false,
  });

  bool get isActive => status == 'active';

  bool get isComplete => paidMonths >= totalMonths || status == 'completed';

  factory OrphanSponsorship.fromJson(Map<String, dynamic> json) {
    return OrphanSponsorship(
      id: json['id']?.toString() ?? '',
      requestId: json['requestId'] is int
          ? json['requestId'] as int
          : int.tryParse(json['requestId']?.toString() ?? ''),
      childName: json['childName']?.toString() ?? '',
      monthlyAmount: _readDouble(json['monthlyAmount']),
      currency: json['currency']?.toString() ?? 'USD',
      totalMonths: (json['totalMonths'] as num?)?.toInt() ?? 1,
      paidMonths: (json['paidMonths'] as num?)?.toInt() ?? 0,
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      nextChargeAt:
          DateTime.tryParse(json['nextChargeAt']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'active',
      needsDecision: json['needsDecision'] == true,
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'requestId': requestId,
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
    int? paidMonths,
    DateTime? nextChargeAt,
    String? status,
    bool? needsDecision,
  }) {
    return OrphanSponsorship(
      id: id,
      requestId: requestId,
      childName: childName,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      currency: currency,
      totalMonths: totalMonths,
      paidMonths: paidMonths ?? this.paidMonths,
      startedAt: startedAt,
      nextChargeAt: nextChargeAt ?? this.nextChargeAt,
      status: status ?? this.status,
      needsDecision: needsDecision ?? this.needsDecision,
    );
  }
}
