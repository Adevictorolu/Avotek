import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/pay_for_me_dialog.dart';
import '../../widgets/transaction_success_dialog.dart';

class InternetScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const InternetScreen({super.key, required this.onToggleTheme});

  @override
  State<InternetScreen> createState() => _InternetScreenState();
}

class _InternetScreenState extends State<InternetScreen> {
  int _activeMode = 0; // 0: Buy Now, 1: Gift Voucher
  String _selectedProvider = 'smile';
  Map<String, dynamic>? _selectedPackage;
  bool _autoRenew = false;
  bool _payForMe = false;
  bool _isPurchasing = false;

  final _accountController = TextEditingController();
  final _phoneController = TextEditingController();

  static final List<Map<String, dynamic>> _providers = [
    {
      'id': 'smile',
      'name': 'Smile 4G',
      'icon': Icons.wifi_tethering_rounded,
      'color': const Color(0xFFE50914),
      'accountHint': 'Enter Smile Account / Voice Number (10 digits)',
    },
    {
      'id': 'spectranet',
      'name': 'Spectranet',
      'icon': Icons.router_rounded,
      'color': const Color(0xFF0052FF),
      'accountHint': 'Enter Spectranet User ID / Refill ID',
    },
    {
      'id': 'swift',
      'name': 'Swift 4G',
      'icon': Icons.cell_tower_rounded,
      'color': const Color(0xFF10B981),
      'accountHint': 'Enter Swift Customer ID / Device ID',
    },
    {
      'id': 'fibre',
      'name': 'Fibre Broadband',
      'icon': Icons.hub_rounded,
      'color': const Color(0xFF8B5CF6),
      'accountHint': 'Enter Fibre Subscription Account Number',
    },
  ];

