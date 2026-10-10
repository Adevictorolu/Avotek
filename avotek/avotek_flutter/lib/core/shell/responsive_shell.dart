import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../responsive/responsive_layout.dart';
import '../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_logo.dart';

class ResponsiveShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final VoidCallback? onToggleTheme;

  const ResponsiveShell({
    super.key,
    required this.child,
    required this.currentRoute,
    this.onToggleTheme,
  });

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleThemeToggle() {
    context.read<ThemeProvider>().toggleTheme();
    widget.onToggleTheme?.call();
  }

  int _getSelectedIndex() {
    final route = widget.currentRoute;
    if (route.startsWith('/services')) return 1;
    if (route.startsWith('/transactions') || route.startsWith('/history')) return 2;
    if (route.startsWith('/wallet')) return 3;
    if (route.startsWith('/profile')) return 4;
    return 0; // default Home
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/services');
        break;
      case 2:
        context.go('/transactions');
        break;
      case 3:
        context.go('/wallet');
        break;
      case 4:
        _scaffoldKey.currentState?.openDrawer();
        break;
    }
  }

  void _showOwnVtuWebsiteModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: AppColors.electricCyan),
            const SizedBox(width: 10),
            Text('Own a VTU Website', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get a fully branded automated VTU portal with your own domain, customized theme, and direct aggregator API connection in 24 hours.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.electricCyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.electricCyan, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Includes Mobile App + Web Admin + Supabase DB',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Our VTU team will contact you shortly!'), backgroundColor: AppColors.success),
              );
            },
            child: Text('Get Started', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
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
    final wallet = context.watch<WalletProvider>();

    final userName = (auth.user?.name != null && auth.user!.name.isNotEmpty) ? auth.user!.name : 'Ademola';
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'AV';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      drawer: !isDesktop ? _buildDrawer(context, isDark, auth, wallet, userName, userInitials) : null,
      appBar: !isDesktop
          ? AppBar(
              elevation: 0,
              backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              title: const AvotekLogo(size: 26, showText: true),
              actions: [
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 20,
                  ),
                  onPressed: _handleThemeToggle,
                ),
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                  onPressed: () => context.push('/wallet'),
                ),
              ],
            )
          : null,
      body: Row(
        children: [
          if (isDesktop) _buildDesktopSidebar(context, isDark, auth, wallet, userName, userInitials),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: _getSelectedIndex(),
              onDestinationSelected: _onBottomNavTapped,
              backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Services'),
                NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'History'),
                NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
                NavigationDestination(icon: Icon(Icons.menu_rounded), selectedIcon: Icon(Icons.menu_rounded), label: 'Menu'),
              ],
            )
          : null,
    );
  }

  // --- DESKTOP SIDEBAR (MATCHES SCREENSHOTS 1, 2, 3, 4, 5) ---
  Widget _buildDesktopSidebar(
    BuildContext context,
    bool isDark,
    AuthProvider auth,
    WalletProvider wallet,
    String userName,
    String userInitials,
  ) {
    final currentRoute = widget.currentRoute;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Brand Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
            child: Row(
              children: [
                const AvotekLogo(size: 32, showText: false),
                const SizedBox(width: 10),
                Text(
                  'Avotek',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(left: 2, top: 8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.electricCyan,
                  ),
                ),
              ],
            ),
          ),

          // 2. Promotional Card: "Own a VTU Website - Buy & start selling ↗"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: InkWell(
              onTap: _showOwnVtuWebsiteModal,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.electricCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.rocket_launch_rounded, color: AppColors.electricCyan, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Own a VTU Website',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Buy & start selling',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 14,
                      color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 3. Scrollable Navigation List (MENU, BUSINESS, ACCOUNT)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
                // --- SECTION: MENU ---
                _buildSectionLabel('MENU', isDark),
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  route: '/dashboard',
                  isActive: currentRoute == '/dashboard' || currentRoute == '/',
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Services',
                  route: '/services',
                  isActive: currentRoute.startsWith('/services'),
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'History',
                  route: '/transactions',
                  isActive: currentRoute.startsWith('/transactions') || currentRoute.startsWith('/history'),
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet',
                  route: '/wallet',
                  isActive: currentRoute.startsWith('/wallet'),
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.sync_rounded,
                  activeIcon: Icons.sync_rounded,
                  label: 'Subscriptions',
                  route: '/services/tv',
                  isActive: false,
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.credit_card_outlined,
                  activeIcon: Icons.credit_card_rounded,
                  label: 'Requests',
                  route: '/transactions',
                  isActive: false,
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.confirmation_number_outlined,
                  activeIcon: Icons.confirmation_number_rounded,
                  label: 'Coupons',
                  route: '/coupons',
                  isActive: currentRoute.startsWith('/coupons'),
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.card_giftcard_outlined,
                  activeIcon: Icons.card_giftcard_rounded,
                  label: 'Gifts',
                  route: '/gifts',
                  isActive: currentRoute.startsWith('/gifts'),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // --- SECTION: BUSINESS ---
                _buildSectionLabel('BUSINESS', isDark),
                _buildNavItem(
                  icon: Icons.bar_chart_rounded,
                  activeIcon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  route: '/stats',
                  isActive: currentRoute == '/stats',
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Affiliate',
                  route: '/affiliate',
                  isActive: currentRoute.startsWith('/affiliate'),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // --- SECTION: ACCOUNT ---
                _buildSectionLabel('ACCOUNT', isDark),
                _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  route: '/profile',
                  isActive: currentRoute == '/profile',
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  route: '/settings',
                  isActive: currentRoute == '/settings',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // 4. User Footer Card (Matches Screenshots 1, 2, 3, 4, 5)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // User info tile
                InkWell(
                  onTap: () => context.push('/profile'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141824) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(
                            userInitials,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Regular',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Logout & Theme Mode Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          auth.signOut();
                          context.go('/login');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.logout_rounded, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Logout',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _handleThemeToggle,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Row(
                          children: [
                            Icon(
                              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                              size: 16,
                              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDark ? 'Light' : 'Dark',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required bool isActive,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppColors.primaryBlue.withValues(alpha: 0.15) : const Color(0xFFEFF6FF))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppColors.primaryCyan.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 18,
                color: isActive
                    ? AppColors.electricCyan
                    : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? (isDark ? AppColors.electricCyan : AppColors.primaryBlue)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                ),
              ),
            ],
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
    String userName,
    String userInitials,
  ) {
    return Drawer(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: SafeArea(
        child: _buildDesktopSidebar(context, isDark, auth, wallet, userName, userInitials),
      ),
    );
  }
}
