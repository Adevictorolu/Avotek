import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_logo.dart';
import '../../widgets/onboarding_pin_dialog.dart';
import '../../widgets/top_notification.dart';

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
  final _usernameController = TextEditingController();
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
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isProcessing = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (!success) {
      _showSnackBar(
        auth.errorMessage ?? 'Google sign-in could not be started.',
        AppColors.error,
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(
      text: _identifierController.text.contains('@')
          ? _identifierController.text.trim()
          : '',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          'Reset your password',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Email address',
            labelStyle: TextStyle(color: Color(0xFFCBD5E1)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                _showSnackBar('Enter a valid email address.', AppColors.error);
                return;
              }
              final auth = context.read<AuthProvider>();
              final sent = await auth.sendPasswordResetEmail(email);
              if (!mounted || !dialogContext.mounted) return;
              if (sent) {
                Navigator.pop(dialogContext);
                _showSnackBar(
                  'Password reset link sent. Check your email.',
                  AppColors.success,
                );
              } else {
                _showSnackBar(
                  auth.errorMessage ??
                      'Could not send the password reset link.',
                  AppColors.error,
                );
              }
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    ).whenComplete(emailController.dispose);
  }

  // --- Real Sign-in Action ---
  Future<void> _handleSignIn() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar(
        'Please enter your Avotek ID, phone, or email, and your password.',
        AppColors.error,
      );
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
      _showSnackBar(
        auth.authError ??
            'Invalid credentials. Please verify your Avotek ID or password.',
        AppColors.error,
      );
    }
  }

  // --- Direct Instant Registration (No Phone OTP Friction) ---
  Future<void> _handleSignUp() async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final referral = _referralController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      _showSnackBar(
        'Please fill in your full name, phone number, email, and password.',
        AppColors.error,
      );
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters.', AppColors.error);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar(
        'Passwords do not match. Please re-enter.',
        AppColors.error,
      );
      return;
    }

    setState(() => _isProcessing = true);
    final auth = context.read<AuthProvider>();

    try {
      final success = await auth.register(
        name: fullName,
        email: email,
        phone: phone,
        password: password,
        referralCode: referral.isNotEmpty ? referral : null,
        username: username.isEmpty ? null : username,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (success) {
        final newUser = auth.user;
        final avotekId = newUser?.avoId ?? '';

        // Show registration celebration dialog with permanent Avotek ID
        await showDialog(
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
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 48,
                  ),
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryCyan,
                      width: 1.5,
                    ),
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
                  'You can use this Avotek ID ($avotekId), your username, or your email to sign in anytime.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(welcomeCtx);
                    },
                    child: Text(
                      'Enter Dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (!mounted) return;
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
        _showSnackBar(
          auth.errorMessage ??
              'Account creation did not complete. Please try again.',
          AppColors.error,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnackBar('Registration error: $e', AppColors.error);
      }
    }
  }

  void _showSnackBar(String text, Color bg) {
    if (bg == AppColors.error) {
      TopNotification.showError(context, text);
    } else {
      TopNotification.showSuccess(context, text);
    }
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
          height: 52,
          isDark: true,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF23304B)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_rounded,
                        color: AppColors.primaryCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instant SME Data',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '1GB at ₦245 • 30 Days',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryCyan,
                            ),
                          ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF23304B)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '+₦50,000 Credit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'PalmPay 8167002789',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
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

  Widget _buildMiniPhoneMockup({
    required double scale,
    required bool isSelected,
  }) {
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
              color: isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.4),
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
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Avatar + Name
            Row(
              children: [
                CircleAvatar(radius: 8, backgroundColor: AppColors.primaryBlue),
                const SizedBox(width: 6),
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
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
                  Container(
                    width: 30,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦248,500',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryCyan,
                    ),
                  ),
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
                    i == 0
                        ? Icons.phone_android
                        : (i == 1 ? Icons.wifi : Icons.tv),
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
          height: 48,
          isDark: true,
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
                : 'Welcome back — enter your Avotek ID, username, or email.',
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
              controller: _usernameController,
              hint: 'Username (optional)',
              icon: Icons.alternate_email_rounded,
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
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _confirmPasswordController,
              hint: 'Confirm Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              suffixWidget: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
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
              hint: 'Avotek ID (e.g. AVO-28491), Username, or Email',
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
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
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
                          color: _rememberMe
                              ? AppColors.primaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _rememberMe
                                ? AppColors.primaryBlue
                                : const Color(0xFF475569),
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check,
                                size: 13,
                                color: Colors.white,
                              )
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
              onPressed: _isProcessing
                  ? null
                  : (_isSignUp ? _handleSignUp : _handleSignIn),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Text(
                      _isSignUp ? 'Create Account' : 'Sign In',
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
              const Expanded(
                child: Divider(color: Color(0xFF23304B), height: 1),
              ),
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
              const Expanded(
                child: Divider(color: Color(0xFF23304B), height: 1),
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Switch between Sign in and Create one
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp
                    ? 'Already have an account? '
                    : "Don't have an account? ",
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
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202B3D)
            : const Color(0xFFE2E8F0),
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
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFB6C2D2)
                : const Color(0xFF64748B),
          ),
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: AppColors.primaryCyan)
              : null,
          suffixIcon: suffixWidget,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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
