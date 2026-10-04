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
import '../../providers/wallet_provider.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const DashboardScreen({super.key, required this.onToggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.id != null) {
      setState(() => _isRefreshing = true);
      await context.read<WalletProvider>().fetchWallet(auth.user!.id!);
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _showTransferDialog() {
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryCyan),
              const SizedBox(width: 10),
              Text(
                'Send Money (User to User)',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Recipient Phone or Avotek ID',
                  hintText: '0803 123 4567',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Amount (₦)',
                  hintText: 'e.g. 2000',
                ),
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
                    content: Text(
                      'Transfer successful! ₦${amountCtrl.text} sent instantly.',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text('Transfer Now', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawDialog() {
    final bankCtrl = TextEditingController(text: 'Access Bank');
    final acctCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.arrow_downward_rounded, color: AppColors.warning),
              const SizedBox(width: 10),
              Text(
                'Withdraw to Bank',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: const InputDecoration(labelText: 'Destination Bank', hintText: 'Select Bank'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: acctCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: const InputDecoration(labelText: 'NUBAN Account Number', hintText: '10 digits'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: const InputDecoration(labelText: 'Amount to Withdraw (₦)', hintText: 'Minimum ₦1,000'),
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
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Withdrawal request queued! Settlement in under 2 minutes.',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text('Withdraw', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final rawName = auth.user?.name ?? 'Customer';
    final firstName = rawName.split(' ').first;
    final accountNumber = wallet.walletSummary?.virtualAccountNumber ?? '';
    final bankName = wallet.walletSummary?.virtualAccountBank ?? '';

    return ResponsiveShell(
      currentRoute: '/dashboard',
      onToggleTheme: widget.onToggleTheme,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primaryCyan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP GREETING & QUICK REFRESH ROW
                _buildHeaderRow(firstName, isDark),
                const SizedBox(height: 18),

                // 2. HERO WALLET CARD
                _buildWalletHeroCard(wallet, accountNumber, bankName, isDark),
                const SizedBox(height: 28),

                // 3. CORE VTU SERVICES GRID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Services',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Instant Delivery',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryCyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildServicesGrid(isDesktop, isDark),
                const SizedBox(height: 32),

                // 4. RECENT TRANSACTIONS
                _buildRecentTransactionsSection(wallet, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(String firstName, bool isDark) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$timeGreeting, $firstName',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'Active Reseller',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Automated 24/7',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              ],
            ),
          ],
        ),

        // In-App Refresh Icon Button
        IconButton(
          tooltip: 'In-App Refresh',
          icon: _isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan),
                )
              : const Icon(Icons.refresh_rounded, size: 22, color: AppColors.primaryCyan),
          onPressed: _isRefreshing ? null : _loadData,
        ),
      ],
    );
  }

  Widget _buildWalletHeroCard(
    WalletProvider wallet,
    String accountNumber,
    String bankName,
    bool isDark,
  ) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final formattedBalance = currencyFormat.format(wallet.balance);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF131B2A), const Color(0xFF0A0F1A)]
              : [const Color(0xFF002B47), const Color(0xFF0A192F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primaryCyan.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Available Balance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: wallet.toggleBalanceVisibility,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        wallet.isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'NGN (₦)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Big Bold Balance Number
          Text(
            wallet.isBalanceVisible ? '₦$formattedBalance' : '₦••••••••',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons: Fund, Transfer, Withdraw
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/wallet/fund'),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: Text(
                    'Fund Wallet',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCyan,
                    foregroundColor: const Color(0xFF002B47),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showTransferDialog,
                  icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Send',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showWithdrawDialog,
                  icon: const Icon(Icons.account_balance_outlined, size: 16, color: Colors.white),
                  label: Text(
                    'Withdraw',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Automated Bank Transfer Virtual Account Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primaryCyan),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dedicated Virtual Account',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          accountNumber.isNotEmpty
                              ? '$bankName • $accountNumber'
                              : 'Auto-Assigned on First Deposit',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                if (accountNumber.isNotEmpty)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: accountNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Account number $accountNumber copied!',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.primaryCyan,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded, size: 14, color: AppColors.primaryCyan),
                          const SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryCyan),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => context.push('/wallet/fund'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Fund',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF002B47)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(bool isDesktop, bool isDark) {
    final services = [
      _ServiceItem(
        title: 'Buy Data',
        subtitle: 'SME & Gifting',
        icon: Icons.wifi_rounded,
        color: const Color(0xFF00A3FF),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderColor: isDark ? const Color(0xFF00A3FF).withValues(alpha: 0.6) : const Color(0xFF00A3FF),
        route: '/services/data',
      ),
      _ServiceItem(
        title: 'Buy Airtime',
        subtitle: 'Instant Discount',
        icon: Icons.phone_android_rounded,
        color: const Color(0xFF0284C7),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderColor: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.6) : const Color(0xFF0284C7),
        route: '/services/airtime',
      ),
      _ServiceItem(
        title: 'Exam PINs',
        subtitle: 'WAEC, JAMB, NECO',
        icon: Icons.school_rounded,
        color: const Color(0xFF10B981),
        backgroundColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFF0FDF4),
        borderColor: const Color(0xFF10B981),
        route: '/services/exam_pin',
      ),
      _ServiceItem(
        title: 'Electricity',
        subtitle: 'Prepaid Tokens',
        icon: Icons.flash_on_rounded,
        color: const Color(0xFFF59E0B),
        route: '/services/electricity',
      ),
      _ServiceItem(
        title: 'Cable TV',
        subtitle: 'DSTV, GOtv, Startimes',
        icon: Icons.tv_rounded,
        color: const Color(0xFF8B5CF6),
        route: '/services/tv',
      ),
      _ServiceItem(
        title: 'Betting Topup',
        subtitle: 'Bet9ja, SportyBet',
        icon: Icons.sports_soccer_rounded,
        color: const Color(0xFF06B6D4),
        route: '/services/betting',
      ),
      _ServiceItem(
        title: 'Airtime to Cash',
        subtitle: 'Instant Payout',
        icon: Icons.currency_exchange_rounded,
        color: const Color(0xFF059669),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Airtime to Cash is ready. Minimum exchange: ₦1,000.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
      _ServiceItem(
        title: 'Fund Wallet',
        subtitle: 'Instant Credit',
        icon: Icons.add_card_rounded,
        color: AppColors.primaryCyan,
        route: '/wallet/fund',
      ),
    ];

    final int crossAxisCount = isDesktop ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isDesktop ? 1.8 : 1.5,
      ),
      itemCount: services.length,
      itemBuilder: (ctx, index) {
        final item = services[index];
        return InkWell(
          onTap: () {
            if (item.route != null) {
              context.push(item.route!);
            } else if (item.onTap != null) {
              item.onTap!();
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.backgroundColor ?? (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: item.borderColor ?? (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                width: item.borderColor != null ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (item.borderColor ?? Colors.black).withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactionsSection(WalletProvider wallet, bool isDark) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final transactions = wallet.transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/transactions'),
              child: Text(
                'View All',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryCyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 36, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                const SizedBox(height: 10),
                Text(
                  'No transactions yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your recent data, airtime and funding history will show here.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
              itemBuilder: (ctx, i) {
                final tx = transactions[i];
                final isCredit = tx.type == 'topup' || tx.type == 'credit';
                final amountStr = currencyFormat.format(tx.amount);
                final dateStr = DateFormat('dd MMM, hh:mm a').format(tx.createdAt);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCredit
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isCredit ? AppColors.success : AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tx.narration ?? (isCredit ? 'Wallet Top-up' : 'VTU Purchase'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    dateStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                    ),
                  ),
                  trailing: Text(
                    '${isCredit ? "+" : "-"}₦$amountStr',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isCredit
                          ? AppColors.success
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;
  final String? route;
  final VoidCallback? onTap;

  _ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.borderColor,
    this.route,
    this.onTap,
  });
}
