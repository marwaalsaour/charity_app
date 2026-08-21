import 'dart:io';

import '../../../profile/data/models/wallet_currencies.dart';

enum BenefitRequestKind { patient, orphan, school, university }

/// How the beneficiary wants to receive a fully funded amount.
enum PayoutPreference {
  unset,
  wallet,
  associationCenter;

  String get storageValue => switch (this) {
        PayoutPreference.unset => 'unset',
        PayoutPreference.wallet => 'wallet',
        PayoutPreference.associationCenter => 'association_center',
      };

  static PayoutPreference fromString(String? value) {
    return switch (value) {
      'wallet' => PayoutPreference.wallet,
      'association_center' ||
      'associationCenter' ||
      'center' =>
        PayoutPreference.associationCenter,
      _ => PayoutPreference.unset,
    };
  }
}

class BenefitRequestSubmitParams {
  final BenefitRequestKind kind;
  final String fullName;
  final String nationalId;
  final int governorateId;
  final int regionId;
  final String description;

  /// Patient only: true = use logged-in user contact.
  final bool isSelf;
  final String? phone;
  final String? email;
  final double? requiredAmount;
  final String currency;

  /// School / university
  final String? academicGrade;
  final String? schoolName;
  final String? academicYear;
  final String? universityName;
  final String? supportType; // laptopsupport | tuitionassistance

  /// When true, donors may see the beneficiary real name on the case card.
  final bool showBeneficiaryName;

  /// Required files by kind
  final File? medicalReport;
  final File? nationalIdDocument;
  final File? familyBooklet;
  final File? fatherDeathCertificate;
  final File? familyBookPhoto;
  final File? universityIdPhoto;

  const BenefitRequestSubmitParams({
    required this.kind,
    required this.fullName,
    required this.nationalId,
    required this.governorateId,
    required this.regionId,
    required this.description,
    this.isSelf = true,
    this.phone,
    this.email,
    this.requiredAmount,
    this.currency = 'USD',
    this.academicGrade,
    this.schoolName,
    this.academicYear,
    this.universityName,
    this.supportType,
    this.showBeneficiaryName = false,
    this.medicalReport,
    this.nationalIdDocument,
    this.familyBooklet,
    this.fatherDeathCertificate,
    this.familyBookPhoto,
    this.universityIdPhoto,
  });
}

class BenefitRequestItem {
  final int id;
  final String requestType;
  final String status;
  final String? title;
  final String? description;
  final DateTime createdAt;
  final String? beneficiaryName;
  final bool showBeneficiaryName;
  final double requiredAmount;
  final double donatedAmount;
  final int donorsCount;
  final String currency;
  final PayoutPreference payoutPreference;

  const BenefitRequestItem({
    required this.id,
    required this.requestType,
    required this.status,
    required this.createdAt,
    this.title,
    this.description,
    this.beneficiaryName,
    this.showBeneficiaryName = false,
    this.requiredAmount = 0,
    this.donatedAmount = 0,
    this.donorsCount = 0,
    this.currency = 'USD',
    this.payoutPreference = PayoutPreference.unset,
  });

  bool get isApproved {
    final s = status.trim().toLowerCase();
    return s == 'accepted' || s == 'approved' || s == 'published';
  }

  bool get isRejected {
    final s = status.trim().toLowerCase();
    return s == 'rejected' ||
        s == 'declined' ||
        s == 'refused' ||
        s == 'denied' ||
        s == 'refuse' ||
        s == 'reject';
  }

  bool get isPending => !isApproved && !isRejected;

  bool get isPublished => isApproved;

  bool get hasFundingTarget => requiredAmount > 0;

  double get progress =>
      requiredAmount > 0 ? (donatedAmount / requiredAmount).clamp(0.0, 1.0) : 0.0;

  int get progressPercent => (progress * 100).round();

  bool get isFullyFunded =>
      requiredAmount > 0 && donatedAmount >= requiredAmount;

