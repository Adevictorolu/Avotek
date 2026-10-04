import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/avotek_logo.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const LandingScreen({super.key, required this.onToggleTheme});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String _selectedRateNetwork = 'MTN';
  final ScrollController _scrollController = ScrollController();
  bool _showDemoRibbon = true;

  // GlobalKeys for accurate smooth scrolling to sections
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _howKey = GlobalKey();
  final GlobalKey _ratesKey = GlobalKey();
  final GlobalKey _whyKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  // Solid service hues matching Kobo template design tokens
  static const Color sAirtime = Color(0xFF7C3AED); // Solid Violet
  static const Color sData = Color(0xFF2563EB); // Royal Blue
  static const Color sCable = Color(0xFFDB2777); // Pink
  static const Color sPower = Color(0xFFEA580C); // Warm Orange
  static const Color sExam = Color(0xFF0891B2); // Cyan / Teal
  static const Color sPrint = Color(0xFF9333EA); // Vibrant Purple
  static const Color sWallet = Color(0xFF059669); // Emerald Green
  static const Color sTransfer = Color(0xFF4F46E5); // Indigo
  static const Color sRefer = Color(0xFFCA8A04); // Amber Gold

  final List<Map<String, dynamic>> _faqs = [
    {
      'q': 'How long does an order take?',
      'a': 'Airtime and data are usually done in under fifteen seconds. Cable and electricity depend on the provider, so those can take a minute at peak times. Either way you watch the status change, you are not left guessing.',
      'isOpen': true,
    },
    {
      'q': 'What happens when an order fails?',
      'a': 'The wallet is refunded automatically. You do not open a ticket and you do not chase anybody. The failed order stays in your history with its reason attached.',
      'isOpen': false,
    },
    {
      'q': 'How do I fund my wallet?',
      'a': 'Every account gets a dedicated account number. Transfer to it from any Nigerian bank app and the wallet is credited immediately. Card funding is there too if you prefer it.',
      'isOpen': false,
    },
    {
      'q': 'Is there a minimum to start?',
      'a': 'No. Fund with whatever you have and buy from it. There is no monthly fee and no dormant account charge.',
      'isOpen': false,
    },
    {
      'q': 'Can I resell to my own customers?',
      'a': 'Yes, and that is what most people here do. You buy at your price and charge your customers whatever you like. The difference is yours.',
      'isOpen': false,
    },
    {
      'q': 'Do I need a laptop?',
      'a': 'No. Everything works in a phone browser, including funding, buying and downloading receipts.',
      'isOpen': false,
    },
  ];

  // Exact 4-plan sample rates matching Kobo index rates table
  final Map<String, List<Map<String, dynamic>>> _ratePlans = {
    'MTN': [
      {'plan': '500MB', 'validity': '30 days', 'price': 340},
      {'plan': '1GB', 'validity': '30 days', 'price': 620},
      {'plan': '2GB', 'validity': '30 days', 'price': 1240},
      {'plan': '5GB', 'validity': '30 days', 'price': 3100},
    ],
    'Glo': [
      {'plan': '1GB', 'validity': '30 days', 'price': 280},
      {'plan': '2GB', 'validity': '30 days', 'price': 560},
      {'plan': '5GB', 'validity': '30 days', 'price': 1400},
      {'plan': '10GB', 'validity': '30 days', 'price': 2800},
    ],
    'Airtel': [
      {'plan': '500MB', 'validity': '30 days', 'price': 350},
      {'plan': '1GB', 'validity': '30 days', 'price': 640},
      {'plan': '2GB', 'validity': '30 days', 'price': 1280},
      {'plan': '5GB', 'validity': '30 days', 'price': 3200},
    ],
    '9mobile': [
      {'plan': '1GB', 'validity': '30 days', 'price': 300},
      {'plan': '2GB', 'validity': '30 days', 'price': 600},
      {'plan': '3GB', 'validity': '30 days', 'price': 900},
      {'plan': '5GB', 'validity': '30 days', 'price': 1500},
    ],
  };

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
    final isDesktop = screenWidth >= 960;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      endDrawer: !isDesktop ? _buildMobileDrawer(isDark) : null,
      body: Builder(
        builder: (scaffoldContext) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 0. Optional Demo Announcement Ribbon matching Kobo
              if (_showDemoRibbon)
                SliverToBoxAdapter(
                  child: Container(
                    color: isDark ? const Color(0xFF162032) : const Color(0xFFE0F2FE),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0369A1),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Live VTU Platform. ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0C4A6E),
                                  ),
                                ),
                                const TextSpan(
                                  text: 'Dedicated NUBAN funding & automated refunds are active. Top up in seconds.',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _showDemoRibbon = false),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Sticky Top Navigation Bar
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: isDark
                    ? AppColors.darkBg.withValues(alpha: 0.95)
                    : AppColors.lightBg.withValues(alpha: 0.95),
                titleSpacing: isDesktop ? 48 : 16,
                title: Row(
                  children: [
                    const AvotekLogo(size: 34, showText: true),
                    if (isDesktop) ...[
                      const SizedBox(width: 40),
                      _navLink('Services', () => _scrollToKey(_servicesKey), isDark),
                      _navLink('Rates', () => context.push('/rates'), isDark),
                      _navLink('How it works', () => _scrollToKey(_howKey), isDark),
                      _navLink('Why us', () => _scrollToKey(_whyKey), isDark),
                      _navLink('FAQ', () => _scrollToKey(_faqKey), isDark),
                    ],
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Toggle Theme',
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 20,
                      color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                    ),
                    onPressed: widget.onToggleTheme,
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        foregroundColor: const Color(0xFF0A0E17),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: const Text('Create account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                    const SizedBox(width: 48),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
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
                        _buildHeroSection(isDesktop, isDark),
                        _buildStatsStrip(isDark),
                        Container(key: _servicesKey, child: _buildServicesSection(isDesktop, isDark)),
                        Container(key: _howKey, child: _buildHowItWorksSection(isDesktop, isDark)),
                        Container(key: _ratesKey, child: _buildRatesPreviewSection(isDesktop, isDark)),
                        Container(key: _whyKey, child: _buildWhyUsSection(isDesktop, isDark)),
                        _buildTestimonialsSection(isDesktop, isDark),
                        _buildPhoneCounterBanner(isDesktop, isDark),
                        Container(key: _faqKey, child: _buildFaqSection(isDesktop, isDark)),
                        _buildReadyCtaBanner(isDesktop, isDark),
                        _buildFooter(isDesktop, isDark),
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
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AvotekLogo(size: 32, showText: true),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded, size: 20),
              title: const Text('Services', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(context).pop();
                _scrollToKey(_servicesKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card_rounded, size: 20),
              title: const Text('Rates', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/rates');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bolt_rounded, size: 20),
              title: const Text('How it works', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(context).pop();
                _scrollToKey(_howKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined, size: 20),
              title: const Text('Why us', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(context).pop();
                _scrollToKey(_whyKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded, size: 20),
              title: const Text('FAQ', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(context).pop();
                _scrollToKey(_faqKey);
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: const Color(0xFF0A0E17),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Create free account', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // 1. HERO SECTION (Matching Kobopay .hero)
  // ====================================================================
  Widget _buildHeroSection(bool isDesktop, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: isDesktop ? 64 : 36,
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: _buildHeroCopy(isDark)),
                const SizedBox(width: 48),
                Expanded(flex: 5, child: _buildPhoneMockup(isDark)),
              ],
            )
          : Column(
              children: [
                _buildHeroCopy(isDark),
                const SizedBox(height: 40),
                _buildPhoneMockup(isDark),
              ],
            ),
    );
  }

  Widget _buildHeroCopy(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pill note: New Dedicated account numbers are live
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.primaryCyan),
              const SizedBox(width: 6),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 12, color: AppColors.primaryCyan),
                  children: [
                    TextSpan(text: 'New  ', style: TextStyle(fontWeight: FontWeight.w900)),
                    TextSpan(text: 'Dedicated account numbers are live', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Headline: Airtime, data and bills. Sorted in seconds.
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 38,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.8,
            ),
            children: const [
              TextSpan(text: 'Airtime, data and bills.\n'),
              TextSpan(
                text: 'Sorted in seconds.',
                style: TextStyle(
                  color: AppColors.primaryCyan,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Deck: One wallet for every top-up you make and every one you sell...
        Text(
          'One wallet for every top-up you make and every one you sell. Fund it from any bank, buy at reseller prices, and get your money back automatically when a network misbehaves.',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
          ),
        ),
        const SizedBox(height: 28),
        // CTAs: Create free account -> / See our rates
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Create free account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: const Color(0xFF0A0E17),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            OutlinedButton(
              onPressed: () => context.push('/rates'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('See our rates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Trust social proof: 4 avatars + 18,400 people buy here every week
        Row(
          children: [
            _buildAvatarGroup(),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
                children: [
                  TextSpan(
                    text: '18,400 people ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const TextSpan(text: 'buy here every week'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarGroup() {
    final colors = [AppColors.primaryCyan, AppColors.success, AppColors.warning, Colors.purple];
    final initials = ['AO', 'SB', 'TA', 'NE'];
    return SizedBox(
      height: 32,
      width: 88,
      child: Stack(
        children: List.generate(4, (i) {
          return Positioned(
            left: i * 18.0,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: colors[i],
              child: Text(
                initials[i],
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ====================================================================
  // INTERACTIVE PHONE MOCKUP (Matching Kobopay .phone & .phone__screen)
  // ====================================================================
  Widget _buildPhoneMockup(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speaker notch simulation
          Center(
            child: Container(
              width: 54,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Phone Top Card (Gradient with wallet balance)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0077B6), AppColors.primaryCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good afternoon', style: TextStyle(fontSize: 10, color: Colors.white70)),
                        Text('Ada O.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: const Text('AO', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Wallet balance', style: TextStyle(fontSize: 10, color: Colors.white70)),
                const Text(
                  '₦248,500.00',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 8 Quick Service Icons (Solid circular badges matching Kobo tokens)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniServiceTile('Airtime', Icons.phone_android_rounded, sAirtime, () => context.push('/services/airtime')),
              _miniServiceTile('Data', Icons.wifi_rounded, sData, () => context.push('/services/data')),
              _miniServiceTile('Cable', Icons.tv_rounded, sCable, () => context.push('/services/tv')),
              _miniServiceTile('Power', Icons.bolt_rounded, sPower, () => context.push('/services/electricity')),
              _miniServiceTile('Exams', Icons.school_rounded, sExam, () => context.push('/services/exam_pin')),
              _miniServiceTile('Print', Icons.print_rounded, sPrint, () => context.push('/services/airtime')),
              _miniServiceTile('Fund', Icons.account_balance_wallet_rounded, sWallet, () => context.push('/wallet/fund')),
              _miniServiceTile('Send', Icons.send_rounded, sTransfer, () => context.push('/dashboard')),
            ],
          ),
          const SizedBox(height: 16),

          // Live Recent Transactions List
          Text(
            'Recent Orders',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
          const SizedBox(height: 8),
          _miniTxTile('MTN 10GB SME', 'Delivered • 12:41', '-₦3,400', isDark, false, sData, Icons.wifi_rounded),
          _miniTxTile('Wallet funding', 'Credited • 11:52', '+₦100,000', isDark, true, sWallet, Icons.account_balance_wallet_rounded),
        ],
      ),
    );
  }

  Widget _miniServiceTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color,
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTxTile(String title, String sub, String amt, bool isDark, bool isCredit, Color dotColor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: dotColor,
                child: Icon(icon, size: 11, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Text(
            amt,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isCredit ? AppColors.success : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 2. STATS STRIP (Matching Kobopay .stats-wrap & .stats)
  // ====================================================================
  Widget _buildStatsStrip(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return isNarrow
              ? Column(
                  children: [
                    _statItem('99.9%', 'Orders delivered first try', isDark),
                    const Divider(height: 24),
                    _statItem('186,000+', 'Top-ups processed', isDark),
                    const Divider(height: 24),
                    _statItem('12 sec', 'Average delivery time', isDark),
                    const Divider(height: 24),
                    _statItem('24/7', 'Support that answers', isDark),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('99.9%', 'Orders delivered first try', isDark),
                    _statItem('186,000+', 'Top-ups processed', isDark),
                    _statItem('12 sec', 'Average delivery time', isDark),
                    _statItem('24/7', 'Support that answers', isDark),
                  ],
                );
        },
      ),
    );
  }

  Widget _statItem(String val, String label, bool isDark) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryCyan,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ====================================================================
  // 3. SERVICES SECTION (Matching Kobopay #services)
  // ====================================================================
  Widget _buildServicesSection(bool isDesktop, bool isDark) {
    final services = [
      {
        'title': 'Airtime top-up',
        'desc': 'MTN, Glo, Airtel and 9mobile at a discount, delivered the second you pay.',
        'icon': Icons.phone_android_rounded,
        'color': sAirtime,
        'route': '/services/airtime',
      },
      {
        'title': 'Data bundles',
        'desc': 'SME, gifting and corporate plans. Daily, weekly and monthly, every network.',
        'icon': Icons.wifi_rounded,
        'color': sData,
        'route': '/services/data',
      },
      {
        'title': 'Cable TV',
        'desc': 'DStv, GOtv and Startimes renewals. Enter the smartcard, the box comes back on.',
        'icon': Icons.tv_rounded,
        'color': sCable,
        'route': '/services/tv',
      },
      {
        'title': 'Electricity',
        'desc': 'Prepaid tokens and postpaid bills for every disco, token shown on screen.',
        'icon': Icons.bolt_rounded,
        'color': sPower,
        'route': '/services/electricity',
      },
      {
        'title': 'Result checkers',
        'desc': 'WAEC, NECO and NABTEB pins issued instantly, never resold to anyone else.',
        'icon': Icons.school_rounded,
        'color': sExam,
        'route': '/services/exam_pin',
      },
      {
        'title': 'Card printing',
        'desc': 'Print your own recharge cards in your own design and sell them offline.',
        'icon': Icons.print_rounded,
        'color': sPrint,
        'route': '/services/airtime',
      },
      {
        'title': 'Wallet funding',
        'desc': 'A dedicated account number. Transfer from any bank and it reflects at once.',
        'icon': Icons.account_balance_wallet_rounded,
        'color': sWallet,
        'route': '/wallet/fund',
      },
      {
        'title': 'Referral earnings',
        'desc': 'Bring people in and earn on everything they buy, paid into the same wallet.',
        'icon': Icons.group_add_rounded,
        'color': sRefer,
        'route': '/dashboard',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        children: [
          _sectionHeader(
            'WHAT YOU CAN BUY',
            'One wallet, everything people pay for',
            'Eight services on a single balance. Buy for yourself, or sell to the customer standing in front of you.',
            isDark,
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(height: 36),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.05 : 1.3,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              return InkWell(
                onTap: () => context.push(s['route'] as String),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: s['color'] as Color,
                        child: Icon(s['icon'] as IconData, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 14),
                      Text(s['title'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          s['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primaryCyan),
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
  // 4. HOW IT WORKS (Matching Kobopay #how)
  // ====================================================================
  Widget _buildHowItWorksSection(bool isDesktop, bool isDark) {
    final steps = [
      {
        'step': '1',
        'title': 'Create your account',
        'desc': 'Name, phone number and a password. One OTP and you are in, no paperwork.',
      },
      {
        'step': '2',
        'title': 'Fund your wallet',
        'desc': 'You get a dedicated account number. Transfer from any bank app and it lands instantly.',
      },
      {
        'step': '3',
        'title': 'Start selling',
        'desc': 'Buy for yourself or for a customer standing in front of you. Every order keeps a receipt.',
      },
    ];

    return Container(
      color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8F6FD),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        children: [
          _sectionHeader(
            'GETTING STARTED',
            'Three steps, about five minutes',
            '',
            isDark,
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 36),
          isDesktop
              ? Row(
                  children: steps.map((s) => Expanded(child: _stepCard(s['step']!, s['title']!, s['desc']!, isDark))).toList(),
                )
              : Column(
                  children: steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _stepCard(s['step']!, s['title']!, s['desc']!, isDark))).toList(),
                ),
        ],
      ),
    );
  }

  Widget _stepCard(String num, String title, String desc, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryCyan,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(num, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0A0E17), fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
        ],
      ),
    );
  }

  // ====================================================================
  // 5. RATES PREVIEW SECTION (Matching Kobopay #rates)
  // ====================================================================
  Widget _buildRatesPreviewSection(bool isDesktop, bool isDark) {
    final plans = _ratePlans[_selectedRateNetwork] ?? [];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'RATES',
            'Know the price before you pay',
            'A sample of the data plans. The full list, including airtime discounts, cable and electricity, is on the rates page.',
            isDark,
            icon: Icons.credit_card_rounded,
          ),
          const SizedBox(height: 28),
          // Network selector tabs
          Row(
            children: ['MTN', 'Glo', 'Airtel', '9mobile'].map((net) {
              final isSel = _selectedRateNetwork == net;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    net,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSel ? const Color(0xFF0A0E17) : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppColors.primaryCyan,
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  onSelected: (_) => setState(() => _selectedRateNetwork = net),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Exact 4 rates cards matching Kobopay
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: plans.length,
            itemBuilder: (context, idx) {
              final p = plans[idx];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p['plan'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(p['validity'] as String, style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
                      ],
                    ),
                    Text(
                      '₦${p['price']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryCyan),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/rates'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('See every price', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkCardVariant : const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 6. WHY US SECTION (Matching Kobopay #why)
  // ====================================================================
  Widget _buildWhyUsSection(bool isDesktop, bool isDark) {
    final features = [
      {
        'title': 'Delivered or refunded',
        'desc': 'If a network rejects an order the wallet is credited back automatically. Nobody has to chase anybody.',
        'icon': Icons.bolt_rounded,
      },
      {
        'title': 'A PIN on every purchase',
        'desc': 'Your password signs you in. A separate transaction PIN authorises money leaving the wallet.',
        'icon': Icons.shield_outlined,
      },
      {
        'title': 'A receipt for everything',
        'desc': 'Every order keeps its reference, token and status permanently, so a dispute is settled in seconds.',
        'icon': Icons.receipt_long_rounded,
      },
      {
        'title': 'Prices that stay low',
        'desc': 'Volume pricing passed straight down. What you see on the rates page is what you are charged.',
        'icon': Icons.trending_down_rounded,
      },
      {
        'title': 'Built for a phone',
        'desc': 'The whole platform works on the cheapest Android in the shop, not only on a laptop.',
        'icon': Icons.smartphone_rounded,
      },
      {
        'title': 'Support that replies',
        'desc': 'A human on WhatsApp during working hours, and a ticket trail for anything that needs following up.',
        'icon': Icons.support_agent_rounded,
      },
    ];

    return Container(
      color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8F6FD),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        children: [
          _sectionHeader(
            'WHY PEOPLE STAY',
            'Built around what people complain about',
            'Not the features that demo well. The ones that decide whether somebody comes back tomorrow.',
            isDark,
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 36),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.4 : 1.6,
            ),
            itemCount: features.length,
            itemBuilder: (context, idx) {
              final f = features[idx];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.15),
                      child: Icon(f['icon'] as IconData, size: 20, color: AppColors.primaryCyan),
                    ),
                    const SizedBox(height: 12),
                    Text(f['title'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      f['desc'] as String,
                      style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
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
  // 7. TESTIMONIALS SECTION (Matching Kobopay What people say)
  // ====================================================================
  Widget _buildTestimonialsSection(bool isDesktop, bool isDark) {
    final reviews = [
      {
        'text': 'I sell airtime beside my main goods now. A customer pays me cash and I load it before they finish counting change. That alone brings people into the shop.',
        'name': 'Amaka Obi',
        'role': 'Runs a phone accessories shop, Onitsha',
        'avatar': 'AO',
      },
      {
        'text': 'What sold me was the refund. Before this, a failed order meant messaging somebody and waiting till evening. Here it just comes back into the wallet by itself.',
        'name': 'Suleiman Bello',
        'role': 'Data reseller, Kaduna',
        'avatar': 'SB',
      },
      {
        'text': 'I fund from my bank app and it reflects before I switch back. No more waiting on a confirmation before I can buy data at 2am.',
        'name': 'Tolu Adeyemi',
        'role': 'Student, Ibadan',
        'avatar': 'TA',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        children: [
          _sectionHeader(
            'CUSTOMERS',
            'What people say',
            '',
            isDark,
            icon: Icons.star_rounded,
          ),
          const SizedBox(height: 36),
          isDesktop
              ? Row(
                  children: reviews.map((r) => Expanded(child: _testimonialCard(r, isDark))).toList(),
                )
              : Column(
                  children: reviews.map((r) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _testimonialCard(r, isDark))).toList(),
                ),
        ],
      ),
    );
  }

  Widget _testimonialCard(Map<String, String> r, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (_) => const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '"${r['text']}"',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.2),
                child: Text(r['avatar']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(r['role']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 8. POCKET COUNTER BAND (Matching Kobopay .band)
  // ====================================================================
  Widget _buildPhoneCounterBanner(bool isDesktop, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 32),
      padding: EdgeInsets.all(isDesktop ? 44 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F2B48), const Color(0xFF061826)]
              : [const Color(0xFF0077B6), const Color(0xFF005A94)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(flex: 6, child: _buildBandCopy()),
                const SizedBox(width: 36),
                Expanded(flex: 5, child: _buildBandChecklist()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBandCopy(),
                const SizedBox(height: 24),
                _buildBandChecklist(),
              ],
            ),
    );
  }

  Widget _buildBandCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.smartphone_rounded, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text('ON YOUR PHONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your shop counter fits in your pocket',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'The whole platform runs in a phone browser. Add it to your home screen and it opens like an app, with no download and no storage taken.',
          style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: const Color(0xFF0A0E17),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Create free account', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            OutlinedButton(
              onPressed: () => context.push('/dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Preview the dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBandChecklist() {
    final pts = [
      'Works in any Android or iPhone browser',
      'Funding reflects while you are still in your bank app',
      'Receipts you can download or forward to a customer',
      'A transaction PIN before any money leaves',
    ];

    return Column(
      children: pts.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primaryCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p,
                  style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ====================================================================
  // 9. FAQ SECTION (Matching Kobopay #faq)
  // ====================================================================
  Widget _buildFaqSection(bool isDesktop, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8F6FD),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        children: [
          _sectionHeader(
            'QUESTIONS',
            'Frequently asked',
            '',
            isDark,
            icon: Icons.support_agent_rounded,
          ),
          const SizedBox(height: 36),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: List.generate(_faqs.length, (idx) {
                final faq = _faqs[idx];
                final isOpen = faq['isOpen'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: isOpen,
                    shape: const Border(),
                    title: Text(
                      faq['q'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['a'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 10. BOTTOM READY CTA BANNER
  // ====================================================================
  Widget _buildReadyCtaBanner(bool isDesktop, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            'Ready to start? It takes two minutes',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'No monthly fee, no minimum funding and no paperwork. Create the account, fund it with whatever you have, and buy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Create free account', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: const Color(0xFF0A0E17),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              OutlinedButton(
                onPressed: () => context.push('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('I already have one', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 11. FOOTER (Matching Kobopay .foot)
  // ====================================================================
  Widget _buildFooter(bool isDesktop, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF070B12) : const Color(0xFF0F172A),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 48),
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
                          const AvotekLogo(size: 32, showText: true, isDark: true),
                          const SizedBox(height: 14),
                          const Text(
                            'One wallet for educational utilities and VTU. Dedicated accounts, instant delivery, automated refunds.',
                            style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.6),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _socialIcon(Icons.email_outlined, () => context.push('/community')),
                              const SizedBox(width: 10),
                              _socialIcon(Icons.phone_outlined, () => context.push('/community')),
                              const SizedBox(width: 10),
                              _socialIcon(Icons.language_rounded, () => context.push('/')),
                            ],
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
                        {'title': 'Electricity', 'route': '/services/electricity'},
                        {'title': 'Result pins', 'route': '/services/exam_pin'},
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Company', [
                        {'title': 'About us', 'route': '/rates'},
                        {'title': 'Rates', 'route': '/rates'},
                        {'title': 'Become an agent', 'route': '/dashboard'},
                        {'title': 'Developer API', 'route': '/admin-portal'},
                        {'title': 'Blog', 'route': '/community'},
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Support', [
                        {'title': 'Help centre', 'route': '/community'},
                        {'title': 'Contact us', 'route': '/community'},
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
                    const AvotekLogo(size: 30, showText: true, isDark: true),
                    const SizedBox(height: 12),
                    const Text(
                      'One wallet for educational utilities and VTU. Dedicated accounts, instant delivery, automated refunds.',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 24),
                    _footerCol('Services', [
                      {'title': 'Buy airtime', 'route': '/services/airtime'},
                      {'title': 'Buy data', 'route': '/services/data'},
                      {'title': 'Cable TV', 'route': '/services/tv'},
                      {'title': 'Electricity', 'route': '/services/electricity'},
                      {'title': 'Result pins', 'route': '/services/exam_pin'},
                    ]),
                  ],
                ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© ${DateTime.now().year} Avotek. Leveraging Technology in Education.',
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
              Text(
                'Built on the Avotek VTU Platform',
                style: TextStyle(fontSize: 11, color: AppColors.primaryCyan.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white10,
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
  }

  Widget _footerCol(String header, List<Map<String, String>> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(header, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ...links.map((link) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => context.push(link['route']!),
              child: Text(
                link['title']!,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _sectionHeader(String eyebrow, String title, String subtitle, bool isDark, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: AppColors.primaryCyan),
                const SizedBox(width: 5),
              ],
              Text(
                eyebrow,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.primaryCyan,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
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
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
