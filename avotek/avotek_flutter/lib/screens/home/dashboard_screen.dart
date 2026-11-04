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
import '../../widgets/avotek_loading_indicator.dart';
import '../../widgets/onboarding_pin_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const DashboardScreen({super.key, required this.onToggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _obscureBalance = false;
  bool _isLoadingInitial = true;
  String? _loadError;

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
    final wallet = context.read<WalletProvider>();
    setState(() {
      _loadError = null;
    });
    try {
      if (auth.user != null) {
        await Future.wait([
          auth.refreshWallet(),
          wallet.fetchWallet(auth.user!.id),
        ]);
        if (wallet.errorMessage != null && mounted) {
          setState(() => _loadError = wallet.errorMessage);
        }
        if (mounted && !wallet.hasDedicatedAccount) {
          wallet.ensureDedicatedAccount(auth.user!.id);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _loadError =
              'Your account details are temporarily unavailable. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
    }
  }

  void _showNotificationSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallet = context.read<WalletProvider>();
    final txs = wallet.recentTransactions;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Transaction Alerts',
                          style: GoogleFonts.figtree(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (txs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No recent transaction alerts yet.',
                        style: GoogleFonts.figtree(
                          fontSize: 13,
                          color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                        ),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 340),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: txs.take(6).length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
                      ),
                      itemBuilder: (ctx, idx) {
                        final tx = txs[idx];
                        final isSuccess = tx.status.toLowerCase() == 'completed' ||
                            tx.status.toLowerCase() == 'successful';
                        final isFailed = tx.status.toLowerCase() == 'failed';
                        final statusColor = isSuccess
                            ? AppColors.success
                            : (isFailed ? AppColors.error : AppColors.warning);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            tx.category.toUpperCase(),
                            style: GoogleFonts.figtree(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            tx.narration ?? (isSuccess ? 'Transaction delivered' : 'Transaction failed'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.figtree(
                              fontSize: 11.5,
                              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₦${tx.amount.toStringAsFixed(2)}',
                                style: GoogleFonts.figtree(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isSuccess ? AppColors.success : (isFailed ? AppColors.error : AppColors.primaryBlue),
                                ),
                              ),
                              Text(
                                isSuccess ? 'Delivered' : (isFailed ? 'Failed' : 'Processing'),
                                style: GoogleFonts.figtree(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push('/transactions');
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();

    if (_isLoadingInitial) {
      return ResponsiveShell(
        currentRoute: '/dashboard',
        onToggleTheme: widget.onToggleTheme,
        child: const Center(
          child: AvotekLoadingIndicator(
            logoSize: 56,
            message: 'Loading your account securely…',
          ),
        ),
      );
    }

    if (_loadError != null && auth.wallet == null) {
      return ResponsiveShell(
        currentRoute: '/dashboard',
        onToggleTheme: widget.onToggleTheme,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 54,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load account details',
                  style: GoogleFonts.figtree(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    color: AppColors.slateGrey,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isLoadingInitial = true);
                    _loadData();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry Loading Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userName = (auth.user?.name != null && auth.user!.name.isNotEmpty)
        ? auth.user!.name
        : (auth.user?.email.split('@').first ?? 'Valued User');
    final effectiveBalance = auth.wallet?.balance ?? wallet.balance;

    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning,'
        : (hour < 17 ? 'Good afternoon,' : 'Good evening,');

    return ResponsiveShell(
      currentRoute: '/dashboard',
      onToggleTheme: widget.onToggleTheme,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.electricCyan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 36 : 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP GREETING HEADER (Matches Screenshot 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeGreeting,
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName,
                          style: GoogleFonts.figtree(
                            fontSize: isDesktop ? 26 : 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Role Badge Pill (Regular / Admin)
                        if (auth.user?.isAdmin ?? false)
                          InkWell(
                            onTap: () => context.go('/admin'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: isDark ? 0.18 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 14,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Admin',
                                    style: GoogleFonts.figtree(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF131722)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                  ? const Color(0xFF23304B)
                                  : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: AppColors.metallicLight,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Regular',
                                  style: GoogleFonts.figtree(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.metallicLight
                                        : AppColors.slateGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),

                        // Notification Icon
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              tooltip: 'Transaction Alerts',
                              icon: Icon(
                                Icons.notifications_none_rounded,
                                size: 21,
                                color: isDark
                                    ? AppColors.metallicLight
                                    : AppColors.slateGrey,
                              ),
                              onPressed: () => _showNotificationSheet(context),
                            ),
                            if (wallet.recentTransactions.isNotEmpty)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: wallet.recentTransactions.any((t) => t.status.toLowerCase() == 'failed')
                                        ? AppColors.error
                                        : AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 2. HERO VIRTUAL CARD / WALLET (Matches Screenshot 2)
                _buildHeroVirtualCard(
                  effectiveBalance,
                  auth,
                  wallet,
                  isDark,
                  isDesktop,
                ),
                const SizedBox(height: 18),

                // 3. ACTION BUTTONS ROW (Fund Wallet + History)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D2FF), Color(0xFF0052FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0052FF,
                              ).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/wallet/fund'),
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Fund Wallet',
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF131722)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF23304B)
                                : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/transactions'),
                          icon: Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          label: Text(
                            'History',
                            style: GoogleFonts.figtree(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. METRICS / STATS BAR (4 Cards Row)
                _buildMetricsStatsBar(wallet, isDark, isDesktop),
                const SizedBox(height: 32),

                // 5. QUICK ACTIONS SECTION (Matches Screenshot 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.electricCyan,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.figtree(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => context.push('/services'),
                      child: Row(
                        children: [
                          Text(
                            'All Services',
                            style: GoogleFonts.figtree(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.metallicLight
                                  : AppColors.slateGrey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.metallicLight
                                : AppColors.slateGrey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(isDark, isDesktop),
                const SizedBox(height: 36),

                // 6. RECENT TRANSACTIONS LEDGER PREVIEW
                _buildRecentTransactionsSection(wallet, isDark),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HERO VIRTUAL CARD (MATCHES SCREENSHOT 2) ---
  Widget _buildHeroVirtualCard(
    double balance,
    AuthProvider auth,
    WalletProvider wallet,
    bool isDark,
    bool isDesktop,
  ) {
    final formattedBalance = NumberFormat('#,##0.00', 'en_US').format(balance);
    final assignedHolderName =
        wallet.walletSummary?.virtualAccountName ??
        auth.wallet?.virtualAccountName;
    final holderName =
        (assignedHolderName != null && assignedHolderName.trim().isNotEmpty)
        ? assignedHolderName.trim()
        : ((auth.user?.name != null && auth.user!.name.isNotEmpty)
              ? auth.user!.name
              : (auth.user?.email.split('@').first ?? 'MEMBER'));
    final cardHolder = holderName.toUpperCase();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 26 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0E131E), const Color(0xFF121B2F)]
              : [const Color(0xFF0052FF), const Color(0xFF007AEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF22304C) : const Color(0xFF3880FF),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle circular glows
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.electricCyan.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Card Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Brand & Free Deposits Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'avotek',
                        style: GoogleFonts.figtree(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 2, top: 4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.electricCyan,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'AVOTEK WALLET',
                      style: GoogleFonts.figtree(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Available Balance Row
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AVAILABLE BALANCE',
                    style: GoogleFonts.figtree(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.metallicLight : Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    _obscureBalance ? '₦ • • • • • •' : '₦$formattedBalance',
                    style: GoogleFonts.figtree(
                      fontSize: isDesktop ? 38 : 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(
                      _obscureBalance
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.white70,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () =>
                        setState(() => _obscureBalance = !_obscureBalance),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Card Chip & Avotek ID
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gold EMV Chip Simulation
                  Container(
                    width: 34,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFB8860B)),
                    ),
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 14,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.wifi_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),

              // Large Solid White Fund Wallet Card
              InkWell(
                onTap: () => context.push('/wallet/fund'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052FF).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 20,
                          color: Color(0xFF0052FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'FUND WALLET',
                              style: GoogleFonts.figtree(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Instant Automated Card, Bank Transfer & USSD',
                              style: GoogleFonts.figtree(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: Color(0xFF0052FF),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 10),

              // Cardholder Name & Active Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cardHolder,
                      style: GoogleFonts.figtree(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Active Account',
                          style: GoogleFonts.figtree(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4 STATS CARDS ROW (MATCHES SCREENSHOT 2) ---
  Widget _buildMetricsStatsBar(
    WalletProvider wallet,
    bool isDark,
    bool isDesktop,
  ) {
    final todaySpend = wallet.transactions
        .where((t) => t.isDebit && t.createdAt.day == DateTime.now().day)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalCount = wallet.transactions.length;
    final successCount = wallet.transactions
        .where((t) => t.status == 'completed' || t.status == 'successful')
        .length;
    final failedCount = wallet.transactions
        .where((t) => t.status == 'failed')
        .length;

    final metrics = [
      (
        title: "TODAY'S SPEND",
        value: '₦${todaySpend.toStringAsFixed(0)}',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.primaryBlue,
      ),
      (
        title: 'TRANSACTIONS',
        value: '$totalCount',
        icon: Icons.payments_rounded,
        color: AppColors.electricCyan,
      ),
      (
        title: 'SUCCESSFUL',
        value: '$successCount',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      ),
      (
        title: 'FAILED',
        value: '$failedCount',
        icon: Icons.cancel_rounded,
        color: AppColors.error,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: isDesktop ? 84 : 102,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _buildMetricTile(
          title: metric.title,
          value: metric.value,
          icon: metric.icon,
          iconColor: metric.color,
          isDark: isDark,
          isDesktop: isDesktop,
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required bool isDesktop,
  }) {
    final content = isDesktop
        ? Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.figtree(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: isDark
                            ? AppColors.metallicLight
                            : AppColors.slateGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.figtree(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: isDark
                      ? AppColors.metallicLight
                      : AppColors.slateGrey,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 12 : 8,
        vertical: isDesktop ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: content,
    );
  }

  // --- QUICK ACTIONS 4-GRID (MATCHES SCREENSHOT 2) ---
  Widget _buildQuickActionsGrid(bool isDark, bool isDesktop) {
    final actions = [
      {
        'title': 'Exam PINs',
        'icon': Icons.school_rounded,
        'route': '/services/exam-pins',
      },
      {
        'title': 'Airtime',
        'icon': Icons.phone_android_rounded,
        'route': '/services/airtime',
      },
      {'title': 'Data', 'icon': Icons.wifi_rounded, 'route': '/services/data'},
      {'title': 'Cable', 'icon': Icons.tv_rounded, 'route': '/services/tv'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: isDesktop ? 142 : 126,
      ),
      itemBuilder: (context, index) {
        final item = actions[index];
        return InkWell(
          onTap: () => context.push(item['route'] as String),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF23304B)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.electricCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: AppColors.electricCyan,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item['title'] as String,
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- RECENT TRANSACTIONS PREVIEW ---
  Widget _buildRecentTransactionsSection(WalletProvider wallet, bool isDark) {
    final txs = wallet.transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.figtree(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/transactions'),
              child: Text(
                'View All',
                style: GoogleFonts.figtree(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.electricCyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: txs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                          color: isDark
                              ? AppColors.metallicLight
                              : AppColors.slateGrey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No recent transactions found',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.metallicLight
                                : AppColors.slateGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: txs.length,
                  separatorBuilder: (_, _) => Divider(
                    color: isDark
                        ? const Color(0xFF1E283D)
                        : const Color(0xFFF1F5F9),
                    height: 16,
                  ),
                  itemBuilder: (context, idx) {
                    final tx = txs[idx];
                    final isCredit = tx.isCredit;
                    return Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                (isCredit
                                        ? AppColors.success
                                        : AppColors.primaryBlue)
                                    .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 18,
                            color: isCredit
                                ? AppColors.success
                                : AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.category.toUpperCase(),
                                style: GoogleFonts.figtree(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy • hh:mm a',
                                ).format(tx.createdAt),
                                style: GoogleFonts.figtree(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.metallicLight
                                      : AppColors.slateGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isCredit ? '+' : '-'}₦${tx.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.figtree(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isCredit
                                ? AppColors.success
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
