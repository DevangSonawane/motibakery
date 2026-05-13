import '../config/supabase_config.dart';

String? resolveProductImageNetworkUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  if (trimmed.startsWith('//')) {
    return 'https:$trimmed';
  }

  final supabaseUrl = SupabaseConfig.fromEnvironment().url.trim();
  if (supabaseUrl.isEmpty) {
    return null;
  }

  if (trimmed.startsWith('/storage/v1/object/')) {
    return '$supabaseUrl$trimmed';
  }

  if (trimmed.startsWith('storage/v1/object/')) {
    return '$supabaseUrl/$trimmed';
  }

  // Accept raw "bucket/path/to/file.jpg" and convert to public storage URL.
  if (trimmed.contains('/') && !trimmed.contains(' ')) {
    return '$supabaseUrl/storage/v1/object/public/$trimmed';
  }

  return null;
}

