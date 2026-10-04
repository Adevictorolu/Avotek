import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_logo.dart';

class LoginScreen extends StatefulWidget {
  final bool initialSignUp;

  const LoginScreen({super.key, this.initialSignUp = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _isSignUp;
  bool _isOtpStep = false;
  bool _obscurePassword = true;
  bool _keepMeSignedIn = true;
  bool _agreedToTerms = true;

  // Controllers
  final _identifierController = TextEditingController(text: 'demo@avotek.africa');
  final _firstNameController = TextEditingController(text: 'Ada');
  final _lastNameController = TextEditingController(text: 'Okafor');
  final _phoneController = TextEditingController(text: '0803 411 9920');
  final _emailController = TextEditingController(text: 'ada@example.com');
  final _passwordController = TextEditingController(text: 'demopassword');
  final _referralController = TextEditingController();
  final _otpController = TextEditingController(text: '123456');

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleOneTapDemo() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithDemo();
    if (success && mounted) {
      if (auth.user?.id != null) {
        context.read<WalletProvider>().fetchWallet(auth.user!.id!);
      }
      context.go('/dashboard');
    }
  }

  Future<void> _handleSignIn() async {
    final auth = context.read<AuthProvider>();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      _showError('Please enter your email or phone number');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    final success = await auth.login(
      identifier: identifier,
      password: password,
    );

    if (success && mounted) {
      if (auth.user?.id != null) {
        context.read<WalletProvider>().fetchWallet(auth.user!.id!);
      }
      context.go('/dashboard');
    } else if (mounted && auth.errorMessage != null) {
      _showError(auth.errorMessage!);
    }
  }

  Future<void> _handleStartSignUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showError('Please enter your first and last name');
      return;
    }
    if (phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (!_agreedToTerms) {
      _showError('Please agree to the terms of service to continue');
      return;
    }

    // Advance to OTP verification step (Step 2)
    final auth = context.read<AuthProvider>();
    await auth.sendOtp(phone);
    if (mounted) {
      setState(() {
        _isOtpStep = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your phone! Test code is 123456'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  Future<void> _handleVerifyAndRegister() async {
    final auth = context.read<AuthProvider>();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final referral = _referralController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 4) {
      _showError('Please enter the 6-digit OTP code');
      return;
    }

    // Complete registration
    final success = await auth.register(
      name: '$firstName $lastName',
      phone: phone,
      email: email,
      password: password,
      referralCode: referral,
    );

    if (success && mounted) {
      if (auth.user?.id != null) {
        context.read<WalletProvider>().fetchWallet(auth.user!.id!);
      }
      context.go('/dashboard');
    } else if (mounted && auth.errorMessage != null) {
      _showError(auth.errorMessage!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. AUTH HEADER (Matching Kobopay .auth__head)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => context.go('/'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primaryCyan),
                              const SizedBox(width: 6),
                              Text(
                                'Back to site',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const AvotekLogo(size: 28, showText: true),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. AUTH CARD (Matching Kobopay .auth__card)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isSignUp) ...[
                          // Stepper (Matching Kobopay .stepper)
                          _buildStepper(isDark),
                          const SizedBox(height: 24),
                        ],

                        // Headline & Deck
                        Text(
                          _isOtpStep
                              ? 'Verify phone'
                              : (_isSignUp ? 'Create your account' : 'Welcome back'),
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isOtpStep
                              ? 'Enter the 6-digit verification code sent to your phone.'
                              : (_isSignUp
                                  ? 'Two minutes, no paperwork and no minimum funding.'
                                  : 'Sign in to pick up where you stopped.'),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form body
                        if (_isOtpStep)
                          _buildOtpForm(auth, isDark)
                        else if (_isSignUp)
                          _buildSignUpForm(auth, isDark)
                        else
                          _buildSignInForm(auth, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. ASSURANCE BULLETS (Matching Kobopay .auth__pts)
                  _buildAssurancePoints(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // STEPPER COMPONENT (Replicating Kobopay .stepper)
  Widget _buildStepper(bool isDark) {
    final currentStep = _isOtpStep ? 2 : 1;

    return Row(
      children: [
        _stepperNode(1, 'Your details', currentStep == 1, currentStep > 1, isDark),
        _stepperDivider(currentStep > 1, isDark),
        _stepperNode(2, 'Verify phone', currentStep == 2, currentStep > 2, isDark),
        _stepperDivider(false, isDark),
        _stepperNode(3, 'Start buying', false, false, isDark),
      ],
    );
  }

  Widget _stepperNode(int step, String label, bool isNow, bool isDone, bool isDark) {
    final activeColor = AppColors.primaryCyan;
    final inactiveColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isNow
                      ? activeColor
                      : (isDone ? AppColors.success : inactiveColor),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text(
                          '$step',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isNow ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
              color: isNow
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _stepperDivider(bool isDone, bool isDark) {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isDone
          ? AppColors.success
          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
    );
  }

  // SIGN IN FORM (Matching Kobopay login.html)
  Widget _buildSignInForm(AuthProvider auth, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Identifier
        _inputField(
          label: 'Email or phone number',
          controller: _identifierController,
          hintText: 'demo@avotek.africa or 0803 411 9920',
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 18),

        // Password
        _passwordField(
          label: 'Password',
          controller: _passwordController,
          hintText: '••••••••',
          isDark: isDark,
        ),
        const SizedBox(height: 14),

        // Form Aside (Keep me signed in + Forgot password?)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => setState(() => _keepMeSignedIn = !_keepMeSignedIn),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _keepMeSignedIn,
                      activeColor: AppColors.primaryCyan,
                      checkColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _keepMeSignedIn = val ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Keep me signed in',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset link sent to demo email.')),
                );
              },
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryCyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Primary Sign in Button
        ElevatedButton(
          onPressed: auth.isLoading ? null : _handleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: auth.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        const SizedBox(height: 12),

        // 1-Tap Demo Sign In Button
        OutlinedButton.icon(
          onPressed: _handleOneTapDemo,
          icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.warning),
          label: const Text('Sign in with 1-Tap Demo Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),

        // Auth Switch
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'New here? ',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
              ),
              InkWell(
                onTap: () => setState(() {
                  _isSignUp = true;
                  _isOtpStep = false;
                }),
                child: const Text(
                  'Create an account',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SIGN UP FORM (Matching Kobopay register.html)
  Widget _buildSignUpForm(AuthProvider auth, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Two-col: First name & Last name
        Row(
          children: [
            Expanded(
              child: _inputField(
                label: 'First name',
                controller: _firstNameController,
                hintText: 'Ada',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                label: 'Last name',
                controller: _lastNameController,
                hintText: 'Okafor',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Phone number
        _inputField(
          label: 'Phone number',
          controller: _phoneController,
          hintText: '0803 411 9920',
          keyboardType: TextInputType.phone,
          hintNote: 'Your OTP goes to this number.',
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Email address
        _inputField(
          label: 'Email address',
          controller: _emailController,
          hintText: 'ada@example.com',
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Password
        _passwordField(
          label: 'Password',
          controller: _passwordController,
          hintText: '••••••••',
          hintNote: 'At least eight characters, with one number.',
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Referral code
        _inputField(
          label: 'Referral code, if you have one',
          controller: _referralController,
          hintText: 'Optional',
          isDark: isDark,
        ),
        const SizedBox(height: 18),

        // Terms Checkbox
        InkWell(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _agreedToTerms,
                  activeColor: AppColors.primaryCyan,
                  checkColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'I agree to the terms of service and the privacy policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Submit Button
        ElevatedButton(
          onPressed: auth.isLoading ? null : _handleStartSignUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: auth.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Create account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        const SizedBox(height: 20),

        // Auth Switch
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already registered? ',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
              ),
              InkWell(
                onTap: () => setState(() {
                  _isSignUp = false;
                  _isOtpStep = false;
                }),
                child: const Text(
                  'Sign in',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // OTP VERIFICATION STEP
  Widget _buildOtpForm(AuthProvider auth, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.sms_outlined, size: 20, color: AppColors.primaryCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Code sent to ${_phoneController.text.trim()}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isOtpStep = false),
                child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _inputField(
          label: 'Enter 6-digit code',
          controller: _otpController,
          hintText: '123456',
          keyboardType: TextInputType.number,
          hintNote: 'Sandbox demo code 123456 is pre-filled.',
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: auth.isLoading ? null : _handleVerifyAndRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: auth.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Verify & Start Buying', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        const SizedBox(height: 16),

        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification code resent!')),
            );
          },
          child: const Text('Didn\'t receive code? Resend SMS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
        ),
      ],
    );
  }

  // HELPER FORM FIELDS
  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? hintNote,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (hintNote != null) ...[
          const SizedBox(height: 4),
          Text(
            hintNote,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    String? hintNote,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: _obscurePassword,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (hintNote != null) ...[
          const SizedBox(height: 4),
          Text(
            hintNote,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
        ],
      ],
    );
  }

  // 3 ASSURANCE BULLETS (Replicating Kobopay .auth__pts)
  Widget _buildAssurancePoints(bool isDark) {
    final List<Map<String, dynamic>> items = _isSignUp
        ? [
            {'icon': Icons.check_circle_outline_rounded, 'text': 'No monthly fee and no minimum funding'},
            {'icon': Icons.check_circle_outline_rounded, 'text': 'A dedicated account number the moment you join'},
            {'icon': Icons.check_circle_outline_rounded, 'text': 'Reseller pricing from your very first order'},
          ]
        : [
            {'icon': Icons.bolt_rounded, 'text': 'Orders land in seconds, or refund themselves'},
            {'icon': Icons.shield_outlined, 'text': 'A transaction PIN before any money leaves'},
            {'icon': Icons.receipt_long_outlined, 'text': 'A receipt for every order, kept permanently'},
          ];

    return Column(
      children: items.map((it) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(it['icon'] as IconData, size: 16, color: AppColors.primaryCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  it['text'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
