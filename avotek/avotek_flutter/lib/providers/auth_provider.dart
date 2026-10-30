import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../core/database/app_database.dart';
import '../core/supabase/supabase_service.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';

@visibleForTesting
String friendlyAuthError(Object error) {
  final message = error.toString().replaceFirst('Exception: ', '').trim();
  final normalized = message.toLowerCase();

  if (normalized.contains('invalid login credentials') ||
      normalized == 'invalid credentials.') {
    return 'The email, username, Avotek ID, or password is incorrect.';
  }
  if (normalized.contains('user already registered') ||
      normalized.contains('already been registered') ||
      normalized.contains('email address is already in use')) {
    return 'An account with this email already exists. Sign in or reset your password.';
  }
  if (normalized.contains('email not confirmed') ||
      normalized.contains('email_not_confirmed')) {
    return 'Please check your inbox and verify your email address to activate your account.';
  }
  if (normalized.contains('weak_password') ||
      normalized.contains('password should be at least')) {
    return 'Choose a stronger password with at least 6 characters.';
  }
  if (normalized.contains('too many requests') ||
      normalized.contains('rate limit')) {
    return 'Too many attempts. Wait a few moments and try again.';
  }
  if (normalized.contains('duplicate key') ||
      normalized.contains('already exists') ||
      normalized.contains('unique constraint')) {
    return 'This phone number or username is already taken. Please choose another.';
  }
  if (normalized.contains('socketexception') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('network is unreachable') ||
      normalized.contains('clientexception')) {
    return 'Could not reach Avotek servers. Check your internet connection and retry.';
  }
  return message.isEmpty
      ? 'Authentication could not be completed. Please try again.'
      : message;
}

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  WalletModel? _wallet;
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailVerificationPending = false;
  String? _pendingVerificationEmail;

  AuthProvider() {
    _initSession();
  }

  UserModel? get user => _user;
  WalletModel? get wallet => _wallet;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get authError => _errorMessage;
  bool get emailVerificationPending => _emailVerificationPending;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

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
      AppDatabaseService.instance.clearSession();
    }

    // Listen to real-time auth state changes from Supabase
    SupabaseService.instance.onAuthStateChange.listen((data) async {
      final sessionUser = data.session?.user;
      if (sessionUser != null &&
          (_user == null || _user!.id != sessionUser.id)) {
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
      final metaPinHash =
          authUser.userMetadata?['transaction_pin_hash'] as String?;

      if (profile != null) {
        if ((profile.transactionPinHash == null ||
                profile.transactionPinHash!.isEmpty) &&
            metaPinHash != null &&
            metaPinHash.isNotEmpty) {
          _user = profile.copyWith(transactionPinHash: metaPinHash);
        } else {
          _user = profile;
        }
      } else {
        final name =
            (authUser.userMetadata?['full_name'] as String?) ??
            (authUser.email?.split('@').first as String?) ??
            'Avotek Customer';
        final phone = (authUser.userMetadata?['phone'] as String?) ?? '';

        final avoId =
            (authUser.userMetadata?['avo_id'] as String?) ??
            avotekIdFor(authUser.id.toString());
        final username =
            (authUser.userMetadata?['username'] as String?) ??
            (authUser.email?.split('@').first as String?);

        _user = UserModel(
          id: authUser.id,
          email: authUser.email ?? '',
          name: name,
          phone: phone,
          referralCode: avoId,
          createdAt: DateTime.now(),
          avoId: avoId,
          username: username,
          transactionPinHash: metaPinHash,
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

  /// Starts Google OAuth through Supabase; credentials are entered only at Google.
  Future<bool> loginWithGoogle() async {
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
      _errorMessage = friendlyAuthError(e);
      notifyListeners();
      return false;
    }
  }

  /// Sign In with Email, Avotek ID, Phone, or Username
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim();
    if (cleanId.contains('@')) {
      return await signInWithEmail(email: cleanId, password: password);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await SupabaseService.instance.signInWithIdentifier(
        identifier: cleanId,
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
      _errorMessage = friendlyAuthError(e);
      notifyListeners();
      return false;
    }
  }

  /// User Registration (Direct & Instant - No SMS/Phone OTP friction)
  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
    String? username,
  }) async {
    return await signUpWithEmail(
      email: email,
      password: password,
      name: name,
      phone: phone,
      preferredUsername: username,
      referralCode: referralCode,
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
      _errorMessage = friendlyAuthError(e);
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
    String? preferredUsername,
    String? referralCode,
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
        preferredUsername: preferredUsername,
        referralCode: referralCode,
      );
      if (SupabaseService.instance.currentSession == null) {
        _emailVerificationPending = true;
        _pendingVerificationEmail = email;
        _errorMessage =
            'Verification email sent. Check your inbox to activate your account.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _emailVerificationPending = false;
      _pendingVerificationEmail = null;
      _user = user;
      AppDatabaseService.instance.cacheUser(user);
      await refreshWallet();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = friendlyAuthError(e);
      notifyListeners();
      return false;
    }
  }

  /// Refresh Wallet from Supabase PostgreSQL
  Future<void> refreshWallet() async {
    if (_user == null) return;
    try {
      _wallet = await SupabaseService.instance.getWallet(
        _user!.id,
        userName: _user!.name,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing wallet: $e');
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
      _errorMessage =
          'Could not save your transaction PIN: ${friendlyAuthError(e)}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String password) async {
    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await SupabaseService.instance.updatePassword(password);
      return true;
    } catch (e) {
      _errorMessage = friendlyAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify 4-digit Security PIN
  Future<bool> verifyTransactionPin(String pin) async {
    if (_user == null) return false;
    final cleanPin = pin.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(cleanPin)) return false;
    final inputHash = sha256.convert(utf8.encode(cleanPin)).toString();
    var storedHash = _user!.transactionPinHash;
    if (storedHash == null || storedHash.isEmpty) {
      final freshProfile = await SupabaseService.instance.getProfile(_user!.id);
      final metaPinHash = SupabaseService
          .instance
          .currentAuthUser
          ?.userMetadata?['transaction_pin_hash']
          ?.toString();
      storedHash = freshProfile?.transactionPinHash ?? metaPinHash;
      if (storedHash != null && storedHash.isNotEmpty) {
        _user = _user!.copyWith(transactionPinHash: storedHash);
        AppDatabaseService.instance.cacheUser(_user!);
      } else {
        await setTransactionPin(cleanPin);
        return true;
      }
    }
    return storedHash == inputHash;
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
    final hasValidPhone = phone != null &&
        phone.trim().isNotEmpty &&
        phone.trim() != 'Not configured';
    _user = _user!.copyWith(
      name: name ?? _user!.name,
      phone: phone ?? _user!.phone,
      kycStatus: hasValidPhone
          ? (_user!.isTier2Verified ? 'verified' : 'tier1')
          : _user!.kycStatus,
      kycTier: hasValidPhone ? (_user!.isTier2Verified ? 2 : 1) : _user!.kycTier,
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

  /// Submit 11-digit National Identity Number (NIN) for Tier 2 KYC
  Future<Map<String, dynamic>> submitNinKyc(String nin) async {
    if (_user == null) {
      throw Exception('User is not logged in.');
    }
    final res = await SupabaseService.instance.submitNinKyc(nin);
    _user = _user!.copyWith(
      kycStatus: 'verified',
      kycTier: 2,
      nin: nin.replaceAll(RegExp(r'\D'), ''),
    );
    AppDatabaseService.instance.cacheUser(_user!);
    notifyListeners();
    return res;
  }

  /// Send Password Reset Email via Supabase Auth
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await SupabaseService.instance.sendPasswordResetEmail(email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = friendlyAuthError(e);
      notifyListeners();
      return false;
    }
  }

  /// Convenience alias for logout
  Future<void> signOut() => logout();
}
