import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class CouponsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const CouponsScreen({super.key, required this.onToggleTheme});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  int _selectedTab = 0; // 0 = Redeem Coupon, 1 = History
  final TextEditingController _codeController = TextEditingController();
  bool _isRedeeming = false;

  final List<Map<String, dynamic>> _redemptionHistory = [];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleRedeem() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coupon code.')),
      );
      return;
    }

    setState(() => _isRedeeming = true);

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();

    await Future.delayed(const Duration(milliseconds: 600));

    double rewardAmount = 500.0;
    if (code == 'WELCOME20' || code == 'WELCOME') {
      rewardAmount = 1000.0;
    } else if (code == 'AVOTEK100' || code == 'BONUS') {
      rewardAmount = 500.0;
    } else if (code.startsWith('AVO')) {
      rewardAmount = 750.0;
    }

    if (auth.user?.id != null) {
      final ref = 'CPN-${DateTime.now().millisecondsSinceEpoch}';
      wallet.depositFunds(
        rewardAmount,
        reference: ref,
        narration: 'Coupon $code Redeemed',
      );
      await auth.refreshWallet();

      setState(() {
        _redemptionHistory.insert(0, {
          'code': code,
          'amount': rewardAmount,
          'date': DateTime.now(),
          'reference': ref,
          'status': 'SUCCESSFUL',
        });
        _codeController.clear();
        _isRedeeming = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon $code redeemed! ₦${rewardAmount.toStringAsFixed(2)} credited to your wallet.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      setState(() => _isRedeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ResponsiveShell(
      currentRoute: '/coupons',
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0D14) : const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 36 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP BANNER (Matches Screenshot 1)
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'Back',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Coupons',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Redeem promotional codes and view your redemption history',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. TABS ROW: Redeem Coupon | History (Matches Screenshot 1)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 0),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? AppColors.primaryBlue
                              : (isDark ? const Color(0xFF131722) : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedTab == 0
                                ? AppColors.primaryBlue
                                : (isDark ? const Color(0xFF23304B) : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 16,
                              color: _selectedTab == 0 ? Colors.white : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Redeem Coupon',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _selectedTab == 0 ? Colors.white : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 1),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? AppColors.primaryBlue
                              : (isDark ? const Color(0xFF131722) : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedTab == 1
                                ? AppColors.primaryBlue
                                : (isDark ? const Color(0xFF23304B) : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 16,
                              color: _selectedTab == 1 ? Colors.white : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'History',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _selectedTab == 1 ? Colors.white : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. MAIN CARD (Matches Screenshot 1)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF10141F) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0xFF202A3E) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: _selectedTab == 0 ? _buildRedeemForm(isDark) : _buildHistoryList(isDark),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRedeemForm(bool isDark) {
    return Column(
      children: [
        // Ticket Icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1B2233) : const Color(0xFFEFF6FF)),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.electricCyan.withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.confirmation_number_rounded,
            size: 36,
            color: AppColors.electricCyan,
          ),
        ),
        const SizedBox(height: 18),

        // Heading & Subtitle
        Text(
          'Redeem Coupon',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your coupon code to get instant wallet credit',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
          ),
        ),
        const SizedBox(height: 28),

        // Monospace Code Input Box
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C0F17) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF283654) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'ENTER COUPON CODE (E.G., WELCOME20)',
              hintStyle: GoogleFonts.jetBrainsMono(
                fontSize: 12.5,
                color: isDark ? AppColors.metallicLight.withValues(alpha: 0.6) : Colors.grey,
                letterSpacing: 1.2,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
            label: Text(
              _isRedeeming ? 'Validating...' : 'Redeem Coupon',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              Icon(Icons.history_rounded, size: 48, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
              const SizedBox(height: 14),
              Text(
                'No coupons redeemed yet',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Redeemed vouchers will appear here with instant credit receipts.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.slateGrey),
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
      separatorBuilder: (_, _) => Divider(color: isDark ? const Color(0xFF1C2436) : const Color(0xFFF1F5F9)),
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
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
          ),
          title: Text(
            item['code'] as String,
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          subtitle: Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(item['date'] as DateTime),
            style: GoogleFonts.plusJakartaSans(fontSize: 11),
          ),
          trailing: Text(
            '+₦${(item['amount'] as double).toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
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
