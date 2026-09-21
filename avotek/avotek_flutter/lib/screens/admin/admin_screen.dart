import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/avotek_logo.dart';

/// Representation of an administrative user record with BVN, NIN, and wallet state
class AdminUserRecord {
  final int id;
  String name;
  String phone;
  String email;
  String kycStatus; // 'tier1', 'tier2', 'tier3'
  String bvn;
  String nin;
  double walletBalance;
  bool isBanned;
  String referralCode;
  String virtualAccountNumber;
  String virtualAccountBank;
  DateTime createdAt;
  DateTime lastLogin;

  AdminUserRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.kycStatus,
    required this.bvn,
    required this.nin,
    required this.walletBalance,
    required this.isBanned,
    required this.referralCode,
    required this.virtualAccountNumber,
    required this.virtualAccountBank,
    required this.createdAt,
    required this.lastLogin,
  });
}

/// Representation of a VTU service catalog item with adjustable pricing & fees
class AdminCatalogItem {
  final int id;
  String name;
  String serviceType; // 'data', 'airtime', 'cable', 'electricity', 'exam_pin'
  String provider;
  String variationCode;
  double costPrice;
  double markup;
  bool active;

  AdminCatalogItem({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.provider,
    required this.variationCode,
    required this.costPrice,
    required this.markup,
    required this.active,
  });

  double get sellPrice => costPrice + markup;
}

/// Representation of a platform VTU order
class AdminOrderRecord {
  final int id;
  final int userId;
  final String userName;
  final String serviceType;
  final String provider;
  final String recipient;
  final double amount;
  final double profit;
  final String reference;
  String status; // 'success', 'pending', 'failed', 'refunded'
  final DateTime createdAt;

  AdminOrderRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.serviceType,
    required this.provider,
    required this.recipient,
    required this.amount,
    required this.profit,
    required this.reference,
    required this.status,
    required this.createdAt,
  });
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter State
  String _userSearchQuery = '';
  String _userStatusFilter = 'all'; // 'all', 'active', 'banned', 'tier1', 'tier2', 'tier3'
  String _catalogCategoryFilter = 'all'; // 'all', 'data', 'airtime', 'cable', 'electricity', 'exam_pin'
  String _orderStatusFilter = 'all';

  // Global Regulation Fees
  double _bankTransferFee = 0.0;
  double _cardDepositFeePercent = 1.2;
  double _electricityConvenienceFee = 100.0;
  double _cableTvProcessingFee = 50.0;

  // Data Collections
  List<AdminUserRecord> _users = [];
  List<AdminCatalogItem> _catalog = [];
  List<AdminOrderRecord> _orders = [];

  // SQL Query Console State
  String _selectedSqlSnippet = 'SELECT * FROM users ORDER BY created_at DESC;';
  List<Map<String, dynamic>> _sqlQueryResults = [];
  String _queryExecutionTime = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initAdminData() {
    final now = DateTime.now();

    _users = [
      AdminUserRecord(
        id: 1,
        name: 'Chukwuemeka Obi',
        phone: '08031234567',
        email: 'demo@avotek.africa',
        kycStatus: 'tier2',
        bvn: '22184910283',
        nin: '61029481923',
        walletBalance: 25000.0,
        isBanned: false,
        referralCode: 'AVOTEK01',
        virtualAccountNumber: '9031234567',
        virtualAccountBank: 'Wema Bank (NIBSS)',
        createdAt: now.subtract(const Duration(days: 30)),
        lastLogin: now.subtract(const Duration(minutes: 12)),
      ),
      AdminUserRecord(
        id: 2,
        name: 'Amina Bello',
        phone: '08129841029',
        email: 'amina.bello@unilag.edu.ng',
        kycStatus: 'tier2',
        bvn: '22491029481',
        nin: '72910481920',
        walletBalance: 8450.0,
        isBanned: false,
        referralCode: 'AVOTEK02',
        virtualAccountNumber: '9049182310',
        virtualAccountBank: 'Moniepoint MFB',
        createdAt: now.subtract(const Duration(days: 14)),
        lastLogin: now.subtract(const Duration(hours: 2)),
      ),
      AdminUserRecord(
        id: 3,
        name: 'Tunde Bakare',
        phone: '07051928410',
        email: 'tunde.bakare@abu.edu.ng',
        kycStatus: 'tier3',
        bvn: '22918204918',
        nin: '81029481924',
        walletBalance: 42300.0,
        isBanned: false,
        referralCode: 'AVOTEK03',
        virtualAccountNumber: '9051829410',
        virtualAccountBank: 'Wema Bank (NIBSS)',
        createdAt: now.subtract(const Duration(days: 7)),
        lastLogin: now.subtract(const Duration(hours: 5)),
      ),
      AdminUserRecord(
        id: 4,
        name: 'Ngozi Eze',
        phone: '09038192019',
        email: 'ngozi.eze@unn.edu.ng',
        kycStatus: 'tier1',
        bvn: '22301928491',
        nin: '50192841920',
        walletBalance: 1200.0,
        isBanned: false,
        referralCode: 'AVOTEK04',
        virtualAccountNumber: '9069182410',
        virtualAccountBank: 'Sterling Bank',
        createdAt: now.subtract(const Duration(days: 3)),
        lastLogin: now.subtract(const Duration(days: 1)),
      ),
      AdminUserRecord(
        id: 5,
        name: 'Kayode Alabi',
        phone: '08139481920',
        email: 'kayode.alabi@oauife.edu.ng',
        kycStatus: 'tier2',
        bvn: '22819204918',
        nin: '91029481920',
        walletBalance: 150.0,
        isBanned: true, // Flagged account for suspicious chargeback
        referralCode: 'AVOTEK05',
        virtualAccountNumber: '9071829410',
        virtualAccountBank: 'Wema Bank (NIBSS)',
        createdAt: now.subtract(const Duration(days: 45)),
        lastLogin: now.subtract(const Duration(days: 4)),
      ),
    ];

    _catalog = [
      // Data Bundles
      AdminCatalogItem(id: 1, name: 'MTN SME 1.0GB (30 Days)', serviceType: 'data', provider: 'MTN', variationCode: 'mtn-1gb', costPrice: 245.0, markup: 45.0, active: true),
      AdminCatalogItem(id: 2, name: 'MTN SME 2.0GB (30 Days)', serviceType: 'data', provider: 'MTN', variationCode: 'mtn-2gb', costPrice: 490.0, markup: 50.0, active: true),
      AdminCatalogItem(id: 3, name: 'MTN SME 5.0GB (30 Days)', serviceType: 'data', provider: 'MTN', variationCode: 'mtn-5gb', costPrice: 1225.0, markup: 125.0, active: true),
      AdminCatalogItem(id: 4, name: 'Airtel CG 1.5GB (30 Days)', serviceType: 'data', provider: 'AIRTEL', variationCode: 'airtel-1.5gb', costPrice: 480.0, markup: 60.0, active: true),
      AdminCatalogItem(id: 5, name: 'Glo Gift 2.0GB (30 Days)', serviceType: 'data', provider: 'GLO', variationCode: 'glo-2gb', costPrice: 460.0, markup: 60.0, active: true),
      AdminCatalogItem(id: 6, name: '9mobile SME 1.5GB (30 Days)', serviceType: 'data', provider: '9MOBILE', variationCode: '9mobile-1.5gb', costPrice: 440.0, markup: 60.0, active: true),

      // Airtime Tariffs
      AdminCatalogItem(id: 7, name: 'MTN VTU Airtime (2% Discount)', serviceType: 'airtime', provider: 'MTN', variationCode: 'mtn-vtu', costPrice: 980.0, markup: 0.0, active: true),
      AdminCatalogItem(id: 8, name: 'Airtel VTU Airtime (2.5% Discount)', serviceType: 'airtime', provider: 'AIRTEL', variationCode: 'airtel-vtu', costPrice: 975.0, markup: 0.0, active: true),
      AdminCatalogItem(id: 9, name: 'Glo VTU Airtime (3% Discount)', serviceType: 'airtime', provider: 'GLO', variationCode: 'glo-vtu', costPrice: 970.0, markup: 0.0, active: true),

      // Cable TV Bouquets
      AdminCatalogItem(id: 10, name: 'DStv Compact Bouquet', serviceType: 'cable', provider: 'DSTV', variationCode: 'dstv-compact', costPrice: 15700.0, markup: 100.0, active: true),
      AdminCatalogItem(id: 11, name: 'GOtv Jinja Bouquet', serviceType: 'cable', provider: 'GOTV', variationCode: 'gotv-jinja', costPrice: 3300.0, markup: 50.0, active: true),
      AdminCatalogItem(id: 12, name: 'Startimes Classic', serviceType: 'cable', provider: 'STARTIMES', variationCode: 'startimes-classic', costPrice: 3800.0, markup: 50.0, active: true),

      // Electricity Discos
      AdminCatalogItem(id: 13, name: 'Ikeja Electric (IKEDC) Prepaid', serviceType: 'electricity', provider: 'IKEDC', variationCode: 'ikedc-prepaid', costPrice: 5000.0, markup: 100.0, active: true),
      AdminCatalogItem(id: 14, name: 'Eko Electric (EKEDC) Prepaid', serviceType: 'electricity', provider: 'EKEDC', variationCode: 'ekedc-prepaid', costPrice: 5000.0, markup: 100.0, active: true),
      AdminCatalogItem(id: 15, name: 'Abuja Electric (AEDC) Prepaid', serviceType: 'electricity', provider: 'AEDC', variationCode: 'aedc-prepaid', costPrice: 5000.0, markup: 100.0, active: true),

      // Academic Exam PINs
      AdminCatalogItem(id: 16, name: 'WAEC Result Checker e-PIN', serviceType: 'exam_pin', provider: 'WAEC', variationCode: 'waec-pin', costPrice: 3350.0, markup: 150.0, active: true),
      AdminCatalogItem(id: 17, name: 'NECO Result Token', serviceType: 'exam_pin', provider: 'NECO', variationCode: 'neco-token', costPrice: 1150.0, markup: 100.0, active: true),
      AdminCatalogItem(id: 18, name: 'JAMB UTME Registration e-PIN', serviceType: 'exam_pin', provider: 'JAMB', variationCode: 'jamb-utme', costPrice: 6200.0, markup: 100.0, active: true),
      AdminCatalogItem(id: 19, name: 'NABTEB Result Checker e-PIN', serviceType: 'exam_pin', provider: 'NABTEB', variationCode: 'nabteb-pin', costPrice: 1100.0, markup: 100.0, active: true),
    ];

    _orders = [
      AdminOrderRecord(
        id: 101,
        userId: 1,
        userName: 'Chukwuemeka Obi',
        serviceType: 'data',
        provider: 'MTN',
        recipient: '08031234567',
        amount: 540.0,
        profit: 50.0,
        reference: 'TX-AVO-DATA-001',
        status: 'success',
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      AdminOrderRecord(
        id: 102,
        userId: 2,
        userName: 'Amina Bello',
        serviceType: 'exam_pin',
        provider: 'WAEC',
        recipient: '08129841029',
        amount: 3500.0,
        profit: 150.0,
        reference: 'TX-AVO-EXAM-002',
        status: 'success',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AdminOrderRecord(
        id: 103,
        userId: 3,
        userName: 'Tunde Bakare',
        serviceType: 'electricity',
        provider: 'IKEDC',
        recipient: '45019283741',
        amount: 5100.0,
        profit: 100.0,
        reference: 'TX-AVO-ELEC-003',
        status: 'success',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AdminOrderRecord(
        id: 104,
        userId: 4,
        userName: 'Ngozi Eze',
        serviceType: 'cable',
        provider: 'DSTV',
        recipient: '1092849102',
        amount: 15800.0,
        profit: 100.0,
        reference: 'TX-AVO-CAB-004',
        status: 'pending',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      AdminOrderRecord(
        id: 105,
        userId: 5,
        userName: 'Kayode Alabi',
        serviceType: 'data',
        provider: 'AIRTEL',
        recipient: '08139481920',
        amount: 540.0,
        profit: 60.0,
        reference: 'TX-AVO-DATA-005',
        status: 'failed',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    _runDefaultSqlQuery();
  }

  void _runDefaultSqlQuery() {
    _sqlQueryResults = _users.map((u) {
      return {
        'id': u.id,
        'name': u.name,
        'phone': u.phone,
        'bvn': u.bvn,
        'nin': u.nin,
        'wallet_balance': '₦${NumberFormat('#,##0.00').format(u.walletBalance)}',
        'kyc_status': u.kycStatus,
        'is_banned': u.isBanned ? 'YES (BANNED)' : 'NO (ACTIVE)',
        'created_at': DateFormat('yyyy-MM-dd HH:mm').format(u.createdAt),
      };
    }).toList();
    _queryExecutionTime = '1.42 ms (PostgreSQL in-memory engine)';
  }

  // KPI Calculations
  int get totalRegisteredUsers => _users.length;
  int get activeUsersCount => _users.where((u) => !u.isBanned).length;
  int get bannedUsersCount => _users.where((u) => u.isBanned).length;
  double get totalWalletLiquidity => _users.fold(0.0, (acc, u) => acc + u.walletBalance);
  double get totalOrdersVolume => _orders.fold(0.0, (acc, o) => acc + o.amount);
  double get totalGrossProfit => _orders.fold(0.0, (acc, o) => acc + o.profit);

  // --- Actions ---

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final bvnCtrl = TextEditingController(text: '22${DateTime.now().millisecondsSinceEpoch.toString().substring(4, 13)}');
    final ninCtrl = TextEditingController(text: '61${DateTime.now().millisecondsSinceEpoch.toString().substring(4, 13)}');
    final initialBalCtrl = TextEditingController(text: '10000');
    String selectedKyc = 'tier2';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryCyan),
              SizedBox(width: 8),
              Text('Register New Platform User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. Babatunde Fashola'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number', hintText: '0802 345 6789'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address', hintText: 'user@avotek.africa'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: bvnCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Attached BVN (11 Digits)', hintText: '22184910283'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: ninCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Attached NIN (11 Digits)', hintText: '61029481923'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: initialBalCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Initial Balance (₦)', hintText: '10000'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedKyc,
                          decoration: const InputDecoration(labelText: 'KYC Level'),
                          items: const [
                            DropdownMenuItem(value: 'tier1', child: Text('Tier 1 (Basic)')),
                            DropdownMenuItem(value: 'tier2', child: Text('Tier 2 (BVN Verified)')),
                            DropdownMenuItem(value: 'tier3', child: Text('Tier 3 (Corporate/CAC)')),
                          ],
                          onChanged: (val) => setDlgState(() => selectedKyc = val ?? 'tier2'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid user name and phone number.')),
                  );
                  return;
                }

                final newId = _users.length + 1;
                final initialBal = double.tryParse(initialBalCtrl.text) ?? 0.0;
                final now = DateTime.now();

                setState(() {
                  _users.insert(
                    0,
                    AdminUserRecord(
                      id: newId,
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : 'user$newId@avotek.africa',
                      kycStatus: selectedKyc,
                      bvn: bvnCtrl.text.trim(),
                      nin: ninCtrl.text.trim(),
                      walletBalance: initialBal,
                      isBanned: false,
                      referralCode: 'AVO${newId.toString().padLeft(3, '0')}',
                      virtualAccountNumber: '90${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}',
                      virtualAccountBank: 'Wema Bank (NIBSS)',
                      createdAt: now,
                      lastLogin: now,
                    ),
                  );
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text('User "${nameCtrl.text.trim()}" created successfully with ₦${NumberFormat('#,##0').format(initialBal)} wallet balance!'),
                  ),
                );
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFundUserDialog(AdminUserRecord user) {
    final amountCtrl = TextEditingController(text: '5000');
    final noteCtrl = TextEditingController(text: 'Administrative Credit Adjustment');
    String txType = 'credit'; // 'credit' or 'debit'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(txType == 'credit' ? Icons.add_card_rounded : Icons.remove_circle_outline, color: AppColors.primaryCyan),
              const SizedBox(width: 8),
              Text('Fund / Adjust User Wallet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${user.name} (${user.phone})', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Current Balance: ₦${NumberFormat('#,##0.00').format(user.walletBalance)}', style: const TextStyle(fontSize: 13, color: AppColors.primaryCyan)),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'credit', label: Text('Credit (+)')),
                    ButtonSegment(value: 'debit', label: Text('Debit (-)')),
                  ],
                  selected: {txType},
                  onSelectionChanged: (val) => setDlgState(() => txType = val.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (₦)', prefixText: '₦ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Narration / Reason'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: txType == 'credit' ? AppColors.success : AppColors.error,
              ),
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amt <= 0) return;

                setState(() {
                  if (txType == 'credit') {
                    user.walletBalance += amt;
                  } else {
                    user.walletBalance = (user.walletBalance - amt).clamp(0.0, double.infinity);
                  }
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: txType == 'credit' ? AppColors.success : AppColors.error,
                    content: Text('${txType.toUpperCase()} of ₦${NumberFormat('#,##0.00').format(amt)} recorded for ${user.name}! New Balance: ₦${NumberFormat('#,##0.00').format(user.walletBalance)}'),
                  ),
                );
              },
              child: Text(txType == 'credit' ? 'Credit Wallet' : 'Debit Wallet'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBanUser(AdminUserRecord user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(user.isBanned ? Icons.check_circle_rounded : Icons.block_rounded, color: user.isBanned ? AppColors.success : AppColors.error),
            const SizedBox(width: 8),
            Text(user.isBanned ? 'Unban & Reactivate User?' : 'Ban & Suspend User?'),
          ],
        ),
        content: Text(
          user.isBanned
              ? 'Are you sure you want to reactivate ${user.name}\'s account? They will regain full access to purchase VTU services and transfer wallet funds.'
              : 'Are you sure you want to freeze ${user.name}\'s account? All ongoing VTU orders will be halted and login access will be blocked immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isBanned ? AppColors.success : AppColors.error,
            ),
            onPressed: () {
              setState(() {
                user.isBanned = !user.isBanned;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: user.isBanned ? AppColors.error : AppColors.success,
                  content: Text(user.isBanned ? 'User ${user.name} has been banned.' : 'User ${user.name} has been reactivated.'),
                ),
              );
            },
            child: Text(user.isBanned ? 'Reactivate User' : 'Ban User'),
          ),
        ],
      ),
    );
  }

  void _showUserDossier(AdminUserRecord user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.badge_rounded, color: AppColors.primaryCyan),
            const SizedBox(width: 8),
            Text('User Dossier: ${user.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.2),
                        child: Text(
                          user.name.substring(0, 1),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('${user.phone} • ${user.email}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: user.isBanned ? AppColors.error.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user.isBanned ? 'BANNED / FROZEN' : 'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: user.isBanned ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryCyan.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user.kycStatus.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('National Identification & KYC Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _buildDossierRow('Bank Verification Number (BVN)', user.bvn, isVerified: true),
                _buildDossierRow('National Identity Number (NIN)', user.nin, isVerified: true),
                _buildDossierRow('Dedicated Virtual Account', '${user.virtualAccountNumber} (${user.virtualAccountBank})', isVerified: true),
                _buildDossierRow('Referral Identity Code', user.referralCode, isVerified: false),
                _buildDossierRow('Account Registration Date', DateFormat('MMMM dd, yyyy HH:mm').format(user.createdAt), isVerified: false),
                _buildDossierRow('Last System Activity', DateFormat('MMMM dd, yyyy HH:mm').format(user.lastLogin), isVerified: false),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Wallet Liquidity:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('₦${NumberFormat('#,##0.00').format(user.walletBalance)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showFundUserDialog(user);
            },
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
            label: const Text('Fund Wallet'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isBanned ? AppColors.success : AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _toggleBanUser(user);
            },
            child: Text(user.isBanned ? 'Reactivate' : 'Ban User'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDossierRow(String label, String value, {required bool isVerified}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              if (isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryCyan),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showEditCatalogDialog(AdminCatalogItem item) {
    final costCtrl = TextEditingController(text: item.costPrice.toStringAsFixed(0));
    final markupCtrl = TextEditingController(text: item.markup.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final cost = double.tryParse(costCtrl.text) ?? item.costPrice;
          final markup = double.tryParse(markupCtrl.text) ?? item.markup;
          final retail = cost + markup;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.primaryCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Regulate Tariff: ${item.name}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Provider: ${item.provider} • Code: ${item.variationCode}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Base Provider Cost Price (₦)', prefixText: '₦ '),
                    onChanged: (_) => setDlgState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: markupCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Admin Markup / Profit Margin (₦)', prefixText: '₦ '),
                    onChanged: (_) => setDlgState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Live Retail / Selling Price:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₦${NumberFormat('#,##0.00').format(retail)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newCost = double.tryParse(costCtrl.text) ?? item.costPrice;
                  final newMarkup = double.tryParse(markupCtrl.text) ?? item.markup;

                  setState(() {
                    item.costPrice = newCost;
                    item.markup = newMarkup;
                  });

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Tariff for ${item.name} updated to ₦${NumberFormat('#,##0').format(item.sellPrice)}!'),
                    ),
                  );
                },
                child: const Text('Save Tariff'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _refundOrder(AdminOrderRecord order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.replay_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Reverse Order & Refund User?'),
          ],
        ),
        content: Text(
          'Do you want to reverse order #${order.id} (${order.provider} ₦${NumberFormat('#,##0').format(order.amount)}) and refund the full amount back to ${order.userName}\'s wallet?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              setState(() {
                order.status = 'refunded';
                final targetUser = _users.firstWhere((u) => u.id == order.userId, orElse: () => _users.first);
                targetUser.walletBalance += order.amount;
              });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.success,
                  content: Text('Order #${order.id} reversed and ₦${NumberFormat('#,##0').format(order.amount)} refunded to user wallet!'),
                ),
              );
            },
            child: const Text('Confirm Refund'),
          ),
        ],
      ),
    );
  }

  void _showEditGlobalFeesDialog() {
    final transferCtrl = TextEditingController(text: _bankTransferFee.toStringAsFixed(0));
    final cardCtrl = TextEditingController(text: _cardDepositFeePercent.toStringAsFixed(1));
    final elecCtrl = TextEditingController(text: _electricityConvenienceFee.toStringAsFixed(0));
    final cableCtrl = TextEditingController(text: _cableTvProcessingFee.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: AppColors.primaryCyan),
            SizedBox(width: 8),
            Text('Regulate Global System Fees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: transferCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Virtual Bank Transfer Fee (₦)', prefixText: '₦ '),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cardCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Card Deposit Fee (%)', suffixText: '%'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: elecCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Electricity Token Surcharge (₦)', prefixText: '₦ '),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cableCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cable TV Renewal Fee (₦)', prefixText: '₦ '),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _bankTransferFee = double.tryParse(transferCtrl.text) ?? _bankTransferFee;
                _cardDepositFeePercent = double.tryParse(cardCtrl.text) ?? _cardDepositFeePercent;
                _electricityConvenienceFee = double.tryParse(elecCtrl.text) ?? _electricityConvenienceFee;
                _cableTvProcessingFee = double.tryParse(cableCtrl.text) ?? _cableTvProcessingFee;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.success,
                  content: Text('Global system regulation fees updated successfully!'),
                ),
              );
            },
            child: const Text('Save Fees'),
          ),
        ],
      ),
    );
  }

  void _executeSqlQuery(String query) {
    setState(() {
      _selectedSqlSnippet = query;
      if (query.contains('wallets') || query.contains('balance')) {
        _sqlQueryResults = _users.map((u) {
          return {
            'user_id': u.id,
            'name': u.name,
            'wallet_balance': '₦${NumberFormat('#,##0.00').format(u.walletBalance)}',
            'virtual_account': u.virtualAccountNumber,
            'bank': u.virtualAccountBank,
          };
        }).toList();
      } else if (query.contains('orders') || query.contains('profit')) {
        _sqlQueryResults = _orders.map((o) {
          return {
            'order_id': o.id,
            'service': o.serviceType,
            'provider': o.provider,
            'amount': '₦${NumberFormat('#,##0.00').format(o.amount)}',
            'profit': '₦${NumberFormat('#,##0.00').format(o.profit)}',
            'status': o.status.toUpperCase(),
          };
        }).toList();
      } else {
        _runDefaultSqlQuery();
      }
      _queryExecutionTime = '0.98 ms (PostgreSQL Engine Active)';
    });
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Row(
          children: [
            AvotekLogo(size: 26, isDark: isDark),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ADMIN OPERATIONS SUITE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.primaryCyan,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                SizedBox(width: 4),
                Text('PostgreSQL Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Add New User',
            icon: const Icon(Icons.person_add_rounded, size: 20),
            onPressed: _showAddUserDialog,
          ),
          IconButton(
            tooltip: 'Return to Dashboard',
            icon: const Icon(Icons.dashboard_rounded, size: 20),
            onPressed: () => context.go('/dashboard'),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryCyan,
          labelColor: AppColors.primaryCyan,
          unselectedLabelColor: isDark ? AppColors.metallicLight : AppColors.slateGrey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(icon: const Icon(Icons.people_alt_rounded, size: 18), text: 'Users & BVN (${_users.length})'),
            Tab(icon: const Icon(Icons.price_change_rounded, size: 18), text: 'VTU Pricing & Tariffs (${_catalog.length})'),
            Tab(icon: const Icon(Icons.receipt_long_rounded, size: 18), text: 'Live Orders & Refunds (${_orders.length})'),
            const Tab(icon: Icon(Icons.terminal_rounded, size: 18), text: 'PostgreSQL Console'),
          ],
        ),
      ),
      body: Column(
        children: [
          // KPI Metric Banner
          _buildExecutiveSummaryBanner(isDark),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersManagementTab(isDark),
                _buildPricingTariffsTab(isDark),
                _buildOrdersRefundTab(isDark),
                _buildSqlConsoleTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummaryBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiCard(
              title: 'Total Users',
              value: NumberFormat('#,##0').format(totalRegisteredUsers),
              subtext: '$activeUsersCount Active • $bannedUsersCount Banned',
              icon: Icons.people_outline_rounded,
              color: AppColors.primaryCyan,
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'Total User Liquidity',
              value: '₦${NumberFormat('#,##0').format(totalWalletLiquidity)}',
              subtext: 'Across all verified wallets',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.success,
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'Today\'s VTU Volume',
              value: '₦${NumberFormat('#,##0').format(totalOrdersVolume)}',
              subtext: '${_orders.length} transactions processed',
              icon: Icons.shopping_bag_outlined,
              color: AppColors.primaryBlue,
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'Gross Margin / Profit',
              value: '₦${NumberFormat('#,##0').format(totalGrossProfit)}',
              subtext: 'Calculated from sell markup',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // --- TAB 1: USERS & BVN MANAGEMENT ---

  Widget _buildUsersManagementTab(bool isDark) {
    var filtered = _users.where((u) {
      final q = _userSearchQuery.toLowerCase();
      final matchesQuery = u.name.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.bvn.contains(q) ||
          u.referralCode.toLowerCase().contains(q);

      if (!matchesQuery) return false;

      if (_userStatusFilter == 'active') return !u.isBanned;
      if (_userStatusFilter == 'banned') return u.isBanned;
      if (_userStatusFilter == 'tier1') return u.kycStatus == 'tier1';
      if (_userStatusFilter == 'tier2') return u.kycStatus == 'tier2';
      if (_userStatusFilter == 'tier3') return u.kycStatus == 'tier3';

      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter Toolbar
        Container(
          padding: const EdgeInsets.all(14),
          color: isDark ? AppColors.darkBg : AppColors.lightBg,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, email, or BVN...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => setState(() => _userSearchQuery = val),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _userStatusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(value: 'active', child: Text('Active Only')),
                  DropdownMenuItem(value: 'banned', child: Text('Banned / Suspended')),
                  DropdownMenuItem(value: 'tier1', child: Text('Tier 1 (Basic)')),
                  DropdownMenuItem(value: 'tier2', child: Text('Tier 2 (BVN Verified)')),
                  DropdownMenuItem(value: 'tier3', child: Text('Tier 3 (Corporate)')),
                ],
                onChanged: (val) => setState(() => _userStatusFilter = val ?? 'all'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.person_add_alt_rounded, size: 16),
                label: const Text('Add User'),
              ),
            ],
          ),
        ),

        // Users List
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No matching users found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: u.isBanned
                              ? AppColors.error.withValues(alpha: 0.4)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: u.isBanned
                                    ? AppColors.error.withValues(alpha: 0.15)
                                    : AppColors.primaryCyan.withValues(alpha: 0.15),
                                child: Text(
                                  u.name.substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: u.isBanned ? AppColors.error : AppColors.primaryCyan,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: u.isBanned ? AppColors.error.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            u.isBanned ? 'BANNED' : 'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: u.isBanned ? AppColors.error : AppColors.success,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryCyan.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            u.kycStatus.toUpperCase(),
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${u.phone} • ${u.email}',
                                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 12,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('BVN: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                            Text(
                                              '${u.bvn.substring(0, 4)}••••${u.bvn.substring(u.bvn.length - 3)}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 2),
                                            const Icon(Icons.verified_user_rounded, size: 12, color: AppColors.primaryCyan),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Virtual Acct: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                            Text(u.virtualAccountNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Registered: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                            Text(DateFormat('MMM dd, yyyy').format(u.createdAt), style: const TextStyle(fontSize: 11)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₦${NumberFormat('#,##0.00').format(u.walletBalance)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Wallet Balance', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showUserDossier(u),
                                icon: const Icon(Icons.badge_outlined, size: 15),
                                label: const Text('View Dossier & BVN', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _showFundUserDialog(u),
                                icon: const Icon(Icons.account_balance_wallet_rounded, size: 15),
                                label: const Text('Fund / Adjust', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: u.isBanned ? AppColors.success : AppColors.error,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () => _toggleBanUser(u),
                                icon: Icon(u.isBanned ? Icons.check_circle_outline : Icons.block_rounded, size: 14),
                                label: Text(u.isBanned ? 'Unban' : 'Ban User', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 2: VTU PRICING & TARIFFS REGULATION ---

  Widget _buildPricingTariffsTab(bool isDark) {
    var filtered = _catalog.where((c) {
      if (_catalogCategoryFilter == 'all') return true;
      return c.serviceType == _catalogCategoryFilter;
    }).toList();

    return Column(
      children: [
        // Category Pills
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? AppColors.darkBg : AppColors.lightBg,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill('All Services', 'all', isDark),
                _buildCategoryPill('Data Bundles', 'data', isDark),
                _buildCategoryPill('Airtime Discounts', 'airtime', isDark),
                _buildCategoryPill('Cable TV', 'cable', isDark),
                _buildCategoryPill('Electricity Discos', 'electricity', isDark),
                _buildCategoryPill('Exam PINs', 'exam_pin', isDark),
              ],
            ),
          ),
        ),

        // Global System Fee Configuration Strip
        InkWell(
          onTap: _showEditGlobalFeesDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryCyan),
                    SizedBox(width: 6),
                    Text('Global Regulation Fees (Tap to Edit): ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Wrap(
                  spacing: 16,
                  children: [
                    Text('Bank Transfer Fee: ₦${_bankTransferFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                    Text('Card Deposit: $_cardDepositFeePercent%', style: const TextStyle(fontSize: 11)),
                    Text('Electricity Surcharge: ₦${_electricityConvenienceFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                    Text('Cable Processing: ₦${_cableTvProcessingFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Catalog List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.serviceType == 'data'
                            ? Icons.signal_cellular_alt_rounded
                            : item.serviceType == 'airtime'
                                ? Icons.phone_in_talk_rounded
                                : item.serviceType == 'electricity'
                                    ? Icons.bolt_rounded
                                    : item.serviceType == 'cable'
                                        ? Icons.tv_rounded
                                        : Icons.school_rounded,
                        color: AppColors.primaryCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 3),
                          Text(
                            'Provider: ${item.provider} • Variation Code: ${item.variationCode}',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 10,
                            children: [
                              Text('Cost: ₦${NumberFormat('#,##0').format(item.costPrice)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('+ Markup: ₦${NumberFormat('#,##0').format(item.markup)}', style: const TextStyle(fontSize: 11, color: AppColors.primaryCyan, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦${NumberFormat('#,##0.00').format(item.sellPrice)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.active ? 'Active' : 'Disabled', style: TextStyle(fontSize: 10, color: item.active ? AppColors.success : AppColors.error)),
                            Switch(
                              value: item.active,
                              activeThumbColor: AppColors.success,
                              onChanged: (val) => setState(() => item.active = val),
                            ),
                            IconButton(
                              tooltip: 'Edit Tariff & Markup',
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryCyan),
                              onPressed: () => _showEditCatalogDialog(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill(String title, String category, bool isDark) {
    final isSelected = _catalogCategoryFilter == category;
    return GestureDetector(
      onTap: () => setState(() => _catalogCategoryFilter = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryCyan : (isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
          ),
        ),
      ),
    );
  }

  // --- TAB 3: LIVE ORDERS & REFUNDS ---

  Widget _buildOrdersRefundTab(bool isDark) {
    var filtered = _orders.where((o) {
      if (_orderStatusFilter == 'all') return true;
      return o.status == _orderStatusFilter;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: isDark ? AppColors.darkBg : AppColors.lightBg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Real-time VTU Transaction Stream', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              DropdownButton<String>(
                value: _orderStatusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Orders')),
                  DropdownMenuItem(value: 'success', child: Text('Success Only')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending Only')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed Only')),
                  DropdownMenuItem(value: 'refunded', child: Text('Refunded / Reversed')),
                ],
                onChanged: (val) => setState(() => _orderStatusFilter = val ?? 'all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No orders matching the criteria.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final o = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: o.status == 'success'
                                ? AppColors.success.withValues(alpha: 0.15)
                                : o.status == 'pending'
                                    ? AppColors.warning.withValues(alpha: 0.15)
                                    : AppColors.error.withValues(alpha: 0.15),
                            child: Icon(
                              o.status == 'success'
                                  ? Icons.check_circle_outline
                                  : o.status == 'pending'
                                      ? Icons.hourglass_top_rounded
                                      : Icons.replay_rounded,
                              size: 18,
                              color: o.status == 'success'
                                  ? AppColors.success
                                  : o.status == 'pending'
                                      ? AppColors.warning
                                      : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Order #${o.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: o.status == 'success'
                                            ? AppColors.success.withValues(alpha: 0.2)
                                            : o.status == 'refunded'
                                                ? Colors.purple.withValues(alpha: 0.2)
                                                : AppColors.warning.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        o.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: o.status == 'success'
                                              ? AppColors.success
                                              : o.status == 'refunded'
                                                  ? Colors.purple
                                                  : AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'User: ${o.userName} • Target: ${o.recipient} (${o.provider})',
                                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
                                ),
                                Text(
                                  'Ref: ${o.reference} • ${DateFormat('MMM dd, HH:mm').format(o.createdAt)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₦${NumberFormat('#,##0.00').format(o.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('+₦${NumberFormat('#,##0.00').format(o.profit)} profit', style: const TextStyle(fontSize: 11, color: AppColors.primaryCyan)),
                              const SizedBox(height: 6),
                              if (o.status != 'refunded')
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    foregroundColor: AppColors.warning,
                                  ),
                                  onPressed: () => _refundOrder(o),
                                  icon: const Icon(Icons.replay_rounded, size: 14),
                                  label: const Text('Reverse & Refund', style: TextStyle(fontSize: 11)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 4: POSTGRESQL CONSOLE (BUILT-IN DATABASE) ---

  Widget _buildSqlConsoleTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Built-in PostgreSQL System Console', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Direct query execution without external database tools', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              if (_queryExecutionTime.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_queryExecutionTime, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Query Presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSqlSnippetChip('Users with Attached BVN', 'SELECT id, name, phone, bvn, nin, kyc_status FROM users;'),
              _buildSqlSnippetChip('Wallets & Balances', 'SELECT u.name, w.balance, w.virtual_account_number FROM users u JOIN wallets w ON u.id = w.user_id;'),
              _buildSqlSnippetChip('Orders & Gross Profits', 'SELECT id, service_type, provider, amount, profit, status FROM orders;'),
            ],
          ),
          const SizedBox(height: 12),

          // SQL Command Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, color: AppColors.primaryCyan, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedSqlSnippet,
                    style: const TextStyle(fontFamily: 'Courier', color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy Query',
                  icon: const Icon(Icons.copy_rounded, color: Colors.grey, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _selectedSqlSnippet));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Query copied to clipboard.')));
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCyan,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _executeSqlQuery(_selectedSqlSnippet),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Execute', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SQL Result Table
          const Text('Query Results:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: _sqlQueryResults.isEmpty
                  ? const Center(child: Text('No results.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          headingRowHeight: 40,
                          dataRowMinHeight: 36,
                          dataRowMaxHeight: 44,
                          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryCyan),
                          columns: _sqlQueryResults.first.keys.map((key) {
                            return DataColumn(label: Text(key.toUpperCase()));
                          }).toList(),
                          rows: _sqlQueryResults.map((row) {
                            return DataRow(
                              cells: row.values.map((val) {
                                return DataCell(Text(val.toString(), style: const TextStyle(fontSize: 11)));
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSqlSnippetChip(String label, String query) {
    final isSelected = _selectedSqlSnippet == query;
    return ActionChip(
      avatar: Icon(Icons.terminal_rounded, size: 14, color: isSelected ? AppColors.primaryCyan : Colors.grey),
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onPressed: () => _executeSqlQuery(query),
    );
  }
}
