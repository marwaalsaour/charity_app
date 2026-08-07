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

  const DonationCheckoutArgs({
    required this.causeTitle,
    this.targetType = DonationTargetType.association,
    this.targetId,
  });
}
