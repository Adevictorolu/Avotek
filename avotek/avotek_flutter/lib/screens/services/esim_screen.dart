import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/vtu_api_service.dart';
import '../../core/shell/responsive_shell.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/top_notification.dart';

class EsimScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const EsimScreen({super.key, required this.onToggleTheme});

  @override
  State<EsimScreen> createState() => _EsimScreenState();
}

class _EsimScreenState extends State<EsimScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _ownedEsims = [];
  String _selectedLocation = 'ALL';
  String _searchQuery = '';
  bool _isLoadingPlans = true;
  bool _isLoadingEsims = false;
  bool _isPurchasing = false;
  String? _plansError;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlans());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });
    try {
      final plans = await VtuApiService.instance.getEsimPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _isLoadingPlans = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _plansError = 'Could not load eSIM plans: $error';
        _isLoadingPlans = false;
      });
    }
  }

  Future<void> _loadOwnedEsims() async {
    setState(() => _isLoadingEsims = true);
    try {
      final esims = await VtuApiService.instance.getMyEsims();
      if (!mounted) return;
      setState(() {
        _ownedEsims = esims;
        _isLoadingEsims = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingEsims = false);
      TopNotification.showError(
        context,
        'Could not refresh your eSIMs: $error',
      );
    }
  }

  Future<void> _purchasePlan(Map<String, dynamic> plan) async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final user = auth.user;
    final planId = _intValue(plan['id'] ?? plan['plan_id']);
    final amount = _numberValue(plan['amount'] ?? plan['price']);
    final name = (plan['name'] ?? 'Travel eSIM').toString();
    if (user == null) {
      TopNotification.showError(context, 'Please sign in to continue.');
      return;
    }
    if (planId <= 0 || amount <= 0) {
      TopNotification.showError(context, 'This eSIM plan is unavailable.');
      return;
    }
    if (wallet.balance < amount) {
      TopNotification.showError(
        context,
        'Insufficient balance (₦${wallet.balance.toStringAsFixed(2)} available).',
      );
      return;
    }

    String? transactionPin;
    final confirmed = await PinModal.show(
      context,
      title: 'Confirm eSIM Purchase',
      amount: amount,
      description:
          '$name\n${plan['location_name'] ?? 'International'} • '
          '${plan['data_gb'] ?? ''} GB • ${plan['duration'] ?? ''} '
          '${plan['duration_unit'] ?? 'days'}',
      onPinSubmit: (pin) async {
        transactionPin = pin;
        return auth.verifyPin(pin);
      },
    );
    if (confirmed != true || !mounted || transactionPin == null) return;

    setState(() => _isPurchasing = true);
    try {
      final result = await VtuApiService.instance.purchaseEsim(
        planId: planId,
        sellPrice: amount,
        pin: transactionPin!,
      );
      await auth.refreshWallet();
      await wallet.fetchWallet(user.id);
      if (!mounted) return;
      setState(() => _isPurchasing = false);

      final status = (result['status'] ?? '').toString().toLowerCase();
      if (status == 'failed' || result['success'] == false) {
        TopNotification.showError(
          context,
          (result['message'] ?? 'The eSIM purchase failed.').toString(),
          title: 'Purchase Failed',
        );
        return;
      }
      if (status == 'pending') {
        TopNotification.showInfo(
          context,
          'Your eSIM is provisioning. Check My eSIMs in a moment for the QR code.',
        );
        setState(() => _selectedTab = 1);
        await _loadOwnedEsims();
        return;
      }

      final data = result['data'];
      await _showEsimDetails(
        data is Map ? Map<String, dynamic>.from(data) : result,
        title: name,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      TopNotification.showError(context, 'eSIM purchase failed: $error');
    }
  }

  Future<void> _showEsimDetails(
    Map<String, dynamic> esim, {
    required String title,
  }) async {
    final qrCode = (esim['qr_code'] ?? '').toString();
    final activationCode = (esim['ac'] ?? '').toString();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.figtree(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Your eSIM is ready to install.'),
                if (qrCode.startsWith('https://')) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Image.network(
                      qrCode,
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'The QR code could not be displayed. Use the activation code below.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                if (activationCode.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Activation code',
                    style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(activationCode),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: activationCode),
                        );
                        if (context.mounted) {
                          TopNotification.showSuccess(
                            context,
                            'Activation code copied.',
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 17),
                      label: const Text('Copy code'),
                    ),
                  ),
                ],
                if ((esim['iccid'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('ICCID: ${esim['iccid']}'),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Install this eSIM before travelling. Do not delete it after installation.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _visiblePlans {
    final query = _searchQuery.toLowerCase();
    return _plans.where((plan) {
      final matchesLocation =
          _selectedLocation == 'ALL' ||
          plan['location_code']?.toString() == _selectedLocation;
      final searchable =
          '${plan['name'] ?? ''} ${plan['location_name'] ?? ''} '
                  '${plan['location_code'] ?? ''} ${plan['description'] ?? ''}'
              .toLowerCase();
      return matchesLocation && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  List<Map<String, String>> get _locations {
    final locations = <String, String>{};
    for (final plan in _plans) {
      final code = plan['location_code']?.toString() ?? '';
      if (code.isNotEmpty) {
        locations[code] = plan['location_name']?.toString() ?? code;
      }
    }
    return locations.entries
        .map((entry) => {'code': entry.key, 'name': entry.value})
        .toList()
      ..sort((a, b) => a['name']!.compareTo(b['name']!));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final locations = _locations;

    return ResponsiveShell(
      currentRoute: '/services/esim',
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0D14)
            : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _selectedTab == 0 ? _loadPlans : _loadOwnedEsims,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 36 : 16,
                vertical: 24,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  'Travel eSIM',
                  style: GoogleFonts.figtree(
                    fontSize: isDesktop ? 30 : 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Global mobile data plans, ready to install with a QR code.',
                  style: GoogleFonts.figtree(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _tabButton('Available plans', 0, isDark),
                    const SizedBox(width: 10),
                    _tabButton('My eSIMs', 1, isDark),
                  ],
                ),
                const SizedBox(height: 20),
                if (_selectedTab == 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(
                            () => _searchQuery = value.trim(),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search country or plan',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF131722)
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF23304B)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF23304B)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Refresh plans',
                        onPressed: _isLoadingPlans ? null : _loadPlans,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  if (locations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLocation,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF131722)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All destinations'),
                        ),
                        ...locations.map(
                          (location) => DropdownMenuItem(
                            value: location['code'],
                            child: Text(location['name']!),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLocation = value);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (_isLoadingPlans)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(36),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_plansError != null)
                    _emptyState(
                      _plansError!,
                      isDark,
                      action: TextButton(
                        onPressed: _loadPlans,
                        child: const Text('Try again'),
                      ),
                    )
                  else if (_visiblePlans.isEmpty)
                    _emptyState(
                      'No plans match this destination or search.',
                      isDark,
                    )
                  else
                    ..._visiblePlans.map(
                      (plan) => _buildPlanCard(plan, isDark),
                    ),
                ] else ...[
                  Row(
                    children: [
                      const Expanded(child: Text('Your purchased eSIM plans')),
                      IconButton(
                        tooltip: 'Refresh eSIMs',
                        onPressed: _isLoadingEsims ? null : _loadOwnedEsims,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  if (_isLoadingEsims)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(36),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_ownedEsims.isEmpty)
                    _emptyState(
                      'Your purchased eSIMs will appear here.',
                      isDark,
                      action: TextButton(
                        onPressed: _loadOwnedEsims,
                        child: const Text('Refresh'),
                      ),
                    )
                  else
                    ..._ownedEsims.map(
                      (esim) => _buildOwnedEsimCard(esim, isDark),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String title, int tab, bool isDark) {
    final selected = _selectedTab == tab;
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() => _selectedTab = tab);
          if (tab == 1) _loadOwnedEsims();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF0C73E9)
              : Colors.transparent,
          foregroundColor: selected
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF334155)),
          side: BorderSide(
            color: selected
                ? const Color(0xFF0C73E9)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        child: Text(title),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isDark) {
    final amount = _numberValue(plan['amount'] ?? plan['price']);
    final name = (plan['name'] ?? 'Travel eSIM').toString();
    final data = (plan['data_gb'] ?? '').toString();
    final duration = (plan['duration'] ?? '').toString();
    final unit = (plan['duration_unit'] ?? 'DAY').toString();
    final location = (plan['location_name'] ?? 'International').toString();
    final description = (plan['description'] ?? '').toString();
    final logo = (plan['location_logo'] ?? '').toString();

    return Card(
      color: isDark ? const Color(0xFF131722) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (logo.startsWith('https://'))
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        logo,
                        width: 32,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.public_rounded, size: 28),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.figtree(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: GoogleFonts.figtree(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₦${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.figtree(
                    color: const Color(0xFF0C73E9),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              [
                if (data.isNotEmpty) '$data GB',
                if (duration.isNotEmpty) '$duration $unit',
                if (plan['speed'] != null) plan['speed'].toString(),
              ].join(' • '),
              style: GoogleFonts.figtree(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.figtree(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isPurchasing ? null : () => _purchasePlan(plan),
                child: _isPurchasing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Buy eSIM'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnedEsimCard(Map<String, dynamic> esim, bool isDark) {
    final status = (esim['status'] ?? 'pending').toString();
    final qrCode = (esim['qr_code'] ?? '').toString();
    final name = (esim['package_name'] ?? 'Travel eSIM').toString();
    final activationCode = (esim['ac'] ?? '').toString();
    return Card(
      color: isDark ? const Color(0xFF131722) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          status == 'completed'
              ? Icons.sim_card_rounded
              : status == 'failed'
              ? Icons.error_outline_rounded
              : Icons.hourglass_top_rounded,
          color: status == 'failed' ? Colors.red : const Color(0xFF0C73E9),
          size: 30,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          status == 'completed'
              ? '${esim['esim_status'] ?? 'Ready to install'}'
              : status == 'failed'
              ? 'Provisioning failed — refund processing'
              : 'Provisioning',
        ),
        trailing:
            status == 'completed' &&
                (qrCode.isNotEmpty || activationCode.isNotEmpty)
            ? const Icon(Icons.qr_code_2_rounded)
            : null,
        onTap: status == 'completed'
            ? () => _showEsimDetails(esim, title: name)
            : null,
      ),
    );
  }

  Widget _emptyState(String message, bool isDark, {Widget? action}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Column(
      children: [
        Icon(
          Icons.sim_card_download_outlined,
          size: 38,
          color: isDark ? Colors.white54 : Colors.black38,
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        ?action,
      ],
    ),
  );

  static double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
