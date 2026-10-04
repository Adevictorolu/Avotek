import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/avotek_logo.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String _selectedNetwork = 'MTN';

  final Map<String, List<Map<String, dynamic>>> _dataPlans = {
    'MTN': [
      {'plan': '500MB SME', 'validity': '30 days', 'was': 400, 'price': 340},
      {'plan': '1GB SME', 'validity': '30 days', 'was': 700, 'price': 620},
      {'plan': '2GB SME', 'validity': '30 days', 'was': 1400, 'price': 1240},
      {'plan': '3GB SME', 'validity': '30 days', 'was': 2100, 'price': 1860},
      {'plan': '5GB SME', 'validity': '30 days', 'was': 3500, 'price': 3100},
      {'plan': '10GB SME', 'validity': '30 days', 'was': 4000, 'price': 3400},
      {'plan': '15GB SME', 'validity': '30 days', 'was': 6000, 'price': 5100},
      {'plan': '20GB SME', 'validity': '30 days', 'was': 8000, 'price': 6800},
    ],
    'Glo': [
      {'plan': '1GB Corporate', 'validity': '30 days', 'was': 350, 'price': 280},
      {'plan': '2GB Corporate', 'validity': '30 days', 'was': 700, 'price': 560},
      {'plan': '3GB Corporate', 'validity': '30 days', 'was': 1050, 'price': 840},
      {'plan': '5GB Corporate', 'validity': '30 days', 'was': 1750, 'price': 1400},
      {'plan': '10GB Corporate', 'validity': '30 days', 'was': 3500, 'price': 2800},
      {'plan': '20GB Corporate', 'validity': '30 days', 'was': 7000, 'price': 5600},
    ],
    'Airtel': [
      {'plan': '500MB Gifting', 'validity': '30 days', 'was': 400, 'price': 350},
      {'plan': '1GB Gifting', 'validity': '30 days', 'was': 750, 'price': 640},
      {'plan': '2GB Gifting', 'validity': '30 days', 'was': 1500, 'price': 1280},
      {'plan': '5GB Gifting', 'validity': '30 days', 'was': 3750, 'price': 3200},
      {'plan': '10GB Gifting', 'validity': '30 days', 'was': 4500, 'price': 4000},
      {'plan': '15GB Gifting', 'validity': '30 days', 'was': 6800, 'price': 6000},
    ],
    '9mobile': [
      {'plan': '1GB SME', 'validity': '30 days', 'was': 400, 'price': 300},
      {'plan': '2GB SME', 'validity': '30 days', 'was': 800, 'price': 600},
      {'plan': '3GB SME', 'validity': '30 days', 'was': 1200, 'price': 900},
      {'plan': '5GB SME', 'validity': '30 days', 'was': 2000, 'price': 1500},
      {'plan': '10GB SME', 'validity': '30 days', 'was': 4000, 'price': 3000},
      {'plan': '20GB SME', 'validity': '30 days', 'was': 8000, 'price': 6000},
    ],
  };

  final List<Map<String, dynamic>> _airtimeRates = [
    {'network': 'MTN airtime', 'type': 'Instant top-up', 'discount': '3.0% off'},
    {'network': 'Glo airtime', 'type': 'Instant top-up', 'discount': '5.0% off'},
    {'network': 'Airtel airtime', 'type': 'Instant top-up', 'discount': '3.5% off'},
    {'network': '9mobile airtime', 'type': 'Instant top-up', 'discount': '5.5% off'},
  ];

  final List<Map<String, dynamic>> _cableAndUtility = [
    {'item': 'DStv Padi', 'cat': 'Cable TV', 'price': '₦4,400'},
    {'item': 'DStv Yanga', 'cat': 'Cable TV', 'price': '₦6,000'},
    {'item': 'DStv Compact', 'cat': 'Cable TV', 'price': '₦19,000'},
    {'item': 'GOtv Smallie', 'cat': 'Cable TV', 'price': '₦1,900'},
    {'item': 'GOtv Jinja', 'cat': 'Cable TV', 'price': '₦3,900'},
    {'item': 'Startimes Nova', 'cat': 'Cable TV', 'price': '₦1,900'},
    {'item': 'IKEDC / EKEDC Prepaid', 'cat': 'Electricity', 'price': 'Face Value'},
    {'item': 'AEDC / IBEDC Prepaid', 'cat': 'Electricity', 'price': 'Face Value'},
    {'item': 'SportyBet / Bet9ja Funding', 'cat': 'Betting', 'price': 'Zero Fee'},
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
        title: const AvotekLogo(size: 32, showText: true),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/dashboard'),
            icon: const Icon(Icons.dashboard_rounded, size: 16),
            label: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push('/services/data'),
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
            style: GoogleFonts.plusJakartaSans(
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
    final plans = _dataPlans[_selectedNetwork] ?? [];

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
                    const Text('Data Bundles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Crossed-out figure represents network telecom sticker price',
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
                    onSelected: (_) => setState(() => _selectedNetwork = net),
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
                Expanded(flex: 3, child: Text('DISCOUNT PRICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)))),
              ],
            ),
          ),
          ...plans.map((p) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(p['plan'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(p['validity'] as String, style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Text('₦${p['was']}', style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 8),
                        Text(
                          '₦${p['price']}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryCyan, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => context.push('/services/data'),
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
                const Text('Airtime discounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Buy ₦1,000 of airtime and discount leaves your wallet directly.',
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
                Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('DISCOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)))),
              ],
            ),
          ),
          ..._airtimeRates.map((r) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(r['network'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                          r['discount'] as String,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(item['item'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(
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
