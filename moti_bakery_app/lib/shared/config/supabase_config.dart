class SupabaseConfig {
  const SupabaseConfig._({required this.url, required this.anonKey});

  factory SupabaseConfig.fromEnvironment() {
    const url = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: String.fromEnvironment(
        'VITE_SUPABASE_URL',
        defaultValue: _reactFallbackUrl,
      ),
    );
    const anonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: String.fromEnvironment(
        'VITE_SUPABASE_ANON_KEY',
        defaultValue: _reactFallbackAnonKey,
      ),
    );
    return const SupabaseConfig._(url: url, anonKey: anonKey);
  }

  // Keep Flutter aligned with the React app defaults, while still allowing
  // `--dart-define` overrides for different environments.
  static const String _reactFallbackUrl = 'https://jygsbebawnkvyaqohxes.supabase.co';
  static const String _reactFallbackAnonKey =
      'sb_publishable_XwEYk8d2ipVNun4PryDBfQ_ZE3EqqKU';

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
