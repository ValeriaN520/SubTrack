import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  
  static const String supabaseUrl = 'https://lonaqmlqnxdimbrposgs.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_RLyzT0FxYehu7BeQfKvKXA_7LTQJ2G8';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}