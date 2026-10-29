import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/shell/responsive_shell.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/avotek_loading_indicator.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static String get _projectUrl =>
      'https://supabase.com/dashboard/project/${SupabaseService.supabaseProjectRef}';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null && auth.isLoading) {
      return _shell(
        context,
        const Center(
          child: AvotekLoadingIndicator(logoSize: 34, strokeWidth: 3),
        ),
      );
    }

    if (user == null || !user.isAdmin) {
      return _shell(
        context,
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 44,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Admin access required',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Return to dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _shell(
      context,
      SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, user.email, isDark),
                      const SizedBox(height: 20),
                      _buildSecurityNotice(isDark),
                      const SizedBox(height: 26),
                      Text(
                        'Manage Avotek',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildTools(context, constraints.maxWidth, isDark),
                      const SizedBox(height: 26),
                      Text(
                        'Server configuration',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildServerTools(context, constraints.maxWidth, isDark),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _shell(BuildContext context, Widget child) {
    return ResponsiveShell(
      currentRoute: '/admin',
      onToggleTheme: () => context.read<ThemeProvider>().toggleTheme(),
      child: child,
    );
  }

  Widget _buildHeader(BuildContext context, String email, bool isDark) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 14,
      spacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin panel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              email,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppColors.slateGrey,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            IconButton(
              tooltip: isDark
                  ? 'Switch to light theme'
                  : 'Switch to dark theme',
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityNotice(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2434) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security_rounded, color: AppColors.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Provider credentials and privileged data must be managed on the '
              'secured Supabase backend. Never enter or store API secrets in '
              'Avotek or share them in chat. These links require a Supabase '
              'project account; the Avotek admin email alone does not grant '
              'Supabase project permissions.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white : AppColors.slateGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTools(BuildContext context, double width, bool isDark) {
    final tools = [
      _AdminTool(
        icon: Icons.miscellaneous_services_rounded,
        title: 'Services',
        description: 'Open Avotek’s airtime, data, and bill-payment services.',
        onTap: () => context.go('/services'),
      ),
      _AdminTool(
        icon: Icons.receipt_long_rounded,
        title: 'Transactions',
        description:
            'Review the transaction history available to this account.',
        onTap: () => context.go('/transactions'),
      ),
      _AdminTool(
        icon: Icons.person_outline_rounded,
        title: 'Account profile',
        description: 'View and update the signed-in administrator profile.',
        onTap: () => context.go('/profile'),
      ),
      _AdminTool(
        icon: Icons.settings_outlined,
        title: 'Account settings',
        description: 'Open the account’s security and preference settings.',
        onTap: () => context.go('/settings'),
      ),
    ];
    return _toolGrid(tools, width, isDark);
  }

  Widget _buildServerTools(
    BuildContext context,
    double width,
    bool isDark,
  ) {
    final tools = [
      _AdminTool(
        icon: Icons.key_rounded,
        title: 'Paystack mode & secrets',
        description:
            'Use PAYSTACK_SECRET_KEY for Test mode first. After every Test '
            'check passes, replace it with the Live secret in Supabase. '
            'This secure server-side step cannot be switched in the app.',
        onTap: () => _openExternal(
          context,
          Uri.parse('$_projectUrl/settings/functions'),
        ),
      ),
      _AdminTool(
        icon: Icons.functions_rounded,
        title: 'Edge Functions and logs',
        description:
            'Review deployments and logs for vtu-provider, '
            'paystack-payments, and identifier-login.',
        onTap: () => _openExternal(
          context,
          Uri.parse('$_projectUrl/functions'),
        ),
      ),
      _AdminTool(
        icon: Icons.payments_outlined,
        title: 'Paystack dashboard',
        description:
            'Webhook: ${SupabaseService.supabaseUrl}/functions/v1/'
            'paystack-payments. Callback: Avotek wallet/fund. Complete '
            'Test-mode checks before Live.',
        onTap: () => _openExternal(
          context,
          Uri.parse('https://dashboard.paystack.com/'),
        ),
      ),
      _AdminTool(
        icon: Icons.menu_book_outlined,
        title: 'Bigisub API documentation',
        description:
            'Open provider documentation for request fields and status '
            'contracts, including result-checker PINs, bulk SMS, and airtime '
            'PIN generation.',
        onTap: () => _openExternal(
          context,
          Uri.parse('https://rif.africa/technotronics/api/bigisub'),
        ),
      ),
      _AdminTool(
        icon: Icons.storage_rounded,
        title: 'Database and policies',
        description:
            'Open the Supabase project to manage database configuration and '
            'access policies.',
        onTap: () => _openExternal(context, Uri.parse('$_projectUrl/editor')),
      ),
      _AdminTool(
        icon: Icons.manage_accounts_outlined,
        title: 'Supabase authentication',
        description:
            'Manage authentication users and provider settings in the '
            'Supabase project.',
        onTap: () =>
            _openExternal(context, Uri.parse('$_projectUrl/auth/users')),
      ),
      _AdminTool(
        icon: Icons.checklist_rounded,
        title: 'Go-live checklist',
        description:
            'Review required migrations, endpoint checks, provider tests, and '
            'payment verification before enabling customer transactions.',
        onTap: () => _openExternal(
          context,
          Uri.parse(
            'https://github.com/Adevictorolu/Avotek/blob/main/docs/AVOTEK_GO_LIVE_STATUS.md',
          ),
        ),
      ),
    ];
    return _toolGrid(tools, width, isDark);
  }

  Widget _toolGrid(List<_AdminTool> tools, double width, bool isDark) {
    final count = width >= 900
        ? 3
        : width >= 620
        ? 2
        : 1;
    return GridView.builder(
      itemCount: tools.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 176,
      ),
      itemBuilder: (context, index) => _AdminToolCard(
        tool: tools[index],
        isDark: isDark,
      ),
    );
  }

  Future<void> _openExternal(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the Supabase dashboard.')),
      );
    }
  }
}

class _AdminTool {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AdminTool({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
}

class _AdminToolCard extends StatelessWidget {
  final _AdminTool tool;
  final bool isDark;

  const _AdminToolCard({required this.tool, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? const Color(0xFF1B2434) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tool.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(tool.icon, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: Text(
                        tool.description,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? Colors.white70 : AppColors.slateGrey,
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
