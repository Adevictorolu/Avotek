import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vtu_provider.dart';

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();

  String _selectedNetwork = 'MTN';
  String _selectedTopupType = 'VTU';
  double _amount = 0.0;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _networks = [
    {'name': 'MTN', 'code': 'MTN', 'color': const Color(0xFFFFCC00), 'iconColor': Colors.black},
    {'name': 'GLO', 'code': 'GLO', 'color': const Color(0xFF00A859), 'iconColor': Colors.white},
    {'name': 'AIRTEL', 'code': 'AIRTEL', 'color': const Color(0xFFE60000), 'iconColor': Colors.white},
    {'name': 'T2', 'code': 'T2', 'color': const Color(0xFF005B38), 'iconColor': Colors.white},
    {'name': 'VITEL', 'code': 'VITEL', 'color': const Color(0xFF0284C7), 'iconColor': Colors.white},
  ];

  final List<double> _presetAmounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _amountController.addListener(_onAmountInputChanged);
  }

  void _onAmountInputChanged() {
    final text = _amountController.text.replaceAll(',', '').trim();
    final parsed = double.tryParse(text) ?? 0.0;
    if (parsed != _amount) {
      setState(() {
        _amount = parsed;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _selectPresetAmount(double amt) {
    setState(() {
      _amount = amt;
      _amountController.text = NumberFormat('#,##0').format(amt);
    });
  }

  Future<void> _handlePurchase() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (_amount < 50) {
      _showSnackBar('Minimum airtime amount is ₦50.', AppColors.error);
      return;
    }
    if (_amount > 50000) {
      _showSnackBar('Maximum airtime amount is ₦50,000.', AppColors.error);
      return;
    }
    if (phone.length < 10) {
      _showSnackBar('Please enter a valid 11-digit phone number.', AppColors.error);
      return;
    }
    if (pin.length != 4) {
      _showSnackBar('Please enter your 4-digit transaction PIN.', AppColors.error);
      return;
    }

    final auth = context.read<AuthProvider>();
    final vtu = context.read<VtuProvider>();

    // 1. Verify PIN
    final pinValid = await auth.verifyPin(pin);
    if (!pinValid) {
      _showSnackBar('Invalid transaction PIN. Please re-enter your 4-digit PIN.', AppColors.error);
      return;
    }

    // 2. Check Balance
    final currentBalance = auth.wallet?.balance ?? 0.0;
    if (currentBalance < _amount) {
      _showInsufficientBalanceDialog(_amount, currentBalance);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 3. Atomically debit wallet
      final debited = await auth.debitWallet(_amount);
      if (!debited) {
        _showSnackBar('Insufficient wallet balance. Please add money.', AppColors.error);
        setState(() => _isProcessing = false);
        return;
      }

      // 4. Dispatch live aggregator order (BilalSadaSub Gateway API)
      await vtu.buyAirtime(
        userId: auth.user?.id ?? 1001,
        network: _selectedNetwork,
        phone: phone,
        amount: _amount,
      );

      setState(() => _isProcessing = false);
      _showSuccessDialog(phone, _amount);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar('Order processed: ${e.toString().replaceAll("Exception: ", "")}', const Color(0xFF0284C7));
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
            Icon(Icons.account_balance_wallet_outlined, color: AppColors.electricCyan),
            const SizedBox(width: 10),
            Text('Insufficient Balance', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text(
          'Your balance (₦${currentBal.toStringAsFixed(2)}) is less than the required amount of ₦${requiredAmt.toStringAsFixed(2)}. Please add money to continue.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
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

  void _showSuccessDialog(String phone, double amount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF14171E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text('Airtime Delivered!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '₦${NumberFormat('#,##0.00').format(amount)} $_selectedNetwork airtime sent to $phone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Topup Type: $_selectedTopupType',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF00D2FF)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _pinController.clear();
              _amountController.clear();
              setState(() => _amount = 0.0);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String text, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)), backgroundColor: bg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final walletBalance = auth.wallet?.balance ?? 9.0;
    final formattedPrice = NumberFormat('#,##0.00', 'en_US').format(_amount);

    return ResponsiveShell(
      currentRoute: '/services/airtime',
      onToggleTheme: () {},
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
                  // Title
                  Text(
                    'Buy Airtime',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Breadcrumb matching Screenshot 4
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/dashboard'),
                        child: Text(
                          'Dashboard',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.grey, fontSize: 12),
                        ),
                      ),
                      Text(
                        'Airtime',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2-Column Responsive Layout matching Bilal Sub Screenshot 4 & 5
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildLeftForm(isDark)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildRightSummary(walletBalance, formattedPrice, isDark)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildRightSummary(walletBalance, formattedPrice, isDark),
                        const SizedBox(height: 20),
                        _buildLeftForm(isDark),
                      ],
                    ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),

          // Bottom-Right Floating Yellow Chat FAB
          Positioned(
            right: 24,
            bottom: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Avotek 24/7 Live Support', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Left Form: Steps 1 to 4 ---
  Widget _buildLeftForm(bool isDark) {
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
              onTap: () => setState(() => _selectedNetwork = net['code'] as String),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141720) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00D2FF) : (isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF00D2FF).withOpacity(0.2), blurRadius: 8)]
                      : null,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: net['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (net['code'] as String).substring(0, 1),
                        style: TextStyle(color: net['iconColor'] as Color, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
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

        // STEP 2: TOPUP TYPE
        _buildSectionHeader('2 · TOPUP TYPE'),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildTopupTypePill('VTU', isDark),
            const SizedBox(width: 10),
            _buildTopupTypePill('Share and Sell', isDark),
          ],
        ),
        const SizedBox(height: 24),

        // STEP 3: AMOUNT
        _buildSectionHeader('3 · AMOUNT'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141720) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF26334D) : const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              Text(
                '₦',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Minimum ₦50 — maximum ₦50,000',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        // Quick amount chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetAmounts.map((amt) {
            final isSelected = _amount == amt;
            return InkWell(
              onTap: () => _selectPresetAmount(amt),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.electricCyan.withOpacity(0.2)
                      : (isDark ? const Color(0xFF141720) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.electricCyan
                        : (isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  '₦${NumberFormat('#,##0').format(amt)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppColors.electricCyan
                        : (isDark ? const Color(0xFFCBD5E1) : Colors.black87),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // STEP 4: RECIPIENT DETAILS
        _buildSectionHeader('4 · RECIPIENT DETAILS'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141720) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF26334D) : const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Phone number',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF64748B) : Colors.black38,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // PIN Input Field
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141720) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF26334D) : const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pinController,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: 'Transaction PIN',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      color: isDark ? const Color(0xFF64748B) : Colors.black38,
                    ),
                  ),
                ),
              ),
              const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 18),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '4-digit transaction PIN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        // Action CTA Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_amount <= 0 || _isProcessing) ? null : _handlePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amount > 0 ? AppColors.primaryBlue : const Color(0xFF262930),
              foregroundColor: _amount > 0 ? Colors.white : Colors.white54,
              disabledBackgroundColor: const Color(0xFF262930),
              disabledForegroundColor: const Color(0xFF64748B),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _amount <= 0 ? 'Enter An Amount To Continue' : 'Buy Airtime Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopupTypePill(String type, bool isDark) {
    final isSelected = _selectedTopupType == type;
    return InkWell(
      onTap: () => setState(() => _selectedTopupType = type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : (isDark ? const Color(0xFF141720) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.electricCyan
                : (isDark ? const Color(0xFF26334D) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          type,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  // --- Right Summary: Wallet Balance + Order Summary + Reversal Notice ---
  Widget _buildRightSummary(double walletBalance, String formattedPrice, bool isDark) {
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
                label: Text('Add Money', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            border: Border.all(color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
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
              _buildSummaryRow('Type', _selectedTopupType, isDark),
              const SizedBox(height: 10),
              _buildSummaryRow('Phone', _phoneController.text.isNotEmpty ? _phoneController.text : '—', isDark),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF26334D), height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('You pay', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                  Text(
                    _amount > 0 ? '₦$formattedPrice' : '—',
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
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.electricCyan, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Top-ups land on the recipient\'s line instantly. Failed transactions are auto-reversed to your wallet within minutes.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
