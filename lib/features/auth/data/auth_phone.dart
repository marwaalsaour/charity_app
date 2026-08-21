class AuthPhone {
  static const countryCode = '+963';

  /// 9-digit national number without leading 0 or country code, e.g. 123123123.
  static String localNine(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('963')) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > 9) {
      digits = digits.substring(digits.length - 9);
    }
    return digits;
  }

  /// International Syrian number for the API: 963 + 9 local digits.
  /// No "+" — Laravel signup validates `regex:/^[0-9]+$/`.
  static String forApi(String raw) {
    final local = localNine(raw);
    if (local.isEmpty) return digitsOnly(raw);
    return '963$local';
  }

  /// Canonical E.164 form. Prefer [forApi] when talking to this backend.
  static String normalize(String raw) {
    final local = localNine(raw);
    if (local.isEmpty) return raw.trim();
    return '$countryCode$local';
  }

  /// Strips +, spaces, and dashes. Volunteer APIs require digits only.
  static String digitsOnly(String raw) {
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  /// Formats to try when the API stored the number differently.
  static List<String> loginCandidates(String raw) {
    final local = localNine(raw);
    if (local.isEmpty) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? const [] : [trimmed];
    }
    return [
      '963$local',
      local,
      '$countryCode$local',
      '0$local',
    ];
  }
}
