import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../responsive/responsive_layout.dart';
import '../supabase/supabase_service.dart';
import '../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_logo.dart';
import '../../widgets/logout_dialog.dart';

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
    final onToggleTheme = widget.onToggleTheme;
    if (onToggleTheme != null) {
      onToggleTheme();
    } else {
      context.read<ThemeProvider>().toggleTheme();
    }
  }

  int _getSelectedIndex() {
    final route = widget.currentRoute;
    if (route.startsWith('/services')) return 1;
    if (route.startsWith('/transactions') || route.startsWith('/history')) {
      return 2;
    }
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

  Future<void> _showDownloadApkModal() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String apkUrl = 'https://github.com/adevictorolu/Avotek/releases/latest/download/avotek.apk';
    String version = 'v1.2.0';

    try {
      final fetchedUrl = await SupabaseService.instance.getAppSetting('apk_download_url');
      if (fetchedUrl != null && fetchedUrl.trim().isNotEmpty) {
        apkUrl = fetchedUrl.trim();
      }
      final fetchedVer = await SupabaseService.instance.getAppSetting('apk_version');
      if (fetchedVer != null && fetchedVer.trim().isNotEmpty) {
        version = fetchedVer.trim();
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.android_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download Mobile App',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Android APK Package ($version)',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get the official Avotek Android app directly on your mobile device for lightning-fast recharge, biometric login, and instant push receipts.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Direct APK build verified for Android 8.0+',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: apkUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('APK download link copied to clipboard!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(
              'Copy Link',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(apkUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(
              'Download APK',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
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

    final userName = (auth.user?.name != null && auth.user!.name.isNotEmpty)
        ? auth.user!.name
        : ((auth.user?.email != null && auth.user!.email.isNotEmpty)
              ? auth.user!.email.split('@').first
              : 'User');
    final userInitials = userName.isNotEmpty
        ? userName
              .split(' ')
              .where((n) => n.isNotEmpty)
              .map((n) => n[0].toUpperCase())
              .take(2)
              .join()
        : 'U';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      drawer: !isDesktop
          ? _buildDrawer(context, isDark, auth, wallet, userName, userInitials)
          : null,
      appBar: !isDesktop
          ? AppBar(
              elevation: 0,
              backgroundColor: isDark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
              title: const AvotekLogo(size: 26, showText: true),
              actions: [
                IconButton(
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 20,
                  ),
                  onPressed: _handleThemeToggle,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                  ),
                  onPressed: () => context.push('/wallet'),
                ),
              ],
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            _buildDesktopSidebar(
              context,
              isDark,
              auth,
              wallet,
              userName,
              userInitials,
            ),
          Expanded(child: widget.child),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'avotek_support_assistant',
        tooltip: 'Avotek help',
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: _openSupportAssistant,
        child: const Icon(Icons.support_agent_rounded),
      ),
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: _getSelectedIndex(),
              onDestinationSelected: _onBottomNavTapped,
              backgroundColor: isDark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Services',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: 'Wallet',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_rounded),
                  selectedIcon: Icon(Icons.menu_rounded),
                  label: 'Menu',
                ),
              ],
            )
          : null,
    );
  }

  void _openSupportAssistant() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faqs = <(String, String)>[
      (
        'My transaction is pending',
        'Check Transactions before trying again. Do not repeat a pending purchase; '
            'contact support with its reference if the status does not update.',
      ),
      (
        'How do I reset my password?',
        'Sign out if needed, open Sign in, and use “Forgot password” with the '
            'email address on your account.',
      ),
      (
        'How do I fund my wallet?',
        'Only use a funding method shown as available inside Avotek. Never send '
            'money to an account number from an old screenshot or message.',
      ),
      (
        'How can I contact a person?',
        'Email support@avotek.ng and include your account email and transaction '
            'reference. Do not send your password, transaction PIN, or API token.',
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Avotek help',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quick answers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
              const SizedBox(height: 8),
              ...faqs.map(
                (faq) => ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  title: Text(
                    faq.$1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq.$2,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.45,
                          color: isDark
                              ? AppColors.metallicLight
                              : AppColors.slateGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Email support'),
                  onPressed: () async {
                    final uri = Uri(
                      scheme: 'mailto',
                      path: 'support@avotek.ng',
                      queryParameters: {'subject': 'Avotek support request'},
                    );
                    final opened = await launchUrl(uri);
                    if (!opened && sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No email app is available on this device.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
            child: const AvotekLogo(
              size: 38,
              showText: true,
              hasFrame: true,
              borderRadius: 14,
            ),
          ),

          // 2. Promotional Card: "Download Mobile App - Install Android APK ↗"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: InkWell(
              onTap: _showDownloadApkModal,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardVariant
                      : AppColors.lightCardVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.android_rounded,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download Mobile App',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Install Android APK',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.metallicLight
                                  : AppColors.slateGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.metallicLight
                          : AppColors.slateGrey,
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
                  isActive:
                      currentRoute.startsWith('/transactions') ||
                      currentRoute.startsWith('/history'),
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
                  icon: Icons.tv_rounded,
                  activeIcon: Icons.tv_rounded,
                  label: 'Subscriptions',
                  route: '/services/tv',
                  isActive: currentRoute == '/services/tv' ||
                      currentRoute.startsWith('/services/cable'),
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
                  color: isDark
                      ? const Color(0xFF1E2638)
                      : const Color(0xFFE2E8F0),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141824)
                          : const Color(0xFFF1F5F9),
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
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Regular',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: isDark
                                      ? AppColors.metallicLight
                                      : AppColors.slateGrey,
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
                        onTap: () async {
                          final confirmed = await showLogoutConfirmationDialog(context);
                          if (confirmed && context.mounted) {
                            await auth.signOut();
                            if (context.mounted) context.go('/login');
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              size: 16,
                              color: isDark
                                  ? AppColors.metallicLight
                                  : AppColors.slateGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDark ? 'Light' : 'Dark',
                              style: GoogleFonts.plusJakartaSans(
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
                ? (isDark
                      ? AppColors.primaryBlue.withValues(alpha: 0.15)
                      : const Color(0xFFEFF6FF))
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
                      ? (isDark
                            ? AppColors.electricCyan
                            : AppColors.primaryBlue)
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569)),
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
        child: _buildDesktopSidebar(
          context,
          isDark,
          auth,
          wallet,
          userName,
          userInitials,
        ),
      ),
    );
  }
}
