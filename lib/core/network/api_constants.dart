class ApiConstants {
  static const String origin =
      'https://ataa-laravel-api-b5hjgcc2e8bae8fb.polandcentral-01.azurewebsites.net';

  static const String baseUrl = '$origin/api';

  static const String updateFcmToken = '/updateFcmToken';

  /// Converts a Laravel public disk path to a full URL.
  static String? storageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final value = path.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final normalized = value.startsWith('/') ? value.substring(1) : value;
    final withoutStorage = normalized.startsWith('storage/')
        ? normalized.substring('storage/'.length)
        : normalized;
    return '$origin/storage/$withoutStorage';
  }
}
