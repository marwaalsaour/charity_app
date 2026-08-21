class AuthPhone {
  static const countryCode = '+963';

  /// 9-digit Syrian mobile without leading 0 or country code, e.g. 912345678.
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

  /// Canonical E.164 form used for signup and signin: +9639xxxxxxxx
  static String normalize(String raw) {
    final local = localNine(raw);
    if (local.isEmpty) return raw.trim();
    return '$countryCode$local';
  }

  /// Formats to try when the API stored the number differently.
  static List<String> loginCandidates(String raw) {
    final local = localNine(raw);
    if (local.isEmpty) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? const [] : [trimmed];
    }
    return [
      '$countryCode$local',
      local,
    ];
  }
}
