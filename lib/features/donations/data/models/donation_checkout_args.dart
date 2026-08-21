enum DonationTargetType {
  /// POST /quickDonate — association / admin wallet
  association,

  /// POST /donate/campaign/{id}
  campaign,

  /// POST /donate/request/{id}
  request,
}

class DonationCheckoutArgs {
  final String causeTitle;
  final DonationTargetType targetType;
  final int? targetId;

  /// Currency the case was requested in. Donations in other currencies
  /// are converted to this when checking whether the goal is complete.
  final String? caseCurrency;

  /// Recurring monthly orphan sponsorship instead of a one-time gift.
  final bool isOrphanSponsorship;

  /// Laravel orphan row id for POST /orphanssponsor/{orphan_id}.
  final int? orphanId;

  /// Chosen sponsorship duration in months.
  final int? totalMonths;

  const DonationCheckoutArgs({
    required this.causeTitle,
    this.targetType = DonationTargetType.association,
    this.targetId,
    this.caseCurrency,
    this.isOrphanSponsorship = false,
    this.orphanId,
    this.totalMonths,
  });

  DonationCheckoutArgs copyWith({
    String? causeTitle,
    DonationTargetType? targetType,
    int? targetId,
    String? caseCurrency,
    bool? isOrphanSponsorship,
    int? orphanId,
    int? totalMonths,
  }) {
    return DonationCheckoutArgs(
      causeTitle: causeTitle ?? this.causeTitle,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      caseCurrency: caseCurrency ?? this.caseCurrency,
      isOrphanSponsorship: isOrphanSponsorship ?? this.isOrphanSponsorship,
      orphanId: orphanId ?? this.orphanId,
      totalMonths: totalMonths ?? this.totalMonths,
    );
  }
}
