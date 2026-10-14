import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/avotek_logo.dart';
import '../../widgets/service_brand_logo.dart';
import '../../widgets/top_notification.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const LandingScreen({super.key, this.onToggleTheme});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();

  // GlobalKeys for accurate smooth scrolling
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _howKey = GlobalKey();
  final GlobalKey _whyKey = GlobalKey();

  // Solid service hues matching design tokens
  static const Color sAirtime = Color(0xFF7C3AED); // Solid Violet
  static const Color sData = Color(0xFF2563EB); // Royal Blue
  static const Color sCable = Color(0xFFDB2777); // Pink
  static const Color sPower = Color(0xFFEA580C); // Warm Orange
  static const Color sPrint = Color(0xFF9333EA); // Vibrant Purple
  static const Color sWallet = Color(0xFF059669); // Emerald Green
  static const Color sRefer = Color(0xFFCA8A04); // Amber Gold

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F15),
      endDrawer: !isDesktop ? _buildMobileDrawer(isDark) : null,
      body: Builder(
        builder: (scaffoldContext) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Sticky Top Navigation Bar
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF0D0F15).withOpacity(0.96),
                titleSpacing: isDesktop ? 48 : 16,
                title: Row(
                  mainAxisAlignment: isDesktop
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    // Brand Logo + Name
                    InkWell(
                      onTap: () => context.go('/'),
                      child: const AvotekBrandAsset(
                        height: 42,
                        isDark: true,
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 48),
                      _navLink('Services', () => _scrollToKey(_servicesKey)),
                      _navLink('How it works', () => _scrollToKey(_howKey)),
                      _navLink('Why us', () => _scrollToKey(_whyKey)),
                    ],
                  ],
                ),
                actions: [
                  if (isDesktop) ...[
                    IconButton(
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: isDark
                          ? 'Switch to Light Mode'
                          : 'Switch to Dark Mode',
                      onPressed: () =>
                          context.read<ThemeProvider>().toggleTheme(),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Sign in',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Create account',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ] else ...[
                    IconButton(
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: isDark
                          ? 'Switch to Light Mode'
                          : 'Switch to Dark Mode',
                      onPressed: () =>
                          context.read<ThemeProvider>().toggleTheme(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () =>
                          Scaffold.of(scaffoldContext).openEndDrawer(),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),

              // Content Sections
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroSection(isDesktop),
                        _buildOfficialPartnersStrip(isDesktop),
                        _buildStatsStrip(),
                        Container(
                          key: _servicesKey,
                          child: _buildServicesSection(isDesktop),
                        ),
                        Container(
                          key: _howKey,
                          child: _buildHowItWorksSection(isDesktop),
                        ),
                        Container(
                          key: _whyKey,
                          child: _buildWhyUsSection(isDesktop),
                        ),
                        _buildMobilePocketBand(isDesktop),
                        _buildFinalCtaSection(isDesktop),
                        _buildFooter(isDesktop),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileDrawer(bool isDark) {
    return Drawer(
      backgroundColor: const Color(0xFF141720),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: const [
                  AvotekBrandAsset(
                    height: 40,
                    isDark: true,
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF26334D)),
            _drawerItem('Services', () {
              Navigator.pop(context);
              _scrollToKey(_servicesKey);
            }),
            _drawerItem('How it works', () {
              Navigator.pop(context);
              _scrollToKey(_howKey);
            }),
            _drawerItem('Why us', () {
              Navigator.pop(context);
              _scrollToKey(_whyKey);
            }),
            _drawerItem(
              isDark ? 'Switch to Light Mode ☀️' : 'Switch to Dark Mode 🌙',
              () {
                Navigator.pop(context);
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/login');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF26334D)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign in',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/register');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create account',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // 1. HERO SECTION (UI Psychology: Instant Clarity + Risk Elimination)
  // ====================================================================
  Widget _buildHeroSection(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: isDesktop ? 64 : 36,
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: _buildHeroCopy()),
                const SizedBox(width: 48),
                Expanded(flex: 5, child: _buildPhoneMockup()),
              ],
            )
          : Column(
              children: [
                _buildHeroCopy(),
                const SizedBox(height: 40),
                _buildPhoneMockup(),
              ],
            ),
    );
  }

  Widget _buildHeroCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headline
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 44,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
            children: const [
              TextSpan(text: 'Data, airtime and bills.\n'),
              TextSpan(
                text: 'All in one app.',
                style: TextStyle(
                  color: AppColors.electricCyan,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Deck
        Text(
          'One wallet for every top-up you make and every one you sell. Fund it from any bank app, buy at wholesale reseller prices, and get your money back automatically when a network misbehaves.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 28),

        // CTAs: Create free account -> / See our rates
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.push('/register'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                'Create free account',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                shadowColor: AppColors.primaryBlue.withOpacity(0.4),
              ),
            ),
            OutlinedButton(
              onPressed: () => context.push('/rates'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF26334D), width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'See our rates',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Trust proof
        Row(
          children: [
            _buildAvatarGroup(),
            const SizedBox(width: 14),
            RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                children: const [
                  TextSpan(
                    text: '18,400+ people ',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(text: 'buy & resell here every week'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarGroup() {
    final colors = [
      AppColors.electricCyan,
      const Color(0xFF10B981),
      AppColors.primaryBlue,
      Colors.purple,
    ];
    final initials = ['AO', 'SB', 'TA', 'NE'];
    return SizedBox(
      height: 32,
      width: 90,
      child: Stack(
        children: List.generate(4, (i) {
          return Positioned(
            left: i * 18.0,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: colors[i],
              child: Text(
                initials[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Interactive Phone Mockup matching Kobo .phone screen
  Widget _buildPhoneMockup() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFF26334D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speaker notch simulation
          Center(
            child: Container(
              width: 54,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // User Greeting inside phone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good afternoon',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    'Ada O.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.electricCyan.withOpacity(0.2),
                child: Text(
                  'AO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.electricCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Wallet Balance Card inside phone
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0052FF), Color(0xFF00D2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet balance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₦248,500.00',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 8 Quick Service Icons Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPhoneServiceIcon(
                Icons.phone_android_rounded,
                'Airtime',
                sAirtime,
                '/services/airtime',
              ),
              _buildPhoneServiceIcon(
                Icons.wifi_rounded,
                'Data',
                sData,
                '/services/data',
              ),
              _buildPhoneServiceIcon(
                Icons.tv_rounded,
                'Cable',
                sCable,
                '/services/tv',
              ),
              _buildPhoneServiceIcon(
                Icons.flash_on_rounded,
                'Power',
                sPower,
                '/services/electricity',
              ),
              _buildPhoneServiceIcon(
                Icons.sync_alt_rounded,
                'Convert',
                const Color(0xFF14B8A6),
                '/services',
              ),
              _buildPhoneServiceIcon(
                Icons.sms_rounded,
                'SMS',
                const Color(0xFF6366F1),
                '/services',
              ),
              _buildPhoneServiceIcon(
                Icons.account_balance_wallet_rounded,
                'Fund',
                sWallet,
                '/wallet/fund',
              ),
              _buildPhoneServiceIcon(
                Icons.send_rounded,
                'Send',
                sRefer,
                '/affiliate',
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Live Activity Items
          Text(
            'RECENT ACTIVITY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          _buildPhoneTxItem(
            icon: Icons.wifi_rounded,
            color: sData,
            title: 'MTN 10GB SME',
            subtitle: 'Delivered | 12:41',
            amount: '-₦2,600',
            isCredit: false,
          ),
          const SizedBox(height: 8),
          _buildPhoneTxItem(
            icon: Icons.account_balance_wallet_rounded,
            color: sWallet,
            title: 'Wema Virtual Transfer',
            subtitle: 'Credited | 11:52',
            amount: '+₦5,000',
            isCredit: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneServiceIcon(
    IconData icon,
    String label,
    Color color, [
    String? route,
  ]) {
    return InkWell(
      onTap: () {
        final auth = context.read<AuthProvider>();
        if (auth.isAuthenticated) {
          context.push(route ?? '/services');
        } else {
          TopNotification.showInfo(
            context,
            'Please sign in or create an account to access $label.',
            title: 'Authentication Required',
          );
          context.push('/login');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneTxItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String amount,
    required bool isCredit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isCredit ? const Color(0xFF10B981) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 1.5 OFFICIAL TELECOM & BILL PAYMENT PARTNERS BANNER
  // ====================================================================
  Widget _buildOfficialPartnersStrip(bool isDesktop) {
    final partners = [
      {'provider': 'MTN', 'name': 'MTN Nigeria', 'type': 'Telecom'},
      {'provider': 'AIRTEL', 'name': 'Airtel Nigeria', 'type': 'Telecom'},
      {'provider': 'GLO', 'name': 'Glo Mobile', 'type': 'Telecom'},
      {'provider': '9MOBILE', 'name': '9mobile', 'type': 'Telecom'},
      {'provider': 'DSTV', 'name': 'DStv MultiChoice', 'type': 'Cable TV'},
      {'provider': 'GOTV', 'name': 'GOtv Max/Jinja', 'type': 'Cable TV'},
      {'provider': 'STARTIMES', 'name': 'StarTimes TV', 'type': 'Cable TV'},
      {'provider': 'IKEDC', 'name': 'Ikeja Electric', 'type': 'Electricity'},
      {'provider': 'EKEDC', 'name': 'Eko Electric', 'type': 'Electricity'},
      {'provider': 'AEDC', 'name': 'Abuja Electric', 'type': 'Electricity'},
      {'provider': 'IBEDC', 'name': 'Ibadan Electric', 'type': 'Electricity'},
      {'provider': 'WAEC', 'name': 'WAEC Scratch Card', 'type': 'Education'},
      {'provider': 'NECO', 'name': 'NECO Token', 'type': 'Education'},
      {'provider': 'JAMB', 'name': 'JAMB UTME PIN', 'type': 'Education'},
    ];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 16,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 26,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111520),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF26334D), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.electricCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.electricCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'OFFICIAL OPERATORS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppColors.electricCyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Direct Gateway Integrations',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (isDesktop)
                Text(
                  'Automated 24/7 delivery & instant refunds',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: partners.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161C28),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF23304B)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ServiceBrandLogo(
                      provider: p['provider']!,
                      size: 32,
                      borderRadius: 8,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p['provider']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          p['type']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 2. STATS STRIP (Social Proof & Reliability Metrics)
  // ====================================================================
  Widget _buildStatsStrip() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF26334D)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;
          if (isNarrow) {
            return Column(
              children: [
                _buildStatItem('99.9%', 'Orders delivered first try'),
                const Divider(color: Color(0xFF26334D)),
                _buildStatItem('186,000+', 'Top-ups processed'),
                const Divider(color: Color(0xFF26334D)),
                _buildStatItem('12 sec', 'Average delivery time'),
                const Divider(color: Color(0xFF26334D)),
                _buildStatItem('24/7', 'Instant support on WhatsApp'),
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('99.9%', 'Orders delivered first try'),
              Container(width: 1, height: 40, color: const Color(0xFF26334D)),
              _buildStatItem('186,000+', 'Top-ups processed'),
              Container(width: 1, height: 40, color: const Color(0xFF26334D)),
              _buildStatItem('12 sec', 'Average delivery time'),
              Container(width: 1, height: 40, color: const Color(0xFF26334D)),
              _buildStatItem('24/7', 'Support that answers'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String stat, String label) {
    return Column(
      children: [
        Text(
          stat,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.electricCyan,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // ====================================================================
  // 3. SERVICES SECTION ("What you can buy")
  // ====================================================================
  Widget _buildServicesSection(bool isDesktop) {
    final services = [
      {
        'title': 'Airtime top-up',
        'desc':
            'MTN, Glo, Airtel and 9mobile at wholesale discount, delivered the second you pay.',
        'icon': Icons.phone_android_rounded,
        'color': sAirtime,
        'route': '/services/airtime',
      },
      {
        'title': 'Data bundles',
        'desc':
            'SME, gifting and corporate plans. Daily, weekly and monthly, every single network.',
        'icon': Icons.wifi_rounded,
        'color': sData,
        'route': '/services/data',
      },
      {
        'title': 'Cable TV',
        'desc':
            'DStv, GOtv and Startimes renewals. Enter smartcard, the decoder comes on instantly.',
        'icon': Icons.tv_rounded,
        'color': sCable,
        'route': '/services/tv',
      },
      {
        'title': 'Electricity bills',
        'desc':
            'Prepaid meter tokens and postpaid bills for every Disco with token on screen.',
        'icon': Icons.flash_on_rounded,
        'color': sPower,
        'route': '/services/electricity',
      },
      {
        'title': 'Airtime to Cash',
        'desc':
            'Convert excess airtime from MTN, Airtel, and 9mobile directly to cash in your bank or wallet.',
        'icon': Icons.sync_alt_rounded,
        'color': const Color(0xFF14B8A6),
        'route': '/services/airtime',
      },
      {
        'title': 'Recharge card printing',
        'desc':
            'Print customized recharge cards with your business branding and sell offline.',
        'icon': Icons.print_rounded,
        'color': sPrint,
        'route': '/dashboard',
      },
      {
        'title': 'Wallet funding',
        'desc':
            'Dedicated virtual account numbers. Transfer from any bank and it reflects at once.',
        'icon': Icons.account_balance_wallet_rounded,
        'color': sWallet,
        'route': '/wallet/fund',
      },
      {
        'title': 'Referral earnings',
        'desc':
            'Bring people in and earn 2% on first deposits, paid directly into your wallet.',
        'icon': Icons.people_alt_rounded,
        'color': sRefer,
        'route': '/dashboard',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 48,
      ),
      child: Column(
        children: [
          _buildSectionHeader(
            'WHAT YOU CAN BUY',
            'One wallet, everything people pay for',
            'Eight automated services on a single balance. Buy for yourself, or resell to customers.',
          ),
          const SizedBox(height: 36),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.05 : 0.9,
            ),
            itemCount: services.length,
            itemBuilder: (context, i) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final s = services[i];
              return InkWell(
                onTap: () {
                  final auth = context.read<AuthProvider>();
                  if (!auth.isAuthenticated) {
                    TopNotification.showInfo(
                      context,
                      'Please sign in or create an account to access ${s['title']}.',
                      title: 'Authentication Required',
                    );
                    context.push('/login');
                    return;
                  }
                  context.push(s['route'] as String);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141720) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF26334D)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: s['color'] as Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          s['icon'] as IconData,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        s['title'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          s['desc'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Open',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 4. HOW IT WORKS SECTION ("Three steps, about five minutes")
  // ====================================================================
  Widget _buildHowItWorksSection(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 48,
      ),
      color: const Color(0xFF10131B),
      child: Column(
        children: [
          _buildSectionHeader(
            'GETTING STARTED',
            'Three steps, about five minutes',
            'Everything is automated so you can start buying and reselling right away.',
          ),
          const SizedBox(height: 36),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildStepItem(
                        '1',
                        'Create your account',
                        'Name, phone number and a secure password. Setup your 4-digit PIN in 60 seconds.',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStepItem(
                        '2',
                        'Fund your wallet',
                        'You receive dedicated automated bank accounts. Transfer from any bank app and it reflects instantly.',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStepItem(
                        '3',
                        'Start buying or selling',
                        'Buy for yourself or sell to customers with instant receipts and automated transaction protection.',
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildStepItem(
                      '1',
                      'Create your account',
                      'Name, phone number and a secure password. Setup your 4-digit PIN in 60 seconds.',
                    ),
                    const SizedBox(height: 20),
                    _buildStepItem(
                      '2',
                      'Fund your wallet',
                      'You receive dedicated automated bank accounts. Transfer from any bank app and it reflects instantly.',
                    ),
                    const SizedBox(height: 20),
                    _buildStepItem(
                      '3',
                      'Start buying or selling',
                      'Buy for yourself or sell to customers with instant receipts and automated transaction protection.',
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String num, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF26334D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.electricCyan.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.electricCyan,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 6. WHY US SECTION ("Built around what people complain about")
  // ====================================================================
  Widget _buildWhyUsSection(bool isDesktop) {
    final reasons = [
      {
        'title': 'Delivered or refunded',
        'desc':
            'If a network rejects an order, your wallet balance is credited back automatically. Nobody has to chase anyone.',
        'icon': Icons.bolt_rounded,
      },
      {
        'title': 'A PIN on every purchase',
        'desc':
            'Your password signs you in. A dedicated 4-digit security transaction PIN authorises money leaving your wallet.',
        'icon': Icons.lock_outline_rounded,
      },
      {
        'title': 'A receipt for everything',
        'desc':
            'Every order keeps its verifiable reference, token, and status permanently, so disputes are settled in seconds.',
        'icon': Icons.receipt_long_rounded,
      },
      {
        'title': 'Wholesale prices that stay low',
        'desc':
            'Direct provider volume pricing passed straight to you. What you see on the rates page is what you pay.',
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Built for every phone',
        'desc':
            'Lightweight, ultra-fast, and responsive. Works smoothly on low-end Androids as well as high-end devices.',
        'icon': Icons.phone_android_rounded,
      },
      {
        'title': 'Support that actually replies',
        'desc':
            'Direct human assistance on WhatsApp and in-app live chat. Quick answers whenever you need guidance.',
        'icon': Icons.support_agent_rounded,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 48,
      ),
      color: const Color(0xFF10131B),
      child: Column(
        children: [
          _buildSectionHeader(
            'WHY PEOPLE STAY',
            'Built around what people complain about',
            'Not just features that demo well. The real safeguards that decide whether you stay tomorrow.',
          ),
          const SizedBox(height: 36),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 1,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: isDesktop ? 1.6 : 2.2,
            ),
            itemCount: reasons.length,
            itemBuilder: (context, i) {
              final r = reasons[i];
              return Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF141720),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF26334D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.electricCyan.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        r['icon'] as IconData,
                        color: AppColors.electricCyan,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      r['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r['desc'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF94A3B8),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 8. MOBILE SHOWCASE BAND ("Your shop counter fits in your pocket")
  // ====================================================================
  Widget _buildMobilePocketBand(bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 24,
      ),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.electricCyan.withOpacity(0.3)),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ON YOUR PHONE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.electricCyan,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your shop counter fits in your pocket',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'The whole platform runs smoothly in any mobile browser or app. Instant automated funding and lightning top-ups wherever you are.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: const Color(0xFF94A3B8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.push('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Create free account',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 36),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildCheckBullet(
                        'Works on any Android or iPhone browser',
                      ),
                      _buildCheckBullet(
                        'Funding reflects while still in your bank app',
                      ),
                      _buildCheckBullet(
                        'Receipts you can download or forward instantly',
                      ),
                      _buildCheckBullet(
                        'A 4-digit transaction PIN before any money leaves',
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ON YOUR PHONE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.electricCyan,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your shop counter fits in your pocket',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCheckBullet('Works on any Android or iPhone browser'),
                _buildCheckBullet(
                  'Funding reflects while still in your bank app',
                ),
                _buildCheckBullet(
                  'Receipts you can download or forward instantly',
                ),
                _buildCheckBullet(
                  'A 4-digit transaction PIN before money leaves',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create free account',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCheckBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 10. FINAL CTA CONVERSION BANNER
  // ====================================================================
  Widget _buildFinalCtaSection(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Text(
                'Ready to start? It takes two minutes',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 36 : 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No monthly fee, no minimum funding, and zero paperwork. Create your account, fund it with whatever you have, and top-up in seconds.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  height: 1.6,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.push('/register'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      'Create free account',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push('/login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFF26334D),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'I already have one',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // 11. FOOTER (Real Avotek Brand & Links)
  // ====================================================================
  Widget _buildFooter(bool isDesktop) {
    return Container(
      color: const Color(0xFF090B0F),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 48,
      ),
      child: Column(
        children: [
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              AvotekBrandAsset(
                                height: 40,
                                isDark: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'The fastest way to pay for airtime, data, cable TV and electricity in Nigeria. One wallet, wholesale reseller rates, and automatic instant refunds.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF94A3B8),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Services', [
                        {'title': 'Buy airtime', 'route': '/services/airtime'},
                        {'title': 'Buy data', 'route': '/services/data'},
                        {'title': 'Cable TV', 'route': '/services/tv'},
                        {
                          'title': 'Electricity',
                          'route': '/services/electricity',
                        },
                        {'title': 'Fund Wallet', 'route': '/wallet/fund'},
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Company', [
                        {'title': 'About us', 'route': '/rates'},
                        {'title': 'Rates', 'route': '/rates'},
                        {'title': 'Transactions', 'route': '/transactions'},
                        {'title': 'Dashboard', 'route': '/dashboard'},
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Support', [
                        {'title': 'Help centre', 'route': '/dashboard'},
                        {'title': 'WhatsApp Support', 'route': '/dashboard'},
                        {'title': 'Terms of service', 'route': '/'},
                        {'title': 'Privacy policy', 'route': '/'},
                        {'title': 'Refund policy', 'route': '/rates'},
                      ]),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        AvotekBrandAsset(
                          height: 38,
                          isDark: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The fastest way to pay for airtime, data, bills, and cable in Nigeria.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _footerCol('Services', [
                      {'title': 'Buy airtime', 'route': '/services/airtime'},
                      {'title': 'Buy data', 'route': '/services/data'},
                      {'title': 'Cable TV', 'route': '/services/tv'},
                      {
                        'title': 'Electricity',
                        'route': '/services/electricity',
                      },
                    ]),
                  ],
                ),
          const SizedBox(height: 40),
          const Divider(color: Color(0xFF26334D)),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                '© 2023-${DateTime.now().year} by Avo Technologies.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                'Avotek VTU Platform',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppColors.electricCyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerCol(String header, List<Map<String, String>> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...links.map((link) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                final route = link['route']!;
                final isPublic = route == '/' || route == '/rates';
                final auth = context.read<AuthProvider>();
                if (!isPublic && !auth.isAuthenticated) {
                  TopNotification.showInfo(
                    context,
                    'Please sign in or create an account to access ${link['title']}.',
                    title: 'Authentication Required',
                  );
                  context.push('/login');
                  return;
                }
                context.push(route);
              },
              child: Text(
                link['title']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionHeader(String eyebrow, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.electricCyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            eyebrow,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.electricCyan,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
