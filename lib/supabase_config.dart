import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase Project Configuration
  static const String supabaseUrl = 'https://iqrdctnlggmkjokuzggi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxcmRjdG5sZ2dta2pva3V6Z2dpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4Mjk0ODQsImV4cCI6MjA3NTQwNTQ4NH0.yGipp4amQABjf4EYYUT3fcEfQNIM44j9vEx-GKcY16Q';
  
  // Supabase Client Instance
  static SupabaseClient? _client;
  
  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }
  
  /// Get Supabase Client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseConfig.initialize() first.');
    }
    return _client!;
  }
  
  /// Check if Supabase is initialized
  static bool get isInitialized => _client != null;
  
  /// Get current user from Supabase
  static User? get currentUser => _client?.auth.currentUser;
  
  /// Get current session from Supabase
  static Session? get currentSession => _client?.auth.currentSession;
  
  /// Sign out from Supabase
  static Future<void> signOut() async {
    await _client?.auth.signOut();
  }
  
  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client!.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// Sign up with email and password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client!.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  /// Get Supabase Database
  static SupabaseQueryBuilder from(String table) {
    return _client!.from(table);
  }
  
  /// Get Supabase Storage
  static SupabaseStorageClient get storage => _client!.storage;
  
  /// Get Supabase Realtime
  static RealtimeClient get realtime => _client!.realtime;
}


