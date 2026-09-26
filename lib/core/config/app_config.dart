class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://8e3e8cf6-840e-40df-98a8-4cc7333d0c02-00-3ivl0lr9rugt3.janeway.replit.dev/api',
  );

  static bool get isConfigured => apiBaseUrl.trim().isNotEmpty;
}
