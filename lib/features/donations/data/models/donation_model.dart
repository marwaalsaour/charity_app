import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../profile/data/models/wallet_currencies.dart';
import 'donation_checkout_args.dart';
import 'donation_need_item.dart';

enum DonationCategory { education, medical, orphans }

extension DonationCategoryX on DonationCategory {
  String get titleKey {
    switch (this) {
      case DonationCategory.education:
        return 'education_title';
      case DonationCategory.medical:
        return 'medical_title';
      case DonationCategory.orphans:
        return 'orphans_title';
    }
  }

  IconData get fallbackIcon {
    switch (this) {
      case DonationCategory.education:
        return Icons.school_outlined;
      case DonationCategory.medical:
        return Icons.medical_services_outlined;
      case DonationCategory.orphans:
        return Icons.child_care_outlined;
    }
  }
}

class DonationModel {
  final int id;
  final String nameKey;
  final String titleKey;
  final String descriptionKey;
  final DonationCategory category;
  final double raised;
  final double goal;
  final String image;
  final bool isUrgent;
  final String? techTitleKey;
  final String? techDescKey;
  final List<String> techTagKeys;
  final String? hospitalKey;
  final String? doctorKey;
  final String? storyKey;
  final List<DonationNeedItem> needs;

  /// When false, [nameKey]/[titleKey]/[descriptionKey] are plain display text.
  final bool useTranslationKeys;

  /// Where checkout should send the donation.
  final DonationTargetType donateTargetType;

  /// Real number of donation transactions for this case (when known).
  final int? donorsCount;

  /// Fundraising deadline (from admin, or default 30 days).
  final DateTime? deadlineAt;

  /// True when the beneficiary allowed publishing their real name.
  final bool showBeneficiaryName;

  /// Real beneficiary name when [showBeneficiaryName] is true.
  final String? beneficiaryName;

  /// Governorate / region residence for verification.
  final String? residence;

  /// School or university name (education cases).
  final String? institution;

  /// Currency the case was published in. Same for donor and beneficiary.
  final String currency;

  const DonationModel({
    required this.id,
    required this.nameKey,
    required this.titleKey,
    required this.descriptionKey,
    required this.category,
    required this.raised,
    required this.goal,
    required this.image,
    this.isUrgent = false,
    this.techTitleKey,
    this.techDescKey,
    this.techTagKeys = const [],
    this.hospitalKey,
    this.doctorKey,
    this.storyKey,
    this.needs = const [],
    this.useTranslationKeys = true,
    this.donateTargetType = DonationTargetType.association,
    this.donorsCount,
    this.deadlineAt,
    this.showBeneficiaryName = false,
    this.beneficiaryName,
    this.residence,
    this.institution,
    this.currency = 'USD',
  });

  String get displayCurrency =>
      WalletCurrencies.normalizeCode(currency) ?? 'USD';

  double get progress =>
      goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;

  bool get isFullyFunded => goal > 0 && raised >= goal;

  int get donorCount => donorsCount ?? 0;

  int get daysLeft {
    final end = deadlineAt ?? DateTime.now().add(const Duration(days: 30));
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfEnd = DateTime(end.year, end.month, end.day);
    final days = startOfEnd.difference(startOfToday).inDays;
    return days < 0 ? 0 : days;
  }

  String get cardTitle {
    if (beneficiaryName != null && beneficiaryName!.trim().isNotEmpty) {
      return beneficiaryName!.trim();
    }
    return displayName;
  }

  bool get hasVerificationInfo =>
      (beneficiaryName != null && beneficiaryName!.trim().isNotEmpty) ||
      (residence != null && residence!.trim().isNotEmpty) ||
      (institution != null && institution!.trim().isNotEmpty);

  String formatMoney(double amount, [Locale? locale]) {
    return WalletCurrencies.format(
      amount,
      displayCurrency,
      locale: locale ?? const Locale('en'),
    );
  }

  String formatRaised([Locale? locale]) => formatMoney(raised, locale);

  String formatGoal([Locale? locale]) => formatMoney(goal, locale);

  DonationCheckoutArgs get checkoutArgs => DonationCheckoutArgs(
        causeTitle: cardTitle,
        targetType: donateTargetType,
        targetId: id > 0 ? id : null,
        caseCurrency: displayCurrency,
      );

  DonationCheckoutArgs get sponsorshipCheckoutArgs => checkoutArgs.copyWith(
        isOrphanSponsorship: true,
      );

  DonationModel copyWith({
    int? id,
    String? nameKey,
    String? titleKey,
    String? descriptionKey,
    DonationCategory? category,
    double? raised,
    double? goal,
    String? image,
    bool? isUrgent,
    bool? useTranslationKeys,
    DonationTargetType? donateTargetType,
    int? donorsCount,
    DateTime? deadlineAt,
    bool? showBeneficiaryName,
    String? beneficiaryName,
    String? residence,
    String? institution,
    String? currency,
  }) {
    return DonationModel(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      titleKey: titleKey ?? this.titleKey,
      descriptionKey: descriptionKey ?? this.descriptionKey,
      category: category ?? this.category,
      raised: raised ?? this.raised,
      goal: goal ?? this.goal,
      image: image ?? this.image,
      isUrgent: isUrgent ?? this.isUrgent,
      techTitleKey: techTitleKey,
      techDescKey: techDescKey,
      techTagKeys: techTagKeys,
      hospitalKey: hospitalKey,
      doctorKey: doctorKey,
      storyKey: storyKey,
      needs: needs,
      useTranslationKeys: useTranslationKeys ?? this.useTranslationKeys,
      donateTargetType: donateTargetType ?? this.donateTargetType,
      donorsCount: donorsCount ?? this.donorsCount,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      showBeneficiaryName: showBeneficiaryName ?? this.showBeneficiaryName,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      residence: residence ?? this.residence,
      institution: institution ?? this.institution,
      currency: currency ?? this.currency,
    );
  }

  String get displayName =>
      useTranslationKeys ? nameKey.tr() : nameKey;

  String get displayTitle =>
      useTranslationKeys ? titleKey.tr() : titleKey;

  String get displayDescription =>
      useTranslationKeys ? descriptionKey.tr() : descriptionKey;

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['id'] as int,
      nameKey: json['name_key'] as String,
      titleKey: json['title_key'] as String,
      descriptionKey: json['description_key'] as String,
      category: DonationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => DonationCategory.medical,
      ),
      raised: (json['raised'] as num).toDouble(),
      goal: (json['goal'] as num).toDouble(),
      image: json['image'] as String? ?? '',
      isUrgent: json['is_urgent'] as bool? ?? false,
      currency: WalletCurrencies.normalizeCode(
            json['currency']?.toString(),
          ) ??
          'USD',
    );
  }
}
