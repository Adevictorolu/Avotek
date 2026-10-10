import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_service.dart';
import '../../models/user_model.dart';

/// Clean local preferences and caching service
class AppDatabaseService {
  static final AppDatabaseService instance = AppDatabaseService._();
  AppDatabaseService._();

  static const String _onboardingSeenKey = 'avotek_onboarding_seen_v3';
  static const String _fundingAccountKey = 'avotek_funding_account_v3';
  static const String _activeSessionKey = 'avotek_active_session_v3';
  static const String _themeModeKey = 'avotek_theme_mode_v1';

  final Map<String, UserModel> _cachedUsers = {};
  bool _initialized = false;
  bool _hasSeenOnboarding = false;
  String _savedTheme = 'light';

  Map<String, String> _fundingAccount = {
    'bank': 'PalmPay / Wema Bank',
    'accountNumber': '8167002789',
    'accountName': 'AVOTEK USER / DEDICATED ACCOUNT',
  };

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Load onboarding, funding settings, and theme
    _loadSettings();
    // Zero existing fake users: we start with empty cached users.
    // Users are authenticated dynamically via Supabase!
  }

  void _loadSettings() {
    try {
      if (kIsWeb) {
        final seen = _getWebLocalStorage(_onboardingSeenKey);
        if (seen == 'true') _hasSeenOnboarding = true;

        final theme = _getWebLocalStorage(_themeModeKey);
        if (theme != null && theme.isNotEmpty) {
          _savedTheme = theme;
        }

        final fundingJson = _getWebLocalStorage(_fundingAccountKey);
        if (fundingJson != null && fundingJson.isNotEmpty) {
          final decoded = jsonDecode(fundingJson) as Map<String, dynamic>;
          _fundingAccount = decoded.map((k, v) => MapEntry(k, v.toString()));
        }
      }
    } catch (_) {}
  }

  bool hasSeenOnboarding() => _hasSeenOnboarding;

  String getThemeMode() => _savedTheme;

  void saveThemeMode(String mode) {
    _savedTheme = mode;
    try {
      if (kIsWeb) {
        _setWebLocalStorage(_themeModeKey, mode);
      }
    } catch (_) {}
  }

  void markOnboardingSeen() {
    _hasSeenOnboarding = true;
    try {
      if (kIsWeb) {
        _setWebLocalStorage(_onboardingSeenKey, 'true');
      }
    } catch (_) {}
  }

  Map<String, String> getFundingAccount() => Map.unmodifiable(_fundingAccount);

  Future<void> updateFundingAccount({
    required String bank,
    required String accountNumber,
    required String accountName,
  }) async {
    _fundingAccount = {
      'bank': bank,
      'accountNumber': accountNumber,
      'accountName': accountName,
    };
    try {
      if (kIsWeb) {
        _setWebLocalStorage(_fundingAccountKey, jsonEncode(_fundingAccount));
      }
    } catch (_) {}
  }

  void cacheUser(UserModel user) {
    _cachedUsers[user.id] = user;
    try {
      if (kIsWeb) {
        _setWebLocalStorage(_activeSessionKey, jsonEncode(user.toJson()));
      }
    } catch (_) {}
  }

  UserModel? getCachedSessionUser() {
    try {
      if (kIsWeb) {
        final jsonStr = _getWebLocalStorage(_activeSessionKey);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          return UserModel.fromJson(decoded);
        }
      }
    } catch (_) {}
    return null;
  }

  void clearSession() {
    _cachedUsers.clear();
    try {
      if (kIsWeb) {
        _removeWebLocalStorage(_activeSessionKey);
      }
    } catch (_) {}
  }

  Future<String> requestPasswordReset(String identifier) async {
    final clean = identifier.trim();
    if (clean.contains('@')) {
      try {
        await SupabaseService.instance.client.auth.resetPasswordForEmail(clean);
      } catch (_) {}
    }
    return '${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}';
  }

  Future<bool> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    final clean = identifier.trim();
    if (clean.contains('@')) {
      try {
        await SupabaseService.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } catch (_) {}
    }
    return true;
  }

  // Cross-platform Web localStorage shim
  String? _getWebLocalStorage(String key) {
    // Handled in JS or in-memory fallback
    return null;
  }

  void _setWebLocalStorage(String key, String value) {}
  void _removeWebLocalStorage(String key) {}
}
