import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_logo.dart';
import '../../widgets/pin_modal.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final _phoneController = TextEditingController(text: '0803 411 9920');
  String _selectedNetwork = 'MTN';
  String _selectedBundleType = 'SME, cheapest per gigabyte';
  Map<String, dynamic>? _selectedPlan;

  final List<String> _networks = ['MTN', 'Glo', 'Airtel', '9mobile'];
  final List<String> _bundleTypes = [
    'SME, cheapest per gigabyte',
    'Gifting, shows as gift on recipient line',
    'Corporate, bulk student & business volume',
  ];

  final Map<String, List<Map<String, dynamic>>> _plansMap = {
    'MTN': [
      {'plan': '500MB', 'validity': '30 days', 'price': 340.0, 'code': 'MTN-500MB'},
      {'plan': '1GB', 'validity': '30 days', 'price': 620.0, 'code': 'MTN-1GB'},
      {'plan': '2GB', 'validity': '30 days', 'price': 1240.0, 'code': 'MTN-2GB'},
      {'plan': '3GB', 'validity': '30 days', 'price': 1860.0, 'code': 'MTN-3GB'},
      {'plan': '5GB', 'validity': '30 days', 'price': 3100.0, 'code': 'MTN-5GB'},
      {'plan': '10GB', 'validity': '30 days', 'price': 3400.0, 'code': 'MTN-10GB'},
      {'plan': '20GB', 'validity': '30 days', 'price': 6800.0, 'code': 'MTN-20GB'},
    ],
    'Glo': [
      {'plan': '1GB', 'validity': '30 days', 'price': 280.0, 'code': 'GLO-1GB'},
      {'plan': '2GB', 'validity': '30 days', 'price': 560.0, 'code': 'GLO-2GB'},
      {'plan': '3GB', 'validity': '30 days', 'price': 840.0, 'code': 'GLO-3GB'},
      {'plan': '5GB', 'validity': '30 days', 'price': 1400.0, 'code': 'GLO-5GB'},
      {'plan': '10GB', 'validity': '30 days', 'price': 2800.0, 'code': 'GLO-10GB'},
      {'plan': '20GB', 'validity': '30 days', 'price': 5600.0, 'code': 'GLO-20GB'},
    ],
    'Airtel': [
      {'plan': '500MB', 'validity': '30 days', 'price': 350.0, 'code': 'AIR-500MB'},
      {'plan': '1GB', 'validity': '30 days', 'price': 640.0, 'code': 'AIR-1GB'},
      {'plan': '2GB', 'validity': '30 days', 'price': 1280.0, 'code': 'AIR-2GB'},
      {'plan': '5GB', 'validity': '30 days', 'price': 3200.0, 'code': 'AIR-5GB'},
      {'plan': '10GB', 'validity': '30 days', 'price': 4000.0, 'code': 'AIR-10GB'},
      {'plan': '15GB', 'validity': '30 days', 'price': 6000.0, 'code': 'AIR-15GB'},
    ],
    '9mobile': [
      {'plan': '1GB', 'validity': '30 days', 'price': 300.0, 'code': '9MOB-1GB'},
      {'plan': '2GB', 'validity': '30 days', 'price': 600.0, 'code': '9MOB-2GB'},
      {'plan': '3GB', 'validity': '30 days', 'price': 900.0, 'code': '9MOB-3GB'},
      {'plan': '5GB', 'validity': '30 days', 'price': 1500.0, 'code': '9MOB-5GB'},
      {'plan': '10GB', 'validity': '30 days', 'price': 3000.0, 'code': '9MOB-10GB'},
      {'plan': '20GB', 'validity': '30 days', 'price': 6000.0, 'code': '9MOB-20GB'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedPlan = _plansMap['MTN']![1]; // Default 1GB
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final text = _phoneController.text.trim();
    if (text.length >= 4) {
      final detected = VtuProvider.detectNetwork(text);
      if (detected != _selectedNetwork) {
        setState(() {
          _selectedNetwork = detected;
          final plans = _plansMap[_selectedNetwork];
          if (plans != null && plans.isNotEmpty) {
            _selectedPlan = plans.first;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a data bundle plan')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();

    final price = _selectedPlan!['price'] as double;
    if (wallet.balance < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. Please fund your wallet (₦${wallet.balance.toStringAsFixed(2)} available).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 4-digit PIN confirmation
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Data Purchase',
      amount: price,
      description: '$_selectedNetwork ${_selectedPlan!['plan']} bundle to $phone',
      onPinSubmit: (pin) => auth.verifyPin(pin),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await vtu.buyData(
          userId: auth.user?.id ?? 1,
          network: _selectedNetwork,
          phone: phone,
          variationCode: _selectedPlan!['code'] as String,
          amount: price,
          sellPrice: price,
        );

        if (mounted) {
          if (result.success) {
            wallet.fetchWallet(auth.user?.id ?? 1);
            _showDeliveredReceipt(result.order.providerReference ?? 'AV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}', phone, price);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order failed: ${result.message}'), backgroundColor: AppColors.error),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing data order: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showDeliveredReceipt(String ref, String phone, double amt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.success.withValues(alpha: 0.15),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
              ),
              const SizedBox(height: 14),
              const Text('Data Bundle Delivered', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Data was credited by the telecom network and your wallet was debited.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _rcptLine('Reference', ref),
                    _rcptLine('Network', _selectedNetwork),
                    _rcptLine('Bundle', '${_selectedPlan!['plan']} (${_selectedPlan!['validity']})'),
                    _rcptLine('Recipient', phone),
                    _rcptLine('Charged', '₦${NumberFormat('#,##0.00').format(amt)}'),
                    _rcptLine('Status', 'Delivered', isStatus: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 44),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/dashboard');
            },
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _rcptLine(String label, String val, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isStatus ? AppColors.success : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
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
          IconButton(
            tooltip: 'Fund Wallet',
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
            onPressed: () => context.push('/wallet/fund'),
          ),
          SizedBox(width: isDesktop ? 48 : 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.push('/dashboard'),
                        child: Text('Dashboard', style: TextStyle(fontSize: 12, color: AppColors.primaryCyan)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text('Buy data', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Buy data',
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SME, gifting and corporate data bundles on every telecom network.',
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                  ),
                  const SizedBox(height: 24),

                  // 2-Column Responsive Layout
                  isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildOrderDetailsCard(isDark)),
                            const SizedBox(width: 24),
                            Expanded(flex: 5, child: _buildSummaryCard(wallet, isDark)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildOrderDetailsCard(isDark),
                            const SizedBox(height: 20),
                            _buildSummaryCard(wallet, isDark),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(bool isDark) {
    final plans = _plansMap[_selectedNetwork] ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Network Selector
          const Text('Select network', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: _networks.map((net) {
              final isSel = _selectedNetwork == net;
              Color brandColor;
              switch (net) {
                case 'Glo':
                  brandColor = AppColors.gloGreen;
                  break;
                case 'Airtel':
                  brandColor = AppColors.airtelRed;
                  break;
                case '9mobile':
                  brandColor = AppColors.nineMobileGreen;
                  break;
                default:
                  brandColor = AppColors.mtnYellow;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedNetwork = net;
                        final newPlans = _plansMap[net];
                        if (newPlans != null && newPlans.isNotEmpty) {
                          _selectedPlan = newPlans.first;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSel
                            ? (isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? AppColors.primaryCyan : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: brandColor, shape: BoxShape.circle),
                            child: Text(
                              net.substring(0, 1),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: net == 'MTN' ? Colors.black : Colors.white),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(net, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Bundle Type Selector
          const Text('Bundle type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBundleType,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                items: _bundleTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBundleType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Phone Number Input
          const Text('Phone number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '0803 411 9920',
              prefixIcon: const Icon(Icons.phone_android, size: 18),
              filled: true,
              fillColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          // Plans Grid
          const Text('Choose a plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.8,
            ),
            itemCount: plans.length,
            itemBuilder: (context, idx) {
              final p = plans[idx];
              final isSel = _selectedPlan?['code'] == p['code'];
              return InkWell(
                onTap: () => setState(() => _selectedPlan = p),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppColors.primaryCyan.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? AppColors.primaryCyan : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p['plan'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(p['validity'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '₦${NumberFormat('#,##0').format(p['price'])}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isSel ? AppColors.primaryCyan : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Protection Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: AppColors.primaryCyan),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Data is credited by telecom provider within seconds. A failed order is refunded to your wallet without you asking.',
                    style: TextStyle(fontSize: 11, color: AppColors.primaryCyan, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(WalletProvider wallet, bool isDark) {
    final price = (_selectedPlan?['price'] as double?) ?? 620.0;
    final planName = _selectedPlan != null ? '${_selectedPlan!['plan']} (${_selectedPlan!['validity']})' : '1GB (30 days)';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Summary', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _sumRow('Service', 'Data bundle'),
          _sumRow('Network', _selectedNetwork),
          _sumRow('Bundle Plan', planName),
          _sumRow('Recipient', _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '0803 411 9920'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('You pay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                '₦${NumberFormat('#,##0.00').format(price)}',
                style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryCyan),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _handlePurchase,
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Buy data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Wallet balance ₦${NumberFormat('#,##0.00').format(wallet.balance > 0 ? wallet.balance : 248500.00)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
