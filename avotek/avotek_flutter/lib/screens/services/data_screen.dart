import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/nigerian_network_detector.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/transaction_success_dialog.dart';
import '../../widgets/pay_for_me_dialog.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final _phoneController = TextEditingController();
  final _giftMessageController = TextEditingController();

  // Mode: 0 = Buy Now, 1 = Gift Voucher
  int _activeMode = 0;

  String _selectedNetwork = 'MTN';
  bool _networkManuallySelected = false;
  String _selectedFilter = 'ALL';
  Map<String, dynamic>? _selectedPlan;
  bool _payForMe = false;
  bool _isProcessing = false;

  final List<Map<String, String>> _networks = [
    {
      'code': 'MTN',
      'label': 'MTN',
      'logo': 'assets/images/brands/mtn.png',
    },
    {
      'code': 'GLO',
      'label': 'GLO',
      'logo': 'assets/images/brands/glo.png',
    },
    {
      'code': 'AIRTEL',
      'label': 'AIRTEL',
      'logo': 'assets/images/brands/airtel.png',
    },
    {
      'code': '9MOBILE',
      'label': '9MOBILE',
      'logo': 'assets/images/brands/9mobile.png',
    },
  ];

  final List<String> _filterCategories = [
    'ALL',
    'SME',
    'DATATRANSFER',
    'CGIFTING',
    'GIFTING',
    'CORPORATE',
  ];

  List<Map<String, dynamic>> _livePlans = [];
  bool _isLoadingPlans = false;
  String? _planLoadError;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    final auth = context.read<AuthProvider>();
    if (auth.user?.phone != null && auth.user!.phone!.isNotEmpty) {
      _phoneController.text = auth.user!.phone!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLivePlans());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _giftMessageController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _networkManuallySelected = false;
    } else if (!_networkManuallySelected) {
      final detected = NigerianNetworkDetector.detect(phone);
      if (detected != null && detected != _selectedNetwork) {
        setState(() => _selectedNetwork = detected);
        _loadLivePlans();
      }
    }
    setState(() {});
  }

  Future<void> _loadLivePlans() async {
    final network = _selectedNetwork;
    setState(() {
      _isLoadingPlans = true;
      _planLoadError = null;
      _livePlans = [];
      _selectedPlan = null;
    });

    try {
      final vtu = context.read<VtuProvider>();
      final rawPlans = await vtu.fetchLiveDataPlans(network);
      if (!mounted || network != _selectedNetwork) return;

      final formatted = rawPlans
          .map((p) {
            final size = (p['size'] ?? '').toString().trim();
            final vol = (p['plan_volume'] ?? p['volume'] ?? '').toString().trim();
            final type = (p['plantype'] ?? p['plan_type'] ?? p['type'] ?? 'SME').toString().trim().toUpperCase();
            final val = (p['validity'] ?? p['month_validate'] ?? '30 Days').toString().trim();
            final fallbackName = (p['plan_name'] ?? p['name'] ?? p['plan'] ?? '').toString().trim();
            final rawAmt = p['amount'] ?? p['plan_amount'] ?? p['price'];
            final amt = rawAmt is num
                ? rawAmt.toDouble()
                : double.tryParse(rawAmt?.toString() ?? '') ?? 0.0;
            final rawId = p['id'] ?? p['plan_id'] ?? p['dataplan_id'];
            final id = rawId is num
                ? rawId.toInt()
                : int.tryParse(rawId?.toString() ?? '') ?? 0;

            final displayVol = ('$size$vol').trim().isNotEmpty
                ? '$size$vol'
                : (fallbackName.isNotEmpty ? fallbackName : '$type Data');

            return {
              'id': id,
              'volume': displayVol,
              'price': amt,
              'validity': val,
              'plantype': type,
              'code': 'BIGISUB-$id',
              'fullName': '$displayVol $type ($val)',
            };
          })
          .where((p) => (p['id'] as int) > 0 && (p['price'] as double) > 0)
          .toList();

      setState(() {
        _livePlans = formatted;
        _isLoadingPlans = false;
        final filtered = _getFilteredPlans();
        if (filtered.isNotEmpty) {
          _selectedPlan = filtered.first;
        } else if (formatted.isNotEmpty) {
          _selectedPlan = formatted.first;
        } else {
          _planLoadError = 'No data bundles found for $network.';
        }
      });
    } catch (e) {
      if (!mounted || network != _selectedNetwork) return;
      setState(() {
        _isLoadingPlans = false;
        _planLoadError = 'Failed to load bundles: $e';
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredPlans() {
    if (_selectedFilter == 'ALL') return _livePlans;
    return _livePlans.where((p) {
      final t = (p['plantype'] as String).toUpperCase();
      if (_selectedFilter == 'DATATRANSFER') {
        return t.contains('TRANSFER') || t.contains('DIRECT');
      }
      if (_selectedFilter == 'CGIFTING') {
        return t.contains('CGIFT') || t.contains('C-GIFT');
      }
      if (_selectedFilter == 'GIFTING') {
        return t.contains('GIFT') && !t.contains('CGIFT') && !t.contains('C-GIFT');
      }
      return t == _selectedFilter;
    }).toList();
  }

  List<String> _getValidationErrors() {
    final errors = <String>[];
    if (_selectedPlan == null) {
      errors.add('Select a data plan');
    }
    if (_activeMode == 0) {
      final phone = _phoneController.text.trim();
      if (phone.length < 10) {
        errors.add('Enter a valid 11-digit phone number');
      }
    }
    return errors;
  }

  Future<void> _handleSubmit() async {
    final errors = _getValidationErrors();
    if (errors.isNotEmpty) {
      TopNotification.showWarning(context, errors.first);
      return;
    }

    final plan = _selectedPlan!;
    final planPrice = plan['price'] as double;
    final planName = plan['fullName'] as String;

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final user = auth.user;
    if (user == null) {
      TopNotification.showError(context, 'Please sign in to continue.');
      return;
    }

    if (_activeMode == 0 && _payForMe) {
      final phone = _phoneController.text.trim();
      await PayForMeDialog.show(
        context,
        serviceName: '$_selectedNetwork Data ($planName)',
        recipient: phone.isNotEmpty ? phone : 'My Phone',
        amount: planPrice,
      );
      return;
    }

    if (wallet.balance < planPrice) {
      TopNotification.showError(
        context,
        'Insufficient balance (₦${wallet.balance.toStringAsFixed(2)} available). Please fund your wallet.',
      );
      return;
    }

    if (_activeMode == 1) {
      // Gift Voucher Mode
      final message = _giftMessageController.text.trim();
      final confirmed = await PinModal.show(
        context,
        title: 'Create Data Gift Voucher',
        amount: planPrice,
        description: 'Voucher for $_selectedNetwork - $planName\nRecipient can redeem via coupons.',
        onPinSubmit: (pin) async => auth.verifyPin(pin),
      );

      if (confirmed == true && mounted) {
        try {
          setState(() => _isProcessing = true);
          final res = await SupabaseService.instance.createGiftVoucher(
            amount: planPrice,
            recipient: _phoneController.text.trim(),
            note: 'Data Plan ($_selectedNetwork: $planName) ${message.isNotEmpty ? "• $message" : ""}',
          );
          await auth.refreshWallet();
          await wallet.fetchWallet(user.id);

          if (!mounted) return;
          setState(() => _isProcessing = false);
          final voucherCode = res['code']?.toString() ?? 'GIFT-CODE';
          await TransactionSuccessDialog.show(
            context,
            title: 'Data Voucher Created!',
            serviceType: '$_selectedNetwork Data Gift Voucher',
            recipient: _phoneController.text.isNotEmpty ? _phoneController.text : 'Shareable Link',
            amount: planPrice,
            reference: voucherCode,
            token: voucherCode,
            message: 'Gift voucher created! Share this voucher code with the recipient.',
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          TopNotification.showError(context, 'Failed to create voucher: $e');
        }
      }
      return;
    }

    // Direct Purchase Mode
    final phone = _phoneController.text.trim();
    String? transactionPin;
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Data Purchase',
      amount: planPrice,
      description: '$_selectedNetwork • $phone\n$planName',
      onPinSubmit: (pin) async {
        transactionPin = pin;
        return auth.verifyPin(pin);
      },
    );

    if (confirmed == true && mounted && transactionPin != null) {
      setState(() => _isProcessing = true);
      try {
        final vtu = context.read<VtuProvider>();
        final planId = plan['id'] as int;
        final result = await vtu.buyData(
          userId: user.id,
          network: _selectedNetwork,
          phone: phone,
          variationCode: plan['code'] as String,
          amount: planPrice,
          sellPrice: planPrice,
          planId: planId,
          userPin: transactionPin,
        );

        await auth.refreshWallet();
        await wallet.fetchWallet(user.id);

        if (!mounted) return;
        setState(() => _isProcessing = false);

        if (!result.success || result.order.status == 'failed') {
          TopNotification.showError(context, result.message, title: 'Purchase Failed');
          return;
        }

        await TransactionSuccessDialog.show(
          context,
          title: 'Data Delivered!',
          serviceType: '$_selectedNetwork Data ($planName)',
          recipient: phone,
          amount: planPrice,
          reference: result.order.id,
          providerReference: result.order.providerReference,
          message: '₦${NumberFormat('#,##0.00').format(planPrice)} data bundle sent to $phone successfully.',
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        TopNotification.showError(context, 'Data purchase failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validationErrors = _getValidationErrors();
    final isReady = validationErrors.isEmpty;
    final filteredPlans = _getFilteredPlans();

    return ResponsiveShell(
      currentRoute: '/services/data',
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
                    'Buy Data',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quick and secure data bundle purchase',
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
                                        colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _activeMode == 0
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF0038B8).withOpacity(0.35),
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
                                        colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _activeMode == 1
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF0038B8).withOpacity(0.35),
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
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // SELECT NETWORK PROVIDER matching Screenshot 4
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
                          'SELECT NETWORK PROVIDER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: _networks.map((net) {
                            final isSelected = _selectedNetwork == net['code'];
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: InkWell(
                                  onTap: () {
                                    if (_selectedNetwork != net['code']) {
                                      setState(() {
                                        _selectedNetwork = net['code']!;
                                        _networkManuallySelected = true;
                                      });
                                      _loadLivePlans();
                                    }
                                  },
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
                                                color: const Color(0xFF0052FF).withOpacity(0.2),
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
                                              Image.asset(
                                                net['logo']!,
                                                height: 28,
                                                fit: BoxFit.contain,
                                                errorBuilder: (ctx, err, stack) => Icon(
                                                  Icons.signal_cellular_alt,
                                                  size: 26,
                                                  color: isSelected ? const Color(0xFF0052FF) : Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                net['label']!,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: isSelected
                                                      ? const Color(0xFF0052FF)
                                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF0052FF),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check, size: 10, color: Colors.white),
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

                  // Phone Number & Mode inputs (PLACED ABOVE INITIATE BUTTON & PRICING TABLE)
                  if (_activeMode == 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            'PHONE NUMBER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. 08012345678',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1B1E29) : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _payForMe,
                                  activeColor: const Color(0xFF0038B8),
                                  onChanged: (val) => setState(() => _payForMe = val ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _payForMe = !_payForMe),
                                  child: Text(
                                    'Pay For Me',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            'RECIPIENT PHONE (OPTIONAL)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. 08012345678',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1B1E29) : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'GIFT MESSAGE (OPTIONAL)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _giftMessageController,
                            maxLength: 200,
                            maxLines: 2,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enjoy your data gift!',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1B1E29) : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // SELECT DATA PLAN Card (COMPACT WIDGET WITH INTERNAL SCROLL)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SELECT DATA PLAN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            Text(
                              '${filteredPlans.length} plans',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Plan Category Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _filterCategories.map((cat) {
                              final isCatSel = _selectedFilter == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedFilter = cat;
                                      final filtered = _getFilteredPlans();
                                      if (filtered.isNotEmpty && !_getFilteredPlans().contains(_selectedPlan)) {
                                        _selectedPlan = filtered.first;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isCatSel
                                          ? const Color(0xFF0038B8)
                                          : (isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCatSel
                                            ? const Color(0xFF0038B8)
                                            : (isDark ? const Color(0xFF2A2E3D) : const Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: isCatSel ? FontWeight.w800 : FontWeight.w600,
                                        color: isCatSel
                                            ? Colors.white
                                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_isLoadingPlans)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(color: Color(0xFF0038B8)),
                            ),
                          )
                        else if (_planLoadError != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    _planLoadError!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _loadLivePlans,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0038B8),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Retry Loading'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (filteredPlans.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No plans found for category $_selectedFilter.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          // Roomy scrollable widget container with enhanced typography
                          Container(
                            height: 255,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0D1017) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E2230) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: filteredPlans.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isDesktop ? 3 : 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: isDesktop ? 2.3 : 1.48,
                                ),
                                itemBuilder: (context, index) {
                                  final plan = filteredPlans[index];
                                  final vol = plan['volume'] as String;
                                  final price = plan['price'] as double;
                                  final val = plan['validity'] as String;
                                  final type = plan['plantype'] as String;
                                  final isSelected = _selectedPlan?['id'] == plan['id'];

                                  return InkWell(
                                    onTap: () => setState(() => _selectedPlan = plan),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isDark ? const Color(0xFF172554) : const Color(0xFFDBEAFE))
                                            : (isDark ? const Color(0xFF1B1E29) : Colors.white),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0038B8)
                                              : (isDark ? const Color(0xFF282D3D) : const Color(0xFFCBD5E1)),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            vol,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '₦${price.toStringAsFixed(0)}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '$val • $type',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // INITIATE PAYMENT ACTION CARD (BELOW THE PRICING TABLE)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141721) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isReady
                            ? const Color(0xFF0038B8)
                            : (isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0)),
                        width: isReady ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SELECTED BUNDLE',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedPlan != null
                                        ? '${_selectedPlan!['volume']} (${_selectedPlan!['plantype']}) • ${_selectedPlan!['validity']}'
                                        : 'Select a data plan below',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedPlan != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2638) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF0038B8).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '₦${(_selectedPlan!['price'] as double).toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Initiate Payment Button
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: isReady && !_isProcessing
                                ? const LinearGradient(
                                    colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isReady && !_isProcessing
                                ? null
                                : (isDark ? const Color(0xFF26324D) : const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isReady && !_isProcessing
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF0038B8).withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ElevatedButton(
                            onPressed: isReady && !_isProcessing ? _handleSubmit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white38,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _activeMode == 1
                                            ? Icons.card_giftcard
                                            : (_payForMe ? Icons.share : Icons.flash_on_rounded),
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _activeMode == 1
                                            ? 'Create Gift Voucher'
                                            : (_payForMe
                                                ? 'Generate Pay For Me Link'
                                                : (_selectedPlan != null
                                                    ? 'Buy Data Now • ₦${(_selectedPlan!['price'] as double).toStringAsFixed(0)}'
                                                    : 'Buy Data Now')),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        if (!isReady && validationErrors.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  validationErrors.first,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
