import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../responsive/responsive_layout.dart';
import '../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/education_provider.dart';
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

  int _getSelectedIndex() {
    final route = widget.currentRoute;
    if (route.startsWith('/learn')) return 1;
    if (route.startsWith('/exams')) return 2;
    if (route.startsWith('/wallet')) return 3;
    if (route.startsWith('/profile') || route.startsWith('/more') || route.startsWith('/settings')) return 4;
    return 0; // default Home
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/learn');
        break;
      case 2:
        context.go('/exams');
        break;
      case 3:
        context.go('/wallet');
        break;
      case 4:
        _scaffoldKey.currentState?.openDrawer();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final edu = context.watch<EducationProvider>();

    final userName = auth.user?.name ?? edu.profile.fullName;
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'CO';
    final studentBadge = edu.studentStatusBadge;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      drawer: !isDesktop ? _buildDrawer(context, isDark, auth, edu) : null,
      appBar: !isDesktop
          ? AppBar(
              elevation: 0,
              backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: const AvotekLogo(size: 26, showText: true),
              actions: [
                IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.search_rounded, size: 22),
                  onPressed: () => GlobalSearchDialog.show(context),
                ),
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
                      radius: 15,
                      backgroundColor: AppColors.primaryBlue,
                      child: Text(
                        userInitials,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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
          if (isDesktop) _buildDesktopSidebar(context, isDark, auth, edu),

          // Main View Canvas
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildDesktopTopBar(context, isDark, auth, edu, userName, userInitials, studentBadge),
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
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Learn',
                ),
                NavigationDestination(
                  icon: Icon(Icons.school_outlined),
                  selectedIcon: Icon(Icons.school_rounded),
                  label: 'Exams',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Wallet',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz_rounded),
                  selectedIcon: Icon(Icons.more_horiz_rounded),
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
    EducationProvider edu,
    String userName,
    String userInitials,
    String studentBadge,
  ) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Search Input Button
          InkWell(
            onTap: () => GlobalSearchDialog.show(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 18, color: Colors.grey),
                  SizedBox(width: 10),
                  Text(
                    'Search subjects, exams, questions...',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // Student Mode Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F5F1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD2EBE3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school, size: 14, color: Color(0xFF0E7C66)),
                const SizedBox(width: 6),
                Text(
                  edu.profile.isStudentMode ? 'Education First' : 'General User',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0E7C66),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

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

          // Notifications
          IconButton(
            tooltip: 'Academic Reminders',
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
                const SnackBar(content: Text('Academic Reminder: WAEC registration deadline is approaching!')),
              );
            },
          ),
          const SizedBox(width: 12),

          // User Profile Pill
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardVariant : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      userInitials,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        studentBadge,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
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
    EducationProvider edu,
  ) {
    final currentRoute = widget.currentRoute;

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          // Sidebar Brand
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            alignment: Alignment.centerLeft,
            child: const AvotekLogo(size: 32, showText: true),
          ),
          const Divider(height: 1),

          // Nav Items Scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              children: [
                _buildSidebarGroup('LEARNING JOURNEY'),
                _buildSidebarItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Home',
                  route: '/dashboard',
                  isActive: currentRoute == '/dashboard' || currentRoute == '/',
                ),
                _buildSidebarItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Learn & Practice',
                  route: '/learn',
                  isActive: currentRoute.startsWith('/learn') && !currentRoute.contains('progress'),
                ),
                _buildSidebarItem(
                  icon: Icons.school_rounded,
                  label: 'Exam Centre',
                  route: '/exams',
                  isActive: currentRoute.startsWith('/exams'),
                  badgeText: 'Tokens',
                ),
                _buildSidebarItem(
                  icon: Icons.trending_up_rounded,
                  label: 'My Progress',
                  route: '/learn/progress',
                  isActive: currentRoute == '/learn/progress',
                ),

                const SizedBox(height: 16),
                _buildSidebarGroup('WALLET & CONNECT'),
                _buildSidebarItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Student Wallet',
                  route: '/wallet',
                  isActive: currentRoute == '/wallet' || currentRoute == '/wallet/fund',
                ),
                _buildSidebarItem(
                  icon: Icons.phone_android_rounded,
                  label: 'Buy Airtime',
                  route: '/services/airtime',
                  isActive: currentRoute == '/services/airtime',
                ),
                _buildSidebarItem(
                  icon: Icons.wifi_rounded,
                  label: 'Buy Study Data',
                  route: '/services/data',
                  isActive: currentRoute == '/services/data',
                ),
                _buildSidebarItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Transactions',
                  route: '/transactions',
                  isActive: currentRoute == '/transactions' || currentRoute == '/history',
                ),

                const SizedBox(height: 16),
                _buildSidebarGroup('ACCOUNT & PREP'),
                _buildSidebarItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Student Profile',
                  route: '/profile',
                  isActive: currentRoute == '/profile',
                ),
                _buildSidebarItem(
                  icon: Icons.price_change_outlined,
                  label: 'Pricing & Rates',
                  route: '/rates',
                  isActive: currentRoute == '/rates',
                ),
                _buildSidebarItem(
                  icon: Icons.groups_outlined,
                  label: 'Study Groups',
                  route: '/community',
                  isActive: currentRoute == '/community',
                ),
                if (auth.isSuperAdmin)
                  _buildSidebarItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Console',
                    route: '/admin',
                    isActive: currentRoute == '/admin',
                  ),
              ],
            ),
          ),

          // Sidebar Footer
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      auth.signOut();
                      context.go('/login');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Sign out', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
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

  Widget _buildSidebarGroup(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    String? badgeText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark
        ? AppColors.primaryBlue.withValues(alpha: 0.15)
        : const Color(0xFFEFF6FF);
    final activeColor = AppColors.primaryBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isActive ? activeColor : (isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? activeColor : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F6EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
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
    EducationProvider edu,
  ) {
    final userName = auth.user?.name ?? edu.profile.fullName;
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'CO';

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
                const AvotekLogo(size: 28, showText: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryBlue,
                      child: Text(
                        userInitials,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(edu.studentStatusBadge, style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          _drawerSection('LEARNING'),
          _drawerItem(Icons.grid_view_rounded, 'Home', '/dashboard'),
          _drawerItem(Icons.menu_book_rounded, 'Learn & Practice', '/learn'),
          _drawerItem(Icons.school_rounded, 'Exam Centre (WAEC/JAMB/NECO)', '/exams'),
          _drawerItem(Icons.trending_up_rounded, 'My Progress', '/learn/progress'),

          _drawerSection('WALLET & CONNECTIVITY'),
          _drawerItem(Icons.account_balance_wallet_rounded, 'Student Wallet', '/wallet'),
          _drawerItem(Icons.phone_android_rounded, 'Buy Airtime', '/services/airtime'),
          _drawerItem(Icons.wifi_rounded, 'Buy Study Data', '/services/data'),
          _drawerItem(Icons.receipt_long_rounded, 'Transactions', '/transactions'),

          _drawerSection('ACCOUNT & PREP'),
          _drawerItem(Icons.person_outline_rounded, 'Student Profile', '/profile'),
          _drawerItem(Icons.price_change_outlined, 'Rates & Tariffs', '/rates'),
          _drawerItem(Icons.groups_outlined, 'Study Groups & Community', '/community'),
          if (auth.isSuperAdmin)
            _drawerItem(Icons.admin_panel_settings_rounded, 'Admin Console', '/admin'),

          const Divider(),
          _drawerItem(Icons.logout_rounded, 'Sign out', '/login', isDestructive: true),
        ],
      ),
    );
  }

  Widget _drawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.error : null,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // close drawer
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
