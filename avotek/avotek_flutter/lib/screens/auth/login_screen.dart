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
  bool _obscurePassword = true;
  bool _keepMeSignedIn = true;
  bool _agreedToTerms = true;

  // Controllers
  final _identifierController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _showGoogleAuthDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            _buildGoogleIcon(size: 24),
            const SizedBox(width: 12),
            Text(
              _isSignUp ? 'Google Sign-Up' : 'Google Sign-In',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign in securely with your Google account:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Your name on Google',
                prefixIcon: Icon(Icons.person_outline, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Google Email',
                hintText: 'example@gmail.com',
                prefixIcon: Icon(Icons.email_outlined, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            icon: _buildGoogleIcon(size: 16),
            label: Text(
              'Continue with Google',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () async {
              final enteredEmail = emailController.text.trim();
              final enteredName = nameController.text.trim();
              if (enteredEmail.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your Google email.')),
                );
                return;
              }
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              final success = await auth.socialLogin(
                provider: 'google',
                email: enteredEmail,
                name: enteredName.isNotEmpty ? enteredName : enteredEmail.split('@').first,
              );
              if (success && mounted) {
                if (auth.user?.id != null) {
                  context.read<WalletProvider>().fetchWallet(auth.user!.id!);
                }
                context.go('/dashboard');
              }
            },
          ),
        ],
      ),
    );
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

  Future<void> _handleSignUp() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final referral = _referralController.text.trim();

    if (fullName.isEmpty) {
      _showError('Please enter your full name');
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
      _showError('Please accept the Terms of Service to continue');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: fullName,
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
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. BRAND LOGO - Clean, Undistorted, Perfectly Positioned
                  Center(
                    child: InkWell(
                      onTap: () => context.go('/'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AvotekLogo(
                          size: 46,
                          isLarge: true,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. MAIN AUTH CARD
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header
                        Text(
                          _isSignUp ? 'Create your account' : 'Welcome back',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSignUp
                              ? 'Fast & automated VTU services at wholesale prices.'
                              : 'Sign in to access your wallet and services.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Switcher Tabs (Sign In / Register)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _isSignUp = false),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isSignUp
                                          ? (isDark ? AppColors.darkCard : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_isSignUp
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Sign In',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: !_isSignUp ? FontWeight.w800 : FontWeight.w600,
                                        color: !_isSignUp
                                            ? AppColors.primaryCyan
                                            : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _isSignUp = true),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isSignUp
                                          ? (isDark ? AppColors.darkCard : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _isSignUp
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Register',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: _isSignUp ? FontWeight.w800 : FontWeight.w600,
                                        color: _isSignUp
                                            ? AppColors.primaryCyan
                                            : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // GOOGLE SIGN-IN / SIGN-UP BUTTON
                        OutlinedButton(
                          onPressed: _showGoogleAuthDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: isDark ? AppColors.darkCardVariant.withValues(alpha: 0.5) : Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildGoogleIcon(size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _isSignUp ? 'Sign up with Google' : 'Sign in with Google',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Form Body
                        if (_isSignUp)
                          _buildSignUpFields(auth, isDark)
                        else
                          _buildSignInFields(auth, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. BACK TO SITE / FOOTER
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text(
                        'Return to homepage',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInFields(AuthProvider auth, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          label: 'Email or Phone Number',
          controller: _identifierController,
          hint: '0803 000 0000 or email',
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        _buildPasswordField(
          label: 'Password',
          controller: _passwordController,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => setState(() => _keepMeSignedIn = !_keepMeSignedIn),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: _keepMeSignedIn,
                      activeColor: AppColors.primaryCyan,
                      checkColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => setState(() => _keepMeSignedIn = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: auth.isLoading ? null : _handleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: const Color(0xFF002B47),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: auth.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text(
                  'Sign In',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSignUpFields(AuthProvider auth, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          label: 'Full Name',
          controller: _fullNameController,
          hint: 'e.g. Ada Okafor',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Phone Number',
          controller: _phoneController,
          hint: '0803 411 9920',
          keyboardType: TextInputType.phone,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Email Address',
          controller: _emailController,
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildPasswordField(
          label: 'Create Password',
          controller: _passwordController,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Referral Code (Optional)',
          controller: _referralController,
          hint: 'Enter referral code',
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: _agreedToTerms,
                  activeColor: AppColors.primaryCyan,
                  checkColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'I agree to the Terms of Service and Privacy Policy.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: auth.isLoading ? null : _handleSignUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: const Color(0xFF002B47),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: auth.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text(
                  'Create Free Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: _obscurePassword,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            hintText: '••••••••',
            filled: true,
            fillColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
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
      ],
    );
  }

  Widget _buildGoogleIcon({double size = 20}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double stroke = w * 0.22;

    final red = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final yellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final green = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, w - stroke, h - stroke);

    // Red arc (top)
    canvas.drawArc(rect, 3.8, 1.4, false, red);
    // Yellow arc (left)
    canvas.drawArc(rect, 2.3, 1.5, false, yellow);
    // Green arc (bottom)
    canvas.drawArc(rect, 0.8, 1.5, false, green);
    // Blue arc (right)
    canvas.drawArc(rect, 0.0, 0.8, false, blue);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.42, w * 0.45, stroke),
        Radius.circular(stroke / 2),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
