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

enum ExtraProviderService { examPins, bulkSms }

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
  final _quantityController = TextEditingController(text: '1');
  final _recipientController = TextEditingController();
  final _messageController = TextEditingController();
  final _senderController = TextEditingController();
  List<Map<String, dynamic>> _examPrices = [];
  Map<String, dynamic>? _selectedExam;
  double? _smsCostPerPage;
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _consentConfirmed = false;
  String? _loadError;

  bool get _isExam => widget.service == ExtraProviderService.examPins;
  String get _title => _isExam ? 'Result Checker PINs' : 'Bulk SMS';
  String get _route => _isExam ? '/services/exam-pins' : '/services/bulk-sms';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPricing());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _recipientController.dispose();
    _messageController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    try {
      final vtu = context.read<VtuProvider>();
      if (_isExam) {
        final prices = await vtu.fetchExamPinPrices();
        if (!mounted) return;
        setState(() {
          _examPrices = prices.where((price) {
            return (price['code'] ?? price['exam_type']) != null &&
                (price['amount'] as num?)?.toDouble().isFinite == true &&
                (price['amount'] as num).toDouble() > 0;
          }).toList();
          _selectedExam = _examPrices.isEmpty ? null : _examPrices.first;
          _loadError = _examPrices.isEmpty
              ? 'No examination PINs are available right now.'
              : null;
        });
      } else {
        final response = await vtu.fetchSmsPricing();
        final data = response['data'];
        final cost = data is Map<String, dynamic>
            ? (data['cost_per_page'] as num?)?.toDouble()
            : null;
        if (cost == null || !cost.isFinite || cost <= 0) {
          throw StateError('The provider returned invalid SMS pricing.');
        }
        if (!mounted) return;
        setState(() {
          _smsCostPerPage = cost;
          _loadError = null;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load live pricing. Please retry.');
      TopNotification.showError(context, 'Could not load $_title pricing: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      final quantity = int.tryParse(_quantityController.text.trim());
      return unit != null && quantity != null && quantity > 0
          ? unit * quantity
          : null;
    }
    final cost = _smsCostPerPage;
    final message = _messageController.text.trim();
    final recipients = _recipients();
    if (cost == null || message.isEmpty || recipients.isEmpty) return null;
    final pages = VtuApiService.estimateSmsPages(message);
    return cost * pages * recipients.length;
  }

  Future<void> _purchase() async {
    if (_isPurchasing || _isLoading || _loadError != null) return;
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

    String? transactionPin;
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm $_title',
      amount: amount,
      description: _isExam
          ? '${_selectedExam?['name'] ?? 'Exam PIN'} × ${_quantityController.text}'
          : '${_recipients().length} recipients • ${_senderController.text.trim()}',
      onPinSubmit: (pin) async {
        transactionPin = pin;
        return auth.verifyPin(pin);
      },
    );
    if (confirmed != true || !mounted || transactionPin == null) return;

    setState(() => _isPurchasing = true);
    try {
      final result = _isExam
          ? await vtu.buyExamPins(
              userId: user.id,
              examCode: (_selectedExam?['code'] ??
                      _selectedExam?['exam_type'] ??
                      '')
                  .toString(),
              examName: (_selectedExam?['name'] ??
                      _selectedExam?['exam_type'] ??
                      'Exam PIN')
                  .toString(),
              quantity: int.parse(_quantityController.text.trim()),
              unitPrice: (_selectedExam?['amount'] as num).toDouble(),
              userPin: transactionPin,
            )
          : await vtu.sendBulkSms(
              userId: user.id,
              recipients: _recipients(),
              message: _messageController.text.trim(),
              senderName: _senderController.text.trim(),
              userPin: transactionPin!,
            );

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
      } else if (_isExam && result.issuedPins.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Your examination PINs'),
            content: SelectableText(result.issuedPins.join('\n')),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: result.issuedPins.join('\n')),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Copy PINs'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        TopNotification.showSuccess(context, result.message, title: 'Sent');
      }
    } catch (error) {
      if (mounted) {
        TopNotification.showError(context, '$_title purchase failed: $error');
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : const Color(0xFF172033);
    final price = _price();
    return ResponsiveShell(
      currentRoute: _route,
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A0D14) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(_title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: EdgeInsets.all(
                ResponsiveLayout.isDesktop(context) ? 28 : 18,
              ),
              children: [
                Text(
                  _isExam
                      ? 'Choose a result-checker PIN and quantity.'
                      : 'Send messages only to recipients who have agreed to receive them.',
                  style: GoogleFonts.plusJakartaSans(
                    color: foreground.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_loadError != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline, color: Colors.red),
                      title: Text(_loadError!),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _loadError = null;
                          });
                          _loadPricing();
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  )
                else ...[
                  if (_isExam) ...[
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedExam,
                      decoration: const InputDecoration(
                        labelText: 'Examination',
                        border: OutlineInputBorder(),
                      ),
                      items: _examPrices
                          .map(
                            (exam) => DropdownMenuItem(
                              value: exam,
                              child: Text(
                                '${exam['name'] ?? exam['exam_type']} • ₦${exam['amount']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedExam = value),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Quantity (1–10)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _recipientController,
                      minLines: 3,
                      maxLines: 6,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Recipients',
                        hintText: 'One Nigerian phone number per line',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _senderController,
                      maxLength: 11,
                      decoration: const InputDecoration(
                        labelText: 'Sender name',
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
                        labelText: 'Message',
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
                  const SizedBox(height: 20),
                  if (price != null)
                    Text(
                      'Estimated total: ₦${price.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _isPurchasing ? null : _purchase,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isPurchasing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isExam ? 'Purchase PINs' : 'Send SMS'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
