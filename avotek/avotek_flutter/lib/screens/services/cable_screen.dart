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

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      if (result.isValid) {
        _verifiedCustomerName = result.customerName;
      }
    });

    if (!result.isValid) {
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
    Map<String, dynamic>? selectedPackage;
    for (final package in currentPackages) {
      if (package['code'] == _selectedPackage) {
        selectedPackage = package;
        break;
      }
    }
    final canPurchase =
        !vtu.isLoading &&
        !_isLoadingPackages &&
        selectedPackage != null &&
        _verifiedCustomerName != null;

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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.primaryCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.live_tv_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cable TV',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verify your decoder, choose a plan, and pay from your wallet.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your TV provider',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: ['DSTV', 'GOTV', 'STARTIMES'].map((p) {
                          final isSelected = p == _selectedProvider;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
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
                      const SizedBox(height: 18),
                      TextField(
                        controller: _smartcardController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) =>
                            setState(() => _verifiedCustomerName = null),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Smartcard / IUC number',
                          hintText: 'Enter the decoder number',
                          prefixIcon: const Icon(Icons.credit_card_rounded),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 20,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: TextButton(
                              onPressed: _isVerifying ? null : _handleVerify,
                              child: _isVerifying
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Verify'),
                            ),
                          ),
                        ),
                      ),
                      if (_verifiedCustomerName != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Subscriber: $_verifiedCustomerName',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
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
                            'Subscription plan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                          if (_isLoadingPackages)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue:
                            currentPackages.any(
                              (package) => package['code'] == _selectedPackage,
                            )
                            ? _selectedPackage
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: _isLoadingPackages
                              ? 'Loading live plans...'
                              : 'Select a subscription plan',
                          prefixIcon: const Icon(Icons.subscriptions_rounded),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                        ),
                        items: currentPackages.map((package) {
                          final code = package['code'] as String;
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text(
                              '${package['name']}  •  ₦${(package['price'] as double).toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: currentPackages.isEmpty
                            ? null
                            : (code) {
                                if (code == null) return;
                                final plan = currentPackages.firstWhere(
                                  (package) => package['code'] == code,
                                );
                                setState(() {
                                  _selectedPackage = code;
                                  _packageAmount = (plan['price'] as num)
                                      .toDouble();
                                });
                              },
                      ),
                      if (_packageLoadError != null && !_isLoadingPackages) ...[
                        const SizedBox(height: 10),
                        Text(
                          _packageLoadError!,
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark ? AppColors.warning : AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (selectedPackage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [
                                      Color(0xFF102A50),
                                      Color(0xFF123846),
                                    ]
                                  : const [
                                      Color(0xFFEAF3FF),
                                      Color(0xFFE7F9FA),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedPackage['name'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                '₦${_packageAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? AppColors.primaryCyan
                                      : AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: canPurchase
                                  ? const [
                                      AppColors.primaryBlue,
                                      AppColors.primaryCyan,
                                    ]
                                  : const [
                                      Color(0xFF64748B),
                                      Color(0xFF475569),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: canPurchase ? _handlePurchase : null,
                              child: Center(
                                child: vtu.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        selectedPackage == null
                                            ? 'Verify and select a plan'
                                            : 'Pay ₦${_packageAmount.toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
