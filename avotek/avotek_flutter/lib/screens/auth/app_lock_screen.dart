import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/security/device_security_service.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/avotek_logo.dart';
import '../../widgets/onboarding_pin_dialog.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.returnTo});

  final String? returnTo;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pinController = TextEditingController();
  bool _isPreparing = true;
  bool _isSubmitting = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prepareLock();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _prepareLock() async {
    if (SupabaseService.instance.currentAuthUser == null) {
      if (mounted) context.go('/login');
      return;
    }

    final auth = context.read<AuthProvider>();
    for (var attempt = 0; attempt < 75 && !auth.isAuthenticated; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }

    if (!mounted || !auth.isAuthenticated) {
      if (mounted) {
        setState(() {
          _isPreparing = false;
          _errorMessage = 'Could not load your account. Please try again.';
        });
      }
      return;
    }

    if (auth.needsPinSetup) {
      await OnboardingPinDialog.show(context);
      if (!mounted) return;
    }

    try {
      final available = await DeviceSecurityService.isBiometricAvailable();
      final enabled = await DeviceSecurityService.isBiometricEnabled();
      if (!mounted) return;
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = available && enabled;
        _isPreparing = false;
      });
      if (available && enabled) {
        await _unlockWithBiometrics();
      }
    } catch (error) {
      debugPrint('Preparing app unlock failed: $error');
      if (mounted) {
        setState(() {
          _isPreparing = false;
          _errorMessage = 'Biometric unlock is unavailable. Enter your PIN.';
        });
      }
    }
  }

  Future<void> _unlockWithPin() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final valid = await context.read<AuthProvider>().verifyTransactionPin(
        _pinController.text,
      );
      if (!mounted) return;
      if (valid) {
        _finishUnlock();
      } else {
        setState(() {
          _pinController.clear();
          _errorMessage = 'That PIN is incorrect. Please try again.';
        });
      }
    } catch (error) {
      debugPrint('Verifying app unlock PIN failed: $error');
      if (mounted) {
        setState(() {
          _pinController.clear();
          _errorMessage = 'Could not verify your PIN. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _unlockWithBiometrics() async {
    try {
      final authenticated = await DeviceSecurityService.authenticate();
      if (authenticated && mounted) {
        _finishUnlock();
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Biometric check was not completed. Enter your PIN.';
        });
      }
    } catch (error) {
      debugPrint('Biometric app unlock failed: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric unlock failed. Enter your PIN instead.';
        });
      }
    }
  }

  void _finishUnlock() {
    final returnTo = widget.returnTo;
    final destination =
        returnTo != null &&
            returnTo.startsWith('/') &&
            !returnTo.startsWith('//') &&
            !returnTo.startsWith('/login') &&
            !returnTo.startsWith('/onboarding') &&
            !returnTo.startsWith('/app-lock')
        ? returnTo
        : '/dashboard';
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondary = isDark ? AppColors.metallicLight : AppColors.slateGrey;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: _isPreparing
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AvotekLogo(size: 44, isDark: isDark),
                        const SizedBox(height: 28),
                        Icon(
                          Icons.lock_rounded,
                          size: 38,
                          color: AppColors.electricCyan,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Welcome back',
                          style: GoogleFonts.figtree(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your 4-digit PIN to unlock Avotek.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.figtree(
                            fontSize: 14,
                            color: secondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _pinController,
                          autofocus: true,
                          enabled: !_isSubmitting,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          autofillHints: const [],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.figtree(
                            fontSize: 24,
                            letterSpacing: 12,
                            fontWeight: FontWeight.w700,
                            color: foreground,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••',
                            counterText: '',
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkCard
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onSubmitted: (_) => _unlockWithPin(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.figtree(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _unlockWithPin,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Unlock'),
                          ),
                        ),
                        if (_biometricAvailable && _biometricEnabled) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _unlockWithBiometrics,
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: const Text('Use biometrics'),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
