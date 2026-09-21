import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class AuthEndpoint extends Endpoint {
  // In-memory OTP store for dev/testing: phone -> otp
  static final Map<String, String> _otpCache = {};

  Future<bool> sendOtp(Session session, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    // In production, integrate Termii API: https://api.ng.termii.com/api/sms/send
    // For sandbox and testing, 123456 is standard test OTP
    const otp = '123456';
    _otpCache[cleanPhone] = otp;
    session.log('OTP for $cleanPhone is $otp');
    return true;
  }

  Future<AuthResponse> verifyOtp(
    Session session,
    String phone,
    String otp, {
    String? name,
    String? referralCode,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final cached = _otpCache[cleanPhone] ?? '123456';

    if (otp != cached && otp != '123456') {
      throw FormatException('Invalid OTP code. Please enter 123456');
    }

    final now = DateTime.now();
    var user = await User.db.findFirstRow(
      session,
      where: (u) => u.phone.equals(cleanPhone),
    );

    if (user == null) {
      final assignedName = name != null && name.trim().isNotEmpty ? name.trim() : 'User ${cleanPhone.substring(cleanPhone.length - 4)}';
      final refCode = 'AVO${cleanPhone.substring(cleanPhone.length - 4)}';

      user = await User.db.insertRow(
        session,
        User(
          phone: cleanPhone,
          name: assignedName,
          kycStatus: 'tier1',
          referralCode: refCode,
          referredBy: referralCode,
          createdAt: now,
        ),
      );

      // Create dedicated virtual account on registration
      final suffix = cleanPhone.length >= 8 ? cleanPhone.substring(cleanPhone.length - 8) : '019284';
      await Wallet.db.insertRow(
        session,
        Wallet(
          userId: user.id!,
          balance: 1000.0, // Welcome signup credit for immediate sandbox testing!
          currency: 'NGN',
          virtualAccountNumber: '90$suffix',
          virtualAccountBank: 'Wema Bank / Moniepoint',
          virtualAccountName: 'AVOTEK - $assignedName',
          updatedAt: now,
        ),
      );
    }

    final wallet = await Wallet.db.findFirstRow(
      session,
      where: (w) => w.userId.equals(user!.id!),
    );

    // Generate session token
    final token = sha256.convert(utf8.encode('${user.id}:${user.phone}:$now')).toString();

    return AuthResponse(
      token: token,
      user: user,
      wallet: wallet,
    );
  }

  Future<bool> setTransactionPin(Session session, int userId, String pin) async {
    final user = await User.db.findById(session, userId);
    if (user == null) return false;

    final pinHash = sha256.convert(utf8.encode(pin)).toString();
    user.transactionPinHash = pinHash;
    await User.db.updateRow(session, user);
    return true;
  }

  Future<bool> verifyTransactionPin(Session session, int userId, String pin) async {
    final user = await User.db.findById(session, userId);
    if (user == null || user.transactionPinHash == null) {
      // Default to 1234 if unset in sandbox
      return pin == '1234';
    }
    final pinHash = sha256.convert(utf8.encode(pin)).toString();
    return user.transactionPinHash == pinHash;
  }

  Future<User?> getUserProfile(Session session, int userId) async {
    return await User.db.findById(session, userId);
  }
}
