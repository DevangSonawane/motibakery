class SupabaseConfig {
  const SupabaseConfig._({required this.url, required this.anonKey});

  factory SupabaseConfig.fromEnvironment() {
    return const SupabaseConfig._(
      url: String.fromEnvironment('SUPABASE_URL'),
      anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  final String url;
  final String anonKey;

  bool get isConfigured {
    return url.isNotEmpty &&
        anonKey.isNotEmpty &&
        !_looksLikePlaceholder(url) &&
        !_looksLikePlaceholder(anonKey);
  }

  static bool _looksLikePlaceholder(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.contains('your-project-id') ||
        normalized.contains('your_publishable_or_anon_key') ||
        normalized.contains('replace_me');
  }
}
