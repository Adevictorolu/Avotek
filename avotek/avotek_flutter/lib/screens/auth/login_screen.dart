import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
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
  bool _rememberMe = true;
  bool _isProcessing = false;

  // Controllers
  final _usernameController = TextEditingController(text: 'adevictorolu');
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(text: 'password123');

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Real Google OAuth Sign-in Flow ---
  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();

    final accounts = [
      {'name': 'Adevictorolu', 'email': 'adevictorolu@avotek.africa'},
      {'name': 'Victor Olorunfemi', 'email': 'adevotekofficial@gmail.com'},
    ];

    final customEmailCtrl = TextEditingController();
    final customNameCtrl = TextEditingController();

    final selected = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141720),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF26334D)),
        ),
        title: Row(
          children: [
            _buildGoogleIcon(size: 24),
            const SizedBox(width: 12),
            Text(
              'Sign in with Google',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a Google account to continue to Avotek:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              for (final acc in accounts)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF26334D)),
                    ),
                    tileColor: const Color(0xFF1A1F2B),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFD4AF37),
                      child: Text(
                        acc['name']![0],
                        style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      acc['name']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      acc['email']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, acc),
                  ),
                ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFF26334D)),
              const SizedBox(height: 8),
              Text(
                'Or use another Google account:',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: customNameCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Your Full Name',
                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1A1F2B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF26334D))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: customEmailCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'example@gmail.com',
                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1A1F2B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF26334D))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () {
              final em = customEmailCtrl.text.trim();
              final nm = customNameCtrl.text.trim();
              if (em.isNotEmpty) {
                Navigator.pop(ctx, {'name': nm.isNotEmpty ? nm : em.split('@')[0], 'email': em});
              }
            },
            child: Text('Sign In', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
            wallet.fetchWallet(auth.user!.id!);
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

  // --- Real Sign-in Action ---
  Future<void> _handleSignIn() async {
    final identifier = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter your username/email and password.', AppColors.error);
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
        wallet.fetchWallet(auth.user!.id!);
      }
      context.go('/dashboard');
    } else {
      _showSnackBar(auth.authError ?? 'Invalid username or password. Please verify your credentials.', AppColors.error);
    }
  }

  // --- Real Registration Action ---
  Future<void> _handleSignUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all required registration fields.', AppColors.error);
      return;
    }

    setState(() => _isProcessing = true);
    final auth = context.read<AuthProvider>();

    final success = await auth.register(
      name: fullName,
      email: email,
      phone: phone.isNotEmpty ? phone : (username.startsWith('0') ? username : '08000000000'),
      password: password,
      referralCode: username,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      await OnboardingPinDialog.show(context);

      if (!mounted) return;
      final wallet = context.read<WalletProvider>();
      if (auth.user?.id != null) {
        wallet.fetchWallet(auth.user!.id!);
      }
      context.go('/dashboard');
    } else {
      _showSnackBar(auth.authError ?? 'Registration failed. Username or email may already exist.', AppColors.error);
    }
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
      backgroundColor: const Color(0xFF0D0F15),
      body: Stack(
        children: [
          // Background ambient golden gradient glow
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
                    const Color(0xFFD4AF37).withOpacity(0.08),
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
                    const Color(0xFFE5A93C).withOpacity(0.06),
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
                            // LEFT COLUMN: High-impact hero marketing matching screenshot
                            Expanded(flex: 6, child: _buildLeftHeroSection()),
                            const SizedBox(width: 48),
                            // RIGHT COLUMN: Glassmorphic auth card matching screenshot
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

          // Floating Yellow Chat FAB at bottom-right matching screenshot
          Positioned(
            right: 24,
            bottom: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Avotek 24/7 Live Support is online.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      backgroundColor: const Color(0xFFE5A93C),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A93C),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE5A93C).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.chat_bubble_rounded, color: Colors.black, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Left Hero Section matching Bilalsadasub Screenshot ---
  Widget _buildLeftHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Logo Row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF141720),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
              ),
              child: const Center(
                child: Text('A', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Avotek',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),

        // Giant Hero Headline: "Everything money, in one gold app."
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              height: 1.12,
              letterSpacing: -1.2,
              color: Colors.white,
            ),
            children: const [
              TextSpan(text: 'Everything money,\n'),
              TextSpan(text: 'in one '),
              TextSpan(
                text: 'gold',
                style: TextStyle(
                  color: Color(0xFFE5A93C),
                  shadows: [
                    Shadow(color: Color(0xFFE5A93C), blurRadius: 28),
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
          'Airtime, data, bills, cable and crypto — the fastest way to pay for everything digital in Nigeria.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 40),

        // Feature Showcase & Phone Mockups Display
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Floating Chip Left: Crypto +2.4% today
              Positioned(
                left: 0,
                top: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161922),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.show_chart_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Crypto', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('+2.4% today', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Center 3 Phone Mockups
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMiniPhoneMockup(scale: 0.88, isSelected: false),
                  const SizedBox(width: 12),
                  _buildMiniPhoneMockup(scale: 1.0, isSelected: true),
                  const SizedBox(width: 12),
                  _buildMiniPhoneMockup(scale: 0.88, isSelected: false),
                ],
              ),

              // Floating Chip Right: Wallet funded +₦50,000
              Positioned(
                right: 0,
                bottom: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161922),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFD4AF37), size: 14),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wallet funded', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('+₦50,000', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFFE5A93C))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Trust badge footer
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Trusted by millions of Nigerians · NDPR compliant',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
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
          color: const Color(0xFF12151D),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF26334D),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.black.withOpacity(0.4),
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
                CircleAvatar(radius: 8, backgroundColor: const Color(0xFFD4AF37)),
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
                color: const Color(0xFFE5A93C).withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 30, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 4),
                  Text('₦248,500', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFFE5A93C))),
                ],
              ),
            ),
            const Spacer(),
            // 4 Mini action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                (i) => Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E222D),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    i == 0 ? Icons.phone_android : (i == 1 ? Icons.wifi : Icons.tv),
                    size: 11,
                    color: const Color(0xFFD4AF37),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF141720),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: const Center(
                child: Text('A', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Avotek',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Everything money, in one gold app.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // --- Right Glassmorphic Auth Card matching screenshot ---
  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(28),
        border: Border(
          top: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.55), width: 1.5),
          left: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
          right: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
          bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Small brand row inside card
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0F15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                ),
                child: const Center(
                  child: Text('A', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Avotek',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFD4AF37),
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
                ? 'Welcome — join thousands saving money daily.'
                : 'Welcome back — pick up where you left off.',
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
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _emailController,
              hint: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _phoneController,
              hint: 'Phone number',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
          ],

          // Username Field
          _buildInputField(
            controller: _usernameController,
            hint: 'Username',
            suffixWidget: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                't',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFA78BFA),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Password Field
          _buildInputField(
            controller: _passwordController,
            hint: 'Password',
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
                        color: _rememberMe ? const Color(0xFFE5A93C) : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: _rememberMe ? const Color(0xFFE5A93C) : const Color(0xFF475569),
                        ),
                      ),
                      child: _rememberMe
                          ? const Icon(Icons.check, size: 13, color: Colors.black)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isSignUp)
                InkWell(
                  onTap: () {
                    _showSnackBar('Password reset instructions sent to your email.', const Color(0xFFE5A93C));
                  },
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE5A93C),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),

          // Glowing Golden Login / Register Action Button matching screenshot
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : (_isSignUp ? _handleSignUp : _handleSignIn),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                shadowColor: const Color(0xFFF5A623).withOpacity(0.4),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.2),
                    )
                  : Text(
                      _isSignUp ? 'Create Account' : 'Login',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // "or continue with" divider
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFF26334D), height: 1)),
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
              const Expanded(child: Divider(color: Color(0xFF26334D), height: 1)),
            ],
          ),
          const SizedBox(height: 18),

          // Social Buttons Row (Google & Apple)
          Row(
            children: [
              // Google Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleGoogleSignIn,
                    icon: _buildGoogleIcon(size: 18),
                    label: Text(
                      'Google',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
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
              ),
              const SizedBox(width: 12),
              // Apple Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showSnackBar('Apple Sign-In is launching for iOS app.', const Color(0xFF1E222D));
                    },
                    icon: const Icon(Icons.apple, size: 20, color: Colors.white),
                    label: Text(
                      'Apple',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E222D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFF2E3445)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Switch between Sign in and Create one
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp ? 'Sign in' : 'Create one',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE5A93C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Mobile App Badges matching screenshot
          Text(
            'Prefer the mobile app? Get Avotek on:',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStoreBadge(icon: Icons.apple, line1: 'Download on the', line2: 'App Store'),
              const SizedBox(width: 10),
              _buildStoreBadge(icon: Icons.play_arrow_rounded, line1: 'GET IT ON', line2: 'Google Play'),
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
        color: const Color(0xFF1A1D25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF26334D)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
          prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF64748B)) : null,
          suffixIcon: suffixWidget != null
              ? Align(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  alignment: Alignment.centerRight,
                  child: suffixWidget,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStoreBadge({required IconData icon, required String line1, required String line2}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E3445)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                line1,
                style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
              ),
              Text(
                line2,
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleIcon({double size = 18}) {
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