  static final Map<String, List<Map<String, dynamic>>> _packageData = {
    'smile': [
      {'name': '1.5GB Smile Data', 'validity': '30 Days', 'price': 1000.0, 'code': 'SMILE_1_5GB'},
      {'name': '3GB Smile Data', 'validity': '30 Days', 'price': 1500.0, 'code': 'SMILE_3GB'},
      {'name': '5GB Smile Data', 'validity': '30 Days', 'price': 2000.0, 'code': 'SMILE_5GB'},
      {'name': '10GB Smile Data', 'validity': '30 Days', 'price': 3000.0, 'code': 'SMILE_10GB'},
      {'name': '15GB Smile Data', 'validity': '30 Days', 'price': 4000.0, 'code': 'SMILE_15GB'},
      {'name': '20GB Smile Bigi', 'validity': '30 Days', 'price': 5000.0, 'code': 'SMILE_20GB'},
      {'name': '50GB Smile Jumbo', 'validity': '30 Days', 'price': 10000.0, 'code': 'SMILE_50GB'},
      {'name': '100GB Smile Ultra', 'validity': '30 Days', 'price': 18000.0, 'code': 'SMILE_100GB'},
      {'name': 'Smile Unlimited 30D', 'validity': '30 Days', 'price': 25000.0, 'code': 'SMILE_UNLIMITED'},
    ],
    'spectranet': [
      {'name': '4GB Unified Stay Connected', 'validity': '30 Days', 'price': 2000.0, 'code': 'SPEC_4GB'},
      {'name': '7GB Unified Standard', 'validity': '30 Days', 'price': 3000.0, 'code': 'SPEC_7GB'},
      {'name': '15GB Unified Value', 'validity': '30 Days', 'price': 5000.0, 'code': 'SPEC_15GB'},
      {'name': '25GB Mega Value', 'validity': '30 Days', 'price': 7500.0, 'code': 'SPEC_25GB'},
      {'name': '50GB Mega Boost', 'validity': '30 Days', 'price': 11000.0, 'code': 'SPEC_50GB'},
      {'name': '100GB Mega Heavy', 'validity': '30 Days', 'price': 19000.0, 'code': 'SPEC_100GB'},
      {'name': 'Spectranet Unlimited 24/7', 'validity': '30 Days', 'price': 28000.0, 'code': 'SPEC_UNLIMITED'},
    ],
    'swift': [
      {'name': '3GB Swift Basic', 'validity': '30 Days', 'price': 2000.0, 'code': 'SWIFT_3GB'},
      {'name': '7GB Swift Plus', 'validity': '30 Days', 'price': 3500.0, 'code': 'SWIFT_7GB'},
      {'name': '14GB Swift Max', 'validity': '30 Days', 'price': 6000.0, 'code': 'SWIFT_14GB'},
      {'name': '30GB Swift Pro', 'validity': '30 Days', 'price': 10000.0, 'code': 'SWIFT_30GB'},
      {'name': '60GB Swift Heavy', 'validity': '30 Days', 'price': 18000.0, 'code': 'SWIFT_60GB'},
      {'name': 'Swift 24/7 Unlimited', 'validity': '30 Days', 'price': 27000.0, 'code': 'SWIFT_UNLIMITED'},
    ],
    'fibre': [
      {'name': '20 Mbps Starter Fibre', 'validity': '30 Days', 'price': 15000.0, 'code': 'FIBRE_20M'},
      {'name': '40 Mbps Turbo Fibre', 'validity': '30 Days', 'price': 25000.0, 'code': 'FIBRE_40M'},
      {'name': '100 Mbps Gigabit Enterprise', 'validity': '30 Days', 'price': 45000.0, 'code': 'FIBRE_100M'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedPackage = _packageData[_selectedProvider]?.first;
  }

  @override
  void dispose() {
    _accountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onProviderChanged(String providerId) {
    setState(() {
      _selectedProvider = providerId;
      _selectedPackage = _packageData[providerId]?.first;
    });
  }

  double? _totalAmount() {
    return _selectedPackage?['price'] as double?;
  }

  Future<void> _handlePurchase() async {
    if (_isPurchasing) return;
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final user = auth.user;
    final amount = _totalAmount();

    if (user == null) {
      TopNotification.showError(context, 'Sign in before purchasing.');
      return;
    }
    if (_selectedPackage == null) {
      TopNotification.showWarning(context, 'Please select an internet bundle plan.');
      return;
    }
    final account = _accountController.text.trim();
    if (account.isEmpty || account.length < 5) {
      TopNotification.showWarning(context, 'Please enter a valid Account / Device Number.');
      return;
    }

    if (_payForMe) {
      final provName = _providers.firstWhere((p) => p['id'] == _selectedProvider)['name'];
      await PayForMeDialog.show(
        context,
        serviceName: '$provName - ${_selectedPackage!['name']}',
        recipient: account,
        amount: amount ?? 0,
      );
      return;
    }

    if (amount == null || amount <= 0) {
      TopNotification.showWarning(context, 'Invalid subscription amount.');
      return;
    }
    if (wallet.balance < amount) {
      TopNotification.showError(
        context,
        'Insufficient wallet balance. Available: ₦${wallet.balance.toStringAsFixed(2)}.',
      );
      return;
    }

    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Internet Subscription',
      amount: amount,
      description: '${_selectedPackage!['name']} • Account: $account',
      onPinSubmit: (pin) async {
        return auth.verifyPin(pin);
      },
    );
    if (confirmed != true) return;

    setState(() => _isPurchasing = true);
    try {
      // Simulate/Trigger proxy delivery
      await Future.delayed(const Duration(seconds: 1));
      await auth.refreshWallet();
      await wallet.fetchWallet(user.id);

      if (!mounted) return;
      final ref = 'INT-${DateTime.now().millisecondsSinceEpoch}';
      await TransactionSuccessDialog.show(
        context,
        title: 'Internet Subscription Active!',
        serviceType: '${_selectedPackage!['name']} (${_selectedPackage!['validity']})',
        recipient: account,
        amount: amount,
        reference: ref,
        message: 'Your broadband internet connection has been renewed and activated successfully.',
      );
      _accountController.clear();
      _phoneController.clear();
    } catch (e) {
      if (mounted) {
        TopNotification.showError(context, 'Internet subscription error: $e');
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : const Color(0xFF172033);
    final wallet = context.watch<WalletProvider>();
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final currentPackages = _packageData[_selectedProvider] ?? [];
    final activeProvObj = _providers.firstWhere((p) => p['id'] == _selectedProvider);

    return ResponsiveShell(
      currentRoute: '/services/internet',
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1117) : const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2230) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chevron_left, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Text(
                    'Internet Subscriptions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instant Smile 4G, Spectranet, Swift, and Fibre broadband top-ups',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode Switcher Bar
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161922) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF262A38) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeMode = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: _activeMode == 0
                                    ? const LinearGradient(
                                        colors: [Color(0xFF0052FF), Color(0xFF00D2FF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _activeMode == 0
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF0052FF).withOpacity(0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 18,
                                    color: _activeMode == 0
                                        ? Colors.white
                                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Buy Now',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _activeMode == 0
                                          ? Colors.white
                                          : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeMode = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: _activeMode == 1
                                    ? const LinearGradient(
                                        colors: [Color(0xFF0052FF), Color(0xFF00D2FF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _activeMode == 1
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF0052FF).withOpacity(0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.card_giftcard,
                                    size: 18,
                                    color: _activeMode == 1
                                        ? Colors.white
                                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Gift Voucher',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _activeMode == 1
                                          ? Colors.white
                                          : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_activeMode == 1) ...[
                    const SizedBox(height: 10),
                    Text(
                      'This creates a shareable gift link. The recipient redeems it themselves.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF00D2FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Provider selection card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141721) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT INTERNET PROVIDER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: _providers.map((prov) {
                            final isSelected = _selectedProvider == prov['id'];
                            final icon = prov['icon'] as IconData;
                            final provColor = prov['color'] as Color;

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: InkWell(
                                  onTap: () => _onProviderChanged(prov['id'] as String),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 82,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0052FF)
                                            : (isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1)),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF0052FF).withOpacity(0.25),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                icon,
                                                size: 28,
                                                color: isSelected ? const Color(0xFF00D2FF) : provColor,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                prov['name'] as String,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.5,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF0052FF),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check, size: 12, color: Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Plans Grid Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141721) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT SUBSCRIPTION PLAN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                         constraints: const BoxConstraints(maxHeight: 250),
                         child: GridView.builder(
                          shrinkWrap: true,
                          primary: false,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : 2,
                            childAspectRatio: isDesktop ? 2.3 : 1.9,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: currentPackages.length,
                          itemBuilder: (context, index) {
                            final pkg = currentPackages[index];
                            final isSel = _selectedPackage?['code'] == pkg['code'];
                            final price = (pkg['price'] as num).toDouble();

                            return InkWell(
                              onTap: () => setState(() => _selectedPackage = pkg),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel
                                        ? const Color(0xFF0052FF)
                                        : (isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1)),
                                    width: isSel ? 2 : 1,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF0052FF).withOpacity(0.25),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      pkg['name'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₦${price.toStringAsFixed(0)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: isSel ? const Color(0xFF00D2FF) : foreground,
                                      ),
                                    ),
                                    Text(
                                      pkg['validity'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: isDark ? Colors.white38 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                         ),
                        ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 20),

                  // Account / Device Input Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141721) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACCOUNT / DEVICE NUMBER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _accountController,
                          keyboardType: TextInputType.text,
                          style: GoogleFonts.plusJakartaSans(color: foreground),
                          decoration: InputDecoration(
                            hintText: activeProvObj['accountHint'] as String,
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            prefixIcon: const Icon(Icons.wifi_rounded, color: Color(0xFF00D2FF)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1C202C) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PHONE NUMBER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: GoogleFonts.plusJakartaSans(color: foreground),
                          decoration: InputDecoration(
                            hintText: 'e.g. 08012345678',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF00D2FF)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1C202C) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Auto renew & Pay For Me Checkboxes
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141721) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _autoRenew,
                              activeColor: const Color(0xFF0052FF),
                              onChanged: (val) => setState(() => _autoRenew = val ?? false),
                            ),
                            Expanded(
                              child: Text(
                                'Auto-renew subscription monthly',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                        Row(
                          children: [
                            Checkbox(
                              value: _payForMe,
                              activeColor: const Color(0xFF0052FF),
                              onChanged: (val) => setState(() => _payForMe = val ?? false),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Pay For Me ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '- get a shareable payment link',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Order Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141721) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Wallet Balance',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '₦${wallet.balance.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: foreground,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: foreground,
                              ),
                            ),
                            Text(
                              _totalAmount() != null
                                  ? '₦${_totalAmount()!.toStringAsFixed(2)}'
                                  : '--',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF00D2FF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Action Button
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0052FF), Color(0xFF00D2FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0052FF).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isPurchasing ? null : _handlePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isPurchasing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _payForMe
                                  ? 'Generate Shareable Payment Link'
                                  : 'Pay for Internet (${_selectedPackage != null ? '₦${(_selectedPackage!['price'] as num).toStringAsFixed(0)}' : ''})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
