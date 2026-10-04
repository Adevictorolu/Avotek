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
import '../../providers/education_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_card.dart';
import '../../widgets/daily_challenge_card.dart';
import '../../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const DashboardScreen({super.key, required this.onToggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  void _showTransferDialog() {
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppColors.primaryBlue),
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
              decoration: const InputDecoration(labelText: 'Amount (₦)', hintText: 'e.g. 2000'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
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
    final edu = context.watch<EducationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final rawName = auth.user?.name ?? edu.profile.fullName;
    final firstName = rawName.split(' ').first;
    final studentStatus = edu.studentStatusBadge;

    final accountNumber = wallet.walletSummary?.virtualAccountNumber ?? '2205178431';
    final bankName = wallet.walletSummary?.virtualAccountBank ?? 'Providus Bank';

    return ResponsiveShell(
      currentRoute: '/dashboard',
      onToggleTheme: widget.onToggleTheme,
      child: RefreshIndicator(
        onRefresh: () async {
          if (auth.user?.id != null) {
            await wallet.fetchWallet(auth.user!.id!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AdaptiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. GREETING & STUDENT STATUS
                _buildGreetingSection(firstName, studentStatus, isDark, edu.profile.isStudentMode),
                const SizedBox(height: 20),

                // 2. ACADEMIC REMINDER BANNER
                _buildAcademicReminderBanner(isDark),
                const SizedBox(height: 24),

                // 3. STUDENT WALLET CARD
                _buildStudentWalletCard(wallet, accountNumber, bankName, isDark),
                const SizedBox(height: 28),

                // 4. STUDENT SERVICES (Primary Education Hub)
                _buildSectionTitle(
                  title: 'Student Services',
                  subtitle: 'Examination preparation, question practice, and progress analytics',
                  trailingText: 'Education First',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildStudentServicesGrid(isDesktop, isDark),
                const SizedBox(height: 32),

                // 5. TODAY'S CHALLENGE (Interactive Academic Engagement)
                const DailyChallengeCard(),
                const SizedBox(height: 32),

                // 6. STAY CONNECTED (Secondary VTU & Utilities)
                _buildSectionTitle(
                  title: 'Stay Connected',
                  subtitle: 'Student airtime, research data bundles, and essential utilities',
                  trailingText: 'Instant Delivery',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildStayConnectedGrid(isDesktop, isDark),
                const SizedBox(height: 36),

                // 7. RECENT ACTIVITY (Blended Learning & Utilities Activity)
                _buildRecentActivitySection(wallet, edu, isDark, isDesktop),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(String firstName, String studentStatus, bool isDark, bool isStudentMode) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$timeGreeting, $firstName',
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                StatusBadge.academic(studentStatus),
                const SizedBox(width: 8),
                Text(
                  '• Academic Session 2026/2027',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcademicReminderBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF59E0B),
            ),
            child: const Icon(Icons.campaign, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Notice: WAEC & JAMB 2026 Registration is Ongoing',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Obtain your official examination registration PINs and result tokens directly from the Exam Centre.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF92400E)),
            onPressed: () => context.push('/exams'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Get PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Icon(Icons.arrow_forward, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentWalletCard(
    WalletProvider wallet,
    String accountNumber,
    String bankName,
    bool isDark,
  ) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final formattedBalance = currencyFormat.format(wallet.balance);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF0A66C2), const Color(0xFF0052A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A66C2).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top balance row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Student Wallet Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      wallet.isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    onPressed: wallet.toggleBalanceVisibility,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Zero-Fee Topup',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Balance Display
          Text(
            wallet.isBalanceVisible ? '₦$formattedBalance' : '₦ • • • • • •',
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Primary Actions
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0A66C2),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => context.push('/wallet/fund'),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Fund Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showTransferDialog,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Transfer', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showWithdrawDialog,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bottom Dedicated Account Foot (Matching Meridian high-trust pattern)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Dedicated NUBAN Account',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              accountNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: accountNumber));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Account number copied to clipboard!')),
                                );
                              },
                              child: const Icon(Icons.copy, color: Colors.white70, size: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bankName,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Instant Automatic Credit',
                      style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10, fontWeight: FontWeight.w600),
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

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required String trailingText,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
              ),
            ),
          ],
        ),
        Text(
          trailingText,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentServicesGrid(bool isDesktop, bool isDark) {
    final services = [
      {
        'title': 'Exam Centre',
        'subtitle': 'WAEC, JAMB, NECO & NABTEB tokens',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF0070F3),
        'route': '/exams',
        'badge': 'Tokens',
      },
      {
        'title': 'Practice Questions',
        'subtitle': 'Over 2,500+ CBT past questions',
        'icon': Icons.quiz_rounded,
        'color': const Color(0xFF10B981),
        'route': '/learn/practice',
        'badge': 'CBT Test',
      },
      {
        'title': 'Study Materials',
        'subtitle': 'Syllabus, topics & revision notes',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF8B5CF6),
        'route': '/learn',
        'badge': 'Notes',
      },
      {
        'title': 'My Progress',
        'subtitle': 'Subject mastery, streaks & scores',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFFF59E0B),
        'route': '/learn/progress',
        'badge': 'Analytics',
      },
    ];

    final columns = isDesktop ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: isDesktop ? 1.5 : 1.25,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        final serviceColor = s['color'] as Color;

        return AvotekCard(
          padding: const EdgeInsets.all(16),
          onTap: () => context.push(s['route'] as String),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: serviceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s['icon'] as IconData, color: serviceColor, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: serviceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      s['badge'] as String,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: serviceColor),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['title'] as String,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['subtitle'] as String,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStayConnectedGrid(bool isDesktop, bool isDark) {
    final connectivity = [
      {
        'title': 'Student Airtime',
        'subtitle': 'Instant discount recharge on all networks',
        'icon': Icons.phone_android_rounded,
        'color': const Color(0xFF0070F3),
        'route': '/services/airtime',
      },
      {
        'title': 'Study Data Bundles',
        'subtitle': 'SME & Gifting plans for online research',
        'icon': Icons.wifi_rounded,
        'color': const Color(0xFF059669),
        'route': '/services/data',
      },
      {
        'title': 'Electricity Bills',
        'subtitle': 'Prepaid tokens & meter settlement',
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFFF59E0B),
        'route': '/services/electricity',
      },
      {
        'title': 'Cable Subscriptions',
        'subtitle': 'DStv, GOtv, Startimes renewals',
        'icon': Icons.tv_rounded,
        'color': const Color(0xFFEC4899),
        'route': '/services/tv',
      },
    ];

    final columns = isDesktop ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: isDesktop ? 1.6 : 1.3,
      ),
      itemCount: connectivity.length,
      itemBuilder: (context, index) {
        final c = connectivity[index];
        final color = c['color'] as Color;

        return AvotekCard(
          padding: const EdgeInsets.all(16),
          onTap: () => context.push(c['route'] as String),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(c['icon'] as IconData, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['title'] as String,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c['subtitle'] as String,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitySection(
    WalletProvider wallet,
    EducationProvider edu,
    bool isDark,
    bool isDesktop,
  ) {
    // Blended activity: recent practice test + recent financial orders
    final activities = [
      {
        'type': 'practice',
        'title': 'Mathematics Practice Quiz',
        'meta': 'Score: 8/10 (80%) • JAMB Past Questions',
        'badge': '80% Score',
        'badgeType': 'success',
        'icon': Icons.quiz_rounded,
        'iconColor': const Color(0xFF10B981),
        'time': 'Today, 10:45 AM',
      },
      {
        'type': 'exam',
        'title': 'WAEC Result Checker PIN (2026)',
        'meta': 'WR260194821 • Delivered to PIN Vault',
        'badge': 'Delivered',
        'badgeType': 'success',
        'icon': Icons.school_rounded,
        'iconColor': const Color(0xFF0070F3),
        'time': 'Yesterday, 3:20 PM',
      },
      {
        'type': 'data',
        'title': 'MTN SME 5.0GB Study Bundle',
        'meta': '0803 411 9920 • 30 Days Validity',
        'badge': 'Delivered',
        'badgeType': 'success',
        'icon': Icons.wifi_rounded,
        'iconColor': const Color(0xFF059669),
        'time': 'Oct 2, 11:15 AM',
      },
      {
        'type': 'wallet',
        'title': 'Wallet Funding (Providus Bank)',
        'meta': 'Reference: SW-8841150 • Bank Transfer',
        'badge': '+₦25,000.00',
        'badgeType': 'success',
        'icon': Icons.account_balance_wallet_rounded,
        'iconColor': const Color(0xFF0A66C2),
        'time': 'Oct 1, 9:00 AM',
      },
    ];

    return AvotekCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/transactions'),
                  child: const Row(
                    children: [
                      Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 64),
            itemBuilder: (ctx, i) {
              final act = activities[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (act['iconColor'] as Color).withValues(alpha: 0.12),
                  child: Icon(act['icon'] as IconData, color: act['iconColor'] as Color, size: 20),
                ),
                title: Text(
                  act['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  act['meta'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge.success(act['badge'] as String),
                    const SizedBox(height: 4),
                    Text(
                      act['time'] as String,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
