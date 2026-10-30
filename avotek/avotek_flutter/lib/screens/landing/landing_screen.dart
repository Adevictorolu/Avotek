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
  static const Color sPower = Color(0xFF00D2FF); // Electric Cyan

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
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
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
                backgroundColor: (isDark ? AppColors.darkBg : AppColors.lightBg)
                    .withOpacity(0.96),
                titleSpacing: isDesktop ? 48 : 16,
                title: Row(
                  mainAxisAlignment: isDesktop
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    // Brand Logo + Name
                    InkWell(
                      onTap: () => context.go('/'),
                      child: AvotekBrandAsset(
                        height: 42,
                        isDark: isDark,
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
                        color: isDark ? Colors.white : AppColors.darkBg,
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
                        foregroundColor: isDark
                            ? Colors.white
                            : AppColors.darkBg,
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
                        color: isDark ? Colors.white : AppColors.darkBg,
                        size: 20,
                      ),
                      tooltip: isDark
                          ? 'Switch to Light Mode'
                          : 'Switch to Dark Mode',
                      onPressed: () =>
                          context.read<ThemeProvider>().toggleTheme(),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.menu_rounded,
                        color: isDark ? Colors.white : AppColors.darkBg,
                      ),
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
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  AvotekBrandAsset(
                    height: 40,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
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
                        foregroundColor: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.darkBg,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? Colors.white : AppColors.darkBg,
              letterSpacing: -1.0,
            ),
            children: const [
              TextSpan(text: 'Everyday services,\nmade simpler. '),
              TextSpan(
                text: 'One connected platform.',
                style: TextStyle(
                  color: AppColors.electricCyan,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Deck
        Text(
          'Manage mobile top-ups and essential bill payments from one account, with secure sign-in and clear transaction status.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
          ),
        ),
        const SizedBox(height: 28),

        // CTAs: create an account or explore service information.
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.push('/register'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                'Create account',
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
                foregroundColor: isDark ? Colors.white : AppColors.darkBg,
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Explore services',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        Text(
          'Airtime  ·  Data  ·  Cable TV  ·  Electricity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
          ),
        ),
      ],
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
                    'Welcome to',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    'Your Avotek account',
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
                  'Your service wallet',
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
            ],
          ),
          const SizedBox(height: 18),

          // Live Activity Items
          Text(
            'ORDER TRACKING',
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
            title: 'Transaction history',
            subtitle: 'Review order references and status',
            amount: '',
            isCredit: false,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
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
                      'COMMON SERVICE OPERATORS',
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
                    'Options depend on provider availability',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.darkBg,
                    ),
                  ),
                ],
              ),
              if (isDesktop)
                Text(
                  'Available options are confirmed in each service',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.metallicLight
                        : AppColors.slateGrey,
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
                  color: isDark ? AppColors.darkBg : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
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
                            color: isDark ? Colors.white : AppColors.darkBg,
                          ),
                        ),
                        Text(
                          p['type']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.metallicLight
                                : AppColors.slateGrey,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;
          if (isNarrow) {
            return Column(
              children: [
                _buildStatItem(Icons.lock_outline_rounded, 'Secure account'),
                Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                _buildStatItem(Icons.dashboard_outlined, 'One workspace'),
                Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                _buildStatItem(Icons.receipt_long_outlined, 'Order status'),
                Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                _buildStatItem(Icons.hub_outlined, 'Connected services'),
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.lock_outline_rounded, 'Secure account'),
              Container(
                width: 1,
                height: 40,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              _buildStatItem(Icons.dashboard_outlined, 'One workspace'),
              Container(
                width: 1,
                height: 40,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              _buildStatItem(Icons.receipt_long_outlined, 'Order status'),
              Container(
                width: 1,
                height: 40,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              _buildStatItem(Icons.hub_outlined, 'Connected services'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: isDark ? AppColors.electricCyan : AppColors.primaryBlue,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
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
        'desc': 'Choose a mobile network and top-up amount.',
        'icon': Icons.phone_android_rounded,
        'color': sAirtime,
        'route': '/services/airtime',
      },
      {
        'title': 'Data bundles',
        'desc': 'Browse available plans for supported networks.',
        'icon': Icons.wifi_rounded,
        'color': sData,
        'route': '/services/data',
      },
      {
        'title': 'Cable TV',
        'desc': 'Verify a smartcard and choose a subscription package.',
        'icon': Icons.tv_rounded,
        'color': sCable,
        'route': '/services/tv',
      },
      {
        'title': 'Electricity bills',
        'desc': 'Verify a meter before paying a supported electricity bill.',
        'icon': Icons.flash_on_rounded,
        'color': sPower,
        'route': '/services/electricity',
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
            'AVOTEK SERVICES',
            'Your everyday tools, together',
            'Sign in once to manage mobile top-ups, cable subscriptions and electricity payments in one clear workspace.',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 48,
      ),
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: Column(
        children: [
          _buildSectionHeader(
            'GETTING STARTED',
            'A straightforward flow',
            'Sign in, choose a service, and follow its status from your account.',
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
                        'Enter your account details and complete the prompts.',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStepItem(
                        '2',
                        'Choose a service',
                        'Open airtime, data, cable TV or electricity from the same workspace.',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStepItem(
                        '3',
                        'Review the result',
                        'Confirm your details before ordering, then check the reference and status.',
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildStepItem(
                      '1',
                      'Create your account',
                      'Enter your account details and complete the prompts.',
                    ),
                    const SizedBox(height: 20),
                    _buildStepItem(
                      '2',
                      'Choose a service',
                      'Open airtime, data, cable TV or electricity from the same workspace.',
                    ),
                    const SizedBox(height: 20),
                    _buildStepItem(
                      '3',
                      'Review the result',
                      'Confirm your details before ordering, then check the reference and status.',
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String num, String title, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
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
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasons = [
      {
        'title': 'Protected sign-in',
        'desc':
            'Account access and purchase confirmation are handled as separate steps.',
        'icon': Icons.lock_outline_rounded,
      },
      {
        'title': 'One clear workspace',
        'desc':
            'Move between supported top-ups and bill services without switching apps.',
        'icon': Icons.dashboard_outlined,
      },
      {
        'title': 'Traceable orders',
        'desc':
            'Keep transaction references and check order status from your account.',
        'icon': Icons.receipt_long_rounded,
      },
      {
        'title': 'Built for mobile',
        'desc':
            'A responsive layout keeps the main actions easy to reach on phones and desktop.',
        'icon': Icons.phone_android_rounded,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 48,
      ),
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: Column(
        children: [
          _buildSectionHeader(
            'THE AVOTEK APPROACH',
            'Technology that stays out of your way',
            'Secure account access, connected service flows and readable transaction status in one focused app.',
          ),
          const SizedBox(height: 36),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 1,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: isDesktop ? 0.95 : 2.2,
            ),
            itemCount: reasons.length,
            itemBuilder: (context, i) {
              final r = reasons[i];
              return Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
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
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r['desc'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.metallicLight
                            : AppColors.slateGrey,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 24,
      ),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'The responsive layout keeps account and service actions easy to use on a phone or desktop.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: isDark
                              ? AppColors.metallicLight
                              : AppColors.slateGrey,
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
                          'Create account',
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
                      _buildCheckBullet('Clear purchase confirmation steps'),
                      _buildCheckBullet('Transaction references and status'),
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
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildCheckBullet('Works on any Android or iPhone browser'),
                _buildCheckBullet('Clear purchase confirmation steps'),
                _buildCheckBullet('Transaction references and status'),
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
                      'Create account',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                'Ready to get started?',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 36 : 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Create an account to explore the available services and manage your orders in one place.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  height: 1.6,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
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
                      'Create account',
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
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
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
                            children: [
                              AvotekBrandAsset(
                                height: 40,
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'A connected workspace for supported mobile top-ups, cable subscriptions and electricity services.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppColors.metallicLight
                                  : AppColors.slateGrey,
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
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Explore', [
                        {'title': 'Services', 'route': '/rates'},
                        {'title': 'Rates', 'route': '/rates'},
                        {'title': 'Transactions', 'route': '/transactions'},
                        {'title': 'Dashboard', 'route': '/dashboard'},
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Account', [
                        {'title': 'Sign in', 'route': '/login'},
                        {'title': 'Create account', 'route': '/register'},
                      ]),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AvotekBrandAsset(
                          height: 38,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A connected workspace for supported mobile and bill services.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.metallicLight
                            : AppColors.slateGrey,
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
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.darkBg,
          ),
        ),
        const SizedBox(height: 12),
        ...links.map((link) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                final route = link['route']!;
                final isPublic = {
                  '/',
                  '/rates',
                  '/login',
                  '/register',
                }.contains(route);
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
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
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
