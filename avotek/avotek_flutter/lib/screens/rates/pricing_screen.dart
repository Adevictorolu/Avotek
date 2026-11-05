import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../widgets/avotek_logo.dart';
import '../../widgets/service_brand_logo.dart';
import '../../widgets/top_notification.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String _selectedNetwork = 'MTN';
  final Map<String, List<Map<String, dynamic>>> _liveNetworkPlans = {};
  bool _isLoadingLive = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLiveRatesFor(_selectedNetwork);
      _fetchLiveExamPrices();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchLiveRatesFor(_selectedNetwork);
      _fetchLiveExamPrices();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveExamPrices() async {
    try {
      final prices = await context.read<VtuProvider>().fetchExamPinPrices();
      if (!mounted || prices.isEmpty) return;
      final amounts = <String, double>{};
      for (final item in prices) {
        final code = (item['code'] ?? item['exam_type'] ?? '')
            .toString()
            .toLowerCase();
        final amount = item['amount'];
        if (amount is num && amount > 0) amounts[code] = amount.toDouble();
      }
      if (amounts.isEmpty) return;
      setState(() {
        for (final item in _cableAndUtility) {
          if (item['cat'] != 'Exam E-Pin') continue;
          final label = (item['item'] as String).toLowerCase();
          final code = amounts.keys.firstWhere(
            label.contains,
            orElse: () => '',
          );
          if (code.isEmpty) continue;
          final amount = amounts[code]!;
          item['price'] =
              '₦${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
        }
      });
    } catch (error) {
      debugPrint('Could not load live exam PIN prices: $error');
    }
  }

  Future<void> _fetchLiveRatesFor(String network) async {
    setState(() => _isLoadingLive = true);
    try {
      final vtu = context.read<VtuProvider>();
      final raw = await vtu.fetchLiveDataPlans(network);
      if (raw.isNotEmpty && mounted) {
        final parsed = raw.map((p) {
          final size = (p['size'] ?? '').toString().trim();
          final vol = (p['plan_volume'] ?? p['volume'] ?? '').toString().trim();
          final type = (p['plantype'] ?? p['plan_type'] ?? p['type'] ?? 'SME').toString().trim().toUpperCase();
          final val = (p['validity'] ?? p['month_validate'] ?? p['plan_day'] ?? '30 Days').toString().trim();
          final fallbackName = (p['plan_name'] ?? p['name'] ?? p['plan'] ?? '').toString().trim();
          final rawAmt = p['amount'] ?? p['plan_amount'] ?? p['price'];
          final price = rawAmt is num ? rawAmt.toDouble() : double.tryParse(rawAmt?.toString() ?? '') ?? 0.0;
          final displayVol = ('$size$vol').trim().isNotEmpty
              ? '$size$vol'
              : (fallbackName.isNotEmpty ? fallbackName : '$type Data');
          return {
            'plan': '$displayVol $type',
            'validity': val,
            'price': price,
          };
        }).where((p) => (p['price'] as double) > 0).toList();

        // Rank from lowest pricing to highest pricing
        parsed.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));

        if (mounted) {
          setState(() {
            _liveNetworkPlans[network] = parsed;
            _isLoadingLive = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingLive = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLive = false);
    }
  }

  final List<Map<String, dynamic>> _airtimeRates = [
    {'network': 'MTN airtime', 'type': 'Instant VTU & SNS top-up', 'price': 'Face value'},
    {'network': 'Glo airtime', 'type': 'Instant VTU top-up', 'price': 'Face value'},
    {'network': 'Airtel airtime', 'type': 'Instant VTU top-up', 'price': 'Face value'},
    {'network': '9mobile / T2 airtime', 'type': 'Instant VTU top-up', 'price': 'Face value'},
  ];

  final List<Map<String, dynamic>> _cableAndUtility = [
    {'item': 'GOtv Smallie', 'cat': 'Cable TV', 'price': 'Live provider price'},
    {'item': 'GOtv Jinja', 'cat': 'Cable TV', 'price': 'Live provider price'},
    {'item': 'GOtv Jolli', 'cat': 'Cable TV', 'price': 'Live provider price'},
    {'item': 'GOtv Max', 'cat': 'Cable TV', 'price': 'Live provider price'},
    {'item': 'GOtv Supa', 'cat': 'Cable TV', 'price': 'Live provider price'},
    {'item': 'DStv Padi', 'cat': 'Cable TV', 'price': 'Live provider price'},
    {'item': 'DStv Yanga', 'cat': 'Cable TV', 'price': 'Live provider price'},
    {'item': 'DStv Compact', 'cat': 'Cable TV', 'price': 'Live provider price'},
    {'item': 'Startimes Nova', 'cat': 'Cable TV', 'price': 'Live provider price'},
    {'item': 'NABTEB Result Checker Pin', 'cat': 'Exam E-Pin', 'price': '₦1,000'},
    {'item': 'NECO Result Checker Pin', 'cat': 'Exam E-Pin', 'price': '₦2,500'},
    {'item': 'WAEC Result Checker Pin', 'cat': 'Exam E-Pin', 'price': '₦5,250'},
    {'item': 'JAMB UTME / DE E-Pin', 'cat': 'Exam E-Pin', 'price': '₦8,200'},
    {'item': 'Ikeja Electric (IKEDC)', 'cat': 'Electricity', 'price': 'Face value + applicable fee'},
    {'item': 'Eko Electricity (EKEDC)', 'cat': 'Electricity', 'price': 'Face value + applicable fee'},
    {'item': 'Abuja Electricity (AEDC)', 'cat': 'Electricity', 'price': 'Face value + applicable fee'},
    {'item': 'Kano Electricity (KEDCO)', 'cat': 'Electricity', 'price': 'Face value + applicable fee'},
    {'item': 'Port Harcourt Electric (PHED)', 'cat': 'Electricity', 'price': 'Face value + applicable fee'},
    {'item': 'Kaduna Electric (KAEDCO)', 'cat': 'Electricity', 'price': 'Face value + applicable fee'},
    {'item': 'Benin Electricity (BEDC)', 'cat': 'Electricity', 'price': 'Face value + applicable fee'},
    {'item': 'Aba Power (APLE)', 'cat': 'Electricity', 'price': 'Face value + applicable fee'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        titleSpacing: isDesktop ? 48 : 16,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        title: InkWell(
          onTap: () => context.go('/'),
          child: const AvotekBrandAsset(
            height: 38,
            hasFrame: true,
            borderRadius: 12,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? AppColors.electricCyan : AppColors.primaryBlue,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (!auth.isAuthenticated) {
                TopNotification.showInfo(
                  context,
                  'Please sign in to access your dashboard.',
                  title: 'Sign In Required',
                );
                context.push('/login');
                return;
              }
              context.push('/dashboard');
            },
            icon: const Icon(Icons.dashboard_rounded, size: 16),
            label: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (!auth.isAuthenticated) {
                TopNotification.showInfo(
                  context,
                  'Please sign in to purchase data plans.',
                  title: 'Sign In Required',
                );
                context.push('/login');
                return;
              }
              context.push('/services/data');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Buy Data', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          SizedBox(width: isDesktop ? 48 : 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Header
                  _buildHeader(isDark),
                  const SizedBox(height: 32),

                  // 2. Data Rates Section with Network switcher
                  _buildDataRatesSection(isDark),
                  const SizedBox(height: 40),

                  // 3. Airtime Reseller Discounts Section
                  _buildAirtimeSection(isDark),
                  const SizedBox(height: 40),

                  // 4. Cable TV and Education Section
                  _buildCableEducationSection(isDark),
                  const SizedBox(height: 48),

                  // 5. Account Tiers Section (Matching Kobopay .tiers)
                  _buildAccountTiersSection(isDesktop, isDark),
                  const SizedBox(height: 40),

                  // 6. Auto-Refund Callout
                  _buildGuaranteeBanner(isDark),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'TRANSPARENT RATES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Every price, in the open',
            style: GoogleFonts.figtree(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No extra surcharge or hidden fee appears at checkout. What you see here is what leaves your wallet, and wholesale rates drop further for certified campus merchants and high-volume agents.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRatesSection(bool isDark) {
    final live = _liveNetworkPlans[_selectedNetwork];
    final plans = live ?? const <Map<String, dynamic>>[];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Data Bundles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_isLoadingLive) ...[
                          const SizedBox(width: 8),
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prices use the provider\'s standard catalog rate',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['MTN', 'Glo', 'Airtel', '9mobile'].map((net) {
                final isSel = _selectedNetwork == net;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: ServiceBrandLogo(provider: net, size: 18, borderRadius: 4),
                    label: Text(
                      net,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.black : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppColors.primaryCyan,
                    backgroundColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
                    onSelected: (_) {
                      setState(() => _selectedNetwork = net);
                      _fetchLiveRatesFor(net);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('BUNDLE PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Text('VALIDITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Text('AVOTEK PRICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)))),
              ],
            ),
          ),
          ...plans.map((p) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        ServiceBrandLogo(provider: _selectedNetwork, size: 20, borderRadius: 5),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p['plan'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(p['validity'] as String, style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '₦${p['price']}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryCyan, fontSize: 15),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          final auth = context.read<AuthProvider>();
                          if (!auth.isAuthenticated) {
                            TopNotification.showInfo(
                              context,
                              'Please sign in or create an account to purchase data plans.',
                              title: 'Sign In Required',
                            );
                            context.push('/login');
                            return;
                          }
                          context.push('/services/data');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Buy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (plans.isEmpty && !_isLoadingLive)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Live data prices are temporarily unavailable. Please try again.'),
            ),
        ],
      ),
    );
  }

  Widget _buildAirtimeSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Airtime top-ups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Airtime is charged at face value. Provider discounts are retained by Avotek.',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('NETWORK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 4, child: Text('TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('PRICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)))),
              ],
            ),
          ),
          ..._airtimeRates.map((r) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        ServiceBrandLogo(provider: r['network'] as String, size: 22, borderRadius: 5),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r['network'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(r['type'] as String, style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r['price'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCableEducationSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cable TV & utility bills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Electricity is charged at face value plus a ₦100 convenience fee.',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('ITEM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 4, child: Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('PRICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)))),
              ],
            ),
          ),
          ..._cableAndUtility.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        ServiceBrandLogo(provider: item['item'] as String, size: 22, borderRadius: 5),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item['item'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(item['cat'] as String, style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        item['price'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryCyan, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 5. ACCOUNT TIERS SECTION (Replicating Kobopay .tiers)
  Widget _buildAccountTiersSection(bool isDesktop, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 14, color: AppColors.warning),
                    SizedBox(width: 6),
                    Text('Account tiers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pay less as you sell more',
                style: GoogleFonts.figtree(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'A one-off upgrade fee, not a subscription. The better rate applies from the moment it clears.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 800;
            return isNarrow
                ? Column(
                    children: [
                      _tierCard('Starter', 'Free', '', 'For buying your own top-ups', [
                        'Every service on the platform',
                        'Standard reseller pricing',
                        'A dedicated account number',
                        'Automatic refund on failed orders',
                        'Receipts kept permanently',
                      ], false, isDark),
                      const SizedBox(height: 16),
                      _tierCard('Agent', '₦5,000', 'one off', 'For selling to walk-in customers', [
                        'Everything in Starter',
                        'A better rate on every service',
                        'Bulk purchase in one order',
                        'Referral earnings on your sign-ups',
                        'Priority support queue',
                      ], true, isDark),
                      const SizedBox(height: 16),
                      _tierCard('Merchant', '₦25,000', 'one off', 'For connecting your own site or app', [
                        'Everything in Agent',
                        'Your own merchant API key',
                        'The best rate available',
                        'A webhook on every delivery',
                        'A named support contact',
                      ], false, isDark),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _tierCard('Starter', 'Free', '', 'For buying your own top-ups', [
                          'Every service on the platform',
                          'Standard reseller pricing',
                          'A dedicated account number',
                          'Automatic refund on failed orders',
                          'Receipts kept permanently',
                        ], false, isDark),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _tierCard('Agent', '₦5,000', 'one off', 'For selling to walk-in customers', [
                          'Everything in Starter',
                          'A better rate on every service',
                          'Bulk purchase in one order',
                          'Referral earnings on your sign-ups',
                          'Priority support queue',
                        ], true, isDark),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _tierCard('Merchant', '₦25,000', 'one off', 'For connecting your own site or app', [
                          'Everything in Agent',
                          'Your own merchant API key',
                          'The best rate available',
                          'A webhook on every delivery',
                          'A named support contact',
                        ], false, isDark),
                      ),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _tierCard(
    String title,
    String price,
    String subtitle,
    String desc,
    List<String> bullets,
    bool isFeatured,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFeatured ? AppColors.primaryCyan : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isFeatured ? 2.0 : 1.0,
        ),
        boxShadow: isFeatured
            ? [
                BoxShadow(
                  color: AppColors.primaryCyan.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (isFeatured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('POPULAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primaryCyan)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: GoogleFonts.figtree(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isFeatured ? AppColors.primaryCyan : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...bullets.map((b) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: isFeatured
                ? ElevatedButton(
                    onPressed: () => context.push('/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Upgrade to Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  )
                : OutlinedButton(
                    onPressed: () => context.push('/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      title == 'Starter' ? 'Get started free' : 'Upgrade to Merchant',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C243B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: AppColors.primaryCyan, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivered Or Automatically Refunded',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryCyan),
                ),
                SizedBox(height: 4),
                Text(
                  'If any network provider fails or encounters a timeout, our idempotent engine credits your wallet in real-time. Zero stress, zero lost funds.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
