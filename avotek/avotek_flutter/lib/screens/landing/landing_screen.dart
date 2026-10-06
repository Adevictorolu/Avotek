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

  // GlobalKeys for accurate smooth scrolling
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _howKey = GlobalKey();
  final GlobalKey _ratesKey = GlobalKey();
  final GlobalKey _whyKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  // Solid service hues matching design tokens
  static const Color sAirtime = Color(0xFF7C3AED); // Solid Violet
  static const Color sData = Color(0xFF2563EB); // Royal Blue
  static const Color sCable = Color(0xFFDB2777); // Pink
  static const Color sPower = Color(0xFFEA580C); // Warm Orange
  static const Color sPrint = Color(0xFF9333EA); // Vibrant Purple
  static const Color sWallet = Color(0xFF059669); // Emerald Green
  static const Color sRefer = Color(0xFFCA8A04); // Amber Gold

  final List<Map<String, dynamic>> _faqs = [
    {
      'q': 'How long does an order take?',
      'a': 'Airtime and data are delivered in under 15 seconds automatically. Cable TV and electricity tokens depend on the provider API and usually deliver in 30 to 60 seconds. You watch the live status update on your screen in real time.',
      'isOpen': true,
    },
    {
      'q': 'What happens when an order fails?',
      'a': 'Your wallet balance is refunded automatically within minutes. You do not need to open a support ticket or chase customer care. Every failed transaction logs the exact gateway reason in your order history.',
      'isOpen': false,
    },
    {
      'q': 'How do I fund my wallet?',
      'a': 'Transfer money directly from any Nigerian banking app (OPay, PalmPay, GTB, Kuda, Zenith, etc.) to the official Avotek PalmPay funding account (8167002789) and your wallet is credited instantly.',
      'isOpen': false,
    },
    {
      'q': 'Is there a minimum balance or subscription fee to start?',
      'a': 'No. There are zero monthly charges, zero maintenance fees, and no minimum balance. You can fund as little as ₦100 and buy or resell immediately.',
      'isOpen': false,
    },
    {
      'q': 'Can I resell VTU services to my own customers?',
      'a': 'Yes! Avotek provides wholesale reseller prices. You buy at reseller rates, set your own selling price for your customers, and keep 100% of your profit margin. Every order generates an instant receipt you can share.',
      'isOpen': false,
    },
    {
      'q': 'Do I need a laptop or computer?',
      'a': 'No. Avotek is fully responsive and optimized for any smartphone browser and Android/iOS devices. You can manage everything directly from your pocket.',
      'isOpen': false,
    },
  ];

  final Map<String, List<Map<String, dynamic>>> _ratePlans = {
    'MTN': [
      {'plan': '500MB SME', 'validity': '30 days', 'price': 140},
      {'plan': '1GB SME', 'validity': '30 days', 'price': 260},
      {'plan': '2GB SME', 'validity': '30 days', 'price': 520},
      {'plan': '5GB SME', 'validity': '30 days', 'price': 1300},
      {'plan': '10GB SME', 'validity': '30 days', 'price': 2600},
    ],
    'Glo': [
      {'plan': '500MB Corp', 'validity': '30 days', 'price': 145},
      {'plan': '1GB Corp', 'validity': '30 days', 'price': 255},
      {'plan': '2GB Corp', 'validity': '30 days', 'price': 510},
      {'plan': '5GB Corp', 'validity': '30 days', 'price': 1275},
      {'plan': '10GB Corp', 'validity': '30 days', 'price': 2550},
    ],
    'Airtel': [
      {'plan': '500MB CG', 'validity': '30 days', 'price': 150},
      {'plan': '1GB CG', 'validity': '30 days', 'price': 265},
      {'plan': '2GB CG', 'validity': '30 days', 'price': 530},
      {'plan': '5GB CG', 'validity': '30 days', 'price': 1325},
      {'plan': '10GB CG', 'validity': '30 days', 'price': 2650},
    ],
    '9mobile': [
      {'plan': '1GB Data', 'validity': '30 days', 'price': 240},
      {'plan': '2GB Data', 'validity': '30 days', 'price': 480},
      {'plan': '3GB Data', 'validity': '30 days', 'price': 720},
      {'plan': '5GB Data', 'validity': '30 days', 'price': 1200},
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F15),
      endDrawer: !isDesktop ? _buildMobileDrawer() : null,
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
                  children: [
                    // Brand Logo + Name
                    InkWell(
                      onTap: () => context.go('/'),
                      child: Row(
                        children: [
                          const AvotekLogo(
                            size: 34,
                            hasFrame: true,
                            showText: false,
                            borderRadius: 10,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Avotek',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 48),
                      _navLink('Services', () => _scrollToKey(_servicesKey)),
                      _navLink('Rates', () => context.push('/rates')),
                      _navLink('How it works', () => _scrollToKey(_howKey)),
                      _navLink('Why us', () => _scrollToKey(_whyKey)),
                      _navLink('FAQ', () => _scrollToKey(_faqKey)),
                    ],
                  ],
                ),
                actions: [
                  if (isDesktop) ...[
                    TextButton(
                      onPressed: () => context.push('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: Text('Sign in', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('Create account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    ),
                    const SizedBox(width: 48),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
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
                        _buildHeroSection(isDesktop),
                        _buildStatsStrip(),
                        Container(key: _servicesKey, child: _buildServicesSection(isDesktop)),
                        Container(key: _howKey, child: _buildHowItWorksSection(isDesktop)),
                        Container(key: _ratesKey, child: _buildRatesSection(isDesktop)),
                        Container(key: _whyKey, child: _buildWhyUsSection(isDesktop)),
                        _buildTestimonialsSection(isDesktop),
                        _buildMobilePocketBand(isDesktop),
                        Container(key: _faqKey, child: _buildFaqSection(isDesktop)),
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

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF141720),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const AvotekLogo(
                    size: 32,
                    hasFrame: true,
                    showText: false,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 10),
                  Text('Avotek', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
            ),
            const Divider(color: Color(0xFF26334D)),
            _drawerItem('Services', () {
              Navigator.pop(context);
              _scrollToKey(_servicesKey);
            }),
            _drawerItem('Rates', () {
              Navigator.pop(context);
              context.push('/rates');
            }),
            _drawerItem('How it works', () {
              Navigator.pop(context);
              _scrollToKey(_howKey);
            }),
            _drawerItem('Why us', () {
              Navigator.pop(context);
              _scrollToKey(_whyKey);
            }),
            _drawerItem('FAQ', () {
              Navigator.pop(context);
              _scrollToKey(_faqKey);
            }),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Sign in', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Create account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
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
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
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
              TextSpan(text: 'Airtime, data and bills.\n'),
              TextSpan(
                text: 'Sorted in seconds.',
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
              label: Text('Create free account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                shadowColor: AppColors.primaryBlue.withOpacity(0.4),
              ),
            ),
            OutlinedButton(
              onPressed: () => context.push('/rates'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF26334D), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('See our rates', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
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
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                children: const [
                  TextSpan(
                    text: '18,400+ people ',
                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
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
    final colors = [AppColors.electricCyan, const Color(0xFF10B981), AppColors.primaryBlue, Colors.purple];
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
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
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
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // User Greeting inside phone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good afternoon', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8))),
                  Text('Ada O.', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.electricCyan.withOpacity(0.2),
                child: Text('AO', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.electricCyan)),
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
                Text('Wallet balance', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 2),
                Text('₦248,500.00', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 8 Quick Service Icons Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPhoneServiceIcon(Icons.phone_android_rounded, 'Airtime', sAirtime),
              _buildPhoneServiceIcon(Icons.wifi_rounded, 'Data', sData),
              _buildPhoneServiceIcon(Icons.tv_rounded, 'Cable', sCable),
              _buildPhoneServiceIcon(Icons.flash_on_rounded, 'Power', sPower),
              _buildPhoneServiceIcon(Icons.sync_alt_rounded, 'Convert', const Color(0xFF14B8A6)),
              _buildPhoneServiceIcon(Icons.sms_rounded, 'SMS', const Color(0xFF6366F1)),
              _buildPhoneServiceIcon(Icons.account_balance_wallet_rounded, 'Fund', sWallet),
              _buildPhoneServiceIcon(Icons.send_rounded, 'Send', sRefer),
            ],
          ),
          const SizedBox(height: 18),

          // Live Activity Items
          Text('RECENT ACTIVITY', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 0.8)),
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
            amount: '+₦50,000',
            isCredit: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneServiceIcon(IconData icon, String label, Color color) {
    return SizedBox(
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
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white70)),
        ],
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
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: Colors.grey)),
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
        'desc': 'MTN, Glo, Airtel and 9mobile at wholesale discount, delivered the second you pay.',
        'icon': Icons.phone_android_rounded,
        'color': sAirtime,
        'route': '/services/airtime',
      },
      {
        'title': 'Data bundles',
        'desc': 'SME, gifting and corporate plans. Daily, weekly and monthly, every single network.',
        'icon': Icons.wifi_rounded,
        'color': sData,
        'route': '/services/data',
      },
      {
        'title': 'Cable TV',
        'desc': 'DStv, GOtv and Startimes renewals. Enter smartcard, the decoder comes on instantly.',
        'icon': Icons.tv_rounded,
        'color': sCable,
        'route': '/services/tv',
      },
      {
        'title': 'Electricity bills',
        'desc': 'Prepaid meter tokens and postpaid bills for every Disco with token on screen.',
        'icon': Icons.flash_on_rounded,
        'color': sPower,
        'route': '/services/electricity',
      },
      {
        'title': 'Airtime to Cash',
        'desc': 'Convert excess airtime from MTN, Airtel, and 9mobile directly to cash in your bank or wallet.',
        'icon': Icons.sync_alt_rounded,
        'color': const Color(0xFF14B8A6),
        'route': '/services/airtime',
      },
      {
        'title': 'Recharge card printing',
        'desc': 'Print customized recharge cards with your business branding and sell offline.',
        'icon': Icons.print_rounded,
        'color': sPrint,
        'route': '/dashboard',
      },
      {
        'title': 'Wallet funding',
        'desc': 'Dedicated virtual account numbers. Transfer from any bank and it reflects at once.',
        'icon': Icons.account_balance_wallet_rounded,
        'color': sWallet,
        'route': '/wallet/fund',
      },
      {
        'title': 'Referral earnings',
        'desc': 'Bring people in and earn 2% on first deposits, paid directly into your wallet.',
        'icon': Icons.people_alt_rounded,
        'color': sRefer,
        'route': '/dashboard',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 48),
      child: Column(
        children: [
          _buildSectionHeader('WHAT YOU CAN BUY', 'One wallet, everything people pay for', 'Eight automated services on a single balance. Buy for yourself, or resell to customers.'),
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
              final s = services[i];
              return InkWell(
                onTap: () => context.push(s['route'] as String),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141720),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF26334D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: s['color'] as Color, borderRadius: BorderRadius.circular(12)),
                        child: Icon(s['icon'] as IconData, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 14),
                      Text(s['title'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          s['desc'] as String,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4),
                        ),
                      ),
                      Row(
                        children: [
                          Text('Open', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.electricCyan)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.electricCyan),
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
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 48),
      color: const Color(0xFF10131B),
      child: Column(
        children: [
          _buildSectionHeader('GETTING STARTED', 'Three steps, about five minutes', 'Everything is automated so you can start buying and reselling right away.'),
          const SizedBox(height: 36),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStepItem('1', 'Create your account', 'Name, phone number and a secure password. Setup your 4-digit PIN in 60 seconds.')),
                    const SizedBox(width: 24),
                    Expanded(child: _buildStepItem('2', 'Fund your wallet', 'You receive dedicated automated bank accounts. Transfer from any bank app and it reflects instantly.')),
                    const SizedBox(width: 24),
                    Expanded(child: _buildStepItem('3', 'Start buying or selling', 'Buy for yourself or sell to customers with instant receipts and automated transaction protection.')),
                  ],
                )
              : Column(
                  children: [
                    _buildStepItem('1', 'Create your account', 'Name, phone number and a secure password. Setup your 4-digit PIN in 60 seconds.'),
                    const SizedBox(height: 20),
                    _buildStepItem('2', 'Fund your wallet', 'You receive dedicated automated bank accounts. Transfer from any bank app and it reflects instantly.'),
                    const SizedBox(height: 20),
                    _buildStepItem('3', 'Start buying or selling', 'Buy for yourself or sell to customers with instant receipts and automated transaction protection.'),
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
              child: Text(num, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.electricCyan)),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 8),
          Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8), height: 1.5)),
        ],
      ),
    );
  }

  // ====================================================================
  // 5. LIVE INTERACTIVE RATES SECTION ("Know the price before you pay")
  // ====================================================================
  Widget _buildRatesSection(bool isDesktop) {
    final networks = ['MTN', 'Glo', 'Airtel', '9mobile'];
    final plans = _ratePlans[_selectedRateNetwork] ?? [];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 48),
      child: Column(
        children: [
          _buildSectionHeader('RATES', 'Know the price before you pay', 'Real-time data bundle prices. Clear, wholesale, and 100% transparent.'),
          const SizedBox(height: 24),
          // Network selector tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: networks.map((net) {
              final isSel = _selectedRateNetwork == net;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InkWell(
                  onTap: () => setState(() => _selectedRateNetwork = net),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primaryBlue : const Color(0xFF141720),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSel ? AppColors.electricCyan : const Color(0xFF26334D)),
                    ),
                    child: Text(
                      net,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSel ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          // Rate Cards Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.5 : 1.3,
            ),
            itemCount: plans.length,
            itemBuilder: (context, i) {
              final p = plans[i];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141720),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF26334D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(p['plan'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(p['validity'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8))),
                    const Spacer(),
                    Text('₦${p["price"]}', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.electricCyan)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/rates'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text('See complete rates table', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E222D),
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF26334D)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        'desc': 'If a network rejects an order, your wallet balance is credited back automatically. Nobody has to chase anyone.',
        'icon': Icons.bolt_rounded,
      },
      {
        'title': 'A PIN on every purchase',
        'desc': 'Your password signs you in. A dedicated 4-digit security transaction PIN authorises money leaving your wallet.',
        'icon': Icons.lock_outline_rounded,
      },
      {
        'title': 'A receipt for everything',
        'desc': 'Every order keeps its verifiable reference, token, and status permanently, so disputes are settled in seconds.',
        'icon': Icons.receipt_long_rounded,
      },
      {
        'title': 'Wholesale prices that stay low',
        'desc': 'Direct provider volume pricing passed straight to you. What you see on the rates page is what you pay.',
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Built for every phone',
        'desc': 'Lightweight, ultra-fast, and responsive. Works smoothly on low-end Androids as well as high-end devices.',
        'icon': Icons.phone_android_rounded,
      },
      {
        'title': 'Support that actually replies',
        'desc': 'Direct human assistance on WhatsApp and in-app live chat. Quick answers whenever you need guidance.',
        'icon': Icons.support_agent_rounded,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 48),
      color: const Color(0xFF10131B),
      child: Column(
        children: [
          _buildSectionHeader('WHY PEOPLE STAY', 'Built around what people complain about', 'Not just features that demo well. The real safeguards that decide whether you stay tomorrow.'),
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
                      decoration: BoxDecoration(color: AppColors.electricCyan.withOpacity(0.18), shape: BoxShape.circle),
                      child: Icon(r['icon'] as IconData, color: AppColors.electricCyan, size: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(r['title'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(r['desc'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8), height: 1.45)),
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
  // 7. TESTIMONIALS SECTION ("What people say")
  // ====================================================================
  Widget _buildTestimonialsSection(bool isDesktop) {
    final reviews = [
      {
        'quote': 'I sell airtime beside my main goods now. A customer pays cash and I load it before they finish counting change. That alone brings people into the shop.',
        'name': 'Amaka Obi',
        'role': 'Phone accessories shop owner, Onitsha',
        'initials': 'AO',
      },
      {
        'quote': 'What sold me was the automated refund. Before this, a network failure meant messaging somebody and waiting till evening. Here it just returns to the wallet by itself.',
        'name': 'Suleiman Bello',
        'role': 'Data reseller, Kaduna',
        'initials': 'SB',
      },
      {
        'quote': 'I fund from my bank app and it reflects before I even switch apps. No more waiting on confirmations when I need data late at night.',
        'name': 'Tolu Adeyemi',
        'role': 'Student & campus reseller, Ibadan',
        'initials': 'TA',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 48),
      child: Column(
        children: [
          _buildSectionHeader('CUSTOMERS', 'What people say', 'Real experiences from everyday merchants, students, and businesses.'),
          const SizedBox(height: 36),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: reviews.map((rev) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: _buildReviewCard(rev)))).toList(),
                )
              : Column(
                  children: reviews.map((rev) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _buildReviewCard(rev))).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, String> rev) {
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
          // 5 Stars
          Row(
            children: List.generate(
              5,
              (_) => const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '“${rev['quote']!}”',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: const Color(0xFFCBD5E1), fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryBlue,
                child: Text(rev['initials']!, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rev['name']!, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(rev['role']!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8))),
                ],
              ),
            ],
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
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 24),
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
                      Text('ON YOUR PHONE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.electricCyan, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Text('Your shop counter fits in your pocket', style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 10),
                      Text('The whole platform runs smoothly in any mobile browser or app. Instant automated funding and lightning top-ups wherever you are.', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF94A3B8), height: 1.5)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.push('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Create free account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 36),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildCheckBullet('Works on any Android or iPhone browser'),
                      _buildCheckBullet('Funding reflects while still in your bank app'),
                      _buildCheckBullet('Receipts you can download or forward instantly'),
                      _buildCheckBullet('A 4-digit transaction PIN before any money leaves'),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ON YOUR PHONE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.electricCyan)),
                const SizedBox(height: 8),
                Text('Your shop counter fits in your pocket', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 16),
                _buildCheckBullet('Works on any Android or iPhone browser'),
                _buildCheckBullet('Funding reflects while still in your bank app'),
                _buildCheckBullet('Receipts you can download or forward instantly'),
                _buildCheckBullet('A 4-digit transaction PIN before money leaves'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Create free account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
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
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 9. FAQ SECTION (Accordion)
  // ====================================================================
  Widget _buildFaqSection(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 48),
      child: Column(
        children: [
          _buildSectionHeader('QUESTIONS', 'Frequently asked', 'Everything you need to know about wallet funding, automated refunds, and reselling.'),
          const SizedBox(height: 36),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: _faqs.map((faq) {
                final isOpen = faq['isOpen'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141720),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF26334D)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: isOpen,
                      title: Text(
                        faq['q'] as String,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      iconColor: AppColors.electricCyan,
                      collapsedIconColor: Colors.grey,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            faq['a'] as String,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: const Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 64),
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
                style: GoogleFonts.plusJakartaSans(fontSize: 14.5, height: 1.6, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.push('/register'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text('Create free account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push('/login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF26334D), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('I already have one', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
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
                          Row(
                            children: [
                              const AvotekLogo(
                                size: 28,
                                hasFrame: true,
                                showText: false,
                                borderRadius: 8,
                              ),
                              const SizedBox(width: 8),
                              Text('Avotek', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'The fastest way to pay for airtime, data, cable TV and electricity in Nigeria. One wallet, wholesale reseller rates, and automatic instant refunds.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8), height: 1.6),
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
                        {'title': 'Result pins', 'route': '/services/exam'},
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Company', [
                        {'title': 'About us', 'route': '/rates'},
                        {'title': 'Rates', 'route': '/rates'},
                        {'title': 'Become an agent', 'route': '/dashboard'},
                        {'title': 'Developer API', 'route': '/admin-portal'},
                        {'title': 'Transactions', 'route': '/transactions'},
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
                      children: [
                        const AvotekLogo(
                          size: 28,
                          hasFrame: true,
                          showText: false,
                          borderRadius: 8,
                        ),
                        const SizedBox(width: 8),
                        Text('Avotek', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The fastest way to pay for airtime, data, bills, and cable in Nigeria.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 24),
                    _footerCol('Services', [
                      {'title': 'Buy airtime', 'route': '/services/airtime'},
                      {'title': 'Buy data', 'route': '/services/data'},
                      {'title': 'Cable TV', 'route': '/services/tv'},
                      {'title': 'Electricity', 'route': '/services/electricity'},
                    ]),
                  ],
                ),
          const SizedBox(height: 40),
          const Divider(color: Color(0xFF26334D)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© ${DateTime.now().year} Avotek. All rights reserved.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
              Text(
                'Avotek VTU Platform',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.electricCyan, fontWeight: FontWeight.w700),
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
        Text(header, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 12),
        ...links.map((link) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => context.push(link['route']!),
              child: Text(
                link['title']!,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionHeader(String eyebrow, String title, String subtitle) {
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
            color: Colors.white,
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
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