  bool get needsPayoutChoice =>
      isFullyFunded && payoutPreference == PayoutPreference.unset;

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    if (beneficiaryName != null && beneficiaryName!.trim().isNotEmpty) {
      return beneficiaryName!.trim();
    }
    return requestType;
  }

  BenefitRequestItem copyWith({
    int? id,
    String? requestType,
    String? status,
    String? title,
    String? description,
    DateTime? createdAt,
    String? beneficiaryName,
    bool? showBeneficiaryName,
    double? requiredAmount,
    double? donatedAmount,
    int? donorsCount,
    String? currency,
    PayoutPreference? payoutPreference,
  }) {
    return BenefitRequestItem(
      id: id ?? this.id,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      showBeneficiaryName: showBeneficiaryName ?? this.showBeneficiaryName,
      requiredAmount: requiredAmount ?? this.requiredAmount,
      donatedAmount: donatedAmount ?? this.donatedAmount,
      donorsCount: donorsCount ?? this.donorsCount,
      currency: currency ?? this.currency,
      payoutPreference: payoutPreference ?? this.payoutPreference,
    );
  }

  BenefitRequestItem mergeFundingFrom(BenefitRequestItem other) {
    return copyWith(
      status: isApproved || isRejected ? status : other.status,
      title: (title != null && title!.trim().isNotEmpty) ? title : other.title,
      description: (description != null && description!.trim().isNotEmpty)
          ? description
          : other.description,
      beneficiaryName:
          (beneficiaryName != null && beneficiaryName!.trim().isNotEmpty)
              ? beneficiaryName
              : other.beneficiaryName,
      showBeneficiaryName: showBeneficiaryName || other.showBeneficiaryName,
      requiredAmount:
          requiredAmount > 0 ? requiredAmount : other.requiredAmount,
      donatedAmount:
          donatedAmount >= other.donatedAmount ? donatedAmount : other.donatedAmount,
      donorsCount:
          donorsCount >= other.donorsCount ? donorsCount : other.donorsCount,
      currency: other.currency.isNotEmpty ? other.currency : currency,
    );
  }

  factory BenefitRequestItem.fromJson(Map<String, dynamic> json) {
    final nestedPatient = json['patient'];
    final nestedOrphan = json['orphan'];
    final nestedSchool = json['school_student'] ?? json['schoolStudent'];
    final nestedUni = json['university_student'] ?? json['universityStudent'];

    final requiredAmount = _toDouble(
          json['required_amount'] ??
              json['amount'] ??
              json['goal'] ??
              (nestedPatient is Map ? nestedPatient['required_amount'] : null) ??
              (nestedOrphan is Map ? nestedOrphan['required_amount'] : null) ??
              (nestedSchool is Map ? nestedSchool['required_amount'] : null) ??
              (nestedUni is Map ? nestedUni['required_amount'] : null),
        ) ??
        0;
    final donatedAmount = _toDouble(
          json['donated_amount'] ?? json['raised'] ?? json['collected_amount'],
        ) ??
        0;
    final donorsCount = _toInt(json['donors_count']) ??
        _toInt(json['donations_count']) ??
        (json['donations'] is List ? (json['donations'] as List).length : 0);

    final currencyRaw = json['currency']?.toString().trim();
    final currency = WalletCurrencies.normalizeCode(currencyRaw) ?? 'USD';
    final name = extractBeneficiaryName(json);
    final showName = parseShowBeneficiaryName(json);

    return BenefitRequestItem(
      id: _toInt(json['id']) ??
          _toInt(json['request_id']) ??
          _toInt(json['request'] is Map ? json['request']['id'] : null) ??
          0,
      requestType: json['request_type']?.toString() ?? '',
      status: normalizeStatus(json),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(
            (json['created_at']?.toString() ?? '').replaceFirst(' ', 'T'),
          ) ??
          DateTime.now(),
      beneficiaryName: name,
      showBeneficiaryName: showName,
      requiredAmount: requiredAmount,
      donatedAmount: donatedAmount,
      donorsCount: donorsCount,
      currency: currency,
      payoutPreference: PayoutPreference.fromString(
        json['payout_preference']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'request_type': requestType,
        'status': status,
        'title': title,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'full_name': beneficiaryName,
        'beneficiary_name': beneficiaryName,
        'beneficiary_public_name': showBeneficiaryName ? beneficiaryName : null,
        'show_beneficiary_name': showBeneficiaryName,
        'beneficiary': {'full_name': beneficiaryName},
        'required_amount': requiredAmount,
        'donated_amount': donatedAmount,
        'donors_count': donorsCount,
        'currency': currency,
        'payout_preference': payoutPreference.storageValue,
      };

  static String? extractBeneficiaryName(Map json) {
    return extractSubmittedName(json) ?? extractProfileName(json);
  }

  /// Name typed on the assistance form / returned by the public cases API.
  /// Does not use the logged-in user profile (`beneficiary` / `user`).
  static String? extractSubmittedName(Map json) {
    final map = normalizeCaseJson(json);
    String? pick(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
        return null;
      }
      return text;
    }

    String? fromRecord(dynamic record) {
      if (record is! Map) return null;
      return pick(record['full_name']) ??
          pick(record['beneficiary_public_name']) ??
          pick(record['beneficiary_name']) ??
          pick(record['name']);
    }

    return pick(map['beneficiary_public_name']) ??
        pick(map['public_full_name']) ??
        pick(map['displayed_name']) ??
        pick(map['display_name']) ??
        pick(map['visible_name']) ??
        pick(map['beneficiary_name']) ??
        pick(map['beneficiaryName']) ??
        pick(map['full_name']) ??
        pick(map['child_name']) ??
        pick(map['student_name']) ??
        pick(map['patient_name']) ??
        fromRecord(map['patient']) ??
        fromRecord(map['orphan']) ??
        fromRecord(map['school_student'] ?? map['schoolStudent']) ??
        fromRecord(map['university_student'] ?? map['universityStudent']) ??
        fromRecord(map['request']) ??
        extractProfileName(map);
  }

  /// Public open-accepted APIs already decide which name is visible.
  static Map<String, dynamic> normalizeCaseJson(Map json) {
    final map = Map<String, dynamic>.from(json);
    for (final key in const [
      'request',
      'case',
      'assistance_request',
      'patient',
      'orphan',
      'school_student',
      'schoolStudent',
      'university_student',
      'universityStudent',
    ]) {
      final nested = map[key];
      if (nested is! Map) continue;
      nested.forEach((k, v) {
        map.putIfAbsent(k.toString(), () => v);
      });
    }
    return map;
  }

  static String? extractProfileName(Map json) {
    String? pick(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
        return null;
      }
      return text;
    }

    String? fromPerson(dynamic person) {
      if (person is! Map) return null;
      return pick(person['full_name']) ??
          pick(person['name']) ??
          pick(person['beneficiary_name']) ??
          () {
            final first = pick(person['first_name']);
            final last = pick(person['last_name']);
            if (first == null && last == null) return null;
            return [first, last].whereType<String>().join(' ').trim();
          }();
    }

    return fromPerson(json['beneficiary']) ?? fromPerson(json['user']);
  }

  static bool parseShowBeneficiaryName(Map json) {
    bool flag(dynamic value) => parseBool(value);

    if (flag(json['show_beneficiary_name']) ||
        flag(json['showBeneficiaryName']) ||
        flag(json['show_name']) ||
        flag(json['display_name_consent']) ||
        flag(json['is_name_public'])) {
      return true;
    }

    for (final key in const [
      'patient',
      'orphan',
      'school_student',
      'schoolStudent',
      'university_student',
      'universityStudent',
    ]) {
      final nested = json[key];
      if (nested is Map &&
          (flag(nested['show_beneficiary_name']) ||
              flag(nested['show_name']))) {
        return true;
      }
    }

    // Public cases APIs already omit the name when consent is false.
    return extractSubmittedName(json) != null;
  }

  static bool parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes';
    }
    return false;
  }

  static String normalizeStatus(Map json) {
    final tokens = <dynamic>[];
    _collectStatusTokens(json, tokens, 0);

    if (_hasRejectionMarker(json, 0)) return 'rejected';

    var sawAccepted = parseBool(json['is_accepted']) ||
        parseBool(json['accepted']) ||
        parseBool(json['is_approved']) ||
        parseBool(json['approved']);
    var sawClosed = false;

    for (final token in tokens) {
      final mapped = _mapStatusToken(token);
      if (mapped == 'rejected') return 'rejected';
      if (mapped == 'accepted') sawAccepted = true;
      if (mapped == 'closed') sawClosed = true;
    }

    if (sawAccepted) return 'accepted';
    if (sawClosed) return 'rejected';
    return 'pending';
  }

  static void _collectStatusTokens(
    dynamic node,
    List<dynamic> tokens,
    int depth,
  ) {
    if (depth > 4 || node == null) return;
    if (node is Map) {
      node.forEach((key, value) {
        final k = key.toString().toLowerCase();
        if (k.contains('donation') ||
            k.contains('notif') ||
            k.contains('comment') ||
            k.contains('message')) {
          return;
        }
        if (k.contains('status') ||
            k.contains('decision') ||
            k.contains('approval') ||
            k.contains('accept') ||
            k.contains('reject') ||
            k == 'state') {
          tokens.add(value);
        }
        if (value is Map || value is List) {
          _collectStatusTokens(value, tokens, depth + 1);
        }
      });
      return;
    }
    if (node is List) {
      for (final item in node.take(20)) {
        _collectStatusTokens(item, tokens, depth + 1);
      }
    }
  }

  static bool _hasRejectionMarker(dynamic node, int depth) {
    if (depth > 4 || node is! Map) return false;
    for (final entry in node.entries) {
      final key = entry.key.toString().toLowerCase();
      final value = entry.value;
      if (key.contains('reject') ||
          key.contains('declin') ||
          key.contains('رفض')) {
        if (_isPresentMarker(value)) return true;
      }
      if (value is Map && _hasRejectionMarker(value, depth + 1)) return true;
    }
    return parseBool(node['is_rejected']) || parseBool(node['rejected']);
  }

  static bool _isPresentMarker(dynamic value) {
    if (value == null || value == false || value == 0) return false;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v.isNotEmpty &&
          v != '0' &&
          v != 'false' &&
          v != 'null' &&
          v != 'pending';
    }
    return true;
  }

  static String? _mapStatusToken(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      return _mapStatusToken(
        raw['name'] ??
            raw['value'] ??
            raw['label'] ??
            raw['status'] ??
            raw['en'] ??
            raw['ar'] ??
            raw['key'],
      );
    }
    if (raw is num) {
      return switch (raw.toInt()) {
        0 => 'pending',
        1 => 'accepted',
        2 => 'rejected',
        3 => 'accepted',
        _ => null,
      };
    }
    var text = raw.toString().trim().toLowerCase();
    if (text.isEmpty || text == 'null') return null;
    text = text.replaceAll('-', '_').replaceAll(' ', '_');
    if (text == '0') return 'pending';
    if (text == '1') return 'accepted';
    if (text == '2') return 'rejected';
    if (text.contains('reject') ||
        text.contains('declin') ||
        text.contains('refus') ||
        text.contains('denied') ||
        text.contains('not_accepted') ||
        text.contains('unaccepted') ||
        text.contains('مرفوض') ||
        text.contains('رفض')) {
      return 'rejected';
    }
    if (text == 'accepted' ||
        text == 'approved' ||
        text == 'published' ||
        text == 'accept' ||
        text == 'approve' ||
        text.contains('موافق')) {
      return 'accepted';
    }
    if (text == 'close' ||
        text == 'closed' ||
        text == 'cancelled' ||
        text == 'canceled') {
      return 'closed';
    }
    if (text == 'pending' ||
        text == 'waiting' ||
        text == 'review' ||
        text == 'under_review' ||
        text == 'in_review') {
      return 'pending';
    }
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim());
    }
    return null;
  }
}
