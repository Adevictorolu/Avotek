import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../models/wallet_model.dart';
import '../../models/transaction_model.dart';
import '../../models/vtu_models.dart';
import '../../models/notification_preferences.dart';

@visibleForTesting
String buildWebAuthRedirectUrl(Uri currentUri, String route) {
  return Uri(
    scheme: currentUri.scheme,
    userInfo: currentUri.userInfo,
    host: currentUri.host,
    port: currentUri.hasPort ? currentUri.port : null,
    path: currentUri.path,
    fragment: route,
  ).toString();
}

class SupabaseService {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gcixbqrridzgobkqnlfz.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable__KqtFYoV1zOBWx9oQCySBQ_pIbwAEMO',
  );
  static String get supabaseProjectRef =>
      Uri.parse(supabaseUrl).host.split('.').first;

  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  SupabaseClient get client => Supabase.instance.client;
  User? get currentAuthUser => _initialized ? client.auth.currentUser : null;
  Session? get currentSession =>
      _initialized ? client.auth.currentSession : null;

  Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  // Fallback cache if Supabase PostgreSQL tables are pending migration in the SQL editor
  final Map<String, UserModel> _fallbackProfiles = {};
  final Map<String, WalletModel> _fallbackWallets = {};
  final Map<String, List<TransactionModel>> _fallbackTransactions = {};
  final Map<String, List<VtuOrder>> _fallbackOrders = {};

  /// Initialize Supabase with the project URL and Anon Key
  Future<void> initialize() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _initialized = true;
    debugPrint('Supabase successfully initialized.');
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  /// Sign Up with Email and Password
  /// Sign Up with Email and Password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? preferredUsername,
    String? referralCode,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    final username = preferredUsername?.trim() ?? cleanEmail.split('@').first;

    final response = await client.auth.signUp(
      email: cleanEmail,
      password: password,
      emailRedirectTo: _authRedirectUrl('/login-callback'),
      data: {
        'full_name': cleanName,
        'phone': cleanPhone,
        'username': username,
        if (referralCode != null && referralCode.trim().isNotEmpty)
          'referred_by': referralCode.trim().toUpperCase(),
      },
    );

    final authUser = response.user;
    if (authUser == null) {
      throw Exception('Sign up failed: User was not created.');
    }

    final now = DateTime.now();
    final avoId = avotekIdFor(authUser.id);

    final userModel = UserModel(
      id: authUser.id,
      email: cleanEmail,
      name: cleanName,
      phone: cleanPhone,
      referralCode: avoId,
      referredBy: referralCode?.trim().isNotEmpty == true
          ? referralCode!.trim().toUpperCase()
          : null,
      createdAt: now,
      avoId: avoId,
      username: username,
    );

    _fallbackProfiles[userModel.id] = userModel;

    // Create or upsert profile in PostgreSQL
    try {
      await _upsertProfile(userModel);
      await _ensureWalletExists(userModel.id);
    } catch (e) {
      debugPrint('Profile/Wallet upsert warning: $e');
    }

    return userModel;
  }

  /// Sign in using the registered email address and password.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final response = await client.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );
    final authUser = response.user;
    if (authUser == null) {
      throw Exception('Login failed: Invalid credentials.');
    }

    return _loadAuthenticatedUser(authUser, cleanEmail);
  }

  /// Sign in using an Avotek ID, username, or registered phone number.
  Future<UserModel> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final response = await client.functions.invoke(
      'identifier-login',
      body: {'identifier': identifier.trim(), 'password': password},
    );
    final body = response.data;
    final refreshToken = body is Map<String, dynamic>
        ? body['refresh_token'] as String?
        : null;
    if (response.status < 200 ||
        response.status >= 300 ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw Exception('Invalid credentials.');
    }

    await client.auth.setSession(refreshToken);
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      throw Exception('Sign-in completed without an active session.');
    }
    return _loadAuthenticatedUser(authUser, authUser.email ?? '');
  }

  Future<UserModel> _loadAuthenticatedUser(
    User authUser,
    String fallbackEmail,
  ) async {
    final profile = await getProfile(authUser.id);
    if (profile != null) {
      final referralCode = authUser.userMetadata?['referred_by'] as String?;
      if (profile.referredBy == null &&
          referralCode?.trim().isNotEmpty == true) {
        final updatedProfile = profile.copyWith(
          referredBy: referralCode!.trim().toUpperCase(),
        );
        await _upsertProfile(updatedProfile);
        return updatedProfile;
      }
      return profile;
    }

    final name =
        authUser.userMetadata?['full_name'] as String? ??
        authUser.email?.split('@').first ??
        'Avotek User';
    final phone = authUser.userMetadata?['phone'] as String? ?? '';
    final avoId = avotekIdFor(authUser.id);
    final username =
        authUser.userMetadata?['username'] as String? ??
        authUser.email?.split('@').first;

    final fallbackUser = UserModel(
      id: authUser.id,
      email: authUser.email ?? fallbackEmail,
      name: name,
      phone: phone,
      referralCode: avoId,
      referredBy: authUser.userMetadata?['referred_by'] as String?,
      createdAt: DateTime.tryParse(authUser.createdAt) ?? DateTime.now(),
      avoId: avoId,
      username: username,
    );

    _fallbackProfiles[fallbackUser.id] = fallbackUser;
    await _upsertProfile(fallbackUser);
    await _ensureWalletExists(fallbackUser.id);
    return fallbackUser;
  }

  /// Google OAuth Sign In
  Future<bool> signInWithGoogle() async {
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _authRedirectUrl('/login-callback'),
      );
    } catch (e) {
      debugPrint('Google Sign-in error: $e');
      rethrow;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Send a Supabase password-recovery email that returns to the reset screen.
  Future<void> sendPasswordResetEmail(String email) async {
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _authRedirectUrl('/reset-password'),
    );
  }

  String _authRedirectUrl(String path) {
    if (kIsWeb) {
      return buildWebAuthRedirectUrl(Uri.base, path);
    }
    return 'io.supabase.avotek://$path';
  }

  Future<void> updatePassword(String password) async {
    if (currentSession == null) {
      throw Exception('Open the password-reset link from your email first.');
    }
    await client.auth.updateUser(UserAttributes(password: password));
  }

  NotificationPreferences getNotificationPreferences() =>
      NotificationPreferences.fromUserMetadata(currentAuthUser?.userMetadata);

  Future<void> saveNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    final user = currentAuthUser;
    if (user == null) {
      throw StateError('Sign in to update notification preferences.');
    }

    final metadata = Map<String, dynamic>.from(user.userMetadata ?? const {});
    metadata['notification_preferences'] = preferences.toJson();
    await client.auth.updateUser(UserAttributes(data: metadata));
  }

  // ==========================================
  // PROFILE MANAGEMENT
  // ==========================================

  Future<UserModel?> getProfile(String userId) async {
    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        var user = UserModel.fromJson(res);
        if (user.avoId.isEmpty || user.avoId == 'AVO-10001') {
          final guaranteedAvo = avotekIdFor(userId);
          user = user.copyWith(avoId: guaranteedAvo);
        }
        _fallbackProfiles[userId] = user;
        return user;
      }
    } catch (e) {
      debugPrint(
        'Notice: Error fetching profile from Supabase PostgreSQL (using cached state): $e',
      );
    }
    return _fallbackProfiles[userId];
  }

  Future<void> _upsertProfile(UserModel user) async {
    _fallbackProfiles[user.id] = user;
    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': user.name,
        'phone': user.phone,
        'avatar_url': user.avatarUrl,
        'kyc_status': user.kycStatus,
        'referral_code': user.referralCode,
        'referred_by': user.referredBy,
        'avo_id': user.avoId,
        'username': user.username,
        'transaction_pin_hash': user.transactionPinHash,
        'created_at': user.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Notice: Upserting profile to Supabase PostgreSQL: $e');
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    if (_fallbackProfiles.containsKey(userId)) {
      _fallbackProfiles[userId] = _fallbackProfiles[userId]!.copyWith(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
    }

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['full_name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    try {
      await client.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating profile in Supabase: $e');
    }
  }

  Future<void> setTransactionPin(String userId, String pin) async {
    final pinHash = sha256.convert(utf8.encode(pin.trim())).toString();
    if (_fallbackProfiles.containsKey(userId)) {
      _fallbackProfiles[userId] = _fallbackProfiles[userId]!.copyWith(
        transactionPinHash: pinHash,
      );
    }

    // 1. Update user metadata on Supabase Auth session so it's instantly retained
    try {
      await client.auth.updateUser(
        UserAttributes(data: {'transaction_pin_hash': pinHash}),
      );
    } catch (e) {
      debugPrint('Notice updating userMetadata for PIN: $e');
    }

    // 2. Update PostgreSQL profiles table
    try {
      await client
          .from('profiles')
          .update({
            'transaction_pin_hash': pinHash,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('Notice: Setting transaction PIN in Supabase table: $e');
    }
  }

  // ==========================================
  // WALLET MANAGEMENT (Single Direct Wallet)
  // ==========================================

  Future<WalletModel> _ensureWalletExists(String userId) async {
    if (_fallbackWallets.containsKey(userId)) {
      return _fallbackWallets[userId]!;
    }

    final initialWallet = WalletModel(
      id: userId,
      userId: userId,
      balance: 0.0,
      currency: 'NGN',
      totalFunded: 0.0,
      totalSpent: 0.0,
      updatedAt: DateTime.now(),
    );

    _fallbackWallets[userId] = initialWallet;

    try {
      await client.from('wallets').upsert({
        'id': userId,
        'user_id': userId,
        'balance': initialWallet.balance,
        'currency': initialWallet.currency,
        'virtual_account_number': initialWallet.virtualAccountNumber,
        'virtual_account_bank': initialWallet.virtualAccountBank,
        'virtual_account_name': initialWallet.virtualAccountName,
        'total_funded': initialWallet.totalFunded,
        'total_spent': initialWallet.totalSpent,
        'updated_at': initialWallet.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Notice: Wallet upsert in Supabase: $e');
    }

    return initialWallet;
  }

  Future<WalletModel> getWallet(String userId, {String? userName}) async {
    try {
      final res = await client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (res != null) {
        final w = WalletModel.fromJson(res);
        _fallbackWallets[userId] = w;
        return w;
      }
    } catch (e) {
      debugPrint('Notice: Fetching wallet from Supabase: $e');
    }

    return await _ensureWalletExists(userId);
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  Future<List<TransactionModel>> getTransactions(
    String userId, {
    int limit = 50,
    String? filterType,
  }) async {
    try {
      PostgrestFilterBuilder<List<Map<String, dynamic>>> filterBuilder = client
          .from('transactions')
          .select()
          .eq('user_id', userId);

      if (filterType != null && filterType != 'all') {
        filterBuilder = filterBuilder.eq('type', filterType);
      }

      final res = await filterBuilder
          .order('created_at', ascending: false)
          .limit(limit);
      final list = (res as List)
          .map(
            (item) => TransactionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('Notice: Fetching transactions from Supabase: $e');
    }

    final localList = _fallbackTransactions[userId] ?? [];
    if (filterType != null && filterType != 'all') {
      return localList.where((t) => t.type == filterType).take(limit).toList();
    }
    return localList.take(limit).toList();
  }

  // ==========================================
  // VTU ORDERS
  // ==========================================

  Future<VtuOrder> recordOrder({
    required String userId,
    required String serviceType,
    required String network,
    required String phone,
    required String plan,
    required double amount,
    String status = 'successful',
    String? id,
    String? providerReference,
    String? token,
  }) async {
    final order = VtuOrder(
      id: id ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      serviceType: serviceType,
      network: network,
      phone: phone,
      plan: plan,
      amount: amount,
      status: status,
      providerReference: providerReference,
      token: token,
      createdAt: DateTime.now(),
    );

    _fallbackOrders.putIfAbsent(userId, () => []).insert(0, order);

    try {
      await client.from('vtu_orders').insert({
        'id': order.id,
        'user_id': userId,
        'service_type': serviceType,
        'network': network,
        'phone': phone,
        'plan': plan,
        'amount': amount,
        'status': status,
        'provider_reference': providerReference,
        'token': token,
        'created_at': order.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Notice: Saving VTU order in Supabase PostgreSQL: $e');
    }

    return order;
  }

  // --- REFERRAL & REWARDS RPCs ---

  /// Get referral summary for current user
  Future<Map<String, dynamic>> getReferralSummary() async {
    try {
      final res = await client.rpc('get_user_referral_summary');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      debugPrint('Error getting referral summary: $e');
    }
    return {
      'referral_code': '',
      'referral_count': 0,
      'avo_points': 0,
      'total_earned': 0.0,
      'redeemed_points': 0,
    };
  }

  /// Get referral leaderboard
  Future<List<Map<String, dynamic>>> getReferralLeaderboard() async {
    try {
      final res = await client.rpc('get_referral_leaderboard');
      if (res is List) {
        return res.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error getting referral leaderboard: $e');
    }
    return [];
  }

  /// Redeem AVO Points to wallet balance
  Future<Map<String, dynamic>> redeemAvoPoints(int pointsToRedeem) async {
    final res = await client.rpc('redeem_avo_points', params: {
      'points_to_redeem': pointsToRedeem,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  // --- ADMIN DASHBOARD RPCs ---

  /// Get high-level system statistics (super admin only)
  Future<Map<String, dynamic>> adminGetSystemStats() async {
    final res = await client.rpc('admin_get_system_stats');
    return Map<String, dynamic>.from(res as Map);
  }

  /// List users with profile, wallet, and KYC metadata (super admin only)
  Future<List<Map<String, dynamic>>> adminListUsers() async {
    final res = await client.rpc('admin_list_users');
    if (res is List) {
      return res.map((u) => Map<String, dynamic>.from(u as Map)).toList();
    }
    return [];
  }

  /// Update user KYC status (super admin only)
  Future<bool> adminSetUserKyc({
    required String targetUserId,
    required String newStatus,
  }) async {
    try {
      await client.rpc('admin_set_user_kyc', params: {
        'target_user_id': targetUserId,
        'new_status': newStatus,
      });
      return true;
    } catch (e) {
      debugPrint('Error setting user KYC: $e');
      return false;
    }
  }

  /// Credit or debit user wallet (super admin only)
  Future<double> adminAdjustUserWallet({
    required String targetUserId,
    required double deltaAmount,
    required String reason,
  }) async {
    final res = await client.rpc('admin_adjust_user_wallet', params: {
      'target_user_id': targetUserId,
      'delta_amount': deltaAmount,
      'reason': reason,
    });
    return (res as num).toDouble();
  }

  /// Create a gift voucher debited directly from caller's wallet
  Future<Map<String, dynamic>> createGiftVoucher({
    required double amount,
    String recipient = '',
    String note = '',
  }) async {
    final res = await client.rpc('create_gift_voucher', params: {
      'p_amount': amount,
      'p_recipient': recipient,
      'p_note': note,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  /// Redeem a gift voucher or coupon code with instant wallet crediting
  Future<Map<String, dynamic>> redeemGiftVoucher(String code) async {
    final res = await client.rpc('redeem_gift_voucher', params: {
      'p_code': code.trim(),
    });
    return Map<String, dynamic>.from(res as Map);
  }

  /// List gift vouchers created by user
  Future<List<Map<String, dynamic>>> listUserGiftVouchers(String userId) async {
    try {
      final data = await client
          .from('gift_vouchers')
          .select()
          .eq('creator_id', userId)
          .order('created_at', ascending: false);
      if (data is List) {
        return data.map((d) => Map<String, dynamic>.from(d as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error listing gift vouchers: $e');
    }
    return [];
  }
}
