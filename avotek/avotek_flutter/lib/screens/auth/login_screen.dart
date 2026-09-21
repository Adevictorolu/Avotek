import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_illustrations.dart';
import '../../widgets/avotek_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  bool _isOtpMode = false;
  bool _isOtpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers
  final _phoneController = TextEditingController(text: '08031234567');
  final _emailController = TextEditingController(text: 'demo@avotek.africa');
  final _nameController = TextEditingController(text: 'Chukwuemeka Obi');
  final _passwordController = TextEditingController(text: 'password123');
  final _confirmPasswordController = TextEditingController(text: 'password123');
  final _referralController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  void _handleSocialLogin(String provider) async {
    final auth = context.read<AuthProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to $provider...'),
        duration: const Duration(milliseconds: 900),
      ),
    );

    final success = await auth.socialLogin(
      provider: provider,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : 'user@${provider.toLowerCase()}.com',
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Avotek Scholar',
    );

    if (success && mounted) {
      if (auth.user?.id != null) {
        context.read<WalletProvider>().fetchWallet(auth.user!.id!);
      }
      context.go('/dashboard');
    }
  }

  Future<void> _handlePasswordAuth() async {
    final auth = context.read<AuthProvider>();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (_isSignUp) {
      if (name.isEmpty) {
        _showError('Please enter your full name');
        return;
      }
      if (phone.length < 10) {
        _showError('Please enter a valid phone number');
        return;
      }
      if (password.length < 6) {
        _showError('Password must be at least 6 characters');
        return;
      }
      if (password != _confirmPasswordController.text.trim()) {
        _showError('Passwords do not match');
        return;
      }

      final success = await auth.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
        referralCode: _referralController.text.trim(),
      );

      if (success && mounted) {
        if (auth.user?.id != null) {
          context.read<WalletProvider>().fetchWallet(auth.user!.id!);
        }
        context.go('/dashboard');
      } else if (mounted && auth.errorMessage != null) {
        _showError(auth.errorMessage!);
      }
    } else {
      // Sign In
      if (phone.isEmpty && email.isEmpty) {
        _showError('Please enter your phone number or email');
        return;
      }
      if (password.isEmpty) {
        _showError('Please enter your password');
        return;
      }

      final success = await auth.login(
        identifier: phone.isNotEmpty ? phone : email,
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
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showError('Please enter a valid Nigerian phone number');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(phone);
    if (success && mounted) {
      setState(() {
        _isOtpSent = true;
        _otpController.text = '123456'; // Sandbox test OTP
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent! Use test code: 123456')),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    final name = _nameController.text.trim();

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(
      phone: phone,
      otp: otp,
      name: name,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top SVG Hero Banner
                  Center(
                    child: SizedBox(
                      height: 110,
                      child: const AvotekAuthHeroIllustration(width: 300, height: 110),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Avotek Brand Logo & Motto
                  Center(
                    child: Column(
                      children: [
                        AvotekBrandAsset(height: 48, isDark: isDark),
                        const SizedBox(height: 8),
                        Text(
                          'LEVERAGING TECHNOLOGY IN EDUCATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: isDark ? AppColors.primaryCyan : AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Card Container (Sogo-Style Card)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented Tab Switcher (Sign In vs Create Account)
                        if (!_isOtpMode)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildTabButton(
                                    title: 'Sign In',
                                    isSelected: !_isSignUp,
                                    onTap: () => setState(() => _isSignUp = false),
                                  ),
                                ),
                                Expanded(
                                  child: _buildTabButton(
                                    title: 'Create Account',
                                    isSelected: _isSignUp,
                                    onTap: () => setState(() => _isSignUp = true),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                                onPressed: () => setState(() {
                                  _isOtpMode = false;
                                  _isOtpSent = false;
                                }),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isOtpSent ? 'Verify Phone Code' : 'Phone Number Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 20),

                        // Form Fields
                        if (!_isOtpMode) ...[
                          if (_isSignUp) ...[
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                                hintText: 'Chukwuemeka Obi',
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: _isSignUp ? 'Phone Number (Primary)' : 'Phone or Email',
                              prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
                              hintText: '0803 123 4567',
                            ),
                          ),
                          if (_isSignUp) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.email_outlined, size: 20),
                                hintText: 'student@university.edu.ng',
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          if (_isSignUp) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _referralController,
                              decoration: const InputDecoration(
                                labelText: 'Referral Code (Optional)',
                                prefixIcon: Icon(Icons.card_giftcard_rounded, size: 20),
                                hintText: 'e.g. AVO01',
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Main Action Button (Sign In / Sign Up)
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handlePasswordAuth,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSignUp ? 'Create Account' : 'Sign In to Avotek',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ] else ...[
                          // OTP Mode
                          if (!_isOtpSent) ...[
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Nigerian Phone Number',
                                prefixIcon: Icon(Icons.phone_iphone_rounded, size: 20),
                                hintText: '0803 123 4567',
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _handleSendOtp,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Send Verification Code'),
                              ),
                            ),
                          ] else ...[
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                hintText: '123456',
                                labelText: 'Enter 6-Digit Code',
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _handleVerifyOtp,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Verify & Continue'),
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 20),

                        // Divider with OR
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Social Login Grid (Google, Yahoo, Facebook, Phone)
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                brand: 'google',
                                label: 'Google',
                                onTap: () => _handleSocialLogin('Google'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSocialButton(
                                brand: 'yahoo',
                                label: 'Yahoo',
                                onTap: () => _handleSocialLogin('Yahoo'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSocialButton(
                                brand: 'facebook',
                                label: 'Facebook',
                                onTap: () => _handleSocialLogin('Facebook'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Phone Number Option
                        OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _isOtpMode = !_isOtpMode;
                            _isOtpSent = false;
                          }),
                          icon: Icon(
                            _isOtpMode ? Icons.lock_outline_rounded : Icons.phone_iphone_rounded,
                            size: 18,
                            color: AppColors.primaryCyan,
                          ),
                          label: Text(
                            _isOtpMode ? 'Switch to Password Sign In' : 'Sign in with Phone SMS OTP',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ⚡ Instant Sandbox Demo Account Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00385C), Color(0xFF00A3FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _handleOneTapDemo,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.flash_on_rounded, color: Colors.amber, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      '⚡ Try Instant Demo (₦25,000 Sandbox Balance)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),



                  // Mobile splash screen re-opener link
                  if (!kIsWeb) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.push('/onboarding'),
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text(
                          'View App Splash Tour',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
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

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkCard : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppColors.primaryCyan
                : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String brand,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: isDark ? const Color(0xFF131C2D) : const Color(0xFFF8FAFC),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BrandIcon(brand: brand, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
