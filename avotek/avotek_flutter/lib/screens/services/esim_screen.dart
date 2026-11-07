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
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2230)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Back',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0047FF), Color(0xFF00A6D6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0047FF).withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.sim_card_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INTERNATIONAL SERVICES',
                              style: GoogleFonts.figtree(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Travel eSIM',
                              style: GoogleFonts.figtree(
                                fontSize: isDesktop ? 26 : 23,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'International data plans, ready to install with a QR code.',
                              style: GoogleFonts.figtree(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
                          style: GoogleFonts.figtree(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search country or plan',
                            hintStyle: GoogleFonts.figtree(
                              fontSize: 13.5,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                            ),
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _countryFilterChip('ALL', 'All Destinations', Icons.public_rounded, isDark),
                          ...locations.map((loc) => _countryFilterChip(
                            loc['code']!,
                            loc['name']!,
                            null,
                            isDark,
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
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
      child: InkWell(
        onTap: () {
          setState(() => _selectedTab = tab);
          if (tab == 1) _loadOwnedEsims();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected
                ? null
                : (isDark ? const Color(0xFF161922) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0047FF)
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0038B8).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.figtree(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCountryAccentColor(String code) {
    if (code == 'ALL') return const Color(0xFF0052FF);
    final hash = code.codeUnits.fold(0, (acc, c) => acc + c);
    const colors = [
      Color(0xFF0052FF),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
      Color(0xFF0284C7),
      Color(0xFFEA580C),
      Color(0xFF0D9488),
    ];
    return colors[hash % colors.length];
  }

  Widget _countryFilterChip(
    String code,
    String name,
    IconData? icon,
    bool isDark,
  ) {
    final isSelected = _selectedLocation == code;
    final accent = _getCountryAccentColor(code);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedLocation = code),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? accent
                : (isDark
                    ? accent.withValues(alpha: 0.14)
                    : accent.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? accent
                  : accent.withValues(alpha: isDark ? 0.4 : 0.25),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : accent),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                name,
                style: GoogleFonts.figtree(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specBadge(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2E384D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF0052FF)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
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
    final locationCode = (plan['location_code'] ?? '').toString();
    final description = (plan['description'] ?? '').toString();
    final logo = (plan['location_logo'] ?? '').toString();
    final countryAccent = _getCountryAccentColor(locationCode);

    return Card(
      color: isDark ? const Color(0xFF131722) : Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                        width: 36,
                        height: 26,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.public_rounded, size: 28, color: countryAccent),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: countryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.public_rounded, size: 22, color: countryAccent),
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
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: countryAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: countryAccent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          location,
                          style: GoogleFonts.figtree(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : countryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0047FF).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '₦${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.figtree(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (data.isNotEmpty)
                  _specBadge(Icons.data_usage_rounded, '$data GB', isDark),
                if (duration.isNotEmpty)
                  _specBadge(Icons.timer_outlined, '$duration $unit', isDark),
                if (plan['speed'] != null)
                  _specBadge(Icons.speed_rounded, plan['speed'].toString(), isDark),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                style: GoogleFonts.figtree(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : () => _purchasePlan(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0047FF),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF0047FF).withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Buy eSIM',
                            style: GoogleFonts.figtree(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
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
        title: Text(
          name,
          style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          status == 'completed'
              ? '${esim['esim_status'] ?? 'Ready to install'}'
              : status == 'failed'
              ? 'Provisioning failed — refund processing'
              : 'Provisioning',
          style: GoogleFonts.figtree(
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
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
