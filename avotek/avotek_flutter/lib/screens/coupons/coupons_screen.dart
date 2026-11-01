import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/top_notification.dart';

class CouponsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final String? initialCode;

  const CouponsScreen({
    super.key,
    required this.onToggleTheme,
    this.initialCode,
  });

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  int _selectedTab = 0; // 0 = Redeem Coupon, 1 = History
  final TextEditingController _codeController = TextEditingController();
  bool _isRedeeming = false;

  final List<Map<String, dynamic>> _redemptionHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.trim().isNotEmpty) {
      _codeController.text = widget.initialCode!.trim().toUpperCase();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleRedeem() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      TopNotification.showError(
        context,
        'Please enter a coupon code.',
        title: 'Code Required',
      );
      return;
    }

    setState(() => _isRedeeming = true);
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();

    try {
      final res = await SupabaseService.instance.redeemGiftVoucher(code);
      if (!mounted) return;
      await auth.refreshWallet();
      if (auth.user != null) {
        await wallet.fetchWallet(auth.user!.id);
      }
      final creditedAmount = (res['amount'] as num?)?.toDouble() ?? 0.0;
      final newBalance =
          (res['new_balance'] as num?)?.toDouble() ?? wallet.balance;
      final note = (res['note'] ?? '').toString();
      _codeController.clear();
      setState(() {
        _redemptionHistory.insert(0, {
          'code': code,
          'amount': creditedAmount,
          'date': DateTime.now(),
          'status': 'Claimed',
        });
      });
      _showRedeemSuccessDialog(
        code: code,
        amount: creditedAmount,
        newBalance: newBalance,
        note: note,
      );
    } catch (e) {
      if (mounted) {
        final err = e.toString().replaceFirst('Exception: ', '').trim();
        TopNotification.showError(
          context,
          err.contains('not found') || err.contains('already been redeemed')
              ? err
              : 'This coupon code is invalid, already claimed, or expired.',
          title: 'Redemption Failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  void _showRedeemSuccessDialog({
    required String code,
    required double amount,
    required double newBalance,
    required String note,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    color: Color(0xFF10B981),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Coupon Redeemed! 🎉',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your wallet has been credited instantly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '+ ₦${amount.toStringAsFixed(2)}',
                        style: GoogleFonts.figtree(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: $code',
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Message: "$note"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.figtree(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Wallet Balance:',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '₦${newBalance.toStringAsFixed(2)}',
                      style: GoogleFonts.figtree(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.figtree(
                        fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ResponsiveShell(
      currentRoute: '/coupons',
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A0D14) : const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 36 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0052FF), const Color(0xFF00A3FF)]
                        : [const Color(0xFF0052FF), const Color(0xFF00D2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0052FF).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Back to Dashboard',
                              style: GoogleFonts.figtree(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.confirmation_number_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Claim & Redeem Coupons',
                              style: GoogleFonts.figtree(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Instant wallet top-up via promotional or gift voucher codes',
                              style: GoogleFonts.figtree(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. SEGMENTED TABS
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131826)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 0),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? (isDark
                                    ? const Color(0xFF1E2638)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Redeem Coupon',
                              style: GoogleFonts.figtree(
                                fontWeight: _selectedTab == 0
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _selectedTab == 0
                                    ? AppColors.primaryBlue
                                    : (isDark
                                        ? AppColors.metallicLight
                                        : AppColors.slateGrey),
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 1),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? (isDark
                                    ? const Color(0xFF1E2638)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Redemption History',
                              style: GoogleFonts.figtree(
                                fontWeight: _selectedTab == 1
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _selectedTab == 1
                                    ? AppColors.primaryBlue
                                    : (isDark
                                        ? AppColors.metallicLight
                                        : AppColors.slateGrey),
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. TAB CONTENT
              if (_selectedTab == 0)
                _buildRedeemTab(isDark)
              else
                _buildHistoryList(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRedeemTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Coupon Code',
          style: GoogleFonts.figtree(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131826) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E2638)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.figtree(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'ENTER CODE (E.G., AVOGIFT-8K392)',
              hintStyle: GoogleFonts.figtree(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.metallicLight.withValues(alpha: 0.6)
                    : Colors.grey,
                letterSpacing: 1.2,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Redeem Button
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isRedeeming ? null : _handleRedeem,
            icon: _isRedeeming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
            label: Text(
              _isRedeeming ? 'Validating...' : 'Redeem Coupon',
              style: GoogleFonts.figtree(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(bool isDark) {
    if (_redemptionHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
              ),
              const SizedBox(height: 14),
              Text(
                'No coupons redeemed yet',
                style: GoogleFonts.figtree(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Redeemed vouchers will appear here with instant credit receipts.',
                style: GoogleFonts.figtree(
                  fontSize: 12.5,
                  color: AppColors.slateGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _redemptionHistory.length,
      separatorBuilder: (_, _) => Divider(
        color: isDark ? const Color(0xFF1C2436) : const Color(0xFFF1F5F9),
      ),
      itemBuilder: (context, idx) {
        final item = _redemptionHistory[idx];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          title: Text(
            item['code'] as String,
            style: GoogleFonts.figtree(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            DateFormat(
              'dd MMM yyyy, hh:mm a',
            ).format(item['date'] as DateTime),
            style: GoogleFonts.figtree(fontSize: 11),
          ),
          trailing: Text(
            '+₦${(item['amount'] as double).toStringAsFixed(2)}',
            style: GoogleFonts.figtree(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.success,
            ),
          ),
        );
      },
    );
  }
}
