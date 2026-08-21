class TransparencyDocument {
  const TransparencyDocument({
    this.year,
    this.period,
    this.summary,
    this.summaryAr,
    this.summaryEn,
    this.fileUrl,
  });

  final String? year;
  final String? period;
  final String? summary;
  final String? summaryAr;
  final String? summaryEn;
  final String? fileUrl;

  bool get hasFile => fileUrl != null && fileUrl!.trim().isNotEmpty;

  String? localizedSummary(bool isArabic) {
    final specific = isArabic ? summaryAr : summaryEn;
    final value = specific?.trim();
    if (value != null && value.isNotEmpty) return value;
    return null;
  }
}

class TransparencyStats {
  const TransparencyStats({
    required this.totalDonations,
    required this.currency,
    required this.beneficiaries,
    required this.volunteers,
    required this.campaigns,
    this.updatedAt,
  });

  final double totalDonations;
  final String currency;
  final int beneficiaries;
  final int volunteers;
  final int campaigns;
  final DateTime? updatedAt;

  static const empty = TransparencyStats(
    totalDonations: 0,
    currency: 'USD',
    beneficiaries: 0,
    volunteers: 0,
    campaigns: 0,
  );

  TransparencyStats copyWith({
    double? totalDonations,
    String? currency,
    int? beneficiaries,
    int? volunteers,
    int? campaigns,
    DateTime? updatedAt,
  }) {
    return TransparencyStats(
      totalDonations: totalDonations ?? this.totalDonations,
      currency: currency ?? this.currency,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      volunteers: volunteers ?? this.volunteers,
      campaigns: campaigns ?? this.campaigns,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TransparencyData {
  const TransparencyData({
    required this.stats,
    required this.annualReport,
    required this.financialReport,
    this.policyBody,
    this.policyBodyAr,
    this.policyBodyEn,
    this.verificationBody,
    this.verificationBodyAr,
    this.verificationBodyEn,
  });

  final TransparencyStats stats;
  final TransparencyDocument annualReport;
  final TransparencyDocument financialReport;
  final String? policyBody;
  final String? policyBodyAr;
  final String? policyBodyEn;
  final String? verificationBody;
  final String? verificationBodyAr;
  final String? verificationBodyEn;

  static const empty = TransparencyData(
    stats: TransparencyStats.empty,
    annualReport: TransparencyDocument(),
    financialReport: TransparencyDocument(),
  );

  String? localizedPolicy(bool isArabic) {
    final specific = isArabic ? policyBodyAr : policyBodyEn;
    final value = specific?.trim();
    if (value != null && value.isNotEmpty) return value;
    return null;
  }

  String? localizedVerification(bool isArabic) {
    final specific = isArabic ? verificationBodyAr : verificationBodyEn;
    final value = specific?.trim();
    if (value != null && value.isNotEmpty) return value;
    return null;
  }

  TransparencyData copyWith({
    TransparencyStats? stats,
    TransparencyDocument? annualReport,
    TransparencyDocument? financialReport,
    String? policyBody,
    String? policyBodyAr,
    String? policyBodyEn,
    String? verificationBody,
    String? verificationBodyAr,
    String? verificationBodyEn,
  }) {
    return TransparencyData(
      stats: stats ?? this.stats,
      annualReport: annualReport ?? this.annualReport,
      financialReport: financialReport ?? this.financialReport,
      policyBody: policyBody ?? this.policyBody,
      policyBodyAr: policyBodyAr ?? this.policyBodyAr,
      policyBodyEn: policyBodyEn ?? this.policyBodyEn,
      verificationBody: verificationBody ?? this.verificationBody,
      verificationBodyAr: verificationBodyAr ?? this.verificationBodyAr,
      verificationBodyEn: verificationBodyEn ?? this.verificationBodyEn,
    );
  }
}
