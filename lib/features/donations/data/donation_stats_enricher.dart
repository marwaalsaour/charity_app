import 'dart:math' as math;

import 'case_donation_stats_cache.dart';
import 'models/donation_model.dart';

Future<DonationModel> enrichDonationWithLocalStats(DonationModel donation) async {
  final local = await CaseDonationStatsCache.get(donation.id);
  if (local == null) return donation;
  return donation.copyWith(
    donorsCount: math.max(donation.donorCount, local.donorsCount),
    raised: math.max(donation.raised, local.raised),
    currency: donation.currency.isNotEmpty
        ? donation.currency
        : local.caseCurrency,
  );
}
