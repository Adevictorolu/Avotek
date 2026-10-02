import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_logo.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const DashboardScreen({super.key, required this.onToggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user?.id != null) {
        context.read<WalletProvider>().fetchWallet(auth.user!.id!);
      }
    });
  }

  void _onServiceSelected(String route) {
    context.push(route);
  }

  void _openFundWalletModal() {
    context.push('/wallet/fund');
  }

  void _showTransferDialog() {
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppColors.primaryCyan),
            SizedBox(width: 8),
            Text('Transfer Wallet Funds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Recipient Phone or Avotek ID', hintText: '0803 123 4567'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₦)', hintText: 'e.g. 5000'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wallet transfer successful! Funds credited instantly.')),
              );
            },
            child: const Text('Transfer Now'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final bankCtrl = TextEditingController(text: 'Access Bank');
    final acctCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_download_outlined, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Withdraw to Bank Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankCtrl,
              decoration: const InputDecoration(labelText: 'Destination Bank', hintText: 'Select Bank'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: acctCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'NUBAN Account Number', hintText: '10 digits'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount to Withdraw (₦)', hintText: 'Minimum ₦1,000'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawal request initiated. Expected settlement: < 2 minutes.')),
              );
            },
            child: const Text('Withdraw Funds'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    final userName = auth.user?.name ?? 'Ada Okafor';
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'AO';
    final userTier = auth.isSuperAdmin ? 'Super Admin' : 'Agent account';

    final accountNumber = wallet.walletSummary?.virtualAccountNumber ?? '2205178431';
    final bankName = wallet.walletSummary?.virtualAccountBank ?? 'Providus Bank';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      // Desktop & Mobile Appbar (Matching Kobopay .appbar)
      appBar: AppBar(
        titleSpacing: isDesktop ? 48 : 16,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Row(
          children: [
            const AvotekLogo(size: 32, showText: true),
            if (isDesktop) ...[
              const SizedBox(width: 48),
              _topNavLink('Dashboard', '/dashboard', true, isDark),
              _topNavLink('Airtime', '/services/airtime', false, isDark),
              _topNavLink('Data', '/services/data', false, isDark),
              _topNavLink('History', '/transactions', false, isDark),
              _topNavLink('Rates', '/rates', false, isDark),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: Stack(
              children: [
                Icon(Icons.notifications_none_rounded, size: 22, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new unread notifications.')),
              );
            },
          ),
          const SizedBox(width: 8),
          // User chip (Matching Kobopay .who)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.primaryCyan,
                  child: Text(
                    userInitials,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(userTier, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (auth.isSuperAdmin) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Admin Console',
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: AppColors.primaryCyan),
              onPressed: () => context.push('/admin'),
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () {
              auth.signOut();
              context.go('/login');
            },
          ),
          SizedBox(width: isDesktop ? 48 : 16),
        ],
      ),

      // Mobile Navigation Drawer (Matching Kobopay .side)
      drawer: Drawer(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AvotekLogo(size: 30, showText: true),
                  const SizedBox(height: 12),
                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(userTier, style: TextStyle(fontSize: 12, color: AppColors.primaryCyan)),
                ],
              ),
            ),
            _drawerSection('OVERVIEW'),
            _drawerItem(Icons.grid_view_rounded, 'Dashboard', '/dashboard', true),
            _drawerSection('SERVICES'),
            _drawerItem(Icons.phone_android_rounded, 'Buy airtime', '/services/airtime', false),
            _drawerItem(Icons.wifi_rounded, 'Buy data', '/services/data', false),
            _drawerItem(Icons.tv_rounded, 'Cable TV', '/services/tv', false),
            _drawerItem(Icons.bolt_rounded, 'Electricity', '/services/electricity', false),
            _drawerItem(Icons.school_rounded, 'Result pins', '/services/exam_pin', false),
            _drawerSection('MONEY'),
            _drawerItem(Icons.account_balance_wallet_rounded, 'Fund wallet', '/wallet/fund', false),
            _drawerItem(Icons.receipt_long_rounded, 'Transactions', '/transactions', false),
            _drawerItem(Icons.swap_horiz_rounded, 'Transfer', '/dashboard', false),
            _drawerSection('ACCOUNT'),
            _drawerItem(Icons.price_change_rounded, 'Rates & Tariffs', '/rates', false),
            if (auth.isSuperAdmin) _drawerItem(Icons.admin_panel_settings_rounded, 'Admin Operations Suite', '/admin', false),
            _drawerItem(Icons.logout_rounded, 'Sign out', '/login', false),
          ],
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.user?.id != null) {
            await wallet.fetchWallet(auth.user!.id!);
          }
        },
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Header (Matching Kobopay .page__h)
                    Text(
                      'Good afternoon, ${userName.split(' ').first}',
                      style: GoogleFonts.montserrat(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is where your account stands today.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1. THE WALLET CARD (Matching Kobopay .wallet)
                    _buildWalletCard(wallet, accountNumber, bankName, userTier, isDark),
                    const SizedBox(height: 24),

                    // 2. THE 4 METRICS CARDS (Matching Kobopay .metrics)
                    _buildMetricsSection(isDesktop, isDark),
                    const SizedBox(height: 32),

                    // 3. QUICK ACTIONS GRID (Matching Kobopay .qtiles)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quick actions',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Protected by failover router',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.primaryCyan : AppColors.primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildQuickActionsGrid(isDesktop, isDark),
                    const SizedBox(height: 36),

                    // 4. RECENT TRANSACTIONS (Matching Kobopay .card recent transactions)
                    _buildRecentTransactionsCard(wallet, isDark),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // Bottom Navigation Bar for Mobile (Matching Kobopay .tabbar)
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _currentTabIndex,
              onDestinationSelected: (idx) {
                setState(() => _currentTabIndex = idx);
                if (idx == 1) context.push('/services/airtime');
                if (idx == 2) context.push('/services/data');
                if (idx == 3) context.push('/transactions');
                if (idx == 4) _scaffoldKey.currentState?.openDrawer();
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.phone_android_rounded), label: 'Airtime'),
                NavigationDestination(icon: Icon(Icons.wifi_rounded), label: 'Data'),
                NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'History'),
                NavigationDestination(icon: Icon(Icons.menu_rounded), label: 'Menu'),
              ],
            ),
    );
  }

  Widget _topNavLink(String label, String route, bool isActive, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? AppColors.primaryCyan
                  : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
    );
  }

  Widget _drawerItem(IconData icon, String title, String route, bool isActive) {
    return ListTile(
      leading: Icon(icon, size: 20, color: isActive ? AppColors.primaryCyan : Colors.grey),
      title: Text(title, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
      dense: true,
      onTap: () {
        Navigator.pop(context);
        context.push(route);
      },
    );
  }

  // WALLET CARD (Replicating Kobopay .wallet)
  Widget _buildWalletCard(WalletProvider wallet, String acctNum, String bank, String tier, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1E32) : const Color(0xFF0084D6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.primaryCyan.withValues(alpha: 0.3) : const Color(0xFF0072BA),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Label + Eye
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.white70),
                  SizedBox(width: 8),
                  Text('Wallet balance', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                ],
              ),
              IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  wallet.isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white70,
                ),
                onPressed: wallet.toggleBalanceVisibility,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Big Balance Text
          Text(
            wallet.isBalanceVisible
                ? '₦${NumberFormat('#,##0.00').format(wallet.balance > 0 ? wallet.balance : 248500.00)}'
                : '₦ • • • • • •',
            style: GoogleFonts.montserrat(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          // Action Buttons: Add money, Transfer, Withdraw
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: _openFundWalletModal,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add money', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showTransferDialog,
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Transfer', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showWithdrawDialog,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 18),
          // 3-part Footer: Dedicated Account, Bank, Tier
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _walletFootItem(acctNum, 'Your dedicated account number', isCopyable: true),
                        const SizedBox(height: 12),
                        _walletFootItem(bank, 'Transfers reflect instantly'),
                        const SizedBox(height: 12),
                        _walletFootItem(tier, 'A better rate on every service'),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _walletFootItem(acctNum, 'Your dedicated account number', isCopyable: true)),
                        Expanded(child: _walletFootItem(bank, 'Transfers reflect instantly')),
                        Expanded(child: _walletFootItem(tier, 'A better rate on every service')),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _walletFootItem(String title, String subtitle, {bool isCopyable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14)),
            if (isCopyable) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: title));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account number copied to clipboard!')),
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  // 4 METRICS SECTION (Replicating Kobopay .metrics)
  Widget _buildMetricsSection(bool isDesktop, bool isDark) {
    final metrics = [
      {'label': 'Spent today', 'val': '₦46,200', 'badge': '12% more than yesterday', 'icon': Icons.credit_card_rounded, 'color': AppColors.primaryCyan},
      {'label': 'Orders this week', 'val': '318', 'badge': '8% more than last week', 'icon': Icons.receipt_long_rounded, 'color': AppColors.success},
      {'label': 'Delivered first try', 'val': '99.9%', 'badge': '2 refunds settled automatically', 'icon': Icons.check_circle_rounded, 'color': Colors.teal},
      {'label': 'Referral earnings', 'val': '₦18,300', 'badge': '6 new sign-ups this week', 'icon': Icons.group_add_rounded, 'color': AppColors.warning},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = isDesktop ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isDesktop ? 1.4 : 2.2,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, idx) {
            final m = metrics[idx];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m['label'] as String, style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey)),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: (m['color'] as Color).withValues(alpha: 0.15),
                        child: Icon(m['icon'] as IconData, size: 14, color: m['color'] as Color),
                      ),
                    ],
                  ),
                  Text(
                    m['val'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.trending_up_rounded, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          m['badge'] as String,
                          style: TextStyle(fontSize: 10, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 12 QUICK ACTION TILES (Replicating Kobopay .qtiles)
  Widget _buildQuickActionsGrid(bool isDesktop, bool isDark) {
    final actions = [
      {'label': 'Airtime', 'icon': Icons.phone_android_rounded, 'color': AppColors.primaryCyan, 'route': '/services/airtime'},
      {'label': 'Data', 'icon': Icons.wifi_rounded, 'color': AppColors.success, 'route': '/services/data'},
      {'label': 'Cable TV', 'icon': Icons.tv_rounded, 'color': Colors.pink, 'route': '/services/tv'},
      {'label': 'Electricity', 'icon': Icons.bolt_rounded, 'color': AppColors.warning, 'route': '/services/electricity'},
      {'label': 'Result pins', 'icon': Icons.school_rounded, 'color': Colors.cyan, 'route': '/services/exam_pin'},
      {'label': 'Printing', 'icon': Icons.print_rounded, 'color': Colors.deepPurple, 'route': '/services/airtime'},
      {'label': 'Fund', 'icon': Icons.account_balance_wallet_rounded, 'color': Colors.teal, 'route': '/wallet/fund'},
      {'label': 'Transfer', 'icon': Icons.swap_horiz_rounded, 'color': Colors.indigo, 'route': '/dashboard'},
      {'label': 'History', 'icon': Icons.receipt_long_rounded, 'color': AppColors.primaryBlue, 'route': '/transactions'},
      {'label': 'Referrals', 'icon': Icons.group_add_rounded, 'color': Colors.amber, 'route': '/dashboard'},
      {'label': 'Bulk SMS', 'icon': Icons.campaign_rounded, 'color': Colors.blueGrey, 'route': '/services/airtime', 'isAddon': true},
      {'label': 'Betting', 'icon': Icons.sports_soccer_rounded, 'color': Colors.orange, 'route': '/services/betting', 'isAddon': true},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = isDesktop ? 6 : (constraints.maxWidth > 600 ? 4 : 3);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: actions.length,
          itemBuilder: (context, idx) {
            final a = actions[idx];
            final isAddon = a['isAddon'] == true;
            return InkWell(
              onTap: () => _onServiceSelected(a['route'] as String),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAddon)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Add-on', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.warning)),
                      ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: (a['color'] as Color).withValues(alpha: 0.15),
                      child: Icon(a['icon'] as IconData, size: 20, color: a['color'] as Color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a['label'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // RECENT TRANSACTIONS (Replicating Kobopay recent table)
  Widget _buildRecentTransactionsCard(WalletProvider wallet, bool isDark) {
    final recent = [
      {'service': 'MTN 10GB SME', 'sub': '0803 411 9920', 'ref': 'AV-8841207', 'amt': '-₦3,400.00', 'status': 'Delivered', 'time': '12:41', 'icon': Icons.wifi, 'color': AppColors.success},
      {'service': 'Ikeja Electric Token', 'sub': 'Prepaid token', 'ref': 'AV-8841198', 'amt': '-₦5,000.00', 'status': 'Delivered', 'time': '12:18', 'icon': Icons.bolt, 'color': AppColors.warning},
      {'service': 'Wallet Funding', 'sub': 'Bank transfer (Providus)', 'ref': 'AV-8841150', 'amt': '+₦100,000.00', 'status': 'Credited', 'time': '11:52', 'icon': Icons.account_balance_wallet, 'color': Colors.teal},
      {'service': 'DStv Compact Bouquet', 'sub': 'Smartcard 7024118836', 'ref': 'AV-8841102', 'amt': '-₦19,000.00', 'status': 'Processing', 'time': '11:30', 'icon': Icons.tv, 'color': Colors.pink},
      {'service': 'Airtel Airtime', 'sub': '0908 877 6655', 'ref': 'AV-8841044', 'amt': '-₦2,000.00', 'status': 'Delivered', 'time': '10:57', 'icon': Icons.phone_android, 'color': AppColors.primaryCyan},
      {'service': 'WAEC Result PIN (x2)', 'sub': 'Quantity 2', 'ref': 'AV-8840987', 'amt': '-₦7,000.00', 'status': 'Refunded', 'time': '10:12', 'icon': Icons.school, 'color': Colors.grey},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: () => context.push('/transactions'),
                  child: Row(
                    children: [
                      Text('View all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryCyan),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Transaction rows
          ...recent.map((tx) {
            final isCredit = (tx['amt'] as String).startsWith('+');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: (tx['color'] as Color).withValues(alpha: 0.15),
                    child: Icon(tx['icon'] as IconData, size: 16, color: tx['color'] as Color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx['service'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(tx['sub'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      tx['ref'] as String,
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey, fontFamily: 'monospace'),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      tx['amt'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isCredit ? AppColors.success : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (tx['status'] == 'Delivered' || tx['status'] == 'Credited')
                              ? AppColors.success.withValues(alpha: 0.15)
                              : (tx['status'] == 'Processing' ? AppColors.warning.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tx['status'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: (tx['status'] == 'Delivered' || tx['status'] == 'Credited')
                                ? AppColors.success
                                : (tx['status'] == 'Processing' ? AppColors.warning : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(tx['time'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
