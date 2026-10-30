import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pay_for_me_dialog.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/transaction_success_dialog.dart';

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final _meterController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _giftMessageController = TextEditingController();

  // Mode: 0 = Buy Now, 1 = Gift Voucher
  int _activeMode = 0;

  String _selectedDisco = 'ikeja-electric';
  String _selectedMeterType = 'prepaid';
  bool _payForMe = false;
  bool _isVerifying = false;
  bool _isProcessing = false;
  String? _verifiedCustomerName;
  String? _verificationDetails;

  final List<Map<String, String>> _discoList = [
    {'id': 'ikeja-electric', 'name': 'Ikeja Electric - IKEDC (PHCN)'},
    {'id': 'eko-electric', 'name': 'Eko Electricity - EKEDC (PHCN)'},
    {'id': 'kano-electric', 'name': 'Kano Electricity - KEDCO (PHCN)'},
    {'id': 'portharcourt-electric', 'name': 'Port Harcourt Electricity - PHED (PHCN)'},
    {'id': 'jos-electric', 'name': 'Jos Electricity - JED (PHCN)'},
    {'id': 'ibadan-electric', 'name': 'Ibadan Electricity - IBEDC (PHCN)'},
    {'id': 'kaduna-electric', 'name': 'Kaduna Electricity - KAEDCO (PHCN)'},
    {'id': 'abuja-electric', 'name': 'Abuja Electricity - AEDC (PHCN)'},
    {'id': 'enugu-electric', 'name': 'Enugu Electricity - EEDC (PHCN)'},
    {'id': 'benin-electric', 'name': 'Benin Electricity - BEDC (PHCN)'},
    {'id': 'aba-electric', 'name': 'Aba Electricity - AED (PHCN)'},
    {'id': 'yola-electric', 'name': 'Yola Electricity - YED (PHCN)'},
  ];

  final List<double> _quickAmounts = [1000, 2000, 5000, 10000, 20000];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.user?.phone != null && auth.user!.phone!.isNotEmpty) {
      _phoneController.text = auth.user!.phone!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VtuProvider>().fetchElectricityProviders();
    });
  }

  @override
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _giftMessageController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyMeter() async {
    if (_isVerifying) return;
    final meter = _meterController.text.trim();
    if (meter.length < 8) {
      TopNotification.showWarning(context, 'Please enter a valid meter number (at least 8 digits).');
      return;
    }

    setState(() {
      _isVerifying = true;
      _verifiedCustomerName = null;
      _verificationDetails = null;
    });

    final vtu = context.read<VtuProvider>();
    final result = await vtu.verifyMeter(
      disco: _selectedDisco,
      meterNumber: meter,
      meterType: _selectedMeterType,
    );

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      if (result.isValid) {
        _verifiedCustomerName = result.customerName;
        _verificationDetails = result.details;
      }
    });

    if (result.isValid) {
      TopNotification.showSuccess(context, 'Meter verified: ${result.customerName}');
    } else {
      TopNotification.showError(context, 'Could not verify meter number. Please check details and retry.');
    }
  }

  List<String> _getValidationErrors() {
    final errors = <String>[];
    final meter = _meterController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (_activeMode == 0) {
      if (meter.length < 8) {
        errors.add('Enter a valid meter number (8+ digits)');
      }
      if (_verifiedCustomerName == null && !_payForMe) {
        errors.add('Meter number must be verified first');
      }
      final phone = _phoneController.text.trim();
      if (phone.length < 10) {
        errors.add('Enter a valid 11-digit phone number for token delivery');
      }
    }

    if (amount < 500) {
      errors.add('Minimum electricity purchase is ₦500');
    }

    return errors;
  }

  Future<void> _handleSubmit() async {
    final errors = _getValidationErrors();
    if (errors.isNotEmpty) {
      TopNotification.showWarning(context, errors.first);
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final discoName = _discoList.firstWhere(
      (d) => d['id'] == _selectedDisco,
      orElse: () => {'name': _selectedDisco},
    )['name']!;

    // 1. Pay For Me Mode
    if (_payForMe && _activeMode == 0) {
      final meter = _meterController.text.trim();
      await PayForMeDialog.show(
        context,
        serviceName: 'Electricity Bill ($discoName)',
        recipient: 'Meter: $meter ($_selectedMeterType.toUpperCase())',
        amount: amount,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final user = auth.user;
    if (user == null) {
      TopNotification.showError(context, 'Please sign in to proceed.');
      return;
    }

    if (wallet.balance < amount) {
      TopNotification.showError(
        context,
        'Insufficient balance (₦${wallet.balance.toStringAsFixed(2)} available). Please fund your wallet.',
      );
      return;
    }

    // 2. Gift Voucher Mode
    if (_activeMode == 1) {
      final message = _giftMessageController.text.trim();
      final confirmed = await PinModal.show(
        context,
        title: 'Create Electricity Gift Voucher',
        amount: amount,
        description: 'Voucher for $discoName (₦${amount.toStringAsFixed(0)})\nRecipient can redeem via coupons.',
        onPinSubmit: (pin) async => auth.verifyPin(pin),
      );

      if (confirmed == true && mounted) {
        try {
          setState(() => _isProcessing = true);
          final res = await SupabaseService.instance.createGiftVoucher(
            amount: amount,
            recipient: _phoneController.text.trim(),
            note: 'Electricity Bill ($discoName) ${message.isNotEmpty ? "• $message" : ""}',
          );
          await auth.refreshWallet();
          await wallet.fetchWallet(user.id);

          if (!mounted) return;
          setState(() => _isProcessing = false);
          final voucherCode = res['code']?.toString() ?? 'GIFT-CODE';
          await TransactionSuccessDialog.show(
            context,
            title: 'Electricity Voucher Created!',
            serviceType: 'Electricity Gift Voucher ($discoName)',
            recipient: _phoneController.text.isNotEmpty ? _phoneController.text : 'Shareable Link',
            amount: amount,
            reference: voucherCode,
            token: voucherCode,
            message: 'Gift voucher created! Share the code or link with the recipient to redeem instantly.',
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          TopNotification.showError(context, 'Failed to create gift voucher: $e');
        }
      }
      return;
    }

    // 3. Direct Purchase Mode
    final meter = _meterController.text.trim();
    final phone = _phoneController.text.trim();
    String? transactionPin;
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Electricity Purchase',
      amount: amount,
      description: '$discoName • $meter\nCustomer: ${_verifiedCustomerName ?? "Customer"}',
      onPinSubmit: (pin) async {
        transactionPin = pin;
        return auth.verifyPin(pin);
      },
    );

    if (confirmed == true && mounted && transactionPin != null) {
      setState(() => _isProcessing = true);
      try {
        final vtu = context.read<VtuProvider>();
        final result = await vtu.payElectricity(
          userId: user.id,
          disco: _selectedDisco,
          meterNumber: meter,
          meterType: _selectedMeterType,
          amount: amount,
          customerName: _verifiedCustomerName,
          phone: phone,
          userPin: transactionPin,
        );

        await auth.refreshWallet();
        await wallet.fetchWallet(user.id);

        if (!mounted) return;
        setState(() => _isProcessing = false);

        if (!result.success || result.order.status == 'failed') {
          TopNotification.showError(context, result.message, title: 'Payment Failed');
          return;
        }

        await TransactionSuccessDialog.show(
          context,
          title: 'Electricity Token Generated!',
          serviceType: '$discoName ($_selectedMeterType.toUpperCase())',
          recipient: 'Meter: $meter ($_verifiedCustomerName)',
          amount: amount,
          reference: result.order.id,
          providerReference: result.order.providerReference,
          token: result.token,
          message: result.token != null && result.token!.isNotEmpty
              ? 'Token: ${result.token}\nEnter this 20-digit token on your keypad meter to recharge.'
              : 'Payment successful. Receipt delivered to your account.',
        );
        _meterController.clear();
        setState(() {
          _verifiedCustomerName = null;
          _verificationDetails = null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        TopNotification.showError(context, 'Electricity payment failed: $e');
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
      currentRoute: '/services/electricity',
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

                  // Header matching user screenshot
                  Text(
                    'Pay Electricity Bill',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instant meter token delivery and activation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode Switcher Bar (Avotek Blue Gradient)
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
                      'This creates a shareable electricity voucher link. The recipient redeems it for their meter.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF00D2FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // DisCo Grid matching user's uploaded image
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
                          'ELECTRICITY COMPANY (DISCO)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                         constraints: const BoxConstraints(maxHeight: 230),
                         child: GridView.builder(
                          shrinkWrap: true,
                          primary: false,
                          itemCount: _discoList.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: isDesktop ? 2.8 : 2.2,
                          ),
                          itemBuilder: (context, index) {
                            final disco = _discoList[index];
                            final id = disco['id']!;
                            final name = disco['name']!;
                            final isSelected = _selectedDisco == id;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDisco = id;
                                  _verifiedCustomerName = null;
                                  _verificationDetails = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0052FF)
                                        : (isDark ? const Color(0xFF282D3D) : const Color(0xFFCBD5E1)),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF0052FF).withOpacity(0.2),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF00D2FF)
                                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                    ),
                                  ),
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

                  // Meter Type: Prepaid vs Postpaid
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
                          'METER TYPE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedMeterType = 'prepaid'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _selectedMeterType == 'prepaid'
                                        ? const Color(0xFF0052FF).withOpacity(0.18)
                                        : (isDark ? const Color(0xFF1B1E29) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedMeterType == 'prepaid'
                                          ? const Color(0xFF0052FF)
                                          : (isDark ? const Color(0xFF282D3D) : const Color(0xFFCBD5E1)),
                                      width: _selectedMeterType == 'prepaid' ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 18,
                                        color: _selectedMeterType == 'prepaid'
                                            ? const Color(0xFF00D2FF)
                                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Prepaid (Token)',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedMeterType == 'prepaid'
                                              ? const Color(0xFF00D2FF)
                                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedMeterType = 'postpaid'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _selectedMeterType == 'postpaid'
                                        ? const Color(0xFF0052FF).withOpacity(0.18)
                                        : (isDark ? const Color(0xFF1B1E29) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedMeterType == 'postpaid'
                                          ? const Color(0xFF0052FF)
                                          : (isDark ? const Color(0xFF282D3D) : const Color(0xFFCBD5E1)),
                                      width: _selectedMeterType == 'postpaid' ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_rounded,
                                        size: 18,
                                        color: _selectedMeterType == 'postpaid'
                                            ? const Color(0xFF00D2FF)
                                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Postpaid (Bill)',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedMeterType == 'postpaid'
                                              ? const Color(0xFF00D2FF)
                                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Meter Number & Inputs
                  if (_activeMode == 0) ...[
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
                            'METER NUMBER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _meterController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (_) {
                                    if (_verifiedCustomerName != null) {
                                      setState(() => _verifiedCustomerName = null);
                                    }
                                  },
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your meter number',
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
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isVerifying ? null : _handleVerifyMeter,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        'Verify',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          if (_verifiedCustomerName != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified, size: 20, color: Color(0xFF10B981)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Customer: $_verifiedCustomerName',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                        if (_verificationDetails != null && _verificationDetails!.isNotEmpty)
                                          Text(
                                            _verificationDetails!,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: isDark ? Colors.white70 : const Color(0xFF475569),
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

                          Text(
                            'AMOUNT (₦)',
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
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter amount e.g. 5000',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 14, right: 6),
                                child: Text(
                                  '₦',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF00D2FF),
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
                              return InkWell(
                                onTap: () => setState(() => _amountController.text = q.toInt().toString()),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Text(
                                    '₦${q.toInt()}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'PHONE NUMBER (FOR TOKEN RECEIPT)',
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
                            activeColor: AppColors.primaryBlue,
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
                    // Gift Voucher Inputs
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
                            'AMOUNT (₦)',
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
                              hintText: 'Enter amount e.g. 5000',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 14, right: 6),
                                child: Text(
                                  '₦',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF00D2FF),
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1B1E29) : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1B1E29) : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enjoy your electricity voucher! Redeemable on any meter.',
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

                  // Action Button with Avotek Blue Gradient
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isReady && !_isProcessing
                          ? const LinearGradient(
                              colors: [Color(0xFF0052FF), Color(0xFF00D2FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isReady && !_isProcessing ? null : (isDark ? const Color(0xFF26324D) : const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isReady && !_isProcessing
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0052FF).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
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
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _payForMe && _activeMode == 0
                                  ? 'Generate Pay For Me Link'
                                  : (_activeMode == 1 ? 'Create Gift Voucher' : 'Pay Electricity Bill'),
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
