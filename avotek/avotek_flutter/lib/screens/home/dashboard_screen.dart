import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/onboarding_pin_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const DashboardScreen({super.key, required this.onToggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isRefreshing = false;
  bool _obscureBalance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPinOnboarding();
      _loadData();
    });
  }

  void _checkPinOnboarding() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.needsPinSetup) {
      OnboardingPinDialog.show(context);
    }
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.id != null) {
      setState(() => _isRefreshing = true);
      await auth.refreshWallet();
      await context.read<WalletProvider>().fetchWallet(auth.user!.id!);
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _launchWhatsApp() async {
    const phone = '+2348034119920';
    final uri = Uri.parse('https://wa.me/2348034119920?text=Hello%20Avotek%2C%20I%20want%20to%20buy%20data%20and%20airtime');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showCopySnackBar('WhatsApp Support: $phone');
      }
    } catch (_) {
      _showCopySnackBar('WhatsApp Support: $phone');
    }
  }

  void _showCopySnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF25D366),
      ),
    );
  }

  // --- Add Money Modal (Dedicated Bank Account Funding) ---
  void _showAddMoneyDialog() {
    final auth = context.read<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.userRecord;
    final accountNumber = user?.virtualAccountNumber ?? '9034119920';
    final bankName = user?.virtualAccountBank ?? 'Wema Bank / Moniepoint';
    final accountName = user?.virtualAccountName ?? 'AVOTEK - ${auth.user?.name ?? "User"}';

    final testFundCtrl = TextEditingController(text: '5000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF14171E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: isDark ? const Color(0xFFD4AF37).withOpacity(0.3) : const Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_rounded, color: Color(0xFFD4AF37), size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Fund Your Wallet',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transfer any amount to your dedicated virtual account from your bank app. Your wallet credits automatically in seconds.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
              const SizedBox(height: 18),

              // Account Number Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1117) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFFD4AF37).withOpacity(0.4) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ACCOUNT NUMBER', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFD4AF37))),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: accountNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Account number copied!'), backgroundColor: AppColors.success),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFD4AF37)),
                              const SizedBox(width: 4),
                              Text('COPY', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFD4AF37))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      accountNumber,
                      style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFF26334D), height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BANK NAME', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.metallicLight)),
                        Text(bankName, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ACCOUNT NAME', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.metallicLight)),
                        Text(accountName, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Sandbox / Instant Credit Simulator for quick testing
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222D) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instant Test Credit (Sandbox Simulation):',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: testFundCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                            decoration: const InputDecoration(
                              prefixText: '₦ ',
                              hintText: '5000',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: const Color(0xFF0A0E17),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onPressed: () async {
                            final amt = double.tryParse(testFundCtrl.text.trim()) ?? 5000.0;
                            await auth.creditWallet(amt);
                            if (ctx.mounted) Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('₦${amt.toStringAsFixed(2)} successfully credited to your wallet!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                          child: Text('Credit Now', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // --- Withdraw Modal ---
  void _showWithdrawDialog() {
    final bankCtrl = TextEditingController(text: 'Access Bank');
    final acctCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF14171E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            const Icon(Icons.arrow_downward_rounded, color: Color(0xFFF5A623)),
            const SizedBox(width: 10),
            Text('Withdraw to Bank', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: const InputDecoration(labelText: 'Destination Bank', hintText: 'Access Bank'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: acctCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: const InputDecoration(labelText: '10-Digit Account Number', hintText: '0123456789'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: const InputDecoration(labelText: 'Amount (₦)', hintText: 'e.g. 5000'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5A623),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Withdrawal request of ₦${amountCtrl.text} submitted for processing.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text('Withdraw', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // --- Send To User Modal ---
  void _showSendToUserDialog() {
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF14171E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryCyan),
            const SizedBox(width: 10),
            Text('Send Money to User', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: const InputDecoration(labelText: 'Recipient Phone or Username', hintText: '0803 123 4567'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: const InputDecoration(labelText: 'Amount (₦)', hintText: 'e.g. 2000'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: const Color(0xFF002B47),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('₦${amountCtrl.text} sent instantly to ${phoneCtrl.text}!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text('Transfer Now', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // --- Referral Modal ---
  void _showReferralDialog() {
    final auth = context.read<AuthProvider>();
    final code = auth.user?.referralCode ?? 'ADEVICT01';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF14171E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: isDark ? const Color(0xFFD4AF37).withOpacity(0.3) : const Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            const Icon(Icons.group_add_rounded, color: Color(0xFFD4AF37)),
            const SizedBox(width: 10),
            Text('Refer & Earn 2%', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share your referral code. You earn 2% commission on the first deposit of every user who signs up with your link.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1117) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(code, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFFD4AF37), letterSpacing: 1.5)),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFFD4AF37), size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Referral code copied!'), backgroundColor: AppColors.success),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String serviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$serviceName is active and connecting to gateway...', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();

    final userName = auth.user?.name ?? 'Adevictorolu';
    final effectiveBalance = auth.wallet?.balance ?? wallet.balance;

    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning 🌅'
        : (hour < 17 ? 'Good afternoon ☀️' : 'Good evening 🌙');

    return ResponsiveShell(
      currentRoute: '/dashboard',
      onToggleTheme: widget.onToggleTheme,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFFD4AF37),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TOP GREETING & USERNAME (Matching Bilal Sub)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeGreeting,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isDesktop ? 32 : 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        // Top Right Action Buttons
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Buy on WhatsApp',
                              icon: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF25D366), width: 1.5),
                                ),
                                child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 18),
                              ),
                              onPressed: _launchWhatsApp,
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: 'Notifications',
                              icon: const Icon(Icons.notifications_none_rounded, size: 22),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('All services operational. 99.9% gateway uptime.')),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => context.go('/profile'),
                              borderRadius: BorderRadius.circular(20),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF1E293B),
                                child: const Icon(Icons.person, color: Color(0xFF00A3FF), size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. GREEN WHATSAPP BANNER (Matching Bilal Sub)
                    _buildWhatsAppBanner(isDark),
                    const SizedBox(height: 22),

                    // 3. BALANCE & STATS CARDS ROW (Matching Bilal Sub)
                    _buildBalanceSection(effectiveBalance, isDesktop, isDark),
                    const SizedBox(height: 28),

                    // 4. SERVICES GRID (Matching Bilal Sub 20 Cards)
                    Text(
                      'Services',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildServicesGrid(isDesktop, isDark),
                    const SizedBox(height: 24),

                    // 5. INVITE FRIENDS / REFERRAL BANNER (Matching Bilal Sub)
                    _buildInviteBanner(isDark),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),

          // 6. FLOATING ACTION BUTTON (Yellow Circular Chat Button matching Bilal Sub)
          Positioned(
            right: 24,
            bottom: 24,
            child: Material(
              color: const Color(0xFFF5A623), // Bilal Sub Yellow
              shape: const CircleBorder(),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.4),
              child: InkWell(
                onTap: _launchWhatsApp,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 54,
                  height: 54,
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    color: Color(0xFF0A0E17),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Green WhatsApp Banner ---
  Widget _buildWhatsAppBanner(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _launchWhatsApp,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF059669)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C853).withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buy directly on WhatsApp',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chat with Bilal to buy data, airtime & more — Instantly.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- Hero Balance Section (Left Large Amber Card + Right Stacked Cards) ---
  Widget _buildBalanceSection(double balance, bool isDesktop, bool isDark) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final formattedBalance = currencyFormat.format(balance);

    final leftCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15171F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFFD4AF37).withOpacity(0.3) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Eye and Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MAIN WALLET BALANCE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFE5A93C),
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _obscureBalance = !_obscureBalance),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A93C)),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _isRefreshing ? null : _loadData,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Bold Balance
          Text(
            _obscureBalance ? '₦ ••••••' : '₦$formattedBalance',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),

          // Pill Action Buttons (+ Add Money and Withdraw)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddMoneyDialog,
                  icon: const Icon(Icons.add_circle_rounded, size: 16),
                  label: Text(
                    'Add Money',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C), // Gold
                    foregroundColor: const Color(0xFF0A0E17),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showWithdrawDialog,
                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                  label: Text(
                    'Withdraw',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final rightCards = Column(
      children: [
        // 1. Earning balance card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161922) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earning balance',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₦0.00',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Data purchased today card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161922) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wifi_rounded, color: Color(0xFFF5A623), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data purchased today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '0GB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: leftCard),
          const SizedBox(width: 18),
          Expanded(flex: 2, child: rightCards),
        ],
      );
    } else {
      return Column(
        children: [
          leftCard,
          const SizedBox(height: 14),
          rightCards,
        ],
      );
    }
  }

  // --- Services Grid (20 Services matching Bilal Sub Screenshots 1 & 2) ---
  Widget _buildServicesGrid(bool isDesktop, bool isDark) {
    final services = [
      {'title': 'Buy Data', 'icon': Icons.wifi_rounded, 'color': const Color(0xFF00A3FF), 'route': '/services/data'},
      {'title': 'Buy Airtime', 'icon': Icons.phone_android_rounded, 'color': const Color(0xFF10B981), 'route': '/services/airtime'},
      {'title': 'Airtime to Cash', 'icon': Icons.sync_alt_rounded, 'color': const Color(0xFF14B8A6), 'action': () => _showComingSoon('Airtime to Cash')},
      {'title': 'Crypto', 'icon': Icons.currency_bitcoin_rounded, 'color': const Color(0xFFF59E0B), 'action': () => _showComingSoon('Crypto Swap')},
      {'title': 'Electricity', 'icon': Icons.flash_on_rounded, 'color': const Color(0xFFEAB308), 'route': '/services/electricity'},
      {'title': 'Cable TV', 'icon': Icons.tv_rounded, 'color': const Color(0xFF8B5CF6), 'route': '/services/tv'},
      {'title': 'Bulk SMS', 'icon': Icons.sms_rounded, 'color': const Color(0xFF6366F1), 'action': () => _showComingSoon('Bulk SMS')},
      {'title': 'Education', 'icon': Icons.school_rounded, 'color': const Color(0xFF3B82F6), 'route': '/exams'},
      {'title': 'Bonus Transfer', 'icon': Icons.card_giftcard_rounded, 'color': const Color(0xFFF5A623), 'action': () => _showComingSoon('Bonus Transfer')},
      {'title': 'Send to User', 'icon': Icons.send_rounded, 'color': const Color(0xFF10B981), 'action': _showSendToUserDialog},
      {'title': 'Withdraw', 'icon': Icons.arrow_downward_rounded, 'color': const Color(0xFFF97316), 'action': _showWithdrawDialog},
      {'title': 'Virtual Cards', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFFA855F7), 'action': () => _showComingSoon('Virtual USD/NGN Cards')},
      {'title': 'Gift Cards', 'icon': Icons.redeem_rounded, 'color': const Color(0xFFEC4899), 'action': () => _showComingSoon('Gift Cards Exchange')},
      {'title': 'eSIM', 'icon': Icons.sim_card_rounded, 'color': const Color(0xFF06B6D4), 'action': () => _showComingSoon('Global Travel eSIM')},
      {'title': 'Flight', 'icon': Icons.flight_takeoff_rounded, 'color': const Color(0xFF38BDF8), 'action': () => _showComingSoon('Domestic & International Flight Booking')},
      {'title': 'Smile', 'icon': Icons.sentiment_satisfied_alt_rounded, 'color': const Color(0xFF22C55E), 'action': () => _showComingSoon('Smile 4G LTE Top-up')},
      {'title': 'Alpha', 'icon': Icons.looks_one_rounded, 'color': const Color(0xFF00A3FF), 'action': () => _showComingSoon('Alpha Topup')},
      {'title': 'Kirani', 'icon': Icons.diamond_outlined, 'color': const Color(0xFFD4AF37), 'action': () => _showComingSoon('Kirani PIN')},
      {'title': 'Data Card', 'icon': Icons.nfc_rounded, 'color': const Color(0xFF2563EB), 'action': () => _showComingSoon('Data Card Printing')},
      {'title': 'Recharge Card', 'icon': Icons.receipt_rounded, 'color': const Color(0xFFF97316), 'action': () => _showComingSoon('Recharge Card Printing')},
    ];

    final crossAxisCount = isDesktop ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: isDesktop ? 2.3 : 1.7,
      ),
      itemBuilder: (context, index) {
        final item = services[index];
        final title = item['title'] as String;
        final icon = item['icon'] as IconData;
        final color = item['color'] as Color;

        return _buildServiceCard(
          title: title,
          icon: icon,
          accentColor: color,
          isDark: isDark,
          onTap: () {
            if (item.containsKey('route')) {
              context.go(item['route'] as String);
            } else if (item.containsKey('action')) {
              (item['action'] as VoidCallback)();
            }
          },
        );
      },
    );
  }

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        hoverColor: accentColor.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141720) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222D) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withOpacity(0.3), width: 1.2),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Referral Invite Banner (Screenshot 2 bottom) ---
  Widget _buildInviteBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141720) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFFD4AF37).withOpacity(0.25) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_alt_rounded, color: Color(0xFFD4AF37), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite friends, earn 2% on first deposits',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Share your referral code and earn every time someone signs up.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showReferralDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5A623), // Bilal Sub Gold
              foregroundColor: const Color(0xFF0A0E17),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'Earn Now',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
