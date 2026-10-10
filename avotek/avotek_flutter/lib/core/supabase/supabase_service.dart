import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../models/wallet_model.dart';
import '../../models/transaction_model.dart';
import '../../models/vtu_models.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://gcixbqrridzgobkqnlfz.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable__KqtFYoV1zOBWx9oQCySBQ_pIbwAEMO';

  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  SupabaseClient get client => Supabase.instance.client;
  User? get currentAuthUser => _initialized ? client.auth.currentUser : null;
  Session? get currentSession => _initialized ? client.auth.currentSession : null;

  Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  // Fallback cache if Supabase PostgreSQL tables are pending migration in the SQL editor
  final Map<String, UserModel> _fallbackProfiles = {};

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
    if (response.session == null) {
      throw Exception('Check your email to confirm your account before signing in.');
    }

    final now = DateTime.now();
    final avoId = UserModel.avoIdFor(authUser.id);

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
    } catch (e) {
      debugPrint('Profile upsert warning: $e');
    }

    return userModel;
  }

  /// Resolve email from Avotek ID, Username, Phone, or Email
  Future<String> resolveEmailFromIdentifier(String identifier) async {
    final clean = identifier.trim();
    if (clean.contains('@')) return clean;

    final cleanUpper = clean.toUpperCase();

    // 1. Check in-memory fallback profiles
    for (final p in _fallbackProfiles.values) {
      if (p.avoId.toUpperCase() == cleanUpper ||
          (p.username != null && p.username!.toLowerCase() == clean.toLowerCase()) ||
          p.email.split('@').first.toLowerCase() == clean.toLowerCase() ||
          p.phone == clean) {
        return p.email;
      }
    }

    // 2. Query Supabase profiles table
    try {
      final res = await client
          .from('profiles')
          .select('email, avo_id, username, phone')
          .or('avo_id.ilike.$clean,username.ilike.$clean,phone.eq.$clean')
          .maybeSingle();
      if (res != null && res['email'] != null && (res['email'] as String).isNotEmpty) {
        return res['email'] as String;
      }
    } catch (e) {
      debugPrint('Notice resolving identifier in Supabase: $e');
    }

    // 3. Fallback: treat as synthetic username email
    return '$clean@avotek.user';
  }

  /// Sign In with Email, Avotek ID, or Username and Password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final resolvedEmail = await resolveEmailFromIdentifier(cleanEmail);

    final response = await client.auth.signInWithPassword(
      email: resolvedEmail,
      password: password,
    );

    final authUser = response.user;
    if (authUser == null) {
      throw Exception('Login failed: Invalid credentials.');
    }

    // Fetch user profile from PostgreSQL
    final profile = await getProfile(authUser.id);
    if (profile != null) return profile;

    final name = authUser.userMetadata?['full_name'] as String? ??
        authUser.email?.split('@').first ??
        'Avotek User';
    final phone = authUser.userMetadata?['phone'] as String? ?? '';
    final avoId = UserModel.avoIdFor(authUser.id);
    final username = authUser.userMetadata?['username'] as String? ??
        authUser.email?.split('@').first;

    final fallbackUser = UserModel(
      id: authUser.id,
      email: authUser.email ?? resolvedEmail,
      name: name,
      phone: phone,
      referralCode: avoId,
      createdAt: DateTime.tryParse(authUser.createdAt) ?? DateTime.now(),
      avoId: avoId,
      username: username,
    );

    _fallbackProfiles[fallbackUser.id] = fallbackUser;
    await _upsertProfile(fallbackUser);
    return fallbackUser;
  }

  /// Google OAuth Sign In
  Future<bool> signInWithGoogle() async {
    final redirectUrl = kIsWeb ? Uri.base.origin : 'io.supabase.avotek://login-callback';
    return client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Send Password Reset Email via Supabase Auth
  Future<void> sendPasswordResetEmail(String email) async {
    final redirectUrl = kIsWeb
        ? '${Uri.base.origin}/update-password'
        : 'io.supabase.avotek://reset-password';
    await client.auth.resetPasswordForEmail(email.trim(), redirectTo: redirectUrl);
  }

  Future<void> updatePassword(String password) async {
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
          final guaranteedAvo = UserModel.avoIdFor(userId);
          user = user.copyWith(avoId: guaranteedAvo);
        }
        _fallbackProfiles[userId] = user;
        return user;
      }
    } catch (e) {
      debugPrint('Notice: Error fetching profile from Supabase PostgreSQL (using cached state): $e');
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
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN must contain exactly four digits.');
    }
    final pinHash = sha256.convert(utf8.encode(pin.trim())).toString();

    final updatedProfile = await client
        .from('profiles')
        .update({
          'transaction_pin_hash': pinHash,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId)
        .select('id')
        .maybeSingle();

    if (updatedProfile == null) {
      throw StateError('The authenticated user profile was not found; the PIN was not saved.');
    }

    if (_fallbackProfiles.containsKey(userId)) {
      _fallbackProfiles[userId] = _fallbackProfiles[userId]!.copyWith(
        transactionPinHash: pinHash,
      );
    }
  }

  // ==========================================
  // WALLET MANAGEMENT (Single Direct Wallet)
  // ==========================================

  Future<WalletModel> getWallet(String userId, {String? userName}) async {
    final wallet = await client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (wallet == null) {
      throw StateError('Wallet provisioning is not configured for this account.');
    }
    return WalletModel.fromJson(wallet);
  }

  /// Direct Wallet Credit
  Future<WalletModel> creditWallet({
    required String userId,
    required double amount,
    required String reference,
    String? narration,
  }) async {
    throw StateError('Wallet deposits can only be credited by a verified payment webhook.');
  }

  /// Direct Wallet Debit
  Future<WalletModel> debitWallet({
    required String userId,
    required double amount,
    required String reference,
    required String serviceName,
    String? narration,
  }) async {
    throw StateError('VTU purchases require a configured atomic wallet backend.');
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  Future<List<TransactionModel>> getTransactions(
    String userId, {
    int limit = 50,
    String? filterType,
  }) async {
    PostgrestFilterBuilder<List<Map<String, dynamic>>> filterBuilder = client
        .from('transactions')
        .select()
        .eq('user_id', userId);

    if (filterType != null && filterType != 'all') {
      filterBuilder = filterBuilder.eq('type', filterType);
    }

    final res = await filterBuilder.order('created_at', ascending: false).limit(limit);
    return res.map(TransactionModel.fromJson).toList();
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
    required String status,
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

    return order;
  }
}
