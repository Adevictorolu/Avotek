import 'dart:convert';
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

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _giftMessageController = TextEditingController();

  // Mode: 0 = Buy Now, 1 = Gift Voucher
  int _activeMode = 0;

  String _selectedNetwork = 'MTN';
  bool _networkManuallySelected = false;
  double _amount = 0.0;
  bool _payForMe = false;
  bool _isProcessing = false;
  double _cashbackPercent = 2.0; // 2% default instant cashback
  double get _cashbackAmount => (_amount * _cashbackPercent / 100);
  double get _netCharge => (_amount - _cashbackAmount).clamp(0.0, double.infinity);

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

  final List<double> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    _amountController.addListener(_onAmountChanged);

    final auth = context.read<AuthProvider>();
    if (auth.user?.phone != null && auth.user!.phone!.isNotEmpty) {
      _phoneController.text = auth.user!.phone!;
    }
    _loadCashbackRate();
  }

  Future<void> _loadCashbackRate() async {
    try {
      final pricingStr = await SupabaseService.instance.getAppSetting('pricing_overrides');
      if (pricingStr != null && pricingStr.isNotEmpty) {
        final decoded = jsonDecode(pricingStr);
        if (decoded is Map && decoded['airtime_cashback'] != null) {
          final rate = double.tryParse(decoded['airtime_cashback'].toString());
          if (rate != null && rate >= 0 && mounted) {
            setState(() => _cashbackPercent = rate);
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
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
      }
    }
    setState(() {});
  }

  void _onAmountChanged() {
    final clean = _amountController.text.replaceAll(',', '').trim();
    final parsed = double.tryParse(clean) ?? 0.0;
    if (parsed != _amount) {
      setState(() => _amount = parsed);
    }
  }

  void _setPresetAmount(double amt) {
    setState(() {
      _amount = amt;
      _amountController.text = amt.toStringAsFixed(0);
    });
  }

  List<String> _getValidationErrors() {
    final errors = <String>[];
    if (_amount < 50) {
      errors.add('Minimum airtime amount is ₦50');
    }
    if (_amount > 50000) {
      errors.add('Maximum airtime amount is ₦50,000');
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

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final user = auth.user;
    if (user == null) {
      TopNotification.showError(context, 'Please sign in to proceed.');
      return;
    }

    // Pay For Me Mode: generates a shareable payment link without requiring user balance
    if (_activeMode == 0 && _payForMe) {
      final phone = _phoneController.text.trim();
      await PayForMeDialog.show(
        context,
        serviceName: '$_selectedNetwork Airtime Top-up',
        recipient: phone.isNotEmpty ? phone : 'My Phone',
        amount: _amount,
      );
      return;
    }

    final charge = _netCharge;
    if (wallet.balance < charge) {
      TopNotification.showError(
        context,
        'Insufficient balance (₦${wallet.balance.toStringAsFixed(2)} available, ₦${charge.toStringAsFixed(2)} needed). Please fund your wallet.',
      );
      return;
    }

    if (_activeMode == 1) {
      // Gift Voucher Mode
      final message = _giftMessageController.text.trim();
      final confirmed = await PinModal.show(
        context,
        title: 'Create Airtime Gift Voucher',
        amount: _amount,
        description: 'Voucher for $_selectedNetwork Airtime (₦${_amount.toStringAsFixed(0)})\nRecipient can redeem via coupons.',
        onPinSubmit: (pin) async => auth.verifyPin(pin),
      );

      if (confirmed == true && mounted) {
        try {
          setState(() => _isProcessing = true);
          final res = await SupabaseService.instance.createGiftVoucher(
            amount: _amount,
            recipient: _phoneController.text.trim(),
            note: 'Airtime ($_selectedNetwork ₦${_amount.toStringAsFixed(0)}) ${message.isNotEmpty ? "• $message" : ""}',
          );
          await auth.refreshWallet();
          await wallet.fetchWallet(user.id);

          if (!mounted) return;
          setState(() => _isProcessing = false);
          final voucherCode = res['code']?.toString() ?? 'GIFT-CODE';
          await TransactionSuccessDialog.show(
            context,
            title: 'Airtime Voucher Created!',
            serviceType: '$_selectedNetwork Airtime Gift Voucher',
            recipient: _phoneController.text.isNotEmpty ? _phoneController.text : 'Shareable Link',
            amount: _amount,
            reference: voucherCode,
            token: voucherCode,
            message: 'Gift voucher created! Share the code or link with the recipient to redeem instantly.',
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
      title: 'Confirm Airtime Purchase',
      amount: charge,
      description: '$_selectedNetwork • $phone\nValue: ₦${_amount.toStringAsFixed(0)} (Cashback Discount: ₦${_cashbackAmount.toStringAsFixed(2)})',
      onPinSubmit: (pin) async {
        transactionPin = pin;
        return auth.verifyPin(pin);
      },
    );

    if (confirmed == true && mounted && transactionPin != null) {
      setState(() => _isProcessing = true);
      try {
        final vtu = context.read<VtuProvider>();
        final result = await vtu.buyAirtime(
          userId: user.id,
          network: _selectedNetwork,
          phone: phone,
          amount: charge,
          userPin: transactionPin,
          airtimeType: 'vtu',
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
          title: 'Airtime Delivered!',
          serviceType: '$_selectedNetwork Airtime',
          recipient: phone,
          amount: _amount,
          reference: result.order.id,
          providerReference: result.order.providerReference,
          message: '₦${NumberFormat('#,##0.00').format(_amount)} $_selectedNetwork airtime sent to $phone.',
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        TopNotification.showError(context, 'Purchase failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validationErrors = _getValidationErrors();
    final isReady = validationErrors.isEmpty;

    return ResponsiveShell(
      currentRoute: '/services/airtime',
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
                    'Buy Airtime',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quick and secure airtime purchase',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode Switcher Bar matching Avotek Brand Cyan/Blue Gradient
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

                  // SELECT NETWORK PROVIDER matching Screenshot 3
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
                                    setState(() {
                                      _selectedNetwork = net['code']!;
                                      _networkManuallySelected = true;
                                    });
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

                  // AMOUNT Input matching Screenshot 3
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
                          'AMOUNT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter amount e.g. 500',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 14, right: 6),
                              child: Text(
                                '₦',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0052FF),
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1B1E29) : const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Quick amounts
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickAmounts.map((q) {
                            final isSel = _amount == q;
                            return InkWell(
                              onTap: () => _setPresetAmount(q),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFF0052FF).withOpacity(0.2)
                                      : (isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel
                                        ? const Color(0xFF0052FF)
                                        : (isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                                child: Text(
                                  '₦${q.toInt()}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    color: isSel
                                        ? const Color(0xFF0052FF)
                                        : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Instant Cashback Banner
                  if (_amount >= 50 && _cashbackPercent > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052FF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF00D2FF).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0052FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Color(0xFF00D2FF), size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🎉 Instant ${_cashbackPercent.toStringAsFixed(1)}% Cashback Applied!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF00D2FF),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'You save ₦${_cashbackAmount.toStringAsFixed(2)}. You only pay ₦${_netCharge.toStringAsFixed(2)}!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Mode-specific inputs
                  if (_activeMode == 0) ...[
                    // Buy Now Mode: PHONE NUMBER
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Pay For Me Checkbox
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141721) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
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
                    ),
                  ] else ...[
                    // Gift Voucher Mode: GIFT MESSAGE (OPTIONAL) matching Screenshot 3
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
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Happy birthday! Enjoy your airtime...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1B1E29) : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.all(16),
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

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isReady && !_isProcessing ? _handleSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052FF),
                        disabledBackgroundColor: const Color(0xFF26324D),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white38,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: isReady ? 4 : 0,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _activeMode == 1 ? 'Create Gift Voucher' : 'Buy Airtime',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
