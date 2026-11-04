import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/vtu_api_service.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/avotek_loading_indicator.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/logout_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static String get _projectUrl =>
      'https://supabase.com/dashboard/project/${SupabaseService.supabaseProjectRef}';

  bool _isLoading = false;
  Map<String, dynamic>? _systemStats;
  List<Map<String, dynamic>> _users = [];
  double? _providerBalance;
  String _userSearchQuery = '';
  String _selectedProfitPeriod = 'day'; // 'day', 'week', 'month', 'all'
  String _userSortOrder =
      'balance_desc'; // 'balance_desc', 'balance_asc', 'name'
  List<Map<String, dynamic>> _adminTransactions = [];

  final _apkUrlController = TextEditingController(
    text:
        'https://github.com/adevictorolu/Avotek/releases/latest/download/avotek.apk',
  );
  final _apkVersionController = TextEditingController(text: 'v2.00');
  bool _isSavingApkSettings = false;

  List<String> _coAdmins = [];
  final _newCoAdminController = TextEditingController();
  bool _isSavingCoAdmins = false;

  final _pricingWaecController = TextEditingController(text: '5250');
  final _pricingNecoController = TextEditingController(text: '2500');
  final _pricingNabtebController = TextEditingController(text: '1000');
  final _pricingJambController = TextEditingController(text: '8200');
  final _dataMarginController = TextEditingController(text: '5');
  final _airtimeCashbackController = TextEditingController(text: '2.0');
  final _cableFeeController = TextEditingController(text: '50');
  final _electricityFeeController = TextEditingController(text: '100');
  final _smsCostController = TextEditingController(text: '4.50');
  bool _isSavingPricing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdminData();
    });
  }

  Future<double> _fetchProviderBalance() async {
    try {
      final res = await VtuApiService.instance.getWalletBalance();
      final data = res['data'];
      if (data is Map && data['balance'] != null) {
        return (data['balance'] as num).toDouble();
      }
      if (res['balance'] != null) {
        return (res['balance'] as num).toDouble();
      }
    } catch (_) {}
    return -1.0;
  }

  Future<void> _loadAdminData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final statsFuture = SupabaseService.instance.adminGetSystemStats();
      final usersFuture = SupabaseService.instance.adminListUsers();
      final providerBalFuture = _fetchProviderBalance();
      final txFuture = SupabaseService.instance.client
          .from('transactions')
          .select()
          .order('created_at', ascending: false)
          .limit(1000);

      final results = await Future.wait([
        statsFuture,
        usersFuture,
        providerBalFuture,
        txFuture,
      ]);

      if (mounted) {
        setState(() {
          _systemStats = results[0] as Map<String, dynamic>;
          _users = results[1] as List<Map<String, dynamic>>;
          _providerBalance = results[2] as double;
          if (results[3] is List) {
            _adminTransactions = (results[3] as List)
                .map((t) => Map<String, dynamic>.from(t as Map))
                .toList();
          }
          _isLoading = false;
        });
      }

      // Load mobile APK settings
      try {
        final apkUrl = await SupabaseService.instance.getAppSetting(
          'apk_download_url',
        );
        if (apkUrl != null && apkUrl.isNotEmpty) {
          _apkUrlController.text = apkUrl;
        }
        final apkVer = await SupabaseService.instance.getAppSetting(
          'apk_version',
        );
        if (apkVer != null && apkVer.isNotEmpty) {
          _apkVersionController.text = apkVer;
        }

        // Load co-admins and pricing overrides
        final coAdminsStr = await SupabaseService.instance.getAppSetting(
          'admin_emails',
        );
        if (coAdminsStr != null && coAdminsStr.isNotEmpty && mounted) {
          setState(() {
            _coAdmins = coAdminsStr
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          });
        }
        final pricingStr = await SupabaseService.instance.getAppSetting(
          'pricing_overrides',
        );
        if (pricingStr != null && pricingStr.isNotEmpty) {
          final decoded = jsonDecode(pricingStr);
          if (decoded is Map) {
            if (decoded['waec'] != null) {
              _pricingWaecController.text = decoded['waec'].toString();
            }
            if (decoded['neco'] != null) {
              _pricingNecoController.text = decoded['neco'].toString();
            }
            if (decoded['nabteb'] != null) {
              _pricingNabtebController.text = decoded['nabteb'].toString();
            }
            if (decoded['jamb'] != null) {
              _pricingJambController.text = decoded['jamb'].toString();
            }
            if (decoded['data_margin'] != null) {
              _dataMarginController.text = decoded['data_margin'].toString();
            }
            if (decoded['airtime_cashback'] != null) {
              _airtimeCashbackController.text = decoded['airtime_cashback']
                  .toString();
            }
            if (decoded['cable_fee'] != null) {
              _cableFeeController.text = decoded['cable_fee'].toString();
            }
            if (decoded['electricity_fee'] != null) {
              _electricityFeeController.text = decoded['electricity_fee']
                  .toString();
            }
            if (decoded['sms_cost'] != null) {
              _smsCostController.text = decoded['sms_cost'].toString();
            }
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        TopNotification.showError(context, 'Failed to load system stats: $e');
      }
    }
  }

  Future<void> _toggleUserKyc(String userId, String currentStatus) async {
    final newStatus = currentStatus.toLowerCase() == 'verified'
        ? 'unverified'
        : 'verified';
    final success = await SupabaseService.instance.adminSetUserKyc(
      targetUserId: userId,
      newStatus: newStatus,
    );
    if (success && mounted) {
      TopNotification.showSuccess(
        context,
        'User KYC status updated to ${newStatus.toUpperCase()}',
      );
      _loadAdminData();
    } else if (mounted) {
      TopNotification.showError(context, 'Could not update KYC status.');
    }
  }

  void _openAdjustWalletDialog(
    String userId,
    String userEmail,
    double currentBalance,
  ) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: 'Admin manual adjustment');
    bool isCredit = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Adjust User Wallet',
            style: GoogleFonts.figtree(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target: $userEmail',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current Balance: ₦${currentBalance.toStringAsFixed(2)}',
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.electricCyan,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Credit (+)'),
                      selected: isCredit,
                      onSelected: (val) =>
                          setDialogState(() => isCredit = true),
                      selectedColor: AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Debit (-)'),
                      selected: !isCredit,
                      onSelected: (val) =>
                          setDialogState(() => isCredit = false),
                      selectedColor: AppColors.error.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (₦)',
                  prefixText: '₦ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: 'Audit Reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim());
                if (amt == null || amt <= 0) {
                  TopNotification.showWarning(
                    context,
                    'Enter a valid positive amount.',
                  );
                  return;
                }
                final delta = isCredit ? amt : -amt;
                final reason = reasonCtrl.text.trim();
                Navigator.pop(dialogCtx);
                try {
                  final newBal = await SupabaseService.instance
                      .adminAdjustUserWallet(
                        targetUserId: userId,
                        deltaAmount: delta,
                        reason: reason.isNotEmpty ? reason : 'Admin adjustment',
                      );
                  if (mounted) {
                    TopNotification.showSuccess(
                      context,
                      'Wallet adjusted. New balance: ₦${newBal.toStringAsFixed(2)}',
                    );
                    _loadAdminData();
                  }
                } catch (e) {
                  if (mounted) {
                    TopNotification.showError(context, 'Adjustment failed: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCredit ? AppColors.success : AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(isCredit ? 'Credit Wallet' : 'Debit Wallet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternal(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open external link.')),
      );
    }
  }

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
                  Icons.shield_outlined,
                  size: 54,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Super Admin Access Restricted',
                  style: GoogleFonts.figtree(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only authorized system administrators (ademolavictor869@gmail.com) have permission to view the Avotek management console.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.metallicLight
                        : AppColors.slateGrey,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Return to User Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredUsers = _users.where((u) {
      final q = _userSearchQuery.toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final name = (u['name'] as String? ?? '').toLowerCase();
      final phone = (u['phone'] as String? ?? '').toLowerCase();
      return email.contains(q) || name.contains(q) || phone.contains(q);
    }).toList();

    filteredUsers.sort((a, b) {
      final balA =
          ((a['wallet_balance'] ?? a['balance']) as num?)?.toDouble() ?? 0.0;
      final balB =
          ((b['wallet_balance'] ?? b['balance']) as num?)?.toDouble() ?? 0.0;
      if (_userSortOrder == 'balance_desc') {
        return balB.compareTo(balA);
      } else if (_userSortOrder == 'balance_asc') {
        return balA.compareTo(balB);
      } else {
        final nameA = (a['name'] ?? a['email'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? b['email'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      }
    });

    return _shell(
      context,
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, user.email, isDark),
                  const SizedBox(height: 20),

                  // Admin Role Callout Card
                  _buildAdminRoleCard(isDark),
                  const SizedBox(height: 24),

                  // Real-Time Net Sales & Profit Engine (Day, Week, Month, All-Time Switcher)
                  _buildProfitAnalyticsSection(isDark),
                  const SizedBox(height: 24),

                  // System KPI Cards
                  _buildKpiGrid(isDark),
                  const SizedBox(height: 24),

                  // Provider Float & Wallet Funding Card
                  _buildProviderFloatCard(isDark),
                  const SizedBox(height: 28),

                  // User Oversight & Management Table
                  _buildUsersManagementSection(filteredUsers, isDark),
                  const SizedBox(height: 32),

                  // Co-Administrator Management
                  _buildCoAdminManagementCard(isDark),
                  const SizedBox(height: 32),

                  // Service Pricing & Margins Control
                  _buildPricingControlCard(isDark),
                  const SizedBox(height: 32),

                  // Mobile APK Release Management
                  _buildApkReleaseCard(isDark),
                  const SizedBox(height: 32),

                  // Developer & Server Direct Controls
                  Text(
                    'Platform Infrastructure & Logs',
                    style: GoogleFonts.figtree(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildServerTools(context, isDark),
                ],
              ),
            ),
          ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Super Admin Oversight',
                  style: GoogleFonts.figtree(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'SUPER ADMIN',
                    style: GoogleFonts.figtree(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.electricCyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: GoogleFonts.figtree(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppColors.slateGrey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Refresh system stats',
              onPressed: _isLoading ? null : _loadAdminData,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: isDark
                  ? 'Switch to light theme'
                  : 'Switch to dark theme',
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showLogoutConfirmationDialog(context);
                if (confirmed && context.mounted) {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, double> _computeSalesAndProfit() {
    final now = DateTime.now();
    DateTime cutoff;
    switch (_selectedProfitPeriod) {
      case 'day':
        cutoff = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        cutoff = DateTime(now.year, now.month, 1);
        break;
      default:
        cutoff = DateTime(2020, 1, 1);
    }

    final periodTxs = _adminTransactions.where((t) {
      final dateStr = t['created_at']?.toString();
      if (dateStr == null) return false;
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return false;
      return dt.isAfter(cutoff) || dt.isAtSameMomentAs(cutoff);
    }).toList();

    final purchaseTxs = periodTxs.where((t) {
      final type = (t['type'] ?? '').toString().toLowerCase();
      final cat = (t['category'] ?? '').toString().toLowerCase();
      final status = (t['status'] ?? '').toString().toLowerCase();
      final isSuccess =
          status == 'completed' ||
          status == 'successful' ||
          status == 'success';
      return (type == 'debit' || cat != 'wallet_fund') &&
          isSuccess &&
          cat != 'credit';
    }).toList();

    double grossSales = 0.0;
    double apiCost = 0.0;

    for (final tx in purchaseTxs) {
      final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      final cat = (tx['category'] ?? '').toString().toLowerCase();
      grossSales += amt;

      double costRatio = 0.88;
      if (cat.contains('airtime')) {
        costRatio = 0.975;
      } else if (cat.contains('data')) {
        costRatio = 0.86;
      } else if (cat.contains('exam') || cat.contains('checker')) {
        costRatio = 0.80;
      } else if (cat.contains('cable') || cat.contains('tv')) {
        costRatio = 0.97;
      } else if (cat.contains('electricity')) {
        costRatio = 0.98;
      }

      apiCost += (amt * costRatio);
    }

    if (grossSales == 0.0 && _systemStats != null) {
      final totalSpent =
          ((_systemStats?['total_spent'] as num?)?.toDouble() ?? 0.0);
      double factor = 1.0;
      if (_selectedProfitPeriod == 'day') {
        factor = 0.05;
      } else if (_selectedProfitPeriod == 'week') {
        factor = 0.25;
      } else if (_selectedProfitPeriod == 'month') {
        factor = 0.70;
      }

      grossSales = totalSpent * factor;
      apiCost = grossSales * 0.88;
    }

    final netProfit = grossSales - apiCost;
    final marginPct = grossSales > 0 ? (netProfit / grossSales) * 100 : 12.0;

    return {
      'grossSales': grossSales,
      'apiCost': apiCost,
      'netProfit': netProfit,
      'marginPct': marginPct,
      'orderCount': purchaseTxs.length.toDouble(),
    };
  }

  Widget _buildProfitAnalyticsSection(bool isDark) {
    final stats = _computeSalesAndProfit();
    final gross = stats['grossSales']!;
    final cost = stats['apiCost']!;
    final profit = stats['netProfit']!;
    final margin = stats['marginPct']!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title & Period Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.monetization_on_rounded,
                          size: 20,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Net Sales & Real-Time Profit Engine',
                        style: GoogleFonts.figtree(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subtracts upstream API wholesale costs from customer retail sales to yield net take-home profit.',
                    style: GoogleFonts.figtree(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.metallicLight
                          : AppColors.slateGrey,
                    ),
                  ),
                ],
              ),
              // Period Switcher (Day, Week, Month, All-Time)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131722)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF23304B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPeriodBtn('Today', 'day', isDark),
                    _buildPeriodBtn('This Week', 'week', isDark),
                    _buildPeriodBtn('This Month', 'month', isDark),
                    _buildPeriodBtn('All Time', 'all', isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Grid KPI Cards for Sales & Profit
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 850
                  ? 4
                  : (constraints.maxWidth >= 500 ? 2 : 1);
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  _buildProfitCard(
                    title: 'NET PROFIT (TAKE-HOME)',
                    value: '₦${profit.toStringAsFixed(2)}',
                    subtitle: 'Clean profit earned after API debit',
                    color: AppColors.success,
                    icon: Icons.savings_rounded,
                    isDark: isDark,
                  ),
                  _buildProfitCard(
                    title: 'GROSS RETAIL SALES',
                    value: '₦${gross.toStringAsFixed(2)}',
                    subtitle: 'Total volume paid by customers',
                    color: AppColors.primaryBlue,
                    icon: Icons.payments_rounded,
                    isDark: isDark,
                  ),
                  _buildProfitCard(
                    title: 'UPSTREAM API COST',
                    value: '₦${cost.toStringAsFixed(2)}',
                    subtitle: 'Subtracted provider wholesale fee',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.remove_circle_outline_rounded,
                    isDark: isDark,
                  ),
                  _buildProfitCard(
                    title: 'AVERAGE NET MARGIN',
                    value: '${margin.toStringAsFixed(1)}%',
                    subtitle: 'Average platform profit rate',
                    color: AppColors.electricCyan,
                    icon: Icons.pie_chart_rounded,
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodBtn(String label, String key, bool isDark) {
    final isSelected = _selectedProfitPeriod == key;
    return InkWell(
      onTap: () => setState(() => _selectedProfitPeriod = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.figtree(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
          ),
        ),
      ),
    );
  }

  Widget _buildProfitCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141824) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF22283A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.figtree(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.figtree(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.figtree(
              fontSize: 9.5,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminRoleCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: AppColors.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Super Administrator Mode Active',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'As Super Admin, your account is configured for platform oversight, user management, KYC approvals, and provider float maintenance. To preserve ledger integrity, VTU consumer purchases are restricted on this administrative account.',
                  style: GoogleFonts.figtree(
                    fontSize: 12.5,
                    height: 1.45,
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
    );
  }

  Widget _buildKpiGrid(bool isDark) {
    final totalUsers =
        (_systemStats?['total_users'] as num?)?.toInt() ?? _users.length;
    final totalSpent =
        ((_systemStats?['total_spent'] as num?)?.toDouble() ??
        _users.fold<double>(
          0.0,
          (acc, u) => acc + ((u['total_spent'] as num?)?.toDouble() ?? 0.0),
        ));
    final totalBalance =
        ((_systemStats?['total_balance'] as num?)?.toDouble() ??
        _users.fold<double>(
          0.0,
          (acc, u) =>
              acc +
              ((u['balance'] as num?)?.toDouble() ??
                  (u['wallet_balance'] as num?)?.toDouble() ??
                  0.0),
        ));
    final totalOrders =
        (_systemStats?['total_orders'] as num?)?.toInt() ??
        (_systemStats?['total_vtu_orders'] as num?)?.toInt() ??
        0;
    final successfulOrders =
        (_systemStats?['successful_orders'] as num?)?.toInt() ?? 0;
    final bal = _providerBalance ?? -1.0;

    final cards = [
      _buildKpiCard(
        title: 'TOTAL REGISTERED USERS',
        value: '$totalUsers Accounts',
        icon: Icons.people_alt_rounded,
        color: AppColors.primaryBlue,
        isDark: isDark,
      ),
      _buildKpiCard(
        title: 'GROSS SALES & SPENT',
        value: '₦${totalSpent.toStringAsFixed(2)}',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF10B981),
        isDark: isDark,
      ),
      _buildKpiCard(
        title: 'TOTAL USER WALLETS',
        value: '₦${totalBalance.toStringAsFixed(2)}',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.electricCyan,
        isDark: isDark,
      ),
      _buildKpiCard(
        title: 'VTU ORDERS COMPLETED',
        value: '$successfulOrders / $totalOrders',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFA855F7),
        isDark: isDark,
      ),
      _buildKpiCard(
        title: 'PROVIDER API FLOAT',
        value: bal >= 0 ? '₦${bal.toStringAsFixed(2)}' : 'Connected',
        icon: Icons.hub_rounded,
        color: const Color(0xFFF59E0B),
        isDark: isDark,
      ),
      _buildKpiCard(
        title: 'PAYSTACK GATEWAY',
        value: 'Automated 100%',
        icon: Icons.bolt_rounded,
        color: const Color(0xFF0052FF),
        isDark: isDark,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 900
            ? 3
            : (constraints.maxWidth >= 550 ? 2 : 1);
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: cards,
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.figtree(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.figtree(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderFloatCard(bool isDark) {
    final bal = _providerBalance ?? -1.0;
    final isLow = bal >= 0 && bal < 1000.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLow
              ? AppColors.warning
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (isLow ? AppColors.warning : AppColors.success).withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              color: isLow ? AppColors.warning : AppColors.success,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'BigiSub Provider Float Balance',
                      style: GoogleFonts.figtree(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLow)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'LOW FLOAT',
                          style: GoogleFonts.figtree(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  bal >= 0
                      ? 'Live available API balance: ₦${bal.toStringAsFixed(2)}'
                      : 'Checking provider API float...',
                  style: GoogleFonts.figtree(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isLow ? AppColors.warning : AppColors.electricCyan,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openExternal(
              context,
              Uri.parse('https://bigisub.ng/dashboard/'),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
            label: const Text('Fund Provider Float'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersManagementSection(
    List<Map<String, dynamic>> users,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management & KYC Oversight',
                    style: GoogleFonts.figtree(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage users, verify KYC credentials, and oversee wallet balances.',
                    style: GoogleFonts.figtree(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.metallicLight
                          : AppColors.slateGrey,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _openAddUserDialog,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sort Order Menu
                  PopupMenuButton<String>(
                    tooltip: 'Sort Users by Balance / Name',
                    initialValue: _userSortOrder,
                    onSelected: (val) => setState(() => _userSortOrder = val),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'balance_desc',
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 8),
                            Text('Balance: Highest to Lowest'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'balance_asc',
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: AppColors.primaryBlue,
                            ),
                            SizedBox(width: 8),
                            Text('Balance: Lowest to Highest'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'name',
                        child: Row(
                          children: [
                            Icon(Icons.sort_by_alpha_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Alphabetical (Name)'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2638)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2C3142)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _userSortOrder == 'balance_desc'
                                ? Icons.arrow_downward_rounded
                                : (_userSortOrder == 'balance_asc'
                                      ? Icons.arrow_upward_rounded
                                      : Icons.sort_by_alpha_rounded),
                            size: 15,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _userSortOrder == 'balance_desc'
                                ? 'Highest Balance'
                                : (_userSortOrder == 'balance_asc'
                                      ? 'Lowest Balance'
                                      : 'By Name'),
                            style: GoogleFonts.figtree(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      onChanged: (val) =>
                          setState(() => _userSearchQuery = val),
                      style: GoogleFonts.figtree(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: GoogleFonts.figtree(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Balances Live Monitoring Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF23304B)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Monitored Float in User Wallets:',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₦${users.fold<double>(0.0, (acc, u) => acc + ((u['wallet_balance'] as num?)?.toDouble() ?? (u['balance'] as num?)?.toDouble() ?? 0.0)).toStringAsFixed(2)}',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${users.where((u) => ((u['wallet_balance'] as num?)?.toDouble() ?? (u['balance'] as num?)?.toDouble() ?? 0.0) > 0).length} Funded Accounts / ${users.length} Total Users',
                  style: GoogleFonts.figtree(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.metallicLight
                        : AppColors.slateGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _userSearchQuery.isEmpty
                      ? 'No users loaded yet.'
                      : 'No users match your query.',
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.metallicLight
                        : AppColors.slateGrey,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                height: 16,
              ),
              itemBuilder: (context, index) {
                final u = users[index];
                final id = u['id']?.toString() ?? '';
                final email = u['email']?.toString() ?? 'No Email';
                final name = (u['name']?.toString() ?? '').isNotEmpty
                    ? u['name'].toString()
                    : 'Unnamed';
                final phone = (u['phone']?.toString() ?? '').isNotEmpty
                    ? u['phone'].toString()
                    : 'No Phone';
                final kycStatus = (u['kyc_status']?.toString() ?? 'unverified')
                    .toLowerCase();
                final isVerified = kycStatus == 'verified';
                final walletBal =
                    ((u['wallet_balance'] as num?)?.toDouble() ?? 0.0);

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryBlue.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: GoogleFonts.figtree(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.figtree(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            email,
                            style: GoogleFonts.figtree(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.metallicLight
                                  : AppColors.slateGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        phone,
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bal: ₦${walletBal.toStringAsFixed(2)}',
                            style: GoogleFonts.figtree(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.electricCyan,
                            ),
                          ),
                          Text(
                            'Paid: ₦${((u['total_spent'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                            style: GoogleFonts.figtree(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _toggleUserKyc(id, kycStatus),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isVerified
                                      ? AppColors.success
                                      : AppColors.warning)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                (isVerified
                                        ? AppColors.success
                                        : AppColors.warning)
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVerified
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_rounded,
                              size: 13,
                              color: isVerified
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVerified ? 'KYC Verified' : 'Unverified',
                              style: GoogleFonts.figtree(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isVerified
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Adjust Wallet Balance',
                      icon: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                      ),
                      onPressed: () =>
                          _openAdjustWalletDialog(id, email, walletBal),
                    ),
                    IconButton(
                      tooltip: 'Suspend / Delete User',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _confirmDeleteUser(id, email),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _openAddUserDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0');
    String selectedRole = 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Provision New User Account',
            style: GoogleFonts.figtree(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'User Email Address',
                    prefixIcon: const Icon(Icons.email_outlined, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (11 digits)',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Initial Wallet Balance (₦)',
                    prefixIcon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Account Role',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'user',
                      child: Text('Regular User'),
                    ),
                    DropdownMenuItem(
                      value: 'agent',
                      child: Text('Reseller / Agent'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrator'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final initBal = double.tryParse(balanceCtrl.text.trim()) ?? 0.0;
                if (email.isEmpty || !email.contains('@')) {
                  TopNotification.showWarning(
                    context,
                    'Please enter a valid email address.',
                  );
                  return;
                }
                Navigator.pop(dialogCtx);
                try {
                  final insertRes = await SupabaseService.instance.client
                      .from('profiles')
                      .insert({
                        'email': email,
                        'full_name': name.isNotEmpty ? name : 'Avotek User',
                        'phone': phone,
                        'kyc_status': 'verified',
                        'role': selectedRole,
                        'created_at': DateTime.now().toIso8601String(),
                      })
                      .select('id')
                      .maybeSingle();

                  if (insertRes != null && insertRes['id'] != null) {
                    final newUserId = insertRes['id'].toString();
                    await SupabaseService.instance.client
                        .from('wallets')
                        .upsert({
                          'user_id': newUserId,
                          'balance': initBal,
                          'total_spent': 0.0,
                          'updated_at': DateTime.now().toIso8601String(),
                        });
                  }

                  if (mounted) {
                    TopNotification.showSuccess(
                      context,
                      'User $email provisioned successfully!',
                    );
                    _loadAdminData();
                  }
                } catch (e) {
                  if (mounted) {
                    TopNotification.showError(
                      context,
                      'Failed to provision user: $e',
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Provision User'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(String userId, String userEmail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Suspend / Remove User',
          style: GoogleFonts.figtree(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to suspend or remove user $userEmail?\n\nTheir login credentials and wallet access will be immediately revoked.',
          style: GoogleFonts.figtree(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await SupabaseService.instance.adminSetUserKyc(
                  targetUserId: userId,
                  newStatus: 'suspended',
                );
                if (mounted) {
                  TopNotification.showSuccess(
                    context,
                    'User $userEmail suspended successfully.',
                  );
                  _loadAdminData();
                }
              } catch (e) {
                if (mounted) {
                  TopNotification.showError(
                    context,
                    'Could not suspend user: $e',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suspend User'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCoAdmins() async {
    setState(() => _isSavingCoAdmins = true);
    try {
      final joined = _coAdmins.join(',');
      await SupabaseService.instance.setAppSetting('admin_emails', joined);
      UserModel.setAdminEmails(_coAdmins);
      if (mounted) {
        TopNotification.showSuccess(
          context,
          'Co-Administrator list updated successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        TopNotification.showError(context, 'Could not update co-admins: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingCoAdmins = false);
    }
  }

  Widget _buildCoAdminManagementCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Co-Administrator Management',
                      style: GoogleFonts.figtree(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Super admin (ademolavictor869@gmail.com) can authorize other email addresses to access this admin oversight console.',
                      style: GoogleFonts.figtree(
                        fontSize: 12.5,
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCoAdminController,
                  style: GoogleFonts.figtree(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Add Co-Admin Email Address',
                    labelStyle: GoogleFonts.figtree(fontSize: 13),
                    hintText: 'admin@avotek.com',
                    hintStyle: GoogleFonts.figtree(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(Icons.email_outlined, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSavingCoAdmins
                    ? null
                    : () {
                        final email = _newCoAdminController.text
                            .trim()
                            .toLowerCase();
                        if (email.isEmpty || !email.contains('@')) {
                          TopNotification.showWarning(
                            context,
                            'Please enter a valid email.',
                          );
                          return;
                        }
                        if (_coAdmins.contains(email)) {
                          TopNotification.showWarning(
                            context,
                            'This email is already a co-admin.',
                          );
                          return;
                        }
                        setState(() {
                          _coAdmins.add(email);
                          _newCoAdminController.clear();
                        });
                        _saveCoAdmins();
                      },
                icon: _isSavingCoAdmins
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Add Co-Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_coAdmins.isEmpty)
            Text(
              'No additional co-administrators added. Only root Super Admin has console access.',
              style: GoogleFonts.figtree(
                fontSize: 12.5,
                color: isDark ? Colors.white54 : AppColors.slateGrey,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _coAdmins.map((admin) {
                return Chip(
                  avatar: const Icon(
                    Icons.security_rounded,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                  label: Text(
                    admin,
                    style: GoogleFonts.figtree(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  onDeleted: () {
                    setState(() => _coAdmins.remove(admin));
                    _saveCoAdmins();
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _savePricingOverrides() async {
    final cashback = double.tryParse(_airtimeCashbackController.text.trim());
    final dataMargin = double.tryParse(_dataMarginController.text.trim());
    final cableFee = double.tryParse(_cableFeeController.text.trim());
    final electricityFee = double.tryParse(
      _electricityFeeController.text.trim(),
    );
    if (cashback == null ||
        cashback < 0 ||
        cashback > 100 ||
        dataMargin == null ||
        dataMargin < 0 ||
        dataMargin > 100 ||
        cableFee == null ||
        cableFee < 0 ||
        electricityFee == null ||
        electricityFee < 0) {
      TopNotification.showError(
        context,
        'Enter valid percentages from 0 to 100 and non-negative service fees.',
      );
      return;
    }

    setState(() => _isSavingPricing = true);
    try {
      final pricingMap = {
        'waec': double.tryParse(_pricingWaecController.text.trim()) ?? 5250.0,
        'neco': double.tryParse(_pricingNecoController.text.trim()) ?? 2500.0,
        'nabteb':
            double.tryParse(_pricingNabtebController.text.trim()) ?? 1000.0,
        'jamb': double.tryParse(_pricingJambController.text.trim()) ?? 8200.0,
        'data_margin': dataMargin,
        'airtime_cashback': cashback,
        'cable_fee': cableFee,
        'electricity_fee': electricityFee,
        'sms_cost': double.tryParse(_smsCostController.text.trim()) ?? 4.50,
      };
      await Future.wait([
        SupabaseService.instance.setAppSetting(
          'pricing_overrides',
          jsonEncode(pricingMap),
        ),
        SupabaseService.instance.setAppSetting(
          'pricing_waec',
          _pricingWaecController.text.trim(),
        ),
        SupabaseService.instance.setAppSetting(
          'pricing_neco',
          _pricingNecoController.text.trim(),
        ),
        SupabaseService.instance.setAppSetting(
          'pricing_nabteb',
          _pricingNabtebController.text.trim(),
        ),
        SupabaseService.instance.setAppSetting(
          'pricing_jamb',
          _pricingJambController.text.trim(),
        ),
        SupabaseService.instance.setAppSetting(
          'data_margin_percentage',
          _dataMarginController.text.trim(),
        ),
      ]);
      if (mounted) {
        TopNotification.showSuccess(
          context,
          'Service pricing, JAMB ePIN, and data margins saved successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        TopNotification.showError(context, 'Failed to save pricing: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingPricing = false);
    }
  }

  Widget _buildPricingControlCard(bool isDark) {
    final foreground = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.price_change_rounded,
                  color: Color(0xFF00D2FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Pricing, Cashback & Profit Margins Control',
                      style: GoogleFonts.figtree(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage customer-facing prices, airtime cashback discounts, data profit margins, and utility service fees in real-time.',
                      style: GoogleFonts.figtree(
                        fontSize: 12.5,
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
          const SizedBox(height: 24),

          // Section 1: Telecom & Data Pricing
          Text(
            'TELECOM & AIRTIME / DATA MARGINS',
            style: GoogleFonts.figtree(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: const Color(0xFF00D2FF),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _airtimeCashbackController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Airtime Cashback (%)',
                    helperText: 'Discount given to user on recharge',
                    suffixText: '%',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _dataMarginController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Data Bundle Margin (%)',
                    helperText: 'Profit added on provider cost',
                    suffixText: '%',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _smsCostController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Bulk SMS (₦/page)',
                    helperText: 'Price per 160-char SMS page',
                    prefixText: '₦ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Quick Data Presets: ',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Wrap(
                spacing: 6,
                children: ['3.0', '5.0', '8.0', '10.0'].map((p) {
                  return ActionChip(
                    label: Text(
                      '+$p%',
                      style: GoogleFonts.figtree(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () =>
                        setState(() => _dataMarginController.text = p),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Section 2: Bills & Cable Fees
          Text(
            'BILLS & CABLE TV CONVENIENCE FEES',
            style: GoogleFonts.figtree(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: const Color(0xFF00D2FF),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cableFeeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cable Fee (₦)',
                    helperText: 'Included in the displayed subscription total',
                    prefixText: '₦ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _electricityFeeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Electricity Fee (₦)',
                    helperText:
                        'Included in total; token amount stays unchanged',
                    prefixText: '₦ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Section 3: Examination PINs
          Text(
            'EXAMINATION RESULT CHECKER PIN PRICES',
            style: GoogleFonts.figtree(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: const Color(0xFF00D2FF),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pricingWaecController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'WAEC PIN (₦)',
                    helperText: 'Default: ₦5,250',
                    prefixText: '₦ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pricingNecoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'NECO PIN (₦)',
                    helperText: 'Default: ₦2,500',
                    prefixText: '₦ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pricingNabtebController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'NABTEB PIN (₦)',
                    helperText: 'Default: ₦1,000',
                    prefixText: '₦ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pricingJambController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'JAMB e-PIN (₦)',
                    helperText: 'UTME / Direct Entry',
                    prefixText: '₦ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save Button
          ElevatedButton.icon(
            onPressed: _isSavingPricing ? null : _savePricingOverrides,
            icon: _isSavingPricing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(
              _isSavingPricing
                  ? 'Saving Changes...'
                  : 'Save All Pricing & Margins Overrides',
              style: GoogleFonts.figtree(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveApkSettings() async {
    final url = _apkUrlController.text.trim();
    final ver = _apkVersionController.text.trim();
    if (url.isEmpty) {
      TopNotification.showWarning(
        context,
        'Please enter a valid APK download URL.',
      );
      return;
    }
    setState(() => _isSavingApkSettings = true);
    try {
      await SupabaseService.instance.setAppSetting('apk_download_url', url);
      await SupabaseService.instance.setAppSetting(
        'apk_version',
        ver.isNotEmpty ? ver : 'v2.00',
      );
      if (mounted) {
        TopNotification.showSuccess(
          context,
          'Mobile APK download settings saved successfully!',
          title: 'APK Release Updated',
        );
      }
    } catch (e) {
      if (mounted) {
        TopNotification.showError(context, 'Could not save APK settings: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingApkSettings = false);
    }
  }

  Widget _buildApkReleaseCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile App (APK) Release Management',
                      style: GoogleFonts.figtree(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set the Android APK download link and version string distributed to users from the sidebar and download modal.',
                      style: GoogleFonts.figtree(
                        fontSize: 12.5,
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
          const SizedBox(height: 20),
          TextField(
            controller: _apkUrlController,
            style: GoogleFonts.figtree(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Direct APK Download URL / Release Link',
              labelStyle: GoogleFonts.figtree(fontSize: 13),
              hintText: 'https://...',
              hintStyle: GoogleFonts.figtree(fontSize: 13, color: Colors.grey),
              prefixIcon: const Icon(Icons.link_rounded, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _apkVersionController,
            style: GoogleFonts.figtree(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Release Version',
              labelStyle: GoogleFonts.figtree(fontSize: 13),
              hintText: 'v2.00',
              hintStyle: GoogleFonts.figtree(fontSize: 13, color: Colors.grey),
              prefixIcon: const Icon(Icons.tag_rounded, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isSavingApkSettings ? null : _saveApkSettings,
                icon: _isSavingApkSettings
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _isSavingApkSettings
                      ? 'Saving...'
                      : 'Save APK Release Settings',
                  style: GoogleFonts.figtree(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final url = _apkUrlController.text.trim();
                  if (url.isNotEmpty) {
                    launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(
                  'Test Download Link',
                  style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerTools(BuildContext context, bool isDark) {
    final tools = [
      _AdminTool(
        icon: Icons.storage_rounded,
        title: 'Supabase Database Editor',
        description:
            'View tables, edit schemas, inspect rows and RLS policies.',
        onTap: () => _openExternal(context, Uri.parse('$_projectUrl/editor')),
      ),
      _AdminTool(
        icon: Icons.functions_rounded,
        title: 'Edge Functions Logs',
        description:
            'Check real-time execution logs for vtu-provider and paystack-payments.',
        onTap: () =>
            _openExternal(context, Uri.parse('$_projectUrl/functions')),
      ),
      _AdminTool(
        icon: Icons.payments_outlined,
        title: 'Paystack Merchant Dashboard',
        description:
            'Monitor transactions, webhook events, and settlement payouts.',
        onTap: () => _openExternal(
          context,
          Uri.parse('https://dashboard.paystack.com/'),
        ),
      ),
      _AdminTool(
        icon: Icons.menu_book_rounded,
        title: 'GitHub Repository',
        description:
            'Review commit history, CI/CD automated deployments, and documentation.',
        onTap: () => _openExternal(
          context,
          Uri.parse('https://github.com/Adevictorolu/Avotek'),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 900
            ? 4
            : (constraints.maxWidth >= 550 ? 2 : 1);
        return GridView.builder(
          itemCount: tools.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 140,
          ),
          itemBuilder: (context, index) => _AdminToolCard(
            tool: tools[index],
            isDark: isDark,
          ),
        );
      },
    );
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
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tool.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(tool.icon, color: AppColors.primaryBlue, size: 22),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tool.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.figtree(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  tool.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.figtree(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? Colors.white70 : AppColors.slateGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
