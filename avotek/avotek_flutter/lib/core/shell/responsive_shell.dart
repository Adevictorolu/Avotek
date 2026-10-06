import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../responsive/responsive_layout.dart';
import '../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_logo.dart';
import '../../widgets/global_search_dialog.dart';

class ResponsiveShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final VoidCallback onToggleTheme;

  const ResponsiveShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.onToggleTheme,
  });

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isRefreshing = false;

  int _getSelectedIndex() {
    final route = widget.currentRoute;
    if (route.startsWith('/services')) return 1;
    if (route.startsWith('/wallet')) return 2;
    if (route.startsWith('/transactions') || route.startsWith('/history')) return 3;
    if (route.startsWith('/profile') || route.startsWith('/settings')) return 4;
    return 0; // default Home
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/services/data');
        break;
      case 2:
        context.go('/wallet');
        break;
      case 3:
        context.go('/transactions');
        break;
      case 4:
        _scaffoldKey.currentState?.openDrawer();
        break;
    }
  }

  Future<void> _handleInAppRefresh() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.id != null) {
      setState(() => _isRefreshing = true);
      await context.read<WalletProvider>().fetchWallet(auth.user!.id!);
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Wallet & transactions refreshed!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();

    final userName = auth.user?.name ?? 'Customer';
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'AV';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F6F9),
      drawer: !isDesktop ? _buildDrawer(context, isDark, auth, wallet) : null,
      appBar: !isDesktop
          ? AppBar(
              elevation: 0,
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: const AvotekLogo(size: 38, isLarge: true),
              actions: [
                // In-App Refresh Button
                IconButton(
                  tooltip: 'In-App Refresh',
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan),
                        )
                      : const Icon(Icons.refresh_rounded, size: 22, color: AppColors.primaryCyan),
                  onPressed: _isRefreshing ? null : _handleInAppRefresh,
                ),
                // WhatsApp Chat
                IconButton(
                  tooltip: 'WhatsApp Support',
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF25D366)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connecting to WhatsApp Support (+234 803 411 9920)...', style: GoogleFonts.plusJakartaSans()),
                        backgroundColor: const Color(0xFF25D366),
                      ),
                    );
                  },
                ),
                // Theme Toggle
                IconButton(
                  tooltip: 'Toggle Theme',
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 20,
                  ),
                  onPressed: widget.onToggleTheme,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: InkWell(
                    onTap: () => context.push('/profile'),
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primaryBlue,
                      child: Text(
                        userInitials,
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: Row(
        children: [
          // Desktop Fixed Sidebar
          if (isDesktop) _buildDesktopSidebar(context, isDark, auth, wallet),

          // Main View Canvas
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildDesktopTopBar(context, isDark, auth, userName, userInitials),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: _getSelectedIndex(),
              onDestinationSelected: _onBottomNavTapped,
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              elevation: 4,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bolt_outlined),
                  selectedIcon: Icon(Icons.bolt_rounded),
                  label: 'Services',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Wallet',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_rounded),
                  selectedIcon: Icon(Icons.menu_rounded),
                  label: 'More',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildDesktopTopBar(
    BuildContext context,
    bool isDark,
    AuthProvider auth,
    String userName,
    String userInitials,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Quick Search Button
          InkWell(
            onTap: () => GlobalSearchDialog.show(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Search data, airtime, cable, tokens...',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // WhatsApp Support Button
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Connecting to WhatsApp Support (+234 803 411 9920)...', style: GoogleFonts.plusJakartaSans()),
                  backgroundColor: const Color(0xFF25D366),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF25D366)),
            label: Text(
              'WhatsApp Support',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF25D366),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 14),

          // In-App Refresh Button
          IconButton(
            tooltip: 'In-App Refresh',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan),
                  )
                : const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primaryCyan),
            onPressed: _isRefreshing ? null : _handleInAppRefresh,
          ),
          const SizedBox(width: 4),

          // Theme Toggle
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 4),

          // Notifications
          IconButton(
            tooltip: 'Notifications',
            icon: Stack(
              children: [
                Icon(Icons.notifications_none_rounded, size: 22, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryCyan),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All services operating normally. 99.9% uptime.', style: GoogleFonts.plusJakartaSans()),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // User Profile Pill
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      userInitials,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    userName,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    bool isDark,
    AuthProvider auth,
    WalletProvider wallet,
  ) {
    final currentRoute = widget.currentRoute;
    final userName = auth.user?.name ?? 'Adevictorolu';

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0F15) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E222D) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          // 1. Sidebar Brand with Rounded Container, Border Radius, AVOTEK, and << Collapse Icon
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14171E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFFD4AF37).withOpacity(0.35) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    isDark ? 'assets/images/logo.png' : 'assets/images/logo_light.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Bilalsadasub',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.keyboard_double_arrow_left_rounded, size: 18),
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // 2. User Profile Pill (Avatar, ADEVICTOROLU, SMART badge)
          InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161922) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFF1E293B),
                    child: const Icon(Icons.person, color: Color(0xFF00A3FF), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'SMART',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5A623), // Golden amber badge
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Nav Items Scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _buildSidebarGroup('MAIN'),
                _buildSidebarItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  route: '/dashboard',
                  isActive: currentRoute == '/dashboard' || currentRoute == '/',
                ),
                _buildSidebarItem(
                  icon: Icons.send_rounded,
                  label: 'Send To User',
                  route: '/wallet',
                  isActive: currentRoute == '/wallet/transfer',
                ),
                _buildSidebarItem(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Withdraw',
                  route: '/wallet',
                  isActive: currentRoute == '/wallet/withdraw',
                ),
                _buildSidebarItem(
                  icon: Icons.credit_card_rounded,
                  label: 'Virtual Cards',
                  route: '/wallet',
                  isActive: false,
                ),
                _buildSidebarItem(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Fund Wallet',
                  route: '/wallet/fund',
                  isActive: currentRoute == '/wallet/fund',
                  hasChevron: true,
                ),

                const SizedBox(height: 14),
                _buildSidebarGroup('PAY & RECHARGE'),
                _buildSidebarItem(
                  icon: Icons.wifi_rounded,
                  label: 'Buy Data',
                  route: '/services/data',
                  isActive: currentRoute == '/services/data',
                ),
                _buildSidebarItem(
                  icon: Icons.phone_android_rounded,
                  label: 'Buy Airtime',
                  route: '/services/airtime',
                  isActive: currentRoute == '/services/airtime',
                ),
                _buildSidebarItem(
                  icon: Icons.sync_alt_rounded,
                  label: 'Airtime to Cash',
                  route: '/services/airtime',
                  isActive: false,
                ),
                _buildSidebarItem(
                  icon: Icons.flash_on_rounded,
                  label: 'Electricity',
                  route: '/services/electricity',
                  isActive: currentRoute == '/services/electricity',
                ),
                _buildSidebarItem(
                  icon: Icons.tv_rounded,
                  label: 'Cable TV',
                  route: '/services/tv',
                  isActive: currentRoute == '/services/tv',
                ),
                _buildSidebarItem(
                  icon: Icons.sms_rounded,
                  label: 'Bulk SMS',
                  route: '/services/airtime',
                  isActive: false,
                ),
                _buildSidebarItem(
                  icon: Icons.school_rounded,
                  label: 'Education',
                  route: '/exams',
                  isActive: currentRoute == '/exams',
                ),

                const SizedBox(height: 14),
                _buildSidebarGroup('INTERNATIONAL & STORES'),
                _buildSidebarItem(
                  icon: Icons.sim_card_rounded,
                  label: 'eSIM',
                  route: '/services/data',
                  isActive: false,
                ),
                _buildSidebarItem(
                  icon: Icons.flight_takeoff_rounded,
                  label: 'Flight',
                  route: '/services/data',
                  isActive: false,
                ),
                _buildSidebarItem(
                  icon: Icons.price_change_outlined,
                  label: 'Wholesale Rates',
                  route: '/rates',
                  isActive: currentRoute == '/rates',
                ),
                if (auth.isSuperAdmin) ...[
                  const SizedBox(height: 14),
                  _buildSidebarGroup('MANAGEMENT'),
                  _buildSidebarItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Console',
                    route: '/admin',
                    isActive: currentRoute == '/admin',
                  ),
                ],
              ],
            ),
          ),

          // Sidebar Footer with Sign Out
          const Divider(height: 1, color: Color(0xFF1E222D)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: InkWell(
              onTap: () {
                auth.signOut();
                context.go('/login');
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(
                      'Sign out',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarGroup(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    bool hasChevron = false,
    String? badgeText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Active pill container with golden amber border matching Bilal Sub
    final activeBg = isDark ? const Color(0xFF171A22) : const Color(0xFFFEF3C7);
    final activeBorderColor = const Color(0xFFD4AF37);
    final activeColor = isDark ? const Color(0xFFF5A623) : const Color(0xFFB45309);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: activeBorderColor, width: 1.2)
                  : Border.all(color: Colors.transparent, width: 1.2),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isActive ? activeColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                    ),
                  ),
                ),
                if (hasChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    bool isDark,
    AuthProvider auth,
    WalletProvider wallet,
  ) {
    final userName = auth.user?.name ?? 'Customer';
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'AV';

    return Drawer(
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
                const AvotekLogo(size: 38, isLarge: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryBlue,
                      child: Text(
                        userInitials,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          'Active Reseller',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.primaryCyan, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          _drawerSection('MAIN SERVICES'),
          _drawerItem(Icons.grid_view_rounded, 'Dashboard', '/dashboard'),
          _drawerItem(Icons.wifi_rounded, 'Buy Data', '/services/data'),
          _drawerItem(Icons.phone_android_rounded, 'Buy Airtime', '/services/airtime'),
          _drawerItem(Icons.flash_on_rounded, 'Electricity Bills', '/services/electricity'),
          _drawerItem(Icons.school_rounded, 'Exam PINs (WAEC/JAMB)', '/services/exam_pin'),
          _drawerItem(Icons.corporate_fare_rounded, 'CAC Registration', '/services/cac'),

          _drawerSection('FINANCE & ACCOUNT'),
          _drawerItem(Icons.add_card_rounded, 'Fund Wallet', '/wallet/fund'),
          _drawerItem(Icons.account_balance_wallet_rounded, 'My Wallet', '/wallet'),
          _drawerItem(Icons.receipt_long_rounded, 'Transactions', '/transactions'),
          _drawerItem(Icons.price_change_outlined, 'Wholesale Pricing', '/rates'),
          _drawerItem(Icons.person_outline_rounded, 'Profile & Settings', '/profile'),
          if (auth.isSuperAdmin)
            _drawerItem(
              Icons.admin_panel_settings_rounded,
              'Admin Console',
              '/admin',
            ),

          const Divider(),
          _drawerItem(Icons.logout_rounded, 'Sign out', '/login', isDestructive: true),
        ],
      ),
    );
  }

  Widget _drawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, String route, {bool isDestructive = false}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: isDestructive ? AppColors.error : Colors.grey),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : null,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (isDestructive) {
          context.read<AuthProvider>().signOut();
          context.go('/login');
        } else {
          context.go(route);
        }
      },
    );
  }
}
