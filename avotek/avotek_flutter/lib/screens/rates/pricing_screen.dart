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
    {'network': 'MTN', 'discount': '2.5% Cashback', 'sample': '₦1,000 top-up costs ₦975'},
    {'network': 'Glo', 'discount': '3.5% Cashback', 'sample': '₦1,000 top-up costs ₦965'},
    {'network': 'Airtel', 'discount': '2.5% Cashback', 'sample': '₦1,000 top-up costs ₦975'},
    {'network': '9mobile', 'discount': '4.0% Cashback', 'sample': '₦1,000 top-up costs ₦960'},
  ];

  final List<Map<String, dynamic>> _examPins = [
    {'service': 'WAEC Result Checker', 'desc': 'Original official WAEC e-PIN', 'fee': '₦3,500.00'},
    {'service': 'NECO Result Token', 'desc': 'NECO electronic verification token', 'fee': '₦1,200.00'},
    {'service': 'NABTEB Result PIN', 'desc': 'Instant verification card pin', 'fee': '₦1,100.00'},
    {'service': 'JAMB UTME PIN', 'desc': 'Profile registration e-PIN with mock', 'fee': '₦6,800.00'},
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
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Header
                  _buildHeader(isDark),
                  const SizedBox(height: 32),

                  // Data Rates Section
                  _buildDataRatesSection(isDark),
                  const SizedBox(height: 40),

                  // Airtime Discounts Section
                  _buildAirtimeSection(isDark),
                  const SizedBox(height: 40),

                  // Exam Result PINs Section
                  _buildExamSection(isDark),
                  const SizedBox(height: 40),

                  // Auto-Refund Callout
                  _buildGuaranteeBanner(isDark),
                  const SizedBox(height: 40),
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
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w900,
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
                    label: Text(net, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? Colors.black : (isDark ? Colors.white : Colors.black))),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Airtime Reseller Discounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Discount percentage deducted directly before debiting your wallet balance.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: _airtimeRates.length,
            itemBuilder: (context, idx) {
              final r = _airtimeRates[idx];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r['network'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(r['discount'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r['sample'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExamSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Academic Examination PINs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Official examination tokens with verified PIN & Serial combination generated instantly.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
          ),
          const SizedBox(height: 16),
          ..._examPins.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.15),
                    child: const Icon(Icons.school, size: 16, color: AppColors.primaryCyan),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['service'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(item['desc'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    item['fee'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryCyan, fontSize: 14),
                  ),
                ],
              ),
            );
          }),
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
