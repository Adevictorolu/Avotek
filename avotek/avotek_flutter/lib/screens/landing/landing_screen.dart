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

  final List<Map<String, dynamic>> _faqs = [
    {
      'q': 'How long does an order take?',
      'a': 'Airtime and data are usually delivered in under fifteen seconds. Cable TV and electricity depend on the utility provider, so those can take up to a minute during peak hours. You can watch the status update in real time.',
      'isOpen': true,
    },
    {
      'q': 'What happens when an order fails?',
      'a': 'Your wallet is refunded automatically. You do not need to open a ticket or contact support. The failed order remains in your transaction history with the failure reason attached.',
      'isOpen': false,
    },
    {
      'q': 'How do I fund my wallet?',
      'a': 'Every Avotek account receives a dedicated virtual account number (Wema Bank / Providus / Moniepoint). Transfer from any Nigerian bank app and your wallet is credited instantly.',
      'isOpen': false,
    },
    {
      'q': 'Is there a minimum amount to start?',
      'a': 'No. Fund with whatever amount you choose. There is no minimum funding requirement, no monthly subscription fee, and no dormant account charge.',
      'isOpen': false,
    },
    {
      'q': 'Can I resell to my own customers or students?',
      'a': 'Yes! That is what thousands of agents and campus merchants do on Avotek. You buy at our wholesale discount price and charge your customer whatever you choose. The profit is yours.',
      'isOpen': false,
    },
    {
      'q': 'Do I need a laptop or special hardware?',
      'a': 'No. The entire platform works seamlessly in any smartphone browser, Android app, or iPhone with zero performance lag.',
      'isOpen': false,
    },
  ];

  final Map<String, List<Map<String, dynamic>>> _ratePlans = {
    'MTN': [
      {'plan': '500MB SME', 'validity': '30 days', 'price': 340, 'was': 400},
      {'plan': '1GB SME', 'validity': '30 days', 'price': 620, 'was': 700},
      {'plan': '2GB SME', 'validity': '30 days', 'price': 1240, 'was': 1400},
      {'plan': '3GB SME', 'validity': '30 days', 'price': 1860, 'was': 2100},
      {'plan': '5GB SME', 'validity': '30 days', 'price': 3100, 'was': 3500},
      {'plan': '10GB SME', 'validity': '30 days', 'price': 3400, 'was': 4000},
    ],
    'Glo': [
      {'plan': '1GB Corporate', 'validity': '30 days', 'price': 280, 'was': 350},
      {'plan': '2GB Corporate', 'validity': '30 days', 'price': 560, 'was': 700},
      {'plan': '3GB Corporate', 'validity': '30 days', 'price': 840, 'was': 1050},
      {'plan': '5GB Corporate', 'validity': '30 days', 'price': 1400, 'was': 1750},
      {'plan': '10GB Corporate', 'validity': '30 days', 'price': 2800, 'was': 3500},
      {'plan': '20GB Corporate', 'validity': '30 days', 'price': 5600, 'was': 7000},
    ],
    'Airtel': [
      {'plan': '500MB Gifting', 'validity': '30 days', 'price': 350, 'was': 400},
      {'plan': '1GB Gifting', 'validity': '30 days', 'price': 640, 'was': 750},
      {'plan': '2GB Gifting', 'validity': '30 days', 'price': 1280, 'was': 1500},
      {'plan': '5GB Gifting', 'validity': '30 days', 'price': 3200, 'was': 3750},
      {'plan': '10GB Gifting', 'validity': '30 days', 'price': 4000, 'was': 4500},
      {'plan': '15GB Gifting', 'validity': '30 days', 'price': 6000, 'was': 6800},
    ],
    '9mobile': [
      {'plan': '1GB SME', 'validity': '30 days', 'price': 300, 'was': 400},
      {'plan': '2GB SME', 'validity': '30 days', 'price': 600, 'was': 800},
      {'plan': '3GB SME', 'validity': '30 days', 'price': 900, 'was': 1200},
      {'plan': '5GB SME', 'validity': '30 days', 'price': 1500, 'was': 2000},
      {'plan': '10GB SME', 'validity': '30 days', 'price': 3000, 'was': 4000},
      {'plan': '20GB SME', 'validity': '30 days', 'price': 6000, 'was': 8000},
    ],
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(double offset) {
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
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
                  const SizedBox(width: 48),
                  _navLink('Services', () => _scrollToSection(600), isDark),
                  _navLink('Rates', () => context.push('/rates'), isDark),
                  _navLink('How it works', () => _scrollToSection(1300), isDark),
                  _navLink('Why us', () => _scrollToSection(1800), isDark),
                  _navLink('FAQ', () => _scrollToSection(2600), isDark),
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
              const SizedBox(width: 8),
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
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: const Text('Create account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              SizedBox(width: isDesktop ? 48 : 16),
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
                    _buildServicesSection(isDesktop, isDark),
                    _buildHowItWorksSection(isDesktop, isDark),
                    _buildRatesPreviewSection(isDesktop, isDark),
                    _buildWhyUsSection(isDesktop, isDark),
                    _buildTestimonialsSection(isDesktop, isDark),
                    _buildPhoneCounterBanner(isDesktop, isDark),
                    _buildFaqSection(isDesktop, isDark),
                    _buildReadyCtaBanner(isDesktop, isDark),
                    _buildFooter(isDesktop, isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
        ),
      ),
    );
  }

  // 1. HERO SECTION
  Widget _buildHeroSection(bool isDesktop, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: isDesktop ? 60 : 36,
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
                const SizedBox(height: 36),
                _buildPhoneMockup(isDark),
              ],
            ),
    );
  }

  Widget _buildHeroCopy(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pill note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.primaryCyan),
              SizedBox(width: 6),
              Text(
                'Dedicated account numbers are live',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryCyan,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            style: GoogleFonts.montserrat(
              fontSize: 38,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.8,
            ),
            children: [
              const TextSpan(text: 'Airtime, data & bills.\n'),
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
        Text(
          'One wallet for every top-up you make and every one you sell. Fund from any bank, buy at reseller prices, and get your money back automatically when a network misbehaves.',
          style: TextStyle(
            fontSize: 15,
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
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Create free account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: Colors.black,
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
        Row(
          children: [
            _buildAvatarGroup(),
            const SizedBox(width: 12),
            Text(
              '18,400+ students & agents buy weekly',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
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

  // INTERACTIVE PHONE MOCKUP (Matching Kobopay)
  Widget _buildPhoneMockup(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone top
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.primaryCyan],
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 8 mini service tiles
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniServiceTile('Airtime', Icons.phone_android, AppColors.primaryCyan),
              _miniServiceTile('Data', Icons.wifi, AppColors.success),
              _miniServiceTile('Cable', Icons.tv, Colors.pink),
              _miniServiceTile('Power', Icons.bolt, AppColors.warning),
              _miniServiceTile('Exams', Icons.school, Colors.cyan),
              _miniServiceTile('Print', Icons.print, Colors.deepPurple),
              _miniServiceTile('Fund', Icons.account_balance_wallet, Colors.teal),
              _miniServiceTile('Send', Icons.send, Colors.indigo),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Recent Orders',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
          const SizedBox(height: 8),
          _miniTxTile('MTN 10GB SME', 'Delivered • 12:41', '-₦3,400', isDark, false),
          _miniTxTile('Wallet Funding', 'Credited • 11:52', '+₦100,000', isDark, true),
        ],
      ),
    );
  }

  Widget _miniServiceTile(String label, IconData icon, Color color) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _miniTxTile(String title, String sub, String amt, bool isDark, bool isCredit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey)),
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

  // 2. STATS STRIP
  Widget _buildStatsStrip(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w900,
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

  // 3. SERVICES SECTION
  Widget _buildServicesSection(bool isDesktop, bool isDark) {
    final services = [
      {'title': 'Airtime top-up', 'desc': 'MTN, Glo, Airtel and 9mobile at wholesale discount, delivered immediately.', 'icon': Icons.phone_android, 'color': AppColors.primaryCyan, 'route': '/services/airtime'},
      {'title': 'Data bundles', 'desc': 'SME, Gifting and Corporate plans. Daily, weekly and monthly, every network.', 'icon': Icons.wifi, 'color': AppColors.success, 'route': '/services/data'},
      {'title': 'Cable TV', 'desc': 'DStv, GOtv and Startimes renewals. Instant decoder recharge without downtime.', 'icon': Icons.tv, 'color': Colors.pink, 'route': '/services/tv'},
      {'title': 'Electricity DISCOs', 'desc': 'Prepaid tokens and postpaid bills for all DISCOs. Token generated instantly.', 'icon': Icons.bolt, 'color': AppColors.warning, 'route': '/services/electricity'},
      {'title': 'Result checkers', 'desc': 'WAEC, NECO and NABTEB pins issued instantly. Zero reselling or duplicate pins.', 'icon': Icons.school, 'color': Colors.cyan, 'route': '/services/exam_pin'},
      {'title': 'Card printing', 'desc': 'Print branded recharge pins in custom layouts and sell offline in your school/store.', 'icon': Icons.print, 'color': Colors.deepPurple, 'route': '/services/airtime'},
      {'title': 'Wallet funding', 'desc': 'Dedicated account number with instant bank transfer credit and zero delay.', 'icon': Icons.account_balance_wallet, 'color': Colors.teal, 'route': '/wallet/fund'},
      {'title': 'Referral earnings', 'desc': 'Invite friends and fellow students, and earn commissions on every top-up they make.', 'icon': Icons.group_add, 'color': Colors.indigo, 'route': '/dashboard'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 48),
      child: Column(
        children: [
          _sectionHeader('WHAT YOU CAN BUY', 'One wallet, everything people pay for', 'Eight core academic & utility services on a single balance. Buy for yourself, or sell to customers.', isDark),
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
                        backgroundColor: (s['color'] as Color).withValues(alpha: 0.15),
                        child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                      ),
                      const SizedBox(height: 14),
                      Text(s['title'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          s['desc'] as String,
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey, height: 1.4),
                        ),
                      ),
                      Row(
                        children: [
                          Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 12, color: AppColors.primaryCyan),
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

  // 4. HOW IT WORKS
  Widget _buildHowItWorksSection(bool isDesktop, bool isDark) {
    final steps = [
      {'step': '1', 'title': 'Create your account', 'desc': 'Name, phone number and a secure password. Verify once with OTP and you are ready to top up.'},
      {'step': '2', 'title': 'Fund your wallet', 'desc': 'You get an assigned dedicated account number. Transfer from any Nigerian banking app and funds reflect instantly.'},
      {'step': '3', 'title': 'Start transacting & selling', 'desc': 'Top up for yourself or sell to customers and students. Every order includes a permanent downloadable receipt.'},
    ];

    return Container(
      color: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        children: [
          _sectionHeader('GETTING STARTED', 'Three steps, about two minutes', 'No paperwork, no manual authorization. Start topping up in moments.', isDark),
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
            child: Text(num, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
        ],
      ),
    );
  }

  // 5. RATES PREVIEW SECTION
  Widget _buildRatesPreviewSection(bool isDesktop, bool isDark) {
    final plans = _ratePlans[_selectedRateNetwork] ?? [];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('RATES', 'Know the price before you pay', 'A sample of our wholesale data plans. Full rates for all networks, airtime discounts and bills are on the rates page.', isDark),
          const SizedBox(height: 24),
          // Network selector tabs
          Row(
            children: ['MTN', 'Glo', 'Airtel', '9mobile'].map((net) {
              final isSel = _selectedRateNetwork == net;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(net, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? Colors.black : (isDark ? Colors.white : Colors.black))),
                  selected: isSel,
                  selectedColor: AppColors.primaryCyan,
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  onSelected: (_) => setState(() => _selectedRateNetwork = net),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Rates cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: plans.length,
            itemBuilder: (context, idx) {
              final p = plans[idx];
              return Container(
                padding: const EdgeInsets.all(16),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '₦${p['was']}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough),
                        ),
                        Text(
                          '₦${p['price']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryCyan),
                        ),
                      ],
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
            label: const Text('See every price & discount', style: TextStyle(fontWeight: FontWeight.w700)),
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

  // 6. WHY US SECTION
  Widget _buildWhyUsSection(bool isDesktop, bool isDark) {
    final features = [
      {'title': 'Delivered or refunded', 'desc': 'If a network drops an order, the funds are credited back automatically. Nobody has to chase anyone.', 'icon': Icons.bolt_rounded},
      {'title': 'A PIN on every purchase', 'desc': 'Your password logs you in. A separate 4-digit transaction PIN authorizes money leaving your wallet.', 'icon': Icons.lock_outline_rounded},
      {'title': 'A receipt for everything', 'desc': 'Every order stores its transaction reference, token, and timestamp permanently for instant dispute resolution.', 'icon': Icons.receipt_long_rounded},
      {'title': 'Prices that stay low', 'desc': 'Aggregator volume discounts passed directly to you. What you see is what leaves your wallet.', 'icon': Icons.trending_down_rounded},
      {'title': 'Built for any phone', 'desc': 'Optimized for smooth performance on entry-level Android devices as well as high-end iPhones and PCs.', 'icon': Icons.smartphone_rounded},
      {'title': 'Support that replies', 'desc': 'Direct WhatsApp human support during business hours and an automated ticketing pipeline for quick follow-ups.', 'icon': Icons.support_agent_rounded},
    ];

    return Container(
      color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        children: [
          _sectionHeader('WHY PEOPLE STAY', 'Built around what people complain about', 'Not flashy features that only look good in demos. The core reliability that keeps your business running.', isDark),
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
                    Icon(f['icon'] as IconData, size: 24, color: AppColors.primaryCyan),
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

  // 7. TESTIMONIALS SECTION
  Widget _buildTestimonialsSection(bool isDesktop, bool isDark) {
    final reviews = [
      {
        'text': 'I sell airtime beside my stationery shop now. A customer pays cash and I deliver it before they finish counting change. That alone brings people into the shop.',
        'name': 'Amaka Obi',
        'role': 'Runs phone accessories shop, Onitsha',
        'avatar': 'AO',
      },
      {
        'text': 'What sold me was the instant refund. Before Avotek, a failed order meant messaging someone and waiting till evening. Here it just returns to the wallet automatically.',
        'name': 'Suleiman Bello',
        'role': 'Campus Data Reseller, Kaduna',
        'avatar': 'SB',
      },
      {
        'text': 'I fund via bank app transfer and it reflects before I even switch back. No more waiting for manual confirmations when I need to purchase midnight data or an exam pin.',
        'name': 'Tolu Adeyemi',
        'role': 'Undergraduate Student, Ibadan',
        'avatar': 'TA',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        children: [
          _sectionHeader('CUSTOMERS', 'What people say', 'Real experiences from students, agents, and store owners across Nigeria.', isDark),
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
              fontStyle: FontStyle.italic,
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

  // 8. PHONE COUNTER BANNER (Matching Kobopay .band)
  Widget _buildPhoneCounterBanner(bool isDesktop, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 32),
      padding: EdgeInsets.all(isDesktop ? 44 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F2B48), const Color(0xFF061826)]
              : [const Color(0xFF0084D6), const Color(0xFF005A94)],
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
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'The entire platform runs in your mobile browser or as an app. Fast, lightweight, and zero bloat.',
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
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Create free account', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            OutlinedButton(
              onPressed: () => context.push('/dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Preview dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBandChecklist() {
    final pts = [
      'Works in any Android or iPhone browser without downloads',
      'Bank transfers credit while you are still inside your bank app',
      'Downloadable transaction receipts you can share with customers',
      'Mandatory 4-digit transaction PIN before any money leaves',
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

  // 9. FAQ SECTION
  Widget _buildFaqSection(bool isDesktop, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 56),
      child: Column(
        children: [
          _sectionHeader('QUESTIONS', 'Frequently asked', 'Everything you need to know about purchasing and reselling on Avotek.', isDark),
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

  // 10. READY CTA BANNER
  Widget _buildReadyCtaBanner(bool isDesktop, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            'Ready to start? It takes two minutes',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'No monthly fee, no minimum funding and no paperwork. Create your account, fund with whatever you have, and buy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Create free account', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: Colors.black,
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
                child: const Text('I already have an account', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 11. FOOTER
  Widget _buildFooter(bool isDesktop, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCard : const Color(0xFF0F172A),
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
                            'Production-grade Nigerian VTU & Academic Utilities Platform. Built for schools, students, and high-volume retail agents.',
                            style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Services', [
                        {'title': 'Buy Airtime', 'route': '/services/airtime'},
                        {'title': 'Buy Data', 'route': '/services/data'},
                        {'title': 'Cable TV', 'route': '/services/tv'},
                        {'title': 'Electricity', 'route': '/services/electricity'},
                        {'title': 'Result PINs', 'route': '/services/exam_pin'},
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Company', [
                        {'title': 'Rates & Pricing', 'route': '/rates'},
                        {'title': 'Agent Program', 'route': '/dashboard'},
                        {'title': 'Developer API', 'route': '/admin'},
                        {'title': 'Admin Console', 'route': '/admin'},
                      ]),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerCol('Support', [
                        {'title': 'WhatsApp Support', 'route': '/community'},
                        {'title': 'Transaction Dispute', 'route': '/transactions'},
                        {'title': 'Refund Policy', 'route': '/rates'},
                        {'title': 'Terms of Service', 'route': '/landing'},
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
                      'Production-grade Nigerian VTU & Academic Utilities Platform.',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 24),
                    _footerCol('Services', [
                      {'title': 'Buy Airtime', 'route': '/services/airtime'},
                      {'title': 'Buy Data', 'route': '/services/data'},
                      {'title': 'Rates', 'route': '/rates'},
                      {'title': 'Dashboard', 'route': '/dashboard'},
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
                '© ${DateTime.now().year} AVOTEK Platform. All rights reserved.',
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
              Text(
                'High-Speed PostgreSQL & Serverpod Powered',
                style: TextStyle(fontSize: 11, color: AppColors.primaryCyan.withValues(alpha: 0.6)),
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

  Widget _sectionHeader(String eyebrow, String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            eyebrow,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.primaryCyan,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
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
    );
  }
}
