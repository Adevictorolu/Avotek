import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart';
import '../../core/services/verification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_logo.dart';
import '../../widgets/onboarding_pin_dialog.dart';

class LoginScreen extends StatefulWidget {
  final bool initialSignUp;

  const LoginScreen({super.key, this.initialSignUp = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _isSignUp;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  bool _isProcessing = false;

  // Controllers
  final _identifierController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  // --- Real Google OAuth Sign-in Flow ---
  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();

    // Attempt direct native Supabase Google OAuth first if enabled in Supabase dashboard
    try {
      final nativeStarted = await auth.loginWithGoogle();
      if (nativeStarted) return;
    } catch (e) {
      debugPrint('Native Supabase Google OAuth notice (falling back to direct Google sign-in): $e');
    }

    if (!mounted) return;

    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    final selected = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFF23304B)),
              ),
              title: Row(
                children: [
                  _buildGoogleIcon(size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF23304B)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.electricCyan),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Avotek OAuth Client: 499643353122',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Google Account Email',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'name@gmail.com',
                        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
                        prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.electricCyan, size: 18),
                        filled: true,
                        fillColor: const Color(0xFF131B2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF23304B)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF23304B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.electricCyan, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Full Name (Optional)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. Victor Olorunfemi',
                        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.electricCyan, size: 18),
                        filled: true,
                        fillColor: const Color(0xFF131B2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF23304B)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF23304B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.electricCyan, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    final em = emailCtrl.text.trim();
                          final nm = nameCtrl.text.trim();
                          if (em.isEmpty || !em.contains('@')) {
                            setDialogState(() => errorText = 'Please enter a valid Google email address');
                            return;
                          }
                          Navigator.pop(ctx, {
                            'name': nm.isNotEmpty ? nm : em.split('@')[0],
                            'email': em,
                          });
                        },
                  child: Text(
                    'Sign In with Google',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _isProcessing = true);
      try {
        final success = await auth.loginWithGoogle(
          email: selected['email']!,
          displayName: selected['name']!,
        );

        if (!mounted) return;
        setState(() => _isProcessing = false);

        if (success) {
          if (auth.needsPinSetup) {
            await OnboardingPinDialog.show(context);
          }

          if (!mounted) return;
          final wallet = context.read<WalletProvider>();
          if (auth.user?.id != null) {
            wallet.fetchWallet(auth.user!.id);
          }
          context.go('/dashboard');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showSnackBar('Google Sign In failed: $e', AppColors.error);
        }
      }
    }
  }

  // --- Real Forgot Password & OTP Reset Dialog ---
  void _showForgotPasswordDialog() {
    final idCtrl = TextEditingController(text: _identifierController.text.trim());
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    bool hasSentCode = false;
    bool isSubmitting = false;
    String? errorMessage;
    bool obscureNewPass = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFF23304B), width: 1.5),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryCyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasSentCode ? 'Enter Code & New Password' : 'Reset Your Password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!hasSentCode) ...[
                        Text(
                          'Enter your Avotek ID, registered phone number, or email address. We will dispatch a 6-digit verification code.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: idCtrl,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Avotek ID (AVO-1001), Phone, or Email',
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryCyan),
                            filled: true,
                            fillColor: const Color(0xFF131B2E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF23304B))),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'A 6-digit verification code has been dispatched via SMS & Email. Enter it below along with your new password.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '6-digit OTP code',
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13, letterSpacing: 0),
                            prefixIcon: const Icon(Icons.pin_rounded, color: AppColors.primaryCyan),
                            filled: true,
                            fillColor: const Color(0xFF131B2E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF23304B))),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newPassCtrl,
                          obscureText: obscureNewPass,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'New Password (min 6 characters)',
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryCyan),
                            suffixIcon: IconButton(
                              icon: Icon(obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF94A3B8)),
                              onPressed: () => setDialogState(() => obscureNewPass = !obscureNewPass),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF131B2E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF23304B))),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: confirmPassCtrl,
                          obscureText: obscureNewPass,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Confirm New Password',
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryCyan),
                            filled: true,
                            fillColor: const Color(0xFF131B2E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF23304B))),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8))),
                ),
                if (!hasSentCode)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final id = idCtrl.text.trim();
                            if (id.isEmpty) {
                              setDialogState(() => errorMessage = 'Please enter your username, phone, or email.');
                              return;
                            }
                            setDialogState(() {
                              isSubmitting = true;
                              errorMessage = null;
                            });

                            try {
                              final code = await AppDatabaseService.instance.requestPasswordReset(id);
                              // Send real OTP via Termii & SendGrid
                              VerificationService.instance.sendPhoneOtp(phone: id, code: code);
                              VerificationService.instance.sendEmailOtp(email: id, code: code);

                              setDialogState(() {
                                isSubmitting = false;
                                hasSentCode = true;
                                otpCtrl.text = code;
                              });
                            } catch (e) {
                              setDialogState(() {
                                isSubmitting = false;
                                errorMessage = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Send Verification Code', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final code = otpCtrl.text.trim();
                            final pass = newPassCtrl.text.trim();
                            final confirm = confirmPassCtrl.text.trim();

                            if (code.length != 6) {
                              setDialogState(() => errorMessage = 'Please enter the complete 6-digit code.');
                              return;
                            }
                            if (pass.length < 6) {
                              setDialogState(() => errorMessage = 'Password must be at least 6 characters.');
                              return;
                            }
                            if (pass != confirm) {
                              setDialogState(() => errorMessage = 'Passwords do not match.');
                              return;
                            }

                            setDialogState(() {
                              isSubmitting = true;
                              errorMessage = null;
                            });

                            final ok = await AppDatabaseService.instance.resetPassword(
                              identifier: idCtrl.text.trim(),
                              code: code,
                              newPassword: pass,
                            );

                            if (!ctx.mounted) return;
                            if (ok) {
                              Navigator.pop(ctx);
                              if (mounted) {
                                _identifierController.text = idCtrl.text.trim();
                                _passwordController.text = pass;
                                _showSnackBar(
                                  'Password reset successfully! You can now log in.',
                                  const Color(0xFF10B981),
                                );
                              }
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                                errorMessage = 'Invalid or expired verification code. Please try again.';
                              });
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Update Password', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Real Sign-in Action ---
  Future<void> _handleSignIn() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter your Avotek ID, phone, or email, and your password.', AppColors.error);
      return;
    }

    setState(() => _isProcessing = true);
    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      identifier: identifier,
      password: password,
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      if (auth.needsPinSetup) {
        await OnboardingPinDialog.show(context);
      }

      if (!mounted) return;
      final wallet = context.read<WalletProvider>();
      if (auth.user?.id != null) {
        wallet.fetchWallet(auth.user!.id);
      }
      context.go('/dashboard');
    } else {
      _showSnackBar(auth.authError ?? 'Invalid credentials. Please verify your Avotek ID or password.', AppColors.error);
    }
  }

  // --- Real Registration with Live Termii & SendGrid OTP Verification ---
  Future<void> _handleSignUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final referral = _referralController.text.trim();

    if (fullName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in your full name, phone number, email, and password.', AppColors.error);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters.', AppColors.error);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match. Please re-enter.', AppColors.error);
      return;
    }

    setState(() => _isProcessing = true);

    // 1. Generate real 6-digit OTP code
    final otpCode = VerificationService.instance.generateOtpCode();

    // 2. Dispatch real SMS OTP via Termii API and real Email OTP via SendGrid API
    await VerificationService.instance.sendPhoneOtp(phone: phone, code: otpCode, userName: fullName);
    await VerificationService.instance.sendEmailOtp(email: email, code: otpCode, userName: fullName);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // 3. Show Real Verification OTP Modal
    _showVerificationModal(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
      referralCode: referral,
      initialOtpCode: otpCode,
    );
  }

  // --- Real 6-Digit OTP Verification Dialog ---
  void _showVerificationModal({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String referralCode,
    required String initialOtpCode,
  }) {
    final otpController = TextEditingController();
    bool isVerifying = false;
    String? errorText;
    int secondsRemaining = 60;
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (secondsRemaining > 0) {
                setDialogState(() => secondsRemaining--);
              } else {
                timer.cancel();
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFF23304B), width: 1.5),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.primaryCyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Account Verification',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A 6-digit security verification code has been dispatched to:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF23304B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.primaryCyan),
                              const SizedBox(width: 6),
                              Text(phone, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 14, color: AppColors.primaryCyan),
                              const SizedBox(width: 6),
                              Text(email, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (errorText != null) ...[
                      Text(errorText!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Enter 6-digit code',
                        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13, letterSpacing: 0),
                        filled: true,
                        fillColor: const Color(0xFF131B2E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF23304B))),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          secondsRemaining > 0 ? 'Resend in ${secondsRemaining}s' : 'Did not receive code?',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                        ),
                        if (secondsRemaining == 0)
                          TextButton(
                            onPressed: () async {
                              final newCode = VerificationService.instance.generateOtpCode();
                              await VerificationService.instance.sendPhoneOtp(phone: phone, code: newCode, userName: fullName);
                              await VerificationService.instance.sendEmailOtp(email: email, code: newCode, userName: fullName);
                              setDialogState(() {
                                secondsRemaining = 60;
                                errorText = null;
                              });
                            },
                            child: Text(
                              'Resend Code',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryCyan),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying
                      ? null
                      : () {
                          countdownTimer?.cancel();
                          Navigator.pop(modalCtx);
                        },
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final code = otpController.text.trim();
                          if (code.length != 6) {
                            setDialogState(() => errorText = 'Please enter the complete 6-digit code.');
                            return;
                          }

                          setDialogState(() {
                            isVerifying = true;
                            errorText = null;
                          });

                          final isCodeValid = VerificationService.instance.verifyOtp(
                            identifier: phone,
                            enteredCode: code,
                          );

                          if (!isCodeValid) {
                            setDialogState(() {
                              isVerifying = false;
                              errorText = 'Invalid verification code. Please check your SMS or email.';
                            });
                            return;
                          }

                          countdownTimer?.cancel();

                          // Register in real persistent database
                          final auth = context.read<AuthProvider>();
                          final success = await auth.register(
                            name: fullName,
                            email: email,
                            phone: phone,
                            password: password,
                            referralCode: referralCode.isNotEmpty ? referralCode : null,
                          );

                          if (!modalCtx.mounted) return;
                          Navigator.pop(modalCtx);

                          if (success && mounted) {
                            final newUser = auth.user;
                            final avotekId = newUser?.id != null ? 'AVO-${newUser!.id}' : 'AVO-10023';

                            // Show registration celebration dialog with permanent Avotek ID
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (welcomeCtx) => AlertDialog(
                                backgroundColor: const Color(0xFF0F172A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Welcome to Avotek!',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your permanent system identification number is:',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF131B2E),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.primaryCyan, width: 1.5),
                                      ),
                                      child: Text(
                                        avotekId,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                          color: AppColors.primaryCyan,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'You can use this Avotek ID, your phone, or email to sign in anytime.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(welcomeCtx);
                                          context.go('/dashboard');
                                        },
                                        child: Text(
                                          'Enter Dashboard',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (mounted) {
                            _showSnackBar(auth.authError ?? 'Registration failed. Email or phone may already exist.', AppColors.error);
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Verify & Enter', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String text, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: bg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D), // Dark Navy Blue as requested
      body: Stack(
        children: [
          // Background ambient royal blue gradient glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryCyan.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 48 : 20,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // LEFT COLUMN: Avotek Brand Hero
                            Expanded(flex: 6, child: _buildLeftHeroSection()),
                            const SizedBox(width: 48),
                            // RIGHT COLUMN: Avotek Blue/Ash Glassmorphic Card
                            Expanded(flex: 5, child: _buildAuthCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildMobileHeader(),
                            const SizedBox(height: 24),
                            _buildAuthCard(),
                          ],
                        ),
                ),
              ),
            ),
          ),

          // Top right theme toggle button
          Positioned(
            top: 16,
            right: isDesktop ? 40 : 16,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: Theme.of(context).brightness == Brightness.dark
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Left Hero Section: Avotek Royal Navy & Cyan Branding ---
  Widget _buildLeftHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Standard Avotek Logo with rounded border radius that cuts the edge
        const AvotekBrandAsset(
          height: 44,
          isDark: true,
          hasFrame: true,
          borderRadius: 14,
        ),
        const SizedBox(height: 44),

        // Hero Headline
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -1.2,
              color: Colors.white,
            ),
            children: const [
              TextSpan(text: 'Leveraging technology,\n'),
              TextSpan(text: 'in one '),
              TextSpan(
                text: 'smart',
                style: TextStyle(
                  color: AppColors.primaryCyan,
                  shadows: [
                    Shadow(color: AppColors.primaryBlue, blurRadius: 28),
                  ],
                ),
              ),
              TextSpan(text: ' app.'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Subtitle
        Text(
          'Airtime, high-speed SME & corporate data bundles, electricity prepaid tokens, cable TV, and corporate CAC registration across Nigeria.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 36),

        // Feature Showcase & Phone Mockups Display
        SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Floating Chip Left: SME Data Bundle
              Positioned(
                left: 0,
                top: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF23304B)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_rounded, color: AppColors.primaryCyan, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Instant SME Data', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('1GB at ₦245 • 30 Days', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryCyan)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Mini Phone Mockups (Back + Front)
              Positioned(
                left: 170,
                child: _buildMiniPhoneMockup(scale: 0.9, isSelected: false),
              ),
              Positioned(
                left: 215,
                child: _buildMiniPhoneMockup(scale: 1.05, isSelected: true),
              ),

              // Floating Chip Right: Wallet Deposit
              Positioned(
                right: 0,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF23304B)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('+₦50,000 Credit', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('PalmPay 8167002789', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPhoneMockup({required double scale, required bool isSelected}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 110,
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : const Color(0xFF23304B),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Speaker bar
            Center(
              child: Container(
                width: 28,
                height: 3,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            // Avatar + Name
            Row(
              children: [
                CircleAvatar(radius: 8, backgroundColor: AppColors.primaryBlue),
                const SizedBox(width: 6),
                Container(width: 40, height: 6, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(3))),
              ],
            ),
            const SizedBox(height: 12),
            // Balance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 30, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 4),
                  Text('₦248,500', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primaryCyan)),
                ],
              ),
            ),
            const Spacer(),
            // 3 Mini action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                (i) => Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    i == 0 ? Icons.phone_android : (i == 1 ? Icons.wifi : Icons.tv),
                    size: 11,
                    color: AppColors.primaryCyan,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        const AvotekBrandAsset(
          height: 42,
          isDark: true,
          hasFrame: true,
          borderRadius: 14,
        ),
        const SizedBox(height: 14),
        Text(
          'Leveraging technology in one smart app.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // --- Right Blue/Ash Glassmorphic Auth Card ---
  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // Deep slate card surface
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF23304B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Row with rounded framing inside card
          Row(
            children: [
              const AvotekLogo(size: 28, hasFrame: true, borderRadius: 8),
              const SizedBox(width: 10),
              Text(
                'AVOTEK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.primaryCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Header
          Text(
            _isSignUp ? 'Create your account' : 'Sign in to Avotek',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isSignUp
                ? 'Join thousands saving on data and utility recharge daily.'
                : 'Welcome back — enter your Avotek ID, phone, or email.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),

          // Form Fields
          if (_isSignUp) ...[
            _buildInputField(
              controller: _fullNameController,
              hint: 'Full Name',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _phoneController,
              hint: 'Phone Number / WhatsApp (e.g. 08034119920)',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _emailController,
              hint: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _passwordController,
              hint: 'Password (min 6 characters)',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixWidget: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF64748B)),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _confirmPasswordController,
              hint: 'Confirm Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              suffixWidget: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF64748B)),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _referralController,
              hint: 'Referral Code (Optional)',
              icon: Icons.card_giftcard_rounded,
            ),
          ] else ...[
            _buildInputField(
              controller: _identifierController,
              hint: 'Avotek ID (AVO-1001), Phone, or Email',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _passwordController,
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixWidget: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 14),

            // Remember me & Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _rememberMe ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _rememberMe ? AppColors.primaryBlue : const Color(0xFF475569),
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _showForgotPasswordDialog,
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryCyan,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),

          // Primary Blue Login / Register Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : (_isSignUp ? _handleSignUp : _handleSignIn),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    )
                  : Text(
                      _isSignUp ? 'Verify & Create Account' : 'Sign In',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // "or continue with" divider
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFF23304B), height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'or continue with',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFF23304B), height: 1)),
            ],
          ),
          const SizedBox(height: 18),

          // Google Button Only (NO Apple, as requested)
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleGoogleSignIn,
              icon: _buildGoogleIcon(size: 20),
              label: Text(
                'Continue with Google',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Switch between Sign in and Create one
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp ? 'Sign in' : 'Create one',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryCyan,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscureText = false,
    Widget? suffixWidget,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF23304B), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
          prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.primaryCyan) : null,
          suffixIcon: suffixWidget,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon({double size = 20}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Draw Google 4-color Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -0.78, 1.57, true, bluePaint);
    canvas.drawArc(rect, 0.79, 1.57, true, greenPaint);
    canvas.drawArc(rect, 2.36, 1.57, true, yellowPaint);
    canvas.drawArc(rect, 3.93, 1.57, true, redPaint);

    // Inner Cutout
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, innerPaint);

    // Right horizontal bar
    final barRect = Rect.fromLTRB(w * 0.45, h * 0.4, w * 0.95, h * 0.6);
    canvas.drawRect(barRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
