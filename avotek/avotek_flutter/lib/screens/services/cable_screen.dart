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

class CableScreen extends StatefulWidget {
  const CableScreen({super.key});

  @override
  State<CableScreen> createState() => _CableScreenState();
}

class _CableScreenState extends State<CableScreen> {
  final _smartcardController = TextEditingController();
  final _phoneController = TextEditingController();
  final _giftMessageController = TextEditingController();

  // Mode: 0 = Buy Now, 1 = Gift Voucher
  int _activeMode = 0;

  // Options
  bool _autoRenew = false;
  bool _payForMe = false;

  String _selectedProvider = 'GOTV';
  String? _selectedPackage;
  double _packageAmount = 0.0;
  String _selectedPackageName = '';

  bool _isVerifying = false;
  bool _isProcessing = false;
  String? _verifiedCustomerName;

  List<Map<String, dynamic>> _livePackages = [];
  bool _isLoadingPackages = false;
  String? _packageLoadError;

  final List<Map<String, String>> _cableProviders = [
    {
      'id': 'GOTV',
      'label': 'GOTV',
      'logo': 'assets/images/brands/gotv.png',
    },
    {
      'id': 'STARTIMES',
      'label': 'StarTime',
      'logo': 'assets/images/brands/startimes.png',
    },
    {
      'id': 'DSTV',
      'label': 'DSTV',
      'logo': 'assets/images/brands/dstv.png',
    },
    {
      'id': 'SHOWMAX',
      'label': 'Showmax',
      'logo': 'assets/images/brands/showmax.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.user?.phone != null && auth.user!.phone!.isNotEmpty) {
      _phoneController.text = auth.user!.phone!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLivePackages());
  }

