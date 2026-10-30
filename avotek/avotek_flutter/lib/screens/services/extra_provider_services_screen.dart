import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/vtu_api_service.dart';
import '../../core/shell/responsive_shell.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/pay_for_me_dialog.dart';
import '../../widgets/transaction_success_dialog.dart';

enum ExtraProviderService { examPins, bulkSms, airtimePins }

class ExtraProviderServicesScreen extends StatefulWidget {
  final ExtraProviderService service;
  final VoidCallback onToggleTheme;

  const ExtraProviderServicesScreen({
    super.key,
    required this.service,
    required this.onToggleTheme,
  });

  @override
  State<ExtraProviderServicesScreen> createState() =>
      _ExtraProviderServicesScreenState();
}

class _ExtraProviderServicesScreenState
    extends State<ExtraProviderServicesScreen> {
  static final List<Map<String, dynamic>> _defaultExamPrices = [
    {
      'code': 'WAEC',
      'name': 'WAEC Result Checker',
      'exam_type': 'WAEC',
      'amount': 5250.0,
      'badge': 'WEST AFRICA',
      'subtitle': 'Official e-PIN for WASSCE / WAEC exams',
      'color': const Color(0xFF0F9D58),
      'logo': 'assets/images/brands/waec.png',
      'icon': Icons.school_rounded,
    },
    {
      'code': 'NECO',
      'name': 'NECO Result Checker',
      'exam_type': 'NECO',
      'amount': 2500.0,
      'badge': 'NATIONAL',
      'subtitle': 'Token for June/July & Nov/Dec NECO exams',
      'color': const Color(0xFF0052FF),
      'logo': 'assets/images/brands/neco.png',
      'icon': Icons.menu_book_rounded,
    },
    {
      'code': 'NABTEB',
      'name': 'NABTEB Result Checker',
      'exam_type': 'NABTEB',
      'amount': 1000.0,
      'badge': 'TECHNICAL',
      'subtitle': 'Official NBC / NTC verification e-PIN token',
      'color': const Color(0xFF00D2FF),
      'logo': 'assets/images/brands/nabteb.png',
      'icon': Icons.engineering_rounded,
    },
  ];

  static final List<Map<String, dynamic>> _airtimePinNetworks = [
    {
      'id': 1,
      'code': 'MTN',
      'name': 'MTN',
      'logo': 'assets/images/brands/mtn.png',
      'color': const Color(0xFFFFCC00),
      'textColor': const Color(0xFF0F172A),
    },
    {
      'id': 2,
      'code': 'AIRTEL',
      'name': 'Airtel',
      'logo': 'assets/images/brands/airtel.png',
      'color': const Color(0xFFE50914),
      'textColor': Colors.white,
    },
    {
      'id': 3,
      'code': 'GLO',
      'name': 'Glo',
      'logo': 'assets/images/brands/glo.png',
      'color': const Color(0xFF00A859),
      'textColor': Colors.white,
    },
    {
      'id': 4,
      'code': '9MOBILE',
      'name': '9mobile',
      'logo': 'assets/images/brands/9mobile.png',
      'color': const Color(0xFF006838),
      'textColor': Colors.white,
    },
  ];

  static const List<int> _airtimePinDenominations = [100, 200, 500, 1000];

  final _quantityController = TextEditingController(text: '1');
  final _recipientController = TextEditingController();
  final _messageController = TextEditingController();
  final _senderController = TextEditingController();
  final _candidatePhoneController = TextEditingController();
  final _businessNameController = TextEditingController(text: 'Avotek');

  int _selectedNetworkId = 1;
  int _selectedDenomination = 100;
  int _activeMode = 0; // 0: Buy/Send Now, 1: Gift Voucher
  bool _payForMe = false;

  late List<Map<String, dynamic>> _examPrices = List.from(_defaultExamPrices);
  late Map<String, dynamic>? _selectedExam = _examPrices.first;
  double? _smsCostPerPage = 4.50;
  final bool _isLoading = false;
  bool _isPurchasing = false;
  bool _consentConfirmed = false;

  bool get _isExam => widget.service == ExtraProviderService.examPins;
  bool get _isAirtimePins => widget.service == ExtraProviderService.airtimePins;
  String get _title => _isExam
      ? 'Buy Result Checker'
      : (_isAirtimePins ? 'Airtime PIN Generation' : 'Bulk SMS');
  String get _subtitle => _isExam
      ? 'Purchase WAEC, NECO, NABTEB, or NBAIS exam pins'
      : (_isAirtimePins
          ? 'Generate instant printable recharge cards with serial numbers'
          : 'High-speed SMS routing across all Nigerian telecom networks');
  String get _route => _isExam
      ? '/services/exam-pins'
      : (_isAirtimePins ? '/services/airtime-pins' : '/services/bulk-sms');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPricingSilently());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _recipientController.dispose();
    _messageController.dispose();
    _senderController.dispose();
    _candidatePhoneController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPricingSilently() async {
    try {
      final vtu = context.read<VtuProvider>();
      if (_isExam) {
        final prices = await vtu.fetchExamPinPrices();
        if (!mounted || prices.isEmpty) return;
        setState(() {
          final valid = prices.where((p) {
            final amt = p['amount'];
            return (p['code'] ?? p['exam_type']) != null && amt is num && amt > 0;
            }).toList();
          if (valid.isNotEmpty) {
            _examPrices = valid;
            final currentCode = (_selectedExam?['code'] ?? '').toString().toUpperCase();
            _selectedExam = _examPrices.firstWhere(
              (p) => (p['code'] ?? '').toString().toUpperCase() == currentCode,
              orElse: () => _examPrices.first,
            );
          }
        });
      } else {
        final response = await vtu.fetchSmsPricing();
        final data = response['data'];
        final cost = data is Map<String, dynamic>
            ? (data['cost_per_page'] as num?)?.toDouble()
            : null;
        if (cost != null && cost.isFinite && cost > 0 && mounted) {
          setState(() {
            _smsCostPerPage = cost;
          });
        }
      }
    } catch (_) {
      // Keep verified defaults active
    }
  }

  List<String> _recipients() {
    final values = _recipientController.text
        .split(RegExp(r'[\s,;]+'))
        .map((value) => value.replaceAll(RegExp(r'\D'), ''))
        .map((value) => value.startsWith('234') && value.length == 13
            ? '0${value.substring(3)}'
            : value)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    return values;
  }

  double? _price() {
    if (_isExam) {
      final unit = (_selectedExam?['amount'] as num?)?.toDouble();
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
      return unit != null && quantity > 0 ? unit * quantity : null;
    }
    if (_isAirtimePins) {
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
      return quantity > 0 ? (_selectedDenomination * quantity).toDouble() : null;
    }
    final cost = _smsCostPerPage;
    final message = _messageController.text.trim();
    final recipients = _recipients();
    if (cost == null || message.isEmpty || recipients.isEmpty) return null;
    final pages = VtuApiService.estimateSmsPages(message);
    return cost * pages * recipients.length;
  }

  Future<void> _purchase() async {
    if (_isPurchasing || _isLoading) return;
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();
    final user = auth.user;
    final amount = _price();
    if (user == null) {
      TopNotification.showError(context, 'Sign in before purchasing.');
      return;
    }
    if (amount == null || !amount.isFinite || amount <= 0) {
      TopNotification.showWarning(context, 'Complete the required fields first.');
      return;
    }
    if (_isExam) {
      final quantity = int.tryParse(_quantityController.text.trim());
      if (quantity == null || quantity < 1 || quantity > 10) {
        TopNotification.showWarning(context, 'Choose between 1 and 10 PINs.');
        return;
      }
    } else if (_isAirtimePins) {
      final quantity = int.tryParse(_quantityController.text.trim());
      if (quantity == null || quantity < 1 || quantity > 50) {
        TopNotification.showWarning(context, 'Choose between 1 and 50 recharge PINs.');
        return;
      }
    } else {
      final recipients = _recipients();
      if (recipients.isEmpty) {
        TopNotification.showWarning(context, 'Please enter at least one recipient.');
        return;
      }
      if (recipients.length > 500 ||
          recipients.any((phone) => !RegExp(r'^0\d{10}$').hasMatch(phone))) {
        TopNotification.showWarning(
          context,
          'Enter up to 500 valid 11-digit Nigerian phone numbers.',
        );
        return;
      }
      if (!RegExp(r'^[A-Za-z0-9 ]{3,11}$').hasMatch(_senderController.text.trim())) {
        TopNotification.showWarning(
          context,
          'Sender name must be 3 to 11 letters, numbers, or spaces.',
        );
        return;
      }
      if (!_consentConfirmed) {
        TopNotification.showWarning(
          context,
          'Confirm that recipients agreed to receive this message.',
        );
        return;
      }
    }

    if (_payForMe) {
      final networkObj = _airtimePinNetworks.firstWhere(
        (n) => n['id'] == _selectedNetworkId,
        orElse: () => _airtimePinNetworks.first,
      );
      final serviceName = _isExam
          ? '${_selectedExam?['name'] ?? 'Result Checker'} (${_quantityController.text} pin${_quantityController.text != "1" ? "s" : ""})'
          : (_isAirtimePins
              ? '${networkObj['code']} ₦$_selectedDenomination PIN (${_quantityController.text})'
              : 'Bulk SMS (${_recipients().length} recipients)');
      await PayForMeDialog.show(
        context,
        serviceName: serviceName,
        recipient: auth.user?.email ?? auth.user?.phone ?? 'User',
        amount: amount,
      );
      return;
    }

    if (wallet.balance < amount) {
      TopNotification.showError(
        context,
        'Insufficient wallet balance. Available: ₦${wallet.balance.toStringAsFixed(2)}.',
      );
      return;
    }

    setState(() => _isPurchasing = true);
    String? transactionPin;
    final networkObj = _airtimePinNetworks.firstWhere(
      (n) => n['id'] == _selectedNetworkId,
      orElse: () => _airtimePinNetworks.first,
    );
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm $_title',
      amount: amount,
      description: _isExam
          ? '${_selectedExam?['name'] ?? 'Exam PIN'} × ${_quantityController.text}'
          : (_isAirtimePins
              ? '${networkObj['code']} ₦$_selectedDenomination PIN × ${_quantityController.text}'
              : '${_recipients().length} recipients • ${_senderController.text.trim()}'),
      onPinSubmit: (pin) async {
        transactionPin = pin;
        return auth.verifyPin(pin);
      },
    );
    if (!mounted) return;
    if (confirmed != true || transactionPin == null) {
      setState(() => _isPurchasing = false);
      return;
    }
    try {
      final candidatePhone = _candidatePhoneController.text.trim();
      final result = _isExam
          ? await vtu.buyExamPins(
              userId: user.id,
              examCode: (_selectedExam?['code'] ??
                      _selectedExam?['exam_type'] ??
                      'WAEC')
                  .toString(),
              examName: (_selectedExam?['name'] ??
                      _selectedExam?['exam_type'] ??
                      'Exam PIN')
                  .toString(),
              quantity: int.parse(_quantityController.text.trim()),
              unitPrice: (_selectedExam?['amount'] as num).toDouble(),
              userPin: transactionPin,
            )
          : (_isAirtimePins
              ? await vtu.buyAirtimePins(
                  userId: user.id,
                  networkId: _selectedNetworkId,
                  networkName: networkObj['code'] as String,
                  denomination: _selectedDenomination.toDouble(),
                  quantity: int.parse(_quantityController.text.trim()),
                  businessName: _businessNameController.text.trim().isNotEmpty
                      ? _businessNameController.text.trim()
                      : 'Avotek',
                  userPin: transactionPin,
                )
              : await vtu.sendBulkSms(
                  userId: user.id,
                  recipients: _recipients(),
                  message: _messageController.text.trim(),
                  senderName: _senderController.text.trim(),
                  userPin: transactionPin!,
                ));

      await auth.refreshWallet();
      await wallet.fetchWallet(user.id);
      if (!mounted) return;
      if (!result.success || result.order.status == 'failed') {
        TopNotification.showError(context, result.message, title: 'Failed');
      } else if (result.order.status == 'pending') {
        TopNotification.showWarning(
          context,
          result.message,
          title: 'Awaiting provider confirmation',
        );
      } else {
        await TransactionSuccessDialog.show(
          context,
          title: _isExam
              ? 'Exam PIN(s) Ready!'
              : (_isAirtimePins ? 'Airtime PIN(s) Ready!' : 'Bulk SMS Sent!'),
          serviceType: _isExam
              ? '${_selectedExam?['name'] ?? 'Result Checker'} × ${_quantityController.text}'
              : (_isAirtimePins
                  ? '${networkObj['code']} ₦$_selectedDenomination PIN × ${_quantityController.text}'
                  : 'Bulk SMS (${_recipients().length} recipients)'),
          recipient: candidatePhone.isNotEmpty
              ? candidatePhone
              : (_isExam
                  ? 'Candidate / Self'
                  : (_isAirtimePins
                      ? '${_businessNameController.text.trim()} / Self'
                      : _recipients().join(', '))),
          amount: amount,
          reference: result.order.id,
          providerReference: result.order.providerReference,
          token: result.token,
          issuedPins: result.issuedPins,
          message: _isExam
              ? 'Your examination PIN(s) have been generated successfully.'
              : (_isAirtimePins
                  ? 'Your recharge PINs are generated and ready to print or load.'
                  : 'Bulk SMS submitted successfully.'),
        );
        if (!_isExam && !_isAirtimePins) {
          _messageController.clear();
          _recipientController.clear();
        }
      }
    } catch (error) {
      if (mounted) {
        TopNotification.showError(context, '$_title purchase could not be completed: $error');
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
    final price = _price();
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ResponsiveShell(
      currentRoute: _route,
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F1117) : const Color(0xFFF8FAFC),
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

                  // Header Title & Subtitle
                  Text(
                    _title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode Switcher Bar: [ Buy Now / Send Now ] | [ Gift Voucher ] in Avotek Blue/Cyan
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
                                    _isExam || _isAirtimePins
                                        ? Icons.shopping_cart_outlined
                                        : Icons.send_rounded,
                                    size: 18,
                                    color: _activeMode == 0
                                        ? Colors.white
                                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isExam || _isAirtimePins ? 'Buy Now' : 'Send Now',
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

                  // Service Specific UI
                  if (_isAirtimePins) ...[
                    // Step 1: Select Telecom Network
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
                            'SELECT TELECOM NETWORK',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: _airtimePinNetworks.map((net) {
                              final isSelected = _selectedNetworkId == net['id'];
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedNetworkId = net['id'] as int),
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
                                                  net['logo'] as String,
                                                  height: 32,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (ctx, err, stack) => Icon(
                                                    Icons.phone_android,
                                                    size: 26,
                                                    color: isSelected ? const Color(0xFF00D2FF) : Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  net['code'] as String,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
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
                                                child: const Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
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
                    const SizedBox(height: 18),

                    // Step 2: Select Card Denomination
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
                            'SELECT CARD DENOMINATION',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: _airtimePinDenominations.map((denom) {
                              final isSelected = _selectedDenomination == denom;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedDenomination = denom),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF0052FF)
                                            : (isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9)),
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
                                                  color: const Color(0xFF0052FF).withOpacity(0.3),
                                                  blurRadius: 8,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '₦$denom',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                          ),
                                        ),
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
                    const SizedBox(height: 18),

                    // Step 3: Quantity Stepper & Chips
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'QUANTITY (1 TO 50 CARDS)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      final current = int.tryParse(_quantityController.text.trim()) ?? 1;
                                      if (current > 1) {
                                        setState(() => _quantityController.text = (current - 1).toString());
                                      }
                                    },
                                    icon: const Icon(Icons.remove_circle_outline_rounded),
                                    color: const Color(0xFF0052FF),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E2230) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Text(
                                      _quantityController.text,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: foreground,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final current = int.tryParse(_quantityController.text.trim()) ?? 1;
                                      if (current < 50) {
                                        setState(() => _quantityController.text = (current + 1).toString());
                                      }
                                    },
                                    icon: const Icon(Icons.add_circle_outline_rounded),
                                    color: const Color(0xFF0052FF),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [1, 2, 5, 10, 20, 50].map((qty) {
                              final isCur = _quantityController.text == qty.toString();
                              return InkWell(
                                onTap: () => setState(() => _quantityController.text = qty.toString()),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isCur
                                        ? const Color(0xFF0052FF).withOpacity(0.18)
                                        : (isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCur
                                          ? const Color(0xFF0052FF)
                                          : (isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  child: Text(
                                    '$qty card${qty > 1 ? "s" : ""}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: isCur ? FontWeight.w800 : FontWeight.w600,
                                      color: isCur ? const Color(0xFF00D2FF) : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Step 4: Business Name
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
                            'NAME ON RECHARGE CARD (OPTIONAL)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _businessNameController,
                            style: GoogleFonts.plusJakartaSans(color: foreground),
                            decoration: InputDecoration(
                              hintText: 'e.g. Avotek Telecom or My Business Name',
                              hintStyle: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white38 : Colors.black38),
                              prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF00D2FF)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1C202C) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
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
                  ] else if (_isExam) ...[
                    // Exam Type Selector Card
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
                            'EXAM TYPE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: _examPrices.map((exam) {
                              final code = (exam['code'] ?? exam['exam_type'] ?? '').toString().toUpperCase();
                              final isSelected = (_selectedExam?['code'] ?? _selectedExam?['exam_type'] ?? '')
                                      .toString()
                                      .toUpperCase() ==
                                  code;
                              final amount = (exam['amount'] as num?)?.toDouble() ?? 0.0;
                              final logoPath = exam['logo'] as String? ?? 'assets/images/brands/waec.png';

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedExam = exam),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 90,
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
                                                  logoPath,
                                                  height: 30,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (ctx, err, stack) => Icon(
                                                    Icons.school,
                                                    size: 26,
                                                    color: isSelected ? const Color(0xFF00D2FF) : Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  code,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11.5,
                                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                                Text(
                                                  '₦${amount.toStringAsFixed(0)}',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF00D2FF),
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
                    const SizedBox(height: 18),

                    // Quantity Selection
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
                            'QUANTITY',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [1, 2, 5].map((q) {
                              final isSel = _quantityController.text == q.toString();
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () => setState(() => _quantityController.text = q.toString()),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(0xFF0052FF).withOpacity(0.18)
                                            : (isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSel
                                              ? const Color(0xFF0052FF)
                                              : (isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1)),
                                          width: isSel ? 2 : 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$q pin${q > 1 ? 's' : ''}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                            color: isSel ? const Color(0xFF00D2FF) : (isDark ? Colors.white : Colors.black87),
                                          ),
                                        ),
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
                    const SizedBox(height: 18),

                    // Candidate Phone
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
                            'CANDIDATE PHONE NUMBER (OPTIONAL)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _candidatePhoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.plusJakartaSans(color: foreground),
                            decoration: InputDecoration(
                              hintText: '08012345678 (where candidate can receive PIN)',
                              hintStyle: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white38 : Colors.black38),
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
                  ] else ...[
                    // Bulk SMS UI
                    // 1. Supported Networks with Official Logos
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SUPPORTED NETWORKS (100% ROUTING)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Active Delivery',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: _airtimePinNetworks.map((net) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        net['logo'] as String,
                                        height: 28,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        net['code'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Sender ID
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SENDER ID',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                '${_senderController.text.length}/11 chars',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _senderController,
                            maxLength: 11,
                            style: GoogleFonts.plusJakartaSans(color: foreground),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'e.g. MyStore, Notice, Avotek',
                              hintStyle: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white38 : Colors.black38),
                              prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF00D2FF)),
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

                    // 3. Recipients
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RECIPIENTS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0052FF).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_recipients().length} valid recipient(s)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF00D2FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _recipientController,
                            minLines: 3,
                            maxLines: 6,
                            style: GoogleFonts.plusJakartaSans(color: foreground),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Enter Nigerian phone numbers separated by comma or new line\ne.g. 08012345678, 09087654321',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
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

                    // 4. SMS Content
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SMS CONTENT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                '${_messageController.text.length} chars • ${VtuApiService.estimateSmsPages(_messageController.text)} page(s)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF00D2FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _messageController,
                            minLines: 3,
                            maxLines: 6,
                            style: GoogleFonts.plusJakartaSans(color: foreground),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Type your broadcast SMS message here...',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: _consentConfirmed,
                                activeColor: const Color(0xFF0052FF),
                                onChanged: (val) => setState(() => _consentConfirmed = val ?? false),
                              ),
                              Expanded(
                                child: Text(
                                  'I confirm that recipients consented to receive this broadcast message.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Pay For Me Checkbox across all services
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              price != null ? '₦${price.toStringAsFixed(2)}' : '--',
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

                  // Checkout Action Button with Avotek Gradient
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
                      onPressed: _isPurchasing ? null : _purchase,
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
                                  : (_isExam
                                      ? 'Pay for Exam PIN (${_quantityController.text})'
                                      : (_isAirtimePins
                                          ? 'Generate Airtime PIN (${_quantityController.text})'
                                          : 'Send Bulk SMS')),
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
