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

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _phoneController = TextEditingController(text: '0803 411 9920');
  final _customAmountController = TextEditingController();
  String _selectedNetwork = 'MTN';
  double _selectedAmount = 1000.0;

  final List<String> _networks = ['MTN', 'Glo', 'Airtel', '9mobile'];
  final List<double> _presetAmounts = [100, 200, 500, 1000, 2000, 5000];

  double get _discountRate {
    switch (_selectedNetwork) {
      case 'Glo':
        return 0.035;
      case '9mobile':
        return 0.040;
      default:
        return 0.025;
    }
  }

  double get _discountAmount => _selectedAmount * _discountRate;
  double get _finalAmount => _selectedAmount - _discountAmount;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final text = _phoneController.text.trim();
    if (text.length >= 4) {
      final detected = VtuProvider.detectNetwork(text);
      if (detected != _selectedNetwork) {
        setState(() => _selectedNetwork = detected);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    final phone = _phoneController.text.trim();
    final amount = _selectedAmount;

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    if (amount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum airtime amount is ₦50')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();

    if (wallet.balance < _finalAmount) {
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
      title: 'Confirm Airtime Purchase',
      amount: _finalAmount,
      description: '$_selectedNetwork ₦${NumberFormat('#,##0').format(amount)} top-up to $phone',
      onPinSubmit: (pin) => auth.verifyPin(pin),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await vtu.buyAirtime(
          userId: auth.user?.id ?? 1,
          network: _selectedNetwork,
          phone: phone,
          amount: _finalAmount,
        );

        if (mounted) {
          if (result.success) {
            wallet.fetchWallet(auth.user?.id ?? 1);
            _showDeliveredReceipt(result.order.providerReference ?? 'AV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}', phone, amount);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order failed: ${result.message}'), backgroundColor: AppColors.error),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing order: $e'), backgroundColor: AppColors.error),
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
              const Text('Order Delivered', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'The airtime was delivered and your wallet has been debited.',
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
                    _rcptLine('Recipient', phone),
                    _rcptLine('Charged', '₦${NumberFormat('#,##0.00').format(_finalAmount)}'),
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
                  // Breadcrumb & Header
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.push('/dashboard'),
                        child: Text('Dashboard', style: TextStyle(fontSize: 12, color: AppColors.primaryCyan)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text('Buy airtime', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Buy airtime',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instant recharge on every network, at a wholesale discount.',
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
                    onTap: () => setState(() => _selectedNetwork = net),
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
                            decoration: BoxDecoration(
                              color: brandColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              net.substring(0, 1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: net == 'MTN' ? Colors.black : Colors.white,
                              ),
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
          const SizedBox(height: 24),

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
          const SizedBox(height: 4),
          const Text('The phone number that receives the airtime.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 24),

          // Amount Chips
          const Text('Choose amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetAmounts.map((amt) {
              final isSel = _selectedAmount == amt;
              return ChoiceChip(
                label: Text('₦${NumberFormat('#,##0').format(amt)}', style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? Colors.black : (isDark ? Colors.white : Colors.black))),
                selected: isSel,
                selectedColor: AppColors.primaryCyan,
                backgroundColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
                onSelected: (_) {
                  setState(() {
                    _selectedAmount = amt;
                    _customAmountController.clear();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom Amount Input
          const Text('Or type another amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '50 to 50,000',
              prefixText: '₦ ',
              filled: true,
              fillColor: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              if (parsed > 0) {
                setState(() => _selectedAmount = parsed);
              }
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
                    'Airtime lands instantly. If a network provider rejects it, your wallet is credited back automatically.',
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
          _sumRow('Service', 'Airtime top-up'),
          _sumRow('Network', _selectedNetwork),
          _sumRow('Recipient', _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '0803 411 9920'),
          _sumRow('Cashback discount', '-₦${NumberFormat('#,##0.00').format(_discountAmount)}', isGreen: true),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('You pay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                '₦${NumberFormat('#,##0.00').format(_finalAmount)}',
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryCyan),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _handlePurchase,
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Buy airtime', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _sumRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isGreen ? AppColors.success : null,
            ),
          ),
        ],
      ),
    );
  }
}
