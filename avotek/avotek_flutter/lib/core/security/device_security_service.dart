import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSecurityService {
  DeviceSecurityService._();

  static const _biometricEnabledKey = 'avotek_biometric_unlock_enabled';
  static const _biometricPaymentPinKey = 'avotek_biometric_payment_pin';
  static const appUnlockGracePeriod = Duration(minutes: 5);
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _paymentPinStorage = FlutterSecureStorage(
    aOptions: AndroidOptions.biometric(
      enforceBiometrics: true,
      biometricPromptTitle: 'Authorize Avotek payment',
      biometricPromptSubtitle: 'Use your fingerprint to approve this payment',
      biometricPromptNegativeButton: 'Cancel',
    ),
  );

  static bool get isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool shouldLockAfterBackground(Duration duration) =>
      duration >= appUnlockGracePeriod;

  static Future<bool> isBiometricAvailable() async {
    if (!isMobilePlatform) return false;
    return await _localAuth.canCheckBiometrics &&
        (await _localAuth.getAvailableBiometrics()).isNotEmpty;
  }

  static Future<bool> isBiometricEnabled() async {
    if (!isMobilePlatform) return false;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    if (!isMobilePlatform && enabled) {
      throw StateError('Biometric unlock is available only in the mobile app.');
    }
    if (!enabled) {
      await _paymentPinStorage.delete(key: _biometricPaymentPinKey);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_biometricEnabledKey, enabled);
  }

  static Future<void> storePaymentPin(String pin) async {
    if (!isMobilePlatform || !(await isBiometricEnabled())) return;
    await _paymentPinStorage.write(key: _biometricPaymentPinKey, value: pin);
  }

  static Future<String?> authenticatePaymentPin() async {
    if (!isMobilePlatform || !(await isBiometricEnabled())) return null;
    if (defaultTargetPlatform == TargetPlatform.iOS && !await authenticate()) {
      return null;
    }
    return _paymentPinStorage.read(key: _biometricPaymentPinKey);
  }

  static Future<bool> authenticate() {
    if (!isMobilePlatform) {
      throw StateError('Biometric unlock is available only in the mobile app.');
    }
    return _localAuth.authenticate(
      localizedReason: 'Authenticate to unlock Avotek',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  }
}
