import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/nigerian_network_detector.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_loading_indicator.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/service_brand_logo.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/transaction_success_dialog.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  String _selectedNetwork = 'MTN';
  bool _networkManuallySelected = false;
  String _selectedCategory = 'SME';
  Map<String, dynamic>? _selectedPlan;
  bool _isProcessing = false;
  String _processingMessage = 'Processing your request securely…';

  final List<Map<String, dynamic>> _networks = [
    {
      'name': 'MTN',
      'code': 'MTN',
      'color': Color(0xFFFFCC00),
      'iconColor': Colors.black,
    },
    {
      'name': 'GLO',
      'code': 'GLO',
      'color': Color(0xFF00A859),
      'iconColor': Colors.white,
    },
    {
      'name': 'AIRTEL',
      'code': 'AIRTEL',
      'color': Color(0xFFE60000),
      'iconColor': Colors.white,
    },
    {
      'name': '9MOBILE',
      'code': '9MOBILE',
      'color': Color(0xFF005B38),
      'iconColor': Colors.white,
    },
  ];

  final List<String> _categories = ['SME', 'Gifting', 'Corporate'];

  List<Map<String, dynamic>> _livePlans = [];
  bool _isLoadingPlans = false;
  String? _planLoadError;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLivePlans());
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text;
    if (phone.trim().isEmpty) {
      _networkManuallySelected = false;
    } else if (!_networkManuallySelected) {
      final detected = NigerianNetworkDetector.detect(phone);
      if (detected != null && detected != _selectedNetwork) {
        _onNetworkSelected(detected, manuallySelected: false);
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
      if (rawPlans.isNotEmpty && mounted) {
        final formatted = rawPlans
            .map((p) {
              final size = (p['size'] ?? '').toString().trim();
              final vol = (p['plan_volume'] ?? p['volume'] ?? '').toString().trim();
              final type = (p['plantype'] ?? p['plan_type'] ?? p['type'] ?? 'SME').toString().trim();
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
              final label = ('$size$vol').trim().isNotEmpty
                  ? '$size$vol $type ($val)'
                  : (fallbackName.isNotEmpty ? fallbackName : '$type Data Plan');
              return {
                'id': id,
                'plan': label,
                'price': amt,
                'code': 'BIGISUB-$id',
                'plantype': type.toUpperCase(),
              };
            })
            .where((plan) {
              return (plan['id'] as int) > 0 &&
                  (plan['price'] as double) > 0 &&
                  (plan['plan'] as String).trim().isNotEmpty;
            })
            .toList();

        setState(() {
          _livePlans = formatted;
          _isLoadingPlans = false;
          final filtered = _getFilteredPlans();
          if (filtered.isNotEmpty) {
            _selectedPlan = filtered.first;
          } else {
            _planLoadError = 'No live data bundles are currently available.';
          }
        });
        return;
      }
      setState(() {
        _isLoadingPlans = false;
        _planLoadError = 'No live data bundles are currently available.';
      });
    } catch (error) {
      if (!mounted || network != _selectedNetwork) return;
      setState(() {
        _isLoadingPlans = false;
        _planLoadError =
            'Could not load live data bundles. Check your connection and retry.';
      });
      TopNotification.showError(
        context,
        'Could not load live data bundles: $error',
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredPlans() {
    if (_livePlans.isNotEmpty) {
      final filtered = _livePlans.where((p) {
        final type = (p['plantype'] ?? '').toString().toUpperCase();
        return type.contains(_selectedCategory.toUpperCase());
      }).toList();
      if (filtered.isNotEmpty) return filtered;
      return _livePlans;
    }
    return const [];
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onNetworkSelected(
    String netCode, {
    bool manuallySelected = true,
  }) {
    setState(() {
      _selectedNetwork = netCode;
      _networkManuallySelected = manuallySelected;
      _selectedPlan = null;
    });
    _loadLivePlans();
  }

  void _onCategorySelected(String cat) {
    setState(() {
      _selectedCategory = cat;
      final filtered = _getFilteredPlans();
      if (filtered.isNotEmpty) {
        _selectedPlan = filtered.first;
      }
    });
  }

  Future<void> _handlePurchase() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone.length < 10) {
      TopNotification.showError(
        context,
        'Please enter a valid 11-digit phone number.',
        title: 'Invalid Phone',
      );
      return;
    }
    if (_selectedPlan == null) {
      TopNotification.showError(
        context,
        'Please select a data plan bundle.',
        title: 'Bundle Required',
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;
    if (currentUser == null) {
      TopNotification.showError(
        context,
        'Your session has expired. Sign in again to continue.',
        title: 'Sign-in Required',
      );
      return;
    }
    final vtu = context.read<VtuProvider>();
    final amount = (_selectedPlan!['price'] as num).toDouble();

    // Check Balance
    final currentBalance = auth.wallet?.balance ?? 0.0;
    if (currentBalance < amount) {
      _showInsufficientBalanceDialog(amount, currentBalance);
      return;
    }

    String? transactionPin;
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm Data Bundle',
      amount: amount,
      description: '$_selectedNetwork ${_selectedPlan?['name'] ?? 'Data'} • $phone',
      onPinSubmit: (p) async {
        transactionPin = p;
        return auth.verifyPin(p);
      },
    );
    if (!mounted || confirmed != true || transactionPin == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Processing your request securely…';
    });

    try {
      setState(() {
        _processingMessage = 'Confirming your transaction status…';
      });

      // Dispatch the order through the server-side VTU provider.
      final result = await vtu.buyData(
        userId: currentUser.id,
        network: _selectedNetwork,
        phone: phone,
        variationCode: _selectedPlan!['plan'] as String,
        amount: amount,
        sellPrice: amount,
        planId: _selectedPlan!['id'] as int?,
        userPin: transactionPin,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);
      await auth.refreshWallet();
      if (mounted) {
        await context.read<WalletProvider>().fetchWallet(currentUser.id);
      }
      if (!mounted) return;

      if (!result.success || result.order.status == 'failed') {
        TopNotification.showError(
          context,
          result.message,
          title: 'Transaction Failed',
        );
      } else if (result.order.status == 'pending') {
        TopNotification.showWarning(
          context,
          result.message,
          title: 'Transaction Processing',
        );
      } else {
        await TransactionSuccessDialog.show(
          context,
          title: 'Data Bundle Delivered!',
          serviceType: '$_selectedNetwork Data (${_selectedPlan!["plan"]})',
          recipient: phone,
          amount: amount,
          reference: result.order.id,
          providerReference: result.order.providerReference,
          message: '${_selectedPlan!["plan"]} delivered successfully to $phone.',
        );
        _phoneController.clear();
        _pinController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      TopNotification.showError(
        context,
        e.toString().replaceAll("Exception: ", ""),
        title: 'Transaction Notice',
      );
    }
  }

  void _showInsufficientBalanceDialog(double requiredAmt, double currentBal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF14171E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.electricCyan,
            ),
            const SizedBox(width: 10),
            Text(
              'Insufficient Balance',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Your balance (₦${currentBal.toStringAsFixed(2)}) is less than the required bundle cost of ₦${requiredAmt.toStringAsFixed(2)}. Please add money to continue.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/wallet/fund');
            },
            child: const Text('Add Money Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final walletBalance = auth.wallet?.balance ?? 0.0;

    final currentPlanPrice = _selectedPlan != null
        ? (_selectedPlan!['price'] as num).toDouble()
        : 0.0;
    final formattedPrice = NumberFormat(
      '#,##0.00',
      'en_US',
    ).format(currentPlanPrice);

    return ResponsiveShell(
      currentRoute: '/services/data',
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Title & Subtitle
                  Text(
                    'Buy Data',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instant data bundles on every network — delivered in seconds',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2-Column Responsive Layout matching Bilal Sub Screenshot 3
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildLeftForm(isDark)),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: _buildRightSummary(
                            walletBalance,
                            formattedPrice,
                            isDark,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildRightSummary(
                          walletBalance,
                          formattedPrice,
                          isDark,
                        ),
                        const SizedBox(height: 20),
                        _buildLeftForm(isDark),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: AvotekPageLoadingOverlay(message: _processingMessage),
            ),
        ],
      ),
    );
  }

  // --- Left Form: Steps 1 to 4 ---
  Widget _buildLeftForm(bool isDark) {
    final currentPlans = _getFilteredPlans();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // STEP 1: CHOOSE NETWORK
        _buildSectionHeader('1 · CHOOSE NETWORK'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _networks.map((net) {
            final isSelected = _selectedNetwork == net['code'];
            return InkWell(
              onTap: () => _onNetworkSelected(net['code'] as String),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141720) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00D2FF)
                        : (isDark
                              ? const Color(0xFF26334D)
                              : const Color(0xFFE2E8F0)),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00D2FF).withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    ServiceBrandLogo(
                      provider: net['code'] as String,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      net['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // STEP 2: CATEGORY
        _buildSectionHeader('2 · CATEGORY'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(
                cat,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF0052FF),
              backgroundColor: isDark
                  ? const Color(0xFF161922)
                  : const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              onSelected: (val) => _onCategorySelected(cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // STEP 3: PICK A DATA PLAN
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('3 · PICK A DATA PLAN'),
            if (_isLoadingPlans)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00D2FF),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (currentPlans.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141720) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF26334D)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingPlans
                      ? 'Loading live data bundles…'
                      : (_planLoadError ?? 'No live data bundles available.'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppColors.slateGrey,
                  ),
                ),
                if (!_isLoadingPlans) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadLivePlans,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141720) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF26334D)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                value: currentPlans.contains(_selectedPlan)
                    ? _selectedPlan
                    : currentPlans.first,
                dropdownColor: isDark ? const Color(0xFF141720) : Colors.white,
                items: currentPlans.map((plan) {
                  final price = (plan['price'] as num).toDouble();
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: plan,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            plan['plan'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₦${price.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00D2FF),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPlan = val),
              ),
            ),
          ),
        const SizedBox(height: 24),

        // STEP 4: RECIPIENT DETAILS
        _buildSectionHeader('4 · RECIPIENT DETAILS'),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            labelText: 'Phone number',
            hintText: '0803 123 4567',
            filled: true,
            fillColor: isDark ? const Color(0xFF141720) : Colors.white,
            prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (NigerianNetworkDetector.detect(_phoneController.text) != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _networkManuallySelected
                  ? 'Network selected manually. Ported numbers may use a different network.'
                  : 'Suggested network: $_selectedNetwork. Confirm if this number was ported.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141720) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF26334D) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dialpad_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure Keypad PIN Entry',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enter your 4-digit PIN on the encrypted on-screen keypad without browser autofill.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Submit Button
        ElevatedButton(
          onPressed: _isProcessing ? null : _handlePurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(
                  'Enter An Amount To Continue >',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
        ),
      ],
    );
  }

  // --- Right Summary: Golden Balance Card + Order Summary + Notice ---
  Widget _buildRightSummary(
    double walletBalance,
    String formattedPrice,
    bool isDark,
  ) {
    return Column(
      children: [
        // 1. Glowing Brand Wallet Balance Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF0052FF), Color(0xFF00D2FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0052FF).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet balance',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₦${walletBalance.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => context.go('/wallet/fund'),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: Text(
                  'Add Money',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. ORDER SUMMARY Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141720) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ORDER SUMMARY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white70 : Colors.black87,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Network', _selectedNetwork, isDark),
              const SizedBox(height: 10),
              _buildSummaryRow('Category', _selectedCategory, isDark),
              const SizedBox(height: 10),
              _buildSummaryRow('Bundle', _selectedPlan?['plan'] ?? '-', isDark),
              const SizedBox(height: 10),
              _buildSummaryRow(
                'Phone',
                _phoneController.text.isNotEmpty ? _phoneController.text : '-',
                isDark,
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF26334D), height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'You pay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '₦$formattedPrice',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00D2FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Notice Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161922) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.electricCyan,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Top-ups land on the recipient line instantly. Failed transactions are auto-reversed to your wallet within minutes.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFCBD5E1),
        letterSpacing: 0.8,
      ),
    );
  }
}
