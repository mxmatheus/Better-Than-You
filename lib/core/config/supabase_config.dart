import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseConfig {
  static const String defaultUrl = 'https://zlcqkmzwwydjodbzhiyn.supabase.co';
  static const String defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsY3FrbXp3d3lkam9kYnpoaXluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2OTMyNzMsImV4cCI6MjEwMzI2OTI3M30.J6EJtCkyq9dVMQvmeb2b9va_77JzFMusGOoApJdFCMw';

  static String get url => const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: defaultUrl,
      );

  static String get anonKey => const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: defaultAnonKey,
      );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint('[SupabaseConfig] Supabase URL or Anon key is not configured.');
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      if (kDebugMode) {
        debugPrint('[SupabaseConfig] Supabase initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseConfig] Supabase initialization skipped or failed: $e');
      }
    }
  }
}
