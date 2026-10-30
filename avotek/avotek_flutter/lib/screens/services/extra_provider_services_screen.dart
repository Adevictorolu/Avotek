import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/vtu_api_service.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/top_notification.dart';
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
      'color': const Color(0xFFFF6D00),
      'logo': 'assets/images/brands/nabteb.png',
      'icon': Icons.engineering_rounded,
    },
  ];

  static final List<Map<String, dynamic>> _airtimePinNetworks = [
    {
      'id': 1,
      'code': 'MTN',
      'name': 'MTN',
      'color': const Color(0xFFFFCC00),
      'textColor': const Color(0xFF0F172A),
    },
    {
      'id': 2,
      'code': 'AIRTEL',
      'name': 'Airtel',
      'color': const Color(0xFFE50914),
      'textColor': Colors.white,
    },
    {
      'id': 3,
      'code': 'GLO',
      'name': 'Glo',
      'color': const Color(0xFF00A859),
      'textColor': Colors.white,
    },
    {
      'id': 4,
      'code': '9MOBILE',
      'name': '9mobile',
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

  late List<Map<String, dynamic>> _examPrices = List.from(_defaultExamPrices);
  late Map<String, dynamic>? _selectedExam = _examPrices.first;
  double? _smsCostPerPage = 4.50;
  bool _isLoading = false; // Never block UI with rotating spinner
  bool _isPurchasing = false;
  bool _consentConfirmed = false;
  String? _loadError;

  bool get _isExam => widget.service == ExtraProviderService.examPins;
  bool get _isAirtimePins => widget.service == ExtraProviderService.airtimePins;
  String get _title => _isExam
      ? 'Result Checker PINs'
      : (_isAirtimePins ? 'Airtime PIN Generation' : 'Bulk SMS');
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
      // Keep verified defaults active without breaking user experience
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
      if (recipients.length > 500 ||
          recipients.any((phone) => !RegExp(r'^0\d{10}$').hasMatch(phone))) {
        TopNotification.showWarning(
          context,
          'Enter up to 500 valid 11-digit Nigerian phone numbers.',
        );
        return;
      }
      if (!RegExp(r'^[A-Za-z0-9 ]{3,11}$')
          .hasMatch(_senderController.text.trim())) {
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

  void _updateQuantity(int delta) {
    final current = int.tryParse(_quantityController.text.trim()) ?? 1;
    final updated = (current + delta).clamp(1, 10);
    setState(() {
      _quantityController.text = updated.toString();
    });
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
            isDark ? const Color(0xFF0A0D14) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            _title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: EdgeInsets.all(isDesktop ? 28 : 18),
              children: [
                // Top header banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF131F38), const Color(0xFF0F172A)]
                          : [const Color(0xFFEFF6FF), const Color(0xFFF8FAFC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_isExam
                                  ? const Color(0xFF0052FF)
                                  : (_isAirtimePins
                                      ? const Color(0xFFEA580C)
                                      : const Color(0xFF10B981)))
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isExam
                              ? Icons.verified_user_rounded
                              : (_isAirtimePins
                                  ? Icons.print_rounded
                                  : Icons.sms_rounded),
                          color: _isExam
                              ? const Color(0xFF0052FF)
                              : (_isAirtimePins
                                  ? const Color(0xFFEA580C)
                                  : const Color(0xFF10B981)),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isExam
                                  ? 'Instant Result Checker e-PINs'
                                  : (_isAirtimePins
                                      ? 'Airtime PIN & Recharge Cards'
                                      : 'Instant Bulk SMS Delivery'),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isExam
                                  ? 'Official verification tokens with instant display, copy & PDF receipt.'
                                  : (_isAirtimePins
                                      ? 'Generate printable recharge PIN cards instantly with serial numbers.'
                                      : 'High-speed SMS routing across all Nigerian telecom networks.'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                if (_isExam) ...[
                  // Step 1: Select Examination Card Selector (Screenshot 5)
                  Text(
                    'EXAM TYPE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF141721) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFFF6600) : (isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF6600).withOpacity(0.2),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    logoPath,
                                    height: 32,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => Icon(
                                      Icons.school_rounded,
                                      size: 28,
                                      color: isSelected ? const Color(0xFFFF6600) : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$code Result Checker',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₦${amount.toStringAsFixed(0)} per pin',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFF6600),
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
                  const SizedBox(height: 22),

                  // Step 2: Quantity Selector (Screenshot 5)
                  Text(
                    'QUANTITY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
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
                                          ? const Color(0xFFFF6600).withOpacity(0.18)
                                          : (isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSel
                                            ? const Color(0xFFFF6600)
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
                                          color: isSel ? const Color(0xFFFF6600) : (isDark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Only 1, 2, or 5 pins allowed per purchase. For other amounts, make multiple purchases.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Step 3: Candidate Phone (Optional)
                  Text(
                    '3 · CANDIDATE PHONE NUMBER (OPTIONAL)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _candidatePhoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '08012345678 (where candidate can receive PIN)',
                      prefixIcon: const Icon(Icons.phone_iphone_rounded),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ] else if (_isAirtimePins) ...[
                  // Step 1: Select Telecom Network
                  Text(
                    '1 · SELECT TELECOM NETWORK',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _airtimePinNetworks.map((net) {
                      final id = net['id'] as int;
                      final isSelected = _selectedNetworkId == id;
                      final cardColor = net['color'] as Color;
                      final code = net['code'] as String;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setState(() => _selectedNetworkId = id),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? (isSelected ? const Color(0xFF131F38) : const Color(0xFF0F172A))
                                    : (isSelected ? const Color(0xFFEFF6FF) : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? cardColor
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 2.2 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: cardColor.withValues(alpha: 0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: cardColor.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.phone_android_rounded,
                                        color: cardColor,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    code,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: foreground,
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
                  const SizedBox(height: 20),

                  // Step 2: Choose Denomination
                  Text(
                    '2 · SELECT CARD DENOMINATION',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : (isDark ? const Color(0xFF0F172A) : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '₦$denom',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Step 3: Choose Quantity (1-50 cards)
                  Text(
                    '3 · NUMBER OF RECHARGE CARDS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quantity (1 to 50 cards)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: foreground,
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
                                  color: AppColors.primaryBlue,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
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
                                  color: AppColors.primaryBlue,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [1, 2, 5, 10, 20, 50].map((qty) {
                            final isCur = _quantityController.text == qty.toString();
                            return ChoiceChip(
                              label: Text('$qty cards'),
                              selected: isCur,
                              onSelected: (_) => setState(() => _quantityController.text = qty.toString()),
                              selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isCur
                                    ? AppColors.primaryBlue
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 4: Brand / Business Name on Card
                  Text(
                    '4 · NAME ON RECHARGE CARD (OPTIONAL)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _businessNameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Avotek Telecom or My Business Name',
                      prefixIcon: const Icon(Icons.business_rounded),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Bulk SMS UI
                  TextField(
                    controller: _recipientController,
                    minLines: 3,
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Recipients (one Nigerian number per line)',
                      hintText: '08012345678\n08098765432',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _senderController,
                    maxLength: 11,
                    decoration: const InputDecoration(
                      labelText: 'Sender Name (3-11 letters/digits)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    minLines: 3,
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'SMS Content',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _consentConfirmed,
                    onChanged: (value) => setState(
                      () => _consentConfirmed = value ?? false,
                    ),
                    title: const Text(
                      'I have permission to message these recipients.',
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                if (_isExam) ...[
                  const SizedBox(height: 12),
                  // Pay For Me Checkbox (Screenshot 5)
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
                          value: _consentConfirmed,
                          activeColor: const Color(0xFFFF6600),
                          onChanged: (val) => setState(() => _consentConfirmed = val ?? false),
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
                ],
                const SizedBox(height: 20),

                // Order summary card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
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
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '₦${wallet.balance.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: foreground,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _isExam ? const Color(0xFFFF6600) : AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Purchase button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isPurchasing ? null : _purchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isExam ? const Color(0xFFFF6600) : AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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
                            _isExam
                                ? 'Buy Result Checker (${_quantityController.text} pin${_quantityController.text != "1" ? "s" : ""})'
                                : (_isAirtimePins
                                    ? 'Generate ${_airtimePinNetworks.firstWhere((n) => n['id'] == _selectedNetworkId)['code']} ₦$_selectedDenomination PIN (${_quantityController.text})'
                                    : 'Send Bulk SMS'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
