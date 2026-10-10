import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../core/database/app_database.dart';
import '../core/supabase/supabase_service.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  WalletModel? _wallet;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _initSession();
  }

  UserModel? get user => _user;
  WalletModel? get wallet => _wallet;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get authError => _errorMessage;

  /// True if the user is authenticated but hasn't created a 4-digit security PIN yet
  bool get needsPinSetup =>
      isAuthenticated &&
      (_user?.transactionPinHash == null || _user!.transactionPinHash!.isEmpty);

  Future<void> _initSession() async {
    await AppDatabaseService.instance.init();

    // Check if Supabase has an active authenticated session
    final authUser = SupabaseService.instance.currentAuthUser;
    if (authUser != null) {
      await _loadUserFromAuth(authUser);
    } else {
      // Check cached session
      final cached = AppDatabaseService.instance.getCachedSessionUser();
      if (cached != null) {
        _user = cached;
        await refreshWallet();
        notifyListeners();
      }
    }

    // Listen to real-time auth state changes from Supabase
    SupabaseService.instance.onAuthStateChange.listen((data) async {
      final sessionUser = data.session?.user;
      if (sessionUser != null && (_user == null || _user!.id != sessionUser.id)) {
        await _loadUserFromAuth(sessionUser);
      } else if (sessionUser == null && _user != null) {
        _user = null;
        _wallet = null;
        AppDatabaseService.instance.clearSession();
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserFromAuth(dynamic authUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await SupabaseService.instance.getProfile(authUser.id);
      if (profile != null) {
        _user = profile;
      } else {
        final name = (authUser.userMetadata?['full_name'] as String?) ??
            (authUser.email?.split('@').first as String?) ??
            'Avotek Customer';
        final phone = (authUser.userMetadata?['phone'] as String?) ?? '';

        _user = UserModel(
          id: authUser.id,
          email: authUser.email ?? '',
          name: name,
          phone: phone,
          referralCode: 'AVO${authUser.id.toString().substring(0, 6).toUpperCase()}',
          createdAt: DateTime.now(),
        );
      }

      AppDatabaseService.instance.cacheUser(_user!);
      await refreshWallet();
    } catch (e) {
      debugPrint('Error loading auth user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign In with Google via Supabase OAuth or Verified Credentials
  Future<bool> loginWithGoogle({
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    if (email != null && email.isNotEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      try {
        final pass = 'GoogleOAuth_${email.hashCode}_Avotek';
        try {
          final user = await SupabaseService.instance.signInWithEmail(
            email: email,
            password: pass,
          );
          _user = user;
        } catch (_) {
          final user = await SupabaseService.instance.signUpWithEmail(
            email: email,
            password: pass,
            name: displayName ?? email.split('@').first,
            phone: '',
          );
          _user = user;
        }
        AppDatabaseService.instance.cacheUser(_user!);
        await refreshWallet();
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Google quick-auth note: $e');
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await SupabaseService.instance.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google sign-in error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign In with Email, Phone, or Username
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim();
    final email = cleanId.contains('@') ? cleanId : '$cleanId@avotek.user';
    return await signInWithEmail(email: email, password: password);
  }

  /// User Registration
  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    return await signUpWithEmail(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );
  }

  /// Sign In with Email & Password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await SupabaseService.instance.signInWithEmail(
        email: email,
        password: password,
      );
      _user = user;
      AppDatabaseService.instance.cacheUser(user);
      await refreshWallet();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Sign Up with Email & Password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await SupabaseService.instance.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      _user = user;
      AppDatabaseService.instance.cacheUser(user);
      await refreshWallet();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Refresh Wallet from Supabase PostgreSQL
  Future<void> refreshWallet() async {
    if (_user == null) return;
    try {
      _wallet = await SupabaseService.instance.getWallet(_user!.id, userName: _user!.name);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing wallet: $e');
    }
  }

  /// Direct Wallet Credit
  Future<void> creditWallet(double amount, {String? narration}) async {
    if (_user == null) return;
    try {
      final ref = 'CR-${DateTime.now().millisecondsSinceEpoch}';
      _wallet = await SupabaseService.instance.creditWallet(
        userId: _user!.id,
        amount: amount,
        reference: ref,
        narration: narration ?? 'Wallet Funding',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error crediting wallet: $e');
    }
  }

  /// Direct Wallet Debit
  Future<bool> debitWallet(double amount, [String serviceName = 'VTU Service', String? reference]) async {
    if (_user == null) return false;
    try {
      final ref = reference ?? 'TX-${DateTime.now().millisecondsSinceEpoch}';
      _wallet = await SupabaseService.instance.debitWallet(
        userId: _user!.id,
        amount: amount,
        reference: ref,
        serviceName: serviceName,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Set 4-digit Security PIN
  Future<bool> setTransactionPin(String pin) async {
    if (_user == null) return false;
    try {
      final pinHash = sha256.convert(utf8.encode(pin.trim())).toString();
      await SupabaseService.instance.setTransactionPin(_user!.id, pin);
      _user = _user!.copyWith(transactionPinHash: pinHash);
      AppDatabaseService.instance.cacheUser(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to set PIN: $e';
      notifyListeners();
      return false;
    }
  }

  /// Verify 4-digit Security PIN
  Future<bool> verifyTransactionPin(String pin) async {
    if (_user == null) return false;
    final inputHash = sha256.convert(utf8.encode(pin.trim())).toString();
    return _user!.transactionPinHash == inputHash;
  }

  /// Convenience alias for verifyTransactionPin
  Future<bool> verifyPin(String pin) => verifyTransactionPin(pin);

  /// Log out
  Future<void> logout() async {
    await SupabaseService.instance.signOut();
    _user = null;
    _wallet = null;
    AppDatabaseService.instance.clearSession();
    notifyListeners();
  }

  /// Update User Profile details
  Future<void> updateProfile({String? name, String? phone}) async {
    if (_user == null) return;
    _user = _user!.copyWith(
      name: name ?? _user!.name,
      phone: phone ?? _user!.phone,
    );
    AppDatabaseService.instance.cacheUser(_user!);
    try {
      await SupabaseService.instance.updateProfile(
        userId: _user!.id,
        name: name,
        phone: phone,
      );
    } catch (_) {}
    notifyListeners();
  }

  /// Convenience alias for logout
  Future<void> signOut() => logout();
}
