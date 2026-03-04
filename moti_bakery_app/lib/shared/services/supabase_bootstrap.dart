import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

enum SupabaseBootstrapStatus { connected, notConfigured, failed }

class SupabaseBootstrapResult {
  const SupabaseBootstrapResult({
    required this.status,
    this.message,
  });

  final SupabaseBootstrapStatus status;
  final String? message;
}

class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static SupabaseBootstrapResult? _result;
  static bool _initialized = false;

  static SupabaseBootstrapResult get result =>
      _result ??
      const SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.notConfigured,
      );

  static Future<SupabaseBootstrapResult> initialize() async {
    if (_result != null) {
      return _result!;
    }

    final config = SupabaseConfig.fromEnvironment();
    if (!config.isConfigured) {
      _result = const SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.notConfigured,
        message:
            'Missing SUPABASE_URL / SUPABASE_ANON_KEY. Running with local mock services.',
      );
      return _result!;
    }

    try {
      await Supabase.initialize(
        url: config.url,
        anonKey: config.anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _result = const SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.connected,
      );
      _initialized = true;
      return _result!;
    } catch (error) {
      _result = SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.failed,
        message: error.toString(),
      );
      return _result!;
    }
  }

  static bool get isReady =>
      _initialized && result.status == SupabaseBootstrapStatus.connected;

  static void logStatus() {
    switch (result.status) {
      case SupabaseBootstrapStatus.connected:
        debugPrint('Supabase initialized successfully.');
      case SupabaseBootstrapStatus.notConfigured:
        debugPrint(result.message);
      case SupabaseBootstrapStatus.failed:
        debugPrint('Supabase initialization failed: ${result.message}');
    }
  }
}
