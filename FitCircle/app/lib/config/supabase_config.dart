// lib/config/supabase_config.dart
// FitCircle — Supabase client singleton
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static String get url     => dotenv.env['SUPABASE_URL']      ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Call once in main() before runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url:    url,
      anonKey: anonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  /// Convenience accessor for the Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  /// Current authenticated user (null if logged out)
  static User? get currentUser => client.auth.currentUser;
}
