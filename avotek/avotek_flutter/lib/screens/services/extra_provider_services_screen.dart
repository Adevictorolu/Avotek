import '../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/vtu_api_service.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/utils/user_facing_error.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/pay_for_me_dialog.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/transaction_success_dialog.dart';

enum ExtraProviderService { examPins, bulkSms, airtimePins, dataCard, airtimeToCash }

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
      'purpose': 'WASSCE Result Checking & Verification',
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
      'purpose': 'SSCE & BECE Result Checking Token',
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
      'purpose': 'NBC & NTC Verification Token',
      'color': const Color(0xFF0052FF),
      'logo': 'assets/images/brands/nabteb.png',
      'icon': Icons.engineering_rounded,
    },
    {
      'code': 'JAMB',
      'name': 'JAMB UTME / Direct Entry',
      'exam_type': 'JAMB',
      'amount': 8200.0,
      'badge': 'UTME & DE',
      'subtitle': 'Candidate Profile & UTME / Direct Entry Registration',
      'purpose': 'UTME & Direct Entry Registration e-PIN',
      'color': const Color(0xFF0038B8),
      'logo': 'assets/images/brands/jamb.png',
      'icon': Icons.school_rounded,
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

  static final List<Map<String, dynamic>> _dataCardPlans = [
    {'name': '1.5GB (30 Days)', 'price': 480.0, 'code': '1.5GB'},
    {'name': '2.0GB (30 Days)', 'price': 620.0, 'code': '2.0GB'},
    {'name': '3.0GB (30 Days)', 'price': 930.0, 'code': '3.0GB'},
    {'name': '5.0GB (30 Days)', 'price': 1500.0, 'code': '5.0GB'},
  ];
  int _selectedDataCardIndex = 0;
  double get _selectedDataCardPrice => (_dataCardPlans[_selectedDataCardIndex]['price'] as num).toDouble();
  String get _selectedDataCardName => _dataCardPlans[_selectedDataCardIndex]['name'] as String;

  final _airtimeToCashAmountCtrl = TextEditingController(text: '1000');
  final _airtimeToCashSenderPhoneCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final String _payoutDestination = 'wallet'; // 'wallet' or 'bank'

  final _quantityController = TextEditingController(text: '1');
  final _recipientController = TextEditingController();
  final _messageController = TextEditingController();
  final _senderController = TextEditingController();
  final _businessNameController = TextEditingController(text: 'Avotek');

  int _selectedNetworkId = 1;
  List<Map<String, dynamic>> _rechargeCardPlans = [];
  Map<String, dynamic>? _selectedRechargeCardPlan;
  bool _isLoadingRechargeCardPlans = false;
  String? _rechargeCardPlansError;
  int _rechargeCardRequestId = 0;
  int _activeMode = 0; // 0: Buy/Send Now, 1: Gift Voucher

  late List<Map<String, dynamic>> _examPrices = List.from(_defaultExamPrices);
  late Map<String, dynamic>? _selectedExam = _examPrices.first;
  double? _smsCostPerPage = 7;
  final bool _isLoading = false;
  bool _isPurchasing = false;
  bool _consentConfirmed = false;

  bool get _isExam => widget.service == ExtraProviderService.examPins;

  /// Official exam-board logo by code.
  String _examLogoFor(String code) {
    final clean = code.toUpperCase();
    if (clean.contains('NECO')) {
      return 'assets/images/brands/neco.png';
    }
    if (clean.contains('NABTEB')) {
      return 'assets/images/brands/nabteb.png';
    }
    if (clean.contains('JAMB')) {
      return 'assets/images/brands/jamb.png';
    }
    if (clean.contains('WAEC') || clean.contains('WASSCE')) {
      return 'assets/images/brands/waec.png';
    }
    return 'assets/images/brands/waec.png';
  }

  static const List<String> _brandLogoAssets = [
    'assets/images/brands/jamb.png',
    'assets/images/brands/waec.png',
    'assets/images/brands/neco.png',
    'assets/images/brands/nabteb.png',
    'assets/images/brands/mtn.png',
    'assets/images/brands/airtel.png',
    'assets/images/brands/glo.png',
    'assets/images/brands/9mobile.png',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in _brandLogoAssets) {
      precacheImage(ResizeImage(AssetImage(asset), height: 90), context);
    }
  }

  bool get _isAirtimePins => widget.service == ExtraProviderService.airtimePins;
  bool get _isDataCard => widget.service == ExtraProviderService.dataCard;
  bool get _isAirtimeToCash => widget.service == ExtraProviderService.airtimeToCash;

  String get _airtimeToCashReceiverPhone {
    switch (_selectedNetworkId) {
      case 1:
        return 'MTN';
      case 2:
        return 'Airtel';
      default:
        return '';
    }
  }

  String get _title => _isExam
      ? 'Buy Result Checker'
      : (_isAirtimePins
            ? 'Airtime Printing'
            : (_isDataCard
                  ? 'Data Card Printing'
                  : (_isAirtimeToCash ? 'Airtime to Cash' : 'Bulk SMS')));

  String get _subtitle => _isExam
      ? 'Purchase official JAMB, WAEC, NECO, or NABTEB registration & result checker PINs'
      : (_isAirtimePins
            ? 'Generate instant airtime PINs with serial numbers, ready to print'
            : (_isDataCard
                  ? 'Generate printable high-speed data vouchers with serial numbers'
                  : (_isAirtimeToCash
                        ? 'Convert excess airtime directly into wallet balance or bank account cash'
                        : 'High-speed SMS routing across all Nigerian telecom networks')));

  String get _route => _isExam
      ? '/services/exam-pins'
      : (_isAirtimePins
            ? '/services/airtime-pins'
            : (_isDataCard
                  ? '/services/data-card'
                  : (_isAirtimeToCash ? '/services/airtime-to-cash' : '/services/bulk-sms')));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPricingSilently();
    });
  }

  @override
  void dispose() {
    _airtimeToCashAmountCtrl.dispose();
    _airtimeToCashSenderPhoneCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _quantityController.dispose();
    _recipientController.dispose();
    _messageController.dispose();
    _senderController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPricingSilently() async {
    if (_isAirtimePins) {
      await _loadRechargeCardPlans();
      return;
    }
    try {
      final vtu = context.read<VtuProvider>();
      if (_isExam) {
        final prices = await vtu.fetchExamPinPrices();
        if (!mounted || prices.isEmpty) return;
        setState(() {
          final valid = prices.where((p) {
            final amt = p['amount'];
            return (p['code'] ?? p['exam_type']) != null &&
                amt is num &&
                amt > 0;
          }).toList();
          const examOrder = ['WAEC', 'NECO', 'NABTEB', 'JAMB'];
          valid.sort((a, b) {
            final codeA = (a['code'] ?? a['exam_type'] ?? '')
                .toString()
                .toUpperCase();
            final codeB = (b['code'] ?? b['exam_type'] ?? '')
                .toString()
                .toUpperCase();
            final indexA = examOrder.indexOf(codeA);
            final indexB = examOrder.indexOf(codeB);
            return (indexA < 0 ? examOrder.length : indexA).compareTo(
              indexB < 0 ? examOrder.length : indexB,
            );
          });
          if (valid.isNotEmpty) {
            _examPrices = valid.map((p) {
              final code = (p['code'] ?? p['exam_type'] ?? '').toString();
              return {
                ...p,
                'code': code.toUpperCase(),
                'logo': _examLogoFor(code),
              };
            }).toList();
            final currentCode = (_selectedExam?['code'] ?? '')
                .toString()
                .toUpperCase();
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

  Future<void> _loadRechargeCardPlans() async {
    final requestId = ++_rechargeCardRequestId;
    final networkId = _selectedNetworkId;
    setState(() {
      _isLoadingRechargeCardPlans = true;
      _rechargeCardPlansError = null;
      _rechargeCardPlans = [];
      _selectedRechargeCardPlan = null;
    });
    try {
      final plans = await context.read<VtuProvider>().fetchRechargeCardPlans(
        networkId: networkId,
      );
      final validPlans = plans.where((plan) {
        final planType = plan['plan_type']?.toString().trim() ?? '';
        final amount = plan['amount'];
        return planType.isNotEmpty && amount is num && amount > 0;
      }).toList()
        ..sort(
          (a, b) => (a['amount'] as num).compareTo(b['amount'] as num),
        );
      if (!mounted || requestId != _rechargeCardRequestId) return;
      setState(() {
        _rechargeCardPlans = validPlans;
        final initialPlan = validPlans.firstWhere(
          (p) =>
              p['is_available'] != false &&
              (p['available_stock'] == null ||
                  (p['available_stock'] as num) > 0),
          orElse: () => validPlans.first,
        );
        _selectedRechargeCardPlan = validPlans.isEmpty ? null : initialPlan;
        if (validPlans.isEmpty) {
          _rechargeCardPlansError =
              'No airtime PIN denominations are available for this network.';
        }
      });
    } catch (error) {
      if (!mounted || requestId != _rechargeCardRequestId) return;
      setState(() {
        _rechargeCardPlansError = userFacingError(
          error,
          fallback:
              'Recharge-card denominations could not be loaded. Please try again.',
        );
      });
    } finally {
      if (mounted && requestId == _rechargeCardRequestId) {
        setState(() => _isLoadingRechargeCardPlans = false);
      }
    }
  }

  double get _selectedRechargeCardPrice =>
      (_selectedRechargeCardPlan?['amount'] as num?)?.toDouble() ?? 0;

  String get _selectedRechargeCardName =>
      (_selectedRechargeCardPlan?['name'] ??
              _selectedRechargeCardPlan?['card_name'] ??
              'Airtime PIN')
          .toString();

  Future<String?> _promptAirtimeCashCode({
    required String title,
    required String label,
    required String helper,
    required bool obscureText,
  }) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: obscureText,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: label, helperText: helper),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) Navigator.pop(dialogContext, value);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<String> _startAndVerifyAirtimeCash({
    required int networkId,
    required String phone,
    required String userPin,
  }) async {
    final started = await VtuApiService.instance.startAirtimeCashConversion(
      networkId: networkId,
      phone: phone,
      userPin: userPin,
    );
    if (started['success'] != true) {
      throw StateError(
        started['message']?.toString() ??
            'Could not start the airtime conversion.',
      );
    }
    final initialData = started['data']?.toString() ?? '';
    if (initialData.isEmpty) {
      throw StateError(
        'The provider did not return an OTP verification token.',
      );
    }

    final otp = await _promptAirtimeCashCode(
      title: 'Verify your phone number',
      label: 'One-time password',
      helper: 'Enter the OTP sent by your mobile network.',
      obscureText: false,
    );
    if (otp == null) throw StateError('Airtime conversion cancelled.');
    if (!RegExp(r'^\d{4,8}$').hasMatch(otp)) {
      throw StateError('Enter the valid OTP sent by your network.');
    }

    final verified = await VtuApiService.instance.verifyAirtimeCashOtp(
      networkId: networkId,
      phone: phone,
      otp: otp,
      verificationData: initialData,
      userPin: userPin,
    );
    if (verified['success'] != true) {
      throw StateError(
        verified['message']?.toString() ?? 'The network OTP was not accepted.',
      );
    }
    final verifiedData = verified['data']?.toString() ?? initialData;
    if (verifiedData.isEmpty) {
      throw StateError('The provider did not confirm the OTP session.');
    }
    return verifiedData;
  }

  String _normalizedAirtimeCashPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('234') && digits.length == 13) {
      return '0${digits.substring(3)}';
    }
    return digits;
  }

  List<String> _recipients() {
    final values = _recipientController.text
        .split(RegExp(r'[\s,;]+'))
        .map((value) => value.replaceAll(RegExp(r'\D'), ''))
        .map(
          (value) => value.startsWith('234') && value.length == 13
              ? '0${value.substring(3)}'
              : value,
        )
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
      return quantity > 0
          ? _selectedRechargeCardPrice * quantity
          : null;
    }
    if (_isDataCard) {
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
      return quantity > 0 ? (_selectedDataCardPrice * quantity) : null;
    }
    if (_isAirtimeToCash) {
      final amt = double.tryParse(_airtimeToCashAmountCtrl.text.trim()) ?? 1000.0;
      return amt > 0 ? amt : null;
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
    final airtimeCashPhone = _normalizedAirtimeCashPhone(
      _airtimeToCashSenderPhoneCtrl.text.trim().isNotEmpty
          ? _airtimeToCashSenderPhoneCtrl.text
          : user.phone,
    );
    if (amount == null || !amount.isFinite || amount <= 0) {
      TopNotification.showWarning(
        context,
        'Complete the required fields first.',
      );
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
      if (quantity == null || quantity < 1 || quantity > 10) {
        TopNotification.showWarning(
          context,
          'Choose between 1 and 10 recharge PINs.',
        );
        return;
      }
      final stock = _selectedRechargeCardPlan?['available_stock'];
      if (_selectedRechargeCardPlan?['is_available'] == false ||
          (stock != null && (stock as num) < quantity)) {
        TopNotification.showWarning(
          context,
          'This denomination is currently out of stock from the provider. Please choose another denomination.',
        );
        return;
      }
    } else if (_isDataCard) {
      final quantity = int.tryParse(_quantityController.text.trim());
      if (quantity == null || quantity < 1 || quantity > 100) {
        TopNotification.showWarning(
          context,
          'Choose between 1 and 100 data cards.',
        );
        return;
      }
    } else if (_isAirtimeToCash) {
      final airtimeAmount = double.tryParse(
        _airtimeToCashAmountCtrl.text.trim(),
      );
      if (_selectedNetworkId != 1 && _selectedNetworkId != 2) {
        TopNotification.showWarning(
          context,
          'Airtime to Cash currently supports MTN and Airtel only.',
        );
        return;
      }
      if (airtimeAmount == null ||
          airtimeAmount < 1000 ||
          airtimeAmount > 50000 ||
          airtimeAmount != airtimeAmount.truncateToDouble()) {
        TopNotification.showWarning(
          context,
          'Enter a whole-naira amount between ₦1,000 and ₦50,000.',
        );
        return;
      }
      if (!RegExp(r'^0\d{10}$').hasMatch(airtimeCashPhone)) {
        TopNotification.showWarning(
          context,
          'Enter a valid Nigerian mobile number for the network OTP.',
        );
        return;
      }
    } else {
      final recipients = _recipients();
      if (recipients.isEmpty) {
        TopNotification.showWarning(
          context,
          'Please enter at least one recipient.',
        );
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
      if (!RegExp(
        r'^[A-Za-z0-9 ]{3,11}$',
      ).hasMatch(_senderController.text.trim())) {
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

    if (_activeMode == 1) {
      if (wallet.balance < amount) {
        TopNotification.showError(
          context,
          'Insufficient wallet balance. Available: ₦${wallet.balance.toStringAsFixed(2)}.',
        );
        return;
      }
      final confirmed = await PinModal.show(
        context,
        title: 'Create $_title Gift Voucher',
        amount: amount,
        description: 'Redeemable Avotek wallet credit for $_title',
        onPinSubmit: (pin) async => auth.verifyPin(pin),
      );
      if (!mounted || confirmed != true) return;

      setState(() => _isPurchasing = true);
      try {
        final voucher = await SupabaseService.instance.createGiftVoucher(
          amount: amount,
          note: 'Gift voucher for $_title',
        );
        await auth.refreshWallet();
        await wallet.fetchWallet(user.id);
        if (!mounted) return;
        final code = (voucher['code'] ?? '').toString();
        if (code.isEmpty) {
          throw StateError('Voucher was created without a claim code.');
        }
        final claimUrl =
            'https://adevictorolu.github.io/Avotek/#/coupons?code=${Uri.encodeQueryComponent(code)}';
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('$_title gift voucher created'),
            content: SelectableText('Code: $code\n\nClaim link: $claimUrl'),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: claimUrl));
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted) {
                    TopNotification.showSuccess(
                      context,
                      'Voucher claim link copied.',
                    );
                  }
                },
                child: const Text('Copy claim link'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } catch (error) {
        if (mounted) {
          TopNotification.showError(
            context,
            userFacingError(
              error,
              fallback: 'Could not create the gift voucher. Please try again.',
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isPurchasing = false);
      }
      return;
    }

    if (!_isAirtimeToCash && wallet.balance < amount) {
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
    final airtimeAmt = double.tryParse(_airtimeToCashAmountCtrl.text.trim()) ?? 1000.0;
    final rate = _selectedNetworkId == 1 ? 0.85 : 0.82;
    final payoutVal = airtimeAmt * rate;

    final confirmed = await PinModal.show(
      context,
      title: 'Confirm $_title',
      amount: _isAirtimeToCash ? 0.0 : amount,
      description: _isExam
          ? '${_selectedExam?['name'] ?? 'Exam PIN'} × ${_quantityController.text}'
          : (_isAirtimePins
                ? '${networkObj['code']} $_selectedRechargeCardName × ${_quantityController.text}'
                : (_isDataCard
                      ? '${networkObj['code']} $_selectedDataCardName × ${_quantityController.text}'
                      : (_isAirtimeToCash
                            ? 'Convert ₦${airtimeAmt.toInt()} airtime to ₦${payoutVal.round()} cash'
                            : '${_recipients().length} recipients • ${_senderController.text.trim()}'))),
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
    final confirmedPin = transactionPin!;
    try {
      final result = _isAirtimeToCash
          ? await vtu.convertAirtimeToCash(
              userId: user.id,
              networkId: _selectedNetworkId,
              networkName: networkObj['code'] as String,
              amount: airtimeAmt,
              phone: airtimeCashPhone,
              verificationData: await _startAndVerifyAirtimeCash(
                networkId: _selectedNetworkId,
                phone: airtimeCashPhone,
                userPin: confirmedPin,
              ),
              sharePin:
                  (await _promptAirtimeCashCode(
                    title: 'Enter network transfer PIN',
                    label: 'MTN Share-and-Sell PIN / Airtel Me2U PIN',
                    helper: 'This is sent securely to complete the conversion.',
                    obscureText: true,
                  )) ??
                  (throw StateError('Airtime conversion cancelled.')),
              reference: VtuApiService.generatePurchaseReference(),
              userPin: confirmedPin,
            )
          : (_isExam
              ? await vtu.buyExamPins(
              userId: user.id,
              examCode:
                  (_selectedExam?['code'] ??
                          _selectedExam?['exam_type'] ??
                          'WAEC')
                      .toString(),
              examName:
                  (_selectedExam?['name'] ??
                          _selectedExam?['exam_type'] ??
                          'Exam PIN')
                      .toString(),
              quantity: int.parse(_quantityController.text.trim()),
              unitPrice: (_selectedExam?['amount'] as num).toDouble(),
              phone: user.phone.isNotEmpty ? user.phone : '08000000000',
              userPin: confirmedPin,
            )
          : (_isAirtimePins
                ? await vtu.buyAirtimePins(
                    userId: user.id,
                    networkId: _selectedNetworkId,
                    networkName: networkObj['code'] as String,
                      planType: _selectedRechargeCardPlan!['plan_type'].toString(),
                      cardName: _businessNameController.text.trim().isNotEmpty
                          ? _businessNameController.text.trim()
                          : 'Avotek',
                      unitPrice: _selectedRechargeCardPrice,
                      quantity: int.parse(_quantityController.text.trim()),
                      userPin: confirmedPin,
                    )
                : (_isDataCard
                      ? await vtu.buyDataCardPins(
                          userId: user.id,
                          networkId: _selectedNetworkId,
                          networkName: networkObj['code'] as String,
                          planType:
                              _dataCardPlans[_selectedDataCardIndex]['code']
                                  as String,
                          planName: _selectedDataCardName,
                          price: _selectedDataCardPrice,
                          quantity: int.parse(_quantityController.text.trim()),
                          cardName: _businessNameController.text.trim().isNotEmpty
                              ? _businessNameController.text.trim()
                              : 'Avotek Data',
                          userPin: confirmedPin,
                        )
                      : await vtu.sendBulkSms(
                                userId: user.id,
                                recipients: _recipients(),
                                message: _messageController.text.trim(),
                                senderName: _senderController.text.trim(),
                                userPin: confirmedPin,
                              ))));

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
              : (_isAirtimePins
                    ? 'Airtime PINs Ready!'
                    : (_isDataCard
                          ? 'Data Card PIN(s) Ready!'
                          : (_isAirtimeToCash
                                ? 'Airtime to Cash Request Approved!'
                                : 'Bulk SMS Sent!'))),
          serviceType: _isExam
              ? '${_selectedExam?['name'] ?? 'Result Checker'} × ${_quantityController.text}'
              : (_isAirtimePins
                    ? '${networkObj['code']} $_selectedRechargeCardName × ${_quantityController.text}'
                    : (_isDataCard
                          ? '${networkObj['code']} $_selectedDataCardName × ${_quantityController.text}'
                          : (_isAirtimeToCash
                                ? '${networkObj['code']} ₦${_airtimeToCashAmountCtrl.text} to Cash'
                                : 'Bulk SMS (${_recipients().length} recipients)'))),
          recipient: _isExam
              ? (user.name.isNotEmpty ? user.name : (user.phone.isNotEmpty ? user.phone : 'Instant Screen Delivery'))
              : (_isAirtimePins
                    ? '${_businessNameController.text.trim()} / Self'
                    : (_isDataCard
                          ? '${_businessNameController.text.trim()} / Self'
                          : (_isAirtimeToCash
                                ? (_payoutDestination == 'bank' ? '${_bankNameCtrl.text} (${_accountNumberCtrl.text})' : 'Avotek Wallet Credit')
                                : _recipients().join(', ')))),
          amount: _isAirtimeToCash ? result.order.amount : amount,
          reference: result.order.id,
          token: result.token,
          issuedPins: result.issuedPins,
          message: _isExam
              ? 'Your examination PIN(s) have been generated successfully.'
              : (_isAirtimePins
                    ? 'Your recharge cards are generated and ready to print or load.'
                    : (_isDataCard
                          ? 'Your data recharge PINs are generated and ready to print or load.'
                          : (_isAirtimeToCash
                                ? 'Your airtime conversion was completed and credited to your Avotek wallet.'
                                : 'Bulk SMS submitted successfully.'))),
        );
        if (!_isExam &&
            !_isAirtimePins &&
            !_isDataCard &&
            !_isAirtimeToCash) {
          _messageController.clear();
          _recipientController.clear();
        }
      }
    } catch (error) {
      if (mounted) {
        TopNotification.showError(
          context,
          userFacingError(
            error,
            fallback:
                '$_title purchase could not be completed. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _openPayForMeDialog() {
    final qty = int.tryParse(_quantityController.text.trim()) ?? 1;
    final unitPrice =
        (_selectedExam?['amount'] as num?)?.toDouble() ?? 5250.0;
    final total = unitPrice * qty;
    final examName = (_selectedExam?['name'] ??
            _selectedExam?['exam_type'] ??
            'WAEC Result Checker')
        .toString();
    final examCode = (_selectedExam?['code'] ??
            _selectedExam?['exam_type'] ??
            'waec')
        .toString()
        .toLowerCase();

    final user = context.read<AuthProvider>().user;
    final recipient = (user?.name.isNotEmpty == true)
        ? user!.name
        : ((user?.phone.isNotEmpty == true) ? user!.phone : 'Self');

    PayForMeDialog.show(
      context,
      serviceName: '$examName ($qty PIN${qty > 1 ? 's' : ''})',
      recipient: recipient,
      amount: total,
      examCode: examCode,
      quantity: qty,
      note: 'Exam PIN sponsor payment',
    );
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
        backgroundColor: isDark
            ? const Color(0xFF0F1117)
            : const Color(0xFFF8FAFC),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2230)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: GoogleFonts.figtree(
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
                    style: GoogleFonts.figtree(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: GoogleFonts.figtree(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!_isAirtimeToCash) ...[
                  // Mode Switcher Bar: [ Buy Now / Send Now ] | [ Gift Voucher ] in Avotek Blue/Cyan
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF161922)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF262A38)
                            : const Color(0xFFCBD5E1),
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
                                        colors: [
                                          Color(0xFF0047FF),
                                          Color(0xFF0038B8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _activeMode == 0
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF0038B8,
                                          ).withOpacity(0.35),
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
                                        : (isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isExam || _isAirtimePins
                                        ? 'Buy Now'
                                        : 'Send Now',
                                    style: GoogleFonts.figtree(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _activeMode == 0
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white60
                                                : const Color(0xFF64748B)),
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
                                        colors: [
                                          Color(0xFF0047FF),
                                          Color(0xFF0038B8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _activeMode == 1
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF0038B8,
                                          ).withOpacity(0.35),
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
                                        : (isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Gift Voucher',
                                    style: GoogleFonts.figtree(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _activeMode == 1
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white60
                                                : const Color(0xFF64748B)),
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
                  ],

                  if (_activeMode == 1) ...[
                    const SizedBox(height: 10),
                    Text(
                      'This creates a shareable gift link. The recipient redeems it themselves.',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        color: const Color(0xFF0052FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Service Specific UI
                  if (_isAirtimePins || _isDataCard || _isAirtimeToCash) ...[
                    // Step 1: Select Telecom Network
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141721) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SELECT TELECOM NETWORK',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: (_isAirtimeToCash
                                    ? _airtimePinNetworks.where(
                                        (network) =>
                                            network['id'] == 1 ||
                                            network['id'] == 2,
                                      )
                                    : _airtimePinNetworks)
                                .map((net) {
                              final isSelected =
                                  _selectedNetworkId == net['id'];
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      final networkId = net['id'] as int;
                                      if (_selectedNetworkId == networkId) {
                                        return;
                                      }
                                      setState(
                                        () => _selectedNetworkId = networkId,
                                      );
                                      if (_isAirtimePins) {
                                        _loadRechargeCardPlans();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 82,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1C202C)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0052FF)
                                              : (isDark
                                                    ? const Color(0xFF2C3142)
                                                    : const Color(0xFFCBD5E1)),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF0052FF,
                                                  ).withOpacity(0.25),
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  net['logo'] as String,
                                                  height: 32,
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (ctx, err, stack) => Icon(
                                                        Icons.phone_android,
                                                        size: 26,
                                                        color: isSelected
                                                            ? const Color(
                                                                0xFF0038B8,
                                                              )
                                                            : Colors.grey,
                                                      ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  net['code'] as String,
                                                  style: GoogleFonts.figtree(
                                                    fontSize: 12,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A,
                                                          ),
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
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
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

                    if (_isAirtimePins) ...[
                    // Step 2: Select Card Denomination
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141721) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHOOSE RECHARGE CARD DENOMINATION',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_isLoadingRechargeCardPlans)
                            const Center(child: CircularProgressIndicator())
                          else if (_rechargeCardPlansError != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _rechargeCardPlansError!,
                                  style: GoogleFonts.figtree(
                                    color: const Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _loadRechargeCardPlans,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try again'),
                                ),
                              ],
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _rechargeCardPlans.map((plan) {
                                final isSelected =
                                    _selectedRechargeCardPlan?['plan_type'] ==
                                    plan['plan_type'];
                                final amount = (plan['amount'] as num).toDouble();
                                final name = (plan['name'] ??
                                        plan['card_name'] ??
                                        'Airtime PIN')
                                    .toString();
                                return InkWell(
                                  onTap: () => setState(
                                    () => _selectedRechargeCardPlan = plan,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 132,
                                    constraints: const BoxConstraints(
                                      minHeight: 68,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF0038B8)
                                          : (isDark
                                                ? const Color(0xFF1C202C)
                                                : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0038B8)
                                            : (isDark
                                                  ? const Color(0xFF2C3142)
                                                  : const Color(0xFFCBD5E1)),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.figtree(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF475569)),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '₦${amount.toStringAsFixed(0)}',
                                          style: GoogleFonts.figtree(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A)),
                                          ),
                                        ),
                                          if (plan['available_stock'] != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              (plan['available_stock'] as num) <= 0
                                                  ? 'Out of stock'
                                                  : '${plan['available_stock']} left',
                                              style: GoogleFonts.figtree(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: (plan['available_stock'] as num) <= 0
                                                    ? Colors.redAccent
                                                    : (isSelected
                                                        ? Colors.white70
                                                        : const Color(0xFF16A34A)),
                                              ),
                                            ),
                                          ],
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
                    ],

                    if (_isDataCard) ...[
                    // Step 2: Select Data Card Plan
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141721) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHOOSE DATA CARD BUNDLE',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: _dataCardPlans.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final plan = entry.value;
                              final isSelected = _selectedDataCardIndex == idx;
                              final price = (plan['price'] as num).toDouble();
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedDataCardIndex = idx),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF0038B8)
                                            : (isDark ? const Color(0xFF1C202C) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0038B8)
                                              : (isDark ? const Color(0xFF2C3142) : const Color(0xFFCBD5E1)),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            plan['code'] as String,
                                            style: GoogleFonts.figtree(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '₦${price.toStringAsFixed(0)}',
                                            style: GoogleFonts.figtree(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFF0038B8),
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
                    ],

                    if (_isAirtimePins || _isDataCard) ...[
                    // Step 3: Quantity Stepper & Chips
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141721) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
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
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      final current =
                                          int.tryParse(
                                            _quantityController.text.trim(),
                                          ) ??
                                          1;
                                      if (current > 1) {
                                        setState(
                                          () => _quantityController.text =
                                              (current - 1).toString(),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                    ),
                                    color: const Color(0xFF0038B8),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E2230)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF2C3142)
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Text(
                                      _quantityController.text,
                                      style: GoogleFonts.figtree(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: foreground,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final current =
                                          int.tryParse(
                                            _quantityController.text.trim(),
                                          ) ??
                                          1;
                                      if (current < 50) {
                                        setState(
                                          () => _quantityController.text =
                                              (current + 1).toString(),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline_rounded,
                                    ),
                                    color: const Color(0xFF0038B8),
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
                              final isCur =
                                  _quantityController.text == qty.toString();
                              return InkWell(
                                onTap: () => setState(
                                  () =>
                                      _quantityController.text = qty.toString(),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCur
                                        ? const Color(
                                            0xFF0038B8,
                                          ).withOpacity(0.18)
                                        : (isDark
                                              ? const Color(0xFF1C202C)
                                              : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCur
                                          ? const Color(0xFF0038B8)
                                          : (isDark
                                                ? const Color(0xFF2C3142)
                                                : const Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  child: Text(
                                    '$qty card${qty > 1 ? "s" : ""}',
                                    style: GoogleFonts.figtree(
                                      fontSize: 12,
                                      fontWeight: isCur
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isCur
                                          ? const Color(0xFF0038B8)
                                          : (isDark
                                                ? Colors.white70
                                                : const Color(0xFF475569)),
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
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isDataCard ? 'NAME ON DATA CARD (OPTIONAL)' : 'NAME ON RECHARGE CARD (OPTIONAL)',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _businessNameController,
                            style: GoogleFonts.figtree(color: foreground),
                            decoration: InputDecoration(
                              hintText:
                                  _isDataCard ? 'e.g. Avotek Data or My Business Name' : 'e.g. Avotek Telecom or My Business Name',
                              hintStyle: GoogleFonts.figtree(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              prefixIcon: const Icon(
                                Icons.business_rounded,
                                color: Color(0xFF0038B8),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1C202C)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF2C3142)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF2C3142)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ],

                    if (_isAirtimeToCash) ...[
                    // Step 2 & 3: Airtime to Cash Converter Box
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
                            'AIRTIME AMOUNT TO CONVERT (₦)',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _airtimeToCashAmountCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w800),
                            decoration: InputDecoration(
                              hintText: 'Enter amount (e.g. 2000)',
                              prefixIcon: const Icon(Icons.currency_exchange_rounded, color: Color(0xFF0038B8)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1C202C) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [1000, 2000, 5000, 10000, 20000].map((quickAmt) {
                              return ActionChip(
                                label: Text('₦$quickAmt'),
                                onPressed: () => setState(() => _airtimeToCashAmountCtrl.text = quickAmt.toString()),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'SENDER PHONE NUMBER',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _airtimeToCashSenderPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.figtree(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'e.g. 08012345678',
                              prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF0038B8)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1C202C) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Live Conversion Calculation Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF0038B8).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Conversion Payout Rate:', style: GoogleFonts.figtree(fontWeight: FontWeight.w600)),
                                    Text(
                                      _selectedNetworkId == 1 ? '85% (MTN)' : '82% (Airtel)',
                                      style: GoogleFonts.figtree(fontWeight: FontWeight.w800, color: const Color(0xFF0038B8)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('You Will Receive (Cash/Wallet):', style: GoogleFonts.figtree(fontWeight: FontWeight.w700)),
                                    Text(
                                      '₦${((double.tryParse(_airtimeToCashAmountCtrl.text.trim()) ?? 1000.0) * (_selectedNetworkId == 1 ? 0.85 : 0.82)).round()}',
                                      style: GoogleFonts.figtree(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.success),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.security_rounded, size: 16, color: Color(0xFF0038B8)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'We will send an OTP to your $_airtimeToCashReceiverPhone line, then ask you to verify it and enter your network transfer PIN.',
                                        style: GoogleFonts.figtree(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ],
                  ] else if (_isExam) ...[
                    // Exam Type Selector Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141721) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXAM TYPE',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: _examPrices.map((exam) {
                              final code =
                                  (exam['code'] ?? exam['exam_type'] ?? '')
                                      .toString()
                                      .toUpperCase();
                              final isSelected =
                                  (_selectedExam?['code'] ??
                                          _selectedExam?['exam_type'] ??
                                          '')
                                      .toString()
                                      .toUpperCase() ==
                                  code;
                              final amount =
                                  (exam['amount'] as num?)?.toDouble() ?? 0.0;
                              final logoPath = _examLogoFor(code);

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _selectedExam = exam),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 90,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1C202C)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0052FF)
                                              : (isDark
                                                    ? const Color(0xFF2C3142)
                                                    : const Color(0xFFCBD5E1)),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF0052FF,
                                                  ).withOpacity(0.25),
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  logoPath,
                                                  height: 30,
                                                  cacheHeight: 90,
                                                  fit: BoxFit.contain,
                                                  gaplessPlayback: true,
                                                  errorBuilder:
                                                      (ctx, err, stack) => Icon(
                                                        Icons.school,
                                                        size: 26,
                                                        color: isSelected
                                                            ? const Color(
                                                                0xFF0038B8,
                                                              )
                                                            : Colors.grey,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  code,
                                                  style: GoogleFonts.figtree(
                                                    fontSize: 11.5,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A,
                                                          ),
                                                  ),
                                                ),
                                                Text(
                                                  '₦${amount.toStringAsFixed(0)}',
                                                  style: GoogleFonts.figtree(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF0038B8,
                                                    ),
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
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
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
                          if (_selectedExam != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: (_selectedExam?['code'] == 'JAMB')
                                    ? (isDark
                                          ? const Color(0xFF172554)
                                          : const Color(0xFFEFF6FF))
                                    : (isDark
                                          ? const Color(0xFF1E2638)
                                          : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF0038B8).withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: Color(0xFF0038B8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (_selectedExam?['code'] == 'JAMB')
                                          ? 'JAMB Service: Official UTME & Direct Entry (DE) Registration & Profile e-PIN'
                                          : '${_selectedExam?['name']}: ${_selectedExam?['subtitle'] ?? 'Official Exam Verification Token'}',
                                      style: GoogleFonts.figtree(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUANTITY',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [1, 2, 5].map((q) {
                              final isSel =
                                  _quantityController.text == q.toString();
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: InkWell(
                                    onTap: () => setState(
                                      () => _quantityController.text = q
                                          .toString(),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(
                                                0xFF0052FF,
                                              ).withOpacity(0.18)
                                            : (isDark
                                                  ? const Color(0xFF1C202C)
                                                  : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSel
                                              ? const Color(0xFF0052FF)
                                              : (isDark
                                                    ? const Color(0xFF2C3142)
                                                    : const Color(0xFFCBD5E1)),
                                          width: isSel ? 2 : 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$q pin${q > 1 ? 's' : ''}',
                                          style: GoogleFonts.figtree(
                                            fontSize: 14,
                                            fontWeight: isSel
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSel ? const Color(0xFF0052FF)
                                                : (isDark
                                                      ? Colors.white
                                                      : Colors.black87),
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
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'SUPPORTED NETWORKS (100% ROUTING)',
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                    style: GoogleFonts.figtree(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: _airtimePinNetworks.map((net) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1C202C)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF2C3142)
                                          : const Color(0xFFCBD5E1),
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
                                        style: GoogleFonts.figtree(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF334155),
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
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
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
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                '${_senderController.text.length}/11 chars',
                                style: GoogleFonts.figtree(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _senderController,
                            maxLength: 11,
                            style: GoogleFonts.figtree(color: foreground),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'e.g. MyStore, Notice, Avotek',
                              hintStyle: GoogleFonts.figtree(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_rounded,
                                color: Color(0xFF0038B8),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1C202C)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF2C3142)
                                      : const Color(0xFFCBD5E1),
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
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
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
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0052FF,
                                  ).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_recipients().length} valid recipient(s)',
                                  style: GoogleFonts.figtree(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0052FF),
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
                            style: GoogleFonts.figtree(color: foreground),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText:
                                  'Enter Nigerian phone numbers separated by comma or new line\ne.g. 08012345678, 09087654321',
                              hintStyle: GoogleFonts.figtree(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1C202C)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF2C3142)
                                      : const Color(0xFFCBD5E1),
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
                          color: isDark
                              ? const Color(0xFF222634)
                              : const Color(0xFFE2E8F0),
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
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                '${_messageController.text.length} chars • ${VtuApiService.estimateSmsPages(_messageController.text)} page(s)',
                                style: GoogleFonts.figtree(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0052FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _messageController,
                            minLines: 3,
                            maxLines: 6,
                            style: GoogleFonts.figtree(color: foreground),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText:
                                  'Type your broadcast SMS message here...',
                              hintStyle: GoogleFonts.figtree(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1C202C)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF2C3142)
                                      : const Color(0xFFCBD5E1),
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
                                onChanged: (val) => setState(
                                  () => _consentConfirmed = val ?? false,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'I confirm that recipients consented to receive this broadcast message.',
                                  style: GoogleFonts.figtree(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF475569),
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

                  if (_isExam)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF0038B8).withOpacity(0.28),
                                  const Color(0xFF0052FF).withOpacity(0.12),
                                ]
                              : [
                                  const Color(0xFFEBF4FF),
                                  const Color(0xFFF0F9FF),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF0052FF).withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0052FF).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.volunteer_activism_rounded,
                                  color: Color(0xFF0052FF),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Need a Sponsor to Pay For You?',
                                      style: GoogleFonts.figtree(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: foreground,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Share a secure Pay For Me link on WhatsApp or SMS with a parent, guardian, or friend to pay for this PIN.',
                                      style: GoogleFonts.figtree(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _openPayForMeDialog,
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: Text(
                                'Generate Pay For Me Link',
                                style: GoogleFonts.figtree(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0052FF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                        color: isDark
                            ? const Color(0xFF222634)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Wallet Balance',
                              style: GoogleFonts.figtree(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '₦${wallet.balance.toStringAsFixed(2)}',
                              style: GoogleFonts.figtree(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: foreground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.figtree(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: foreground,
                              ),
                            ),
                            Text(
                              price != null
                                  ? '₦${price.toStringAsFixed(2)}'
                                  : '--',
                              style: GoogleFonts.figtree(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0052FF),
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
                        colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0038B8).withOpacity(0.35),
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
                              _isExam
                                  ? 'Pay for Exam PIN (${_quantityController.text})'
                                  : (_isAirtimePins
                                        ? 'Generate Airtime PINs (${_quantityController.text})'
                                        : (_isDataCard
                                              ? 'Generate Data Cards (${_quantityController.text})'
                                              : (_isAirtimeToCash
                                                    ? 'Convert Airtime'
                                                    : 'Send Bulk SMS'))),
                              style: GoogleFonts.figtree(
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
