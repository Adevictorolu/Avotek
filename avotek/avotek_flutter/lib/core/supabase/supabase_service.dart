import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../models/wallet_model.dart';
import '../../models/transaction_model.dart';
import '../../models/vtu_models.dart';

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
  static const String supabaseUrl = 'https://gcixbqrridzgobkqnlfz.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable__KqtFYoV1zOBWx9oQCySBQ_pIbwAEMO';

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
    if (profile != null) return profile;

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
    String? providerReference,
    String? token,
  }) async {
    final order = VtuOrder(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
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
}
