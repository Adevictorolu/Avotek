import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/top_notification.dart';

class CableScreen extends StatefulWidget {
  const CableScreen({super.key});

  @override
  State<CableScreen> createState() => _CableScreenState();
}

class _CableScreenState extends State<CableScreen> {
  final _smartcardController = TextEditingController();
  String _selectedProvider = 'DSTV';
  String? _selectedPackage;
  double _packageAmount = 0;

  bool _isVerifying = false;
  String? _verifiedCustomerName;

  List<Map<String, dynamic>> _livePackages = [];
  bool _isLoadingPackages = false;
  String? _packageLoadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLivePackages());
  }

  Future<void> _loadLivePackages() async {
    final provider = _selectedProvider;
    setState(() {
      _isLoadingPackages = true;
      _packageLoadError = null;
      _livePackages = [];
      _selectedPackage = null;
      _packageAmount = 0;
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
          .where((package) {
            return (package['code'] as String).isNotEmpty &&
                (package['price'] as double) > 0;
          })
          .toList();

      setState(() {
        _livePackages = formatted;
        _isLoadingPackages = false;
        if (formatted.isEmpty) {
          _packageLoadError =
              'No packages are currently available. Try again later.';
        } else {
          _selectedPackage = formatted.first['code'] as String;
          _packageAmount = formatted.first['price'] as double;
        }
      });
    } catch (error) {
      if (!mounted || provider != _selectedProvider) return;
      setState(() {
        _isLoadingPackages = false;
        _packageLoadError =
            'Could not load live packages. Check your connection and retry.';
      });
      TopNotification.showError(
        context,
        'Could not load cable packages: $error',
      );
    }
  }

  List<Map<String, dynamic>> _getCurrentPackages() => _livePackages;

  @override
  void dispose() {
    _smartcardController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final card = _smartcardController.text.trim();
    if (card.length < 8) {
      TopNotification.showWarning(
        context,
        'Please enter a valid smartcard/IUC number',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _verifiedCustomerName = null;
    });
    final vtu = context.read<VtuProvider>();
    final result = await vtu.verifySmartcard(
      provider: _selectedProvider,
      smartcardNumber: card,
    );

    setState(() {
      _isVerifying = false;
      if (result.isValid) {
        _verifiedCustomerName = result.customerName;
      }
    });

    if (!result.isValid && mounted) {
      TopNotification.showError(
        context,
        'Could not verify smartcard number. Please check.',
      );
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackage == null || _livePackages.isEmpty) {
      TopNotification.showWarning(
        context,
        'Live packages are not available. Refresh and try again.',
      );
      return;
    }
    final card = _smartcardController.text.trim();
    if (card.length < 8) {
      TopNotification.showWarning(context, 'Please enter smartcard number');
      return;
    }
    if (_verifiedCustomerName == null) {
      TopNotification.showWarning(
        context,
        'Verify this smartcard before purchasing.',
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final vtu = context.read<VtuProvider>();

    if (wallet.balance < _packageAmount) {
      TopNotification.showError(
        context,
        'Insufficient balance (₦${wallet.balance.toStringAsFixed(2)} available).',
      );
      return;
    }

    String? transactionPin;
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Cable TV Subscription',
      amount: _packageAmount,
      description:
          '$_selectedProvider • $card\nSubscriber: ${_verifiedCustomerName ?? "Customer"}',
      onPinSubmit: (pin) async {
        transactionPin = pin;
        return auth.verifyPin(pin);
      },
    );

    if (confirmed == true && mounted) {
      try {
        final result = await vtu.payCableTV(
          userId: auth.user!.id,
          provider: _selectedProvider,
          smartcardNumber: card,
          variationCode: _selectedPackage!,
          amount: _packageAmount,
          customerName: _verifiedCustomerName,
          phone: auth.user?.phone,
          userPin: transactionPin,
        );

        await auth.refreshWallet();
        await wallet.fetchWallet(auth.user!.id);

        if (!mounted) return;
        if (!result.success || result.order.status == 'failed') {
          TopNotification.showError(
            context,
            result.message,
            title: 'Subscription Failed',
          );
          return;
        }
        if (result.order.status == 'pending') {
          TopNotification.showWarning(
            context,
            result.message,
            title: 'Subscription Pending',
          );
          return;
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text('Subscribed!'),
              ],
            ),
            content: Text(
              '${result.message}\nRef: ${result.order.providerReference ?? result.order.id}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        TopNotification.showError(context, 'Subscription failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vtu = context.watch<VtuProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final currentPackages = _getCurrentPackages();

    return ResponsiveShell(
      currentRoute: '/services/tv',
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0D14)
            : const Color(0xFFF8FAFC),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 24,
              ),
            children: [
              Text(
                'Cable TV Subscription',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Verify your decoder and choose a live subscription package.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: ['DSTV', 'GOTV', 'STARTIMES'].map((p) {
                  final isSelected = p == _selectedProvider;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Center(child: Text(p)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedProvider = p;
                              _verifiedCustomerName = null;
                              _selectedPackage = null;
                              _packageAmount = 0;
                            });
                            _loadLivePackages();
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _smartcardController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _verifiedCustomerName = null),
                decoration: InputDecoration(
                  labelText: 'Smartcard / IUC Number',
                  hintText: 'e.g. 1029384756',
                  prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
                  suffixIcon: TextButton(
                    onPressed: _isVerifying ? null : _handleVerify,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify'),
                  ),
                ),
              ),
              if (_verifiedCustomerName != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Subscriber: $_verifiedCustomerName',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Bouquet / Package',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  if (_isLoadingPackages)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_packageLoadError != null && !_isLoadingPackages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _packageLoadError!,
                    style: TextStyle(
                      color: isDark ? AppColors.warning : AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ...currentPackages.map((pkg) {
                final isSelected = pkg['code'] == _selectedPackage;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPackage = pkg['code'];
                      _packageAmount = pkg['price'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                    ? AppColors.primaryCyan
                                    : AppColors.primaryBlue)
                                .withValues(alpha: 0.1)
                          : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.primaryCyan
                                  : AppColors.primaryBlue)
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pkg['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '₦${pkg['price'].toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.primaryCyan
                                : AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    vtu.isLoading ||
                        _isLoadingPackages ||
                        _selectedPackage == null
                    ? null
                    : _handlePurchase,
                child: vtu.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Pay ₦${_packageAmount.toStringAsFixed(0)}'),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
