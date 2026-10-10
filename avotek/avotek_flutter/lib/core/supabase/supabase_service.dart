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
  final Map<String, WalletModel> _fallbackWallets = {};
  final Map<String, List<TransactionModel>> _fallbackTransactions = {};
  final Map<String, List<VtuOrder>> _fallbackOrders = {};

  /// Initialize Supabase with the project URL and Anon Key
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('Supabase successfully initialized.');
    } catch (e) {
      debugPrint('Supabase initialize error: $e');
      _initialized = true; // Mark initialized if already initialized elsewhere
    }
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  /// Sign Up with Email and Password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': name.trim(),
        'phone': phone.trim(),
      },
    );

    final authUser = response.user;
    if (authUser == null) {
      throw Exception('Sign up failed: User was not created.');
    }

    final now = DateTime.now();
    final userModel = UserModel(
      id: authUser.id,
      email: email.trim(),
      name: name.trim(),
      phone: phone.trim(),
      referralCode: 'AVO${authUser.id.substring(0, 6).toUpperCase()}',
      createdAt: now,
    );

    _fallbackProfiles[userModel.id] = userModel;

    // Create or upsert profile in PostgreSQL
    try {
      await _upsertProfile(userModel);
      await _ensureWalletExists(userModel.id, name.trim());
    } catch (e) {
      debugPrint('Profile/Wallet upsert warning: $e');
    }

    return userModel;
  }

  /// Sign In with Email and Password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email.trim(),
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

    final fallbackUser = UserModel(
      id: authUser.id,
      email: authUser.email ?? email,
      name: name,
      phone: phone,
      referralCode: 'AVO${authUser.id.substring(0, 6).toUpperCase()}',
      createdAt: DateTime.tryParse(authUser.createdAt) ?? DateTime.now(),
    );

    _fallbackProfiles[fallbackUser.id] = fallbackUser;
    await _upsertProfile(fallbackUser);
    await _ensureWalletExists(fallbackUser.id, name);
    return fallbackUser;
  }

  /// Google OAuth Sign In
  Future<bool> signInWithGoogle() async {
    try {
      final redirectUrl = kIsWeb
          ? Uri.base.toString().split('#').first.split('?').first
          : 'io.supabase.avotek://login-callback';
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
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

  /// Send Password Reset Email via Supabase Auth
  Future<void> sendPasswordResetEmail(String email) async {
    await client.auth.resetPasswordForEmail(email.trim());
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
        final user = UserModel.fromJson(res);
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
    try {
      await client.from('profiles').update({
        'transaction_pin_hash': pinHash,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Notice: Setting transaction PIN in Supabase: $e');
    }
  }

  // ==========================================
  // WALLET MANAGEMENT (Single Direct Wallet)
  // ==========================================

  Future<WalletModel> _ensureWalletExists(String userId, String userName) async {
    if (_fallbackWallets.containsKey(userId)) {
      return _fallbackWallets[userId]!;
    }

    final cleanName = userName.isEmpty ? 'Avotek Customer' : userName;
    final virtualAcct = '90${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}';

    final initialWallet = WalletModel(
      id: userId,
      userId: userId,
      balance: 0.0,
      currency: 'NGN',
      virtualAccountNumber: virtualAcct,
      virtualAccountBank: 'Wema Bank / PalmPay',
      virtualAccountName: 'AVOTEK - $cleanName',
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

    return await _ensureWalletExists(userId, userName ?? 'User');
  }

  /// Direct Wallet Credit
  Future<WalletModel> creditWallet({
    required String userId,
    required double amount,
    required String reference,
    String? narration,
  }) async {
    final currentWallet = await getWallet(userId);
    final newBalance = currentWallet.balance + amount;
    final newTotalFunded = currentWallet.totalFunded + amount;

    final updatedWallet = currentWallet.copyWith(
      balance: newBalance,
      totalFunded: newTotalFunded,
      updatedAt: DateTime.now(),
    );

    _fallbackWallets[userId] = updatedWallet;

    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      type: 'credit',
      category: 'wallet_fund',
      amount: amount,
      balanceBefore: currentWallet.balance,
      balanceAfter: newBalance,
      reference: reference,
      narration: narration ?? 'Wallet Funding',
      status: 'completed',
      createdAt: DateTime.now(),
    );

    _fallbackTransactions.putIfAbsent(userId, () => []).insert(0, tx);

    try {
      await client.from('wallets').update({
        'balance': newBalance,
        'total_funded': newTotalFunded,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      // Record in immutable transaction ledger
      await client.from('transactions').insert({
        'user_id': userId,
        'type': 'credit',
        'category': 'wallet_fund',
        'amount': amount,
        'balance_before': currentWallet.balance,
        'balance_after': newBalance,
        'reference': reference,
        'narration': narration ?? 'Wallet Funding',
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Notice: Recording credit in Supabase PostgreSQL: $e');
    }

    return updatedWallet;
  }

  /// Direct Wallet Debit
  Future<WalletModel> debitWallet({
    required String userId,
    required double amount,
    required String reference,
    required String serviceName,
    String? narration,
  }) async {
    final currentWallet = await getWallet(userId);
    if (currentWallet.balance < amount) {
      throw Exception('Insufficient balance. Please fund your wallet.');
    }

    final newBalance = currentWallet.balance - amount;
    final newTotalSpent = currentWallet.totalSpent + amount;

    final updatedWallet = currentWallet.copyWith(
      balance: newBalance,
      totalSpent: newTotalSpent,
      updatedAt: DateTime.now(),
    );

    _fallbackWallets[userId] = updatedWallet;

    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      type: 'debit',
      category: serviceName.toLowerCase(),
      amount: amount,
      balanceBefore: currentWallet.balance,
      balanceAfter: newBalance,
      reference: reference,
      narration: narration ?? '$serviceName Purchase',
      status: 'completed',
      createdAt: DateTime.now(),
    );

    _fallbackTransactions.putIfAbsent(userId, () => []).insert(0, tx);

    try {
      await client.from('wallets').update({
        'balance': newBalance,
        'total_spent': newTotalSpent,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      await client.from('transactions').insert({
        'user_id': userId,
        'type': 'debit',
        'category': serviceName.toLowerCase(),
        'amount': amount,
        'balance_before': currentWallet.balance,
        'balance_after': newBalance,
        'reference': reference,
        'narration': narration ?? '$serviceName Purchase',
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Notice: Recording debit in Supabase PostgreSQL: $e');
    }

    return updatedWallet;
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
          .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
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