  @override
  void dispose() {
    _smartcardController.dispose();
    _phoneController.dispose();
    _giftMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadLivePackages() async {
    final provider = _selectedProvider;
    setState(() {
      _isLoadingPackages = true;
      _packageLoadError = null;
      _livePackages = [];
      _selectedPackage = null;
      _packageAmount = 0.0;
      _selectedPackageName = '';
    });
    try {
      final vtu = context.read<VtuProvider>();
      final pkgs = await vtu.fetchCablePackages(provider);
      if (!mounted || provider != _selectedProvider) return;
      final formatted = pkgs
          .map((p) {
            final amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
            final code =
                p['variation_code']?.toString() ?? p['id']?.toString() ?? '';
            final name = p['product_name']?.toString() ?? code;
            return {
              'code': code,
              'name': name,
              'price': amt,
            };
          })
          .where((p) => (p['code'] as String).isNotEmpty && (p['price'] as double) > 0)
          .toList();

      setState(() {
        _livePackages = formatted;
        _isLoadingPackages = false;
        if (formatted.isEmpty) {
          _packageLoadError = 'No live packages found for $provider. Please retry.';
        } else {
          _selectedPackage = formatted.first['code'] as String;
          _packageAmount = formatted.first['price'] as double;
          _selectedPackageName = formatted.first['name'] as String;
        }
      });
    } catch (e) {
      if (!mounted || provider != _selectedProvider) return;
      setState(() {
        _isLoadingPackages = false;
        _packageLoadError = 'Failed to load packages: $e';
      });
    }
  }

  Future<void> _handleVerifySmartcard() async {
    final card = _smartcardController.text.trim();
    if (card.length < 8) {
      TopNotification.showWarning(context, 'Please enter a valid smartcard/IUC number (at least 8 digits).');
      return;
    }
    setState(() {
      _isVerifying = true;
      _verifiedCustomerName = null;
    });

    try {
      final vtu = context.read<VtuProvider>();
      final res = await vtu.verifySmartcard(
        provider: _selectedProvider,
        smartcardNumber: card,
      );
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        if (res.isValid && res.customerName.isNotEmpty) {
          _verifiedCustomerName = res.customerName;
        } else {
          _verifiedCustomerName = null;
        }
      });

      if (res.isValid && res.customerName.isNotEmpty) {
        TopNotification.showSuccess(context, 'Smartcard verified: ${res.customerName}');
      } else {
        TopNotification.showError(context, 'Could not verify decoder number. Please confirm and retry.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      TopNotification.showError(context, 'Verification error: $e');
    }
  }

  List<String> _getValidationErrors() {
    final errors = <String>[];
    if (_selectedPackage == null) {
      errors.add('Select a subscription plan');
    }
    if (_activeMode == 0) {
      final card = _smartcardController.text.trim();
      if (card.length < 8) {
        errors.add('Enter your IUC/Smart card number (10+ digits)');
      }
      if (_verifiedCustomerName == null && !_payForMe) {
        errors.add('Decoder number must be verified first');
      }
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

    // 1. Pay For Me Mode
    if (_payForMe && _activeMode == 0) {
      final card = _smartcardController.text.trim();
      await PayForMeDialog.show(
        context,
        serviceName: 'Cable TV ($_selectedProvider: $_selectedPackageName)',
        recipient: 'Smartcard: $card (${_verifiedCustomerName ?? "Customer"})',
        amount: _packageAmount,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    if (wallet.balance < _packageAmount) {
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
        title: 'Create Cable Gift Voucher',
        amount: _packageAmount,
        description: 'Voucher for $_selectedProvider - $_selectedPackageName\nRecipient can redeem via coupons.',
        onPinSubmit: (pin) async => auth.verifyPin(pin),
      );
      if (confirmed == true && mounted) {
        try {
          setState(() => _isProcessing = true);
          final res = await SupabaseService.instance.createGiftVoucher(
            amount: _packageAmount,
            recipient: _phoneController.text.trim(),
            note: 'Cable TV ($_selectedProvider: $_selectedPackageName) ${message.isNotEmpty ? "• $message" : ""}',
          );
          await auth.refreshWallet();
          await wallet.fetchWallet(auth.user!.id);

          if (!mounted) return;
          setState(() => _isProcessing = false);
          final voucherCode = res['code']?.toString() ?? 'GIFT-CODE';
          await TransactionSuccessDialog.show(
            context,
            title: 'Gift Voucher Created!',
            serviceType: 'Cable TV Gift Voucher',
            recipient: _phoneController.text.isNotEmpty ? _phoneController.text : 'Shareable Link',
            amount: _packageAmount,
            reference: voucherCode,
            token: voucherCode,
            message: 'Gift voucher created successfully! Share the voucher code with the recipient.',
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          TopNotification.showError(context, 'Failed to create gift voucher: $e');
        }
      }
      return;
    }

    // Direct Purchase Mode
    final card = _smartcardController.text.trim();
    String? transactionPin;
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Cable TV Subscription',
      amount: _packageAmount,
      description: '$_selectedProvider • $card\nSubscriber: $_verifiedCustomerName',
      onPinSubmit: (pin) async {
        transactionPin = pin;
        return auth.verifyPin(pin);
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        final vtu = context.read<VtuProvider>();
        final result = await vtu.payCableTV(
          userId: auth.user!.id,
          provider: _selectedProvider,
          smartcardNumber: card,
          variationCode: _selectedPackage!,
          amount: _packageAmount,
          customerName: _verifiedCustomerName,
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : auth.user?.phone,
          userPin: transactionPin,
        );

        await auth.refreshWallet();
        await wallet.fetchWallet(auth.user!.id);

        if (!mounted) return;
        setState(() => _isProcessing = false);

        if (!result.success || result.order.status == 'failed') {
          TopNotification.showError(context, result.message, title: 'Subscription Failed');
          return;
        }

        await TransactionSuccessDialog.show(
          context,
          title: 'Cable Subscription Active!',
          serviceType: '$_selectedProvider - $_selectedPackageName',
          recipient: 'Smartcard: $card ($_verifiedCustomerName)',
          amount: _packageAmount,
          reference: result.order.id,
          providerReference: result.order.providerReference,
          message: 'Your $_selectedProvider subscription has been renewed successfully.',
        );
        _smartcardController.clear();
        setState(() {
          _verifiedCustomerName = null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        TopNotification.showError(context, 'Subscription failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validationErrors = _getValidationErrors();
    final isReadyToPay = validationErrors.isEmpty;

    return ResponsiveShell(
      currentRoute: '/services/cable',
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
                    'Cable Subscriptions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quick and secure cable subscription payment',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode Switcher Bar: [ Buy Now ] | [ Gift Voucher ] in Avotek Blue Gradient
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
                          'SELECT CABLE PROVIDER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: _cableProviders.map((prov) {
                            final isSelected = _selectedProvider == prov['id'];
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: InkWell(
                                  onTap: () {
                                    if (_selectedProvider != prov['id']) {
                                      setState(() {
                                        _selectedProvider = prov['id']!;
                                        _verifiedCustomerName = null;
                                      });
                                      _loadLivePackages();
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
                                              Image.asset(
                                                prov['logo']!,
                                                height: 32,
                                                fit: BoxFit.contain,
                                                errorBuilder: (ctx, err, stack) => Icon(
                                                  Icons.tv,
                                                  size: 26,
                                                  color: isSelected ? const Color(0xFF00D2FF) : Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                prov['label']!,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: isSelected
                                                      ? const Color(0xFF00D2FF)
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

                  // Smartcard & Phone Inputs (PLACED ABOVE INITIATE BUTTON & PACKAGES)
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
                            'IUC / SMART CARD NUMBER',
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
                                  controller: _smartcardController,
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
                                    hintText: 'Enter your decoder / smart card number',
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
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _isVerifying ? null : _handleVerifySmartcard,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0038B8),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _isVerifying
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Verify', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                          if (_verifiedCustomerName != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Account Name: $_verifiedCustomerName',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
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
                              hintText: 'Enjoy your subscription!',
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

                  // SELECT SUBSCRIPTION PLAN Card (COMPACT WIDGET WITH INTERNAL SCROLL)
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
                              'SELECT SUBSCRIPTION PLAN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            Text(
                              '${_livePackages.length} packages',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_isLoadingPackages)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(color: Color(0xFF0038B8)),
                            ),
                          )
                        else if (_packageLoadError != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    _packageLoadError!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _loadLivePackages,
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
                                itemCount: _livePackages.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isDesktop ? 3 : 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: isDesktop ? 2.3 : 1.5,
                                ),
                                itemBuilder: (context, index) {
                                  final pkg = _livePackages[index];
                                  final code = pkg['code'] as String;
                                  final name = pkg['name'] as String;
                                  final price = pkg['price'] as double;
                                  final isSelected = _selectedPackage == code;

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedPackage = code;
                                        _packageAmount = price;
                                        _selectedPackageName = name;
                                      });
                                    },
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.5,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₦${price.toStringAsFixed(0)}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0038B8),
                                              letterSpacing: 0.2,
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

                  // INITIATE PAYMENT ACTION CARD (BELOW THE PACKAGES LIST)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141721) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isReadyToPay
                            ? const Color(0xFF0038B8)
                            : (isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0)),
                        width: isReadyToPay ? 1.5 : 1,
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
                                    'SELECTED SUBSCRIPTION',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedPackageName.isNotEmpty ? _selectedPackageName : 'Choose a package below',
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
                            if (_packageAmount > 0)
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
                                  '₦${_packageAmount.toStringAsFixed(0)}',
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
                            gradient: isReadyToPay && !_isProcessing
                                ? const LinearGradient(
                                    colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isReadyToPay && !_isProcessing
                                ? null
                                : (isDark ? const Color(0xFF26324D) : const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isReadyToPay && !_isProcessing
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
                            onPressed: isReadyToPay && !_isProcessing ? _handleSubmit : null,
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
                                            : (_payForMe ? Icons.share : Icons.tv_rounded),
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _activeMode == 1
                                            ? 'Create Gift Voucher'
                                            : (_payForMe
                                                ? 'Generate Pay For Me Link'
                                                : (_packageAmount > 0
                                                    ? 'Pay Subscription • ₦${_packageAmount.toStringAsFixed(0)}'
                                                    : 'Pay Subscription')),
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

                        if (!isReadyToPay && validationErrors.isNotEmpty) ...[
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
