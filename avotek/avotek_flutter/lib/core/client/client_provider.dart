import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_service.dart';

class ClientProvider {
  static SupabaseClient get client => SupabaseService.instance.client;
  static Future<void> initialize() async => await SupabaseService.instance.initialize();
}
