import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/shell/responsive_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../models/education_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/education_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_card.dart';
import '../../widgets/pin_modal.dart';
import '../../widgets/status_badge.dart';

class ExamCentreScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const ExamCentreScreen({super.key, required this.onToggleTheme});

  @override
  State<ExamCentreScreen> createState() => _ExamCentreScreenState();
}

class _ExamCentreScreenState extends State<ExamCentreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _revealedPins = {};

  final List<ExamProduct> _products = const [
    ExamProduct(
      id: 'waec',
      examType: 'WAEC',
      title: 'WAEC Result Checker PIN (2026)',
      description: 'Check May/June (School) & Nov/Dec (GCE) official WASSCE results.',
      price: 3900.0,
      instructions: 'Visit waecdirect.org or send WAEC*ExamNo*PIN*ExamYear to 32327 (MTN, Glo, Airtel).',
      resultPortalUrl: 'https://www.waecdirect.org',
      brandColor: Color(0xFF0070F3),
    ),
    ExamProduct(
      id: 'neco',
      examType: 'NECO',
      title: 'NECO Result Token',
      description: 'Official National Examination Council token for SSCE & BECE result verification.',
      price: 1200.0,
      instructions: 'Visit result.neco.gov.ng, enter your token, exam year, and registration number.',
      resultPortalUrl: 'https://result.neco.gov.ng',
      brandColor: Color(0xFF059669),
    ),
    ExamProduct(
      id: 'jamb',
      examType: 'JAMB',
      title: 'JAMB UTME / DE Registration PIN',
      description: 'Official profile code registration PIN for 2026 UTME and Direct Entry candidates.',
      price: 5000.0,
      instructions: 'Use your profile code and PIN at any accredited JAMB CBT centre nationwide.',
      resultPortalUrl: 'https://efacility.jamb.gov.ng',
      brandColor: Color(0xFF8B5CF6),
    ),
    ExamProduct(
      id: 'nabteb',
      examType: 'NABTEB',
      title: 'NABTEB Result Checker PIN',
      description: 'Official result verification for NBC, NTC, and ANBC/ANTC examinations.',
      price: 1100.0,
      instructions: 'Visit eworld.nabteb.gov.ng and enter your candidate number, PIN and serial.',
      resultPortalUrl: 'https://eworld.nabteb.gov.ng',
      brandColor: Color(0xFFF59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleBuyPin(ExamProduct product) async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final edu = context.read<EducationProvider>();

    int quantity = 1;

    // 1. Show quantity and review sheet
    final confirmedQuantity = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        int tempQty = 1;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final totalCost = product.price * tempQty;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Buy ${product.examType} Token', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(product.description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: tempQty > 1 ? () => setSheetState(() => tempQty--) : null,
                          ),
                          Text('$tempQty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: tempQty < 10 ? () => setSheetState(() => tempQty++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Unit Price:'),
                      Text('₦${NumberFormat("#,##0.00").format(product.price)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total to Pay:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '₦${NumberFormat("#,##0.00").format(totalCost)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0070F3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: product.brandColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx, tempQty),
                      child: const Text('Proceed to Authorize', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmedQuantity == null || !mounted) return;
    quantity = confirmedQuantity;
    final totalAmount = product.price * quantity;

    if (wallet.balance < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient wallet balance. You have ₦${wallet.balance.toStringAsFixed(2)}, required ₦${totalAmount.toStringAsFixed(2)}.'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Fund Wallet',
            textColor: Colors.white,
            onPressed: () => context.push('/wallet/fund'),
          ),
        ),
      );
      return;
    }

    // 2. Authorize via 4-Digit Security PIN
    final verified = await PinModal.show(
      context,
      title: 'Authorize Examination Purchase',
      amount: totalAmount,
      description: '$quantity x ${product.title}',
      onPinSubmit: (pin) => auth.verifyPin(pin),
    );

    if (verified == true && mounted) {
      final ref = 'TX-AVO-EXAM-${DateTime.now().millisecondsSinceEpoch}';
      final generatedPin = '${product.examType}-${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 11)}';
      final serial = '${product.examType.substring(0, 2).toUpperCase()}26${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}';

      // Record in VTU provider & wallet
      wallet.recordDebit(
        userId: auth.user?.id ?? 1,
        amount: totalAmount,
        serviceName: '${product.title} (Qty: $quantity)',
        reference: ref,
      );

      // Save to PIN Vault
      final newPinItem = ExamPinItem(
        id: 'pin-${DateTime.now().millisecondsSinceEpoch}',
        examType: product.examType,
        title: product.title,
        pinCode: generatedPin,
        serialNumber: serial,
        amount: totalAmount,
        purchaseDate: DateTime.now(),
        reference: ref,
        status: 'Delivered',
      );
      edu.addPurchasedPin(newPinItem);

      // Show Success Modal
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text('Purchase Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your $quantity ${product.title} has been generated and stored safely in your PIN Vault.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Token / PIN Code:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    SelectableText(
                      generatedPin,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF0070F3)),
                    ),
                    const SizedBox(height: 8),
                    const Text('Serial Number:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    SelectableText(
                      serial,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(product.instructions, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: 'PIN: $generatedPin | Serial: $serial'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN details copied to clipboard!')),
                );
              },
              child: const Text('Copy PIN'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _tabController.animateTo(1); // Jump to Vault tab
              },
              child: const Text('View in PIN Vault'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final edu = context.watch<EducationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ResponsiveShell(
      currentRoute: '/exams',
      onToggleTheme: widget.onToggleTheme,
      child: SingleChildScrollView(
        child: AdaptiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Exam Centre',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Instant result checker PINs, examination registration tokens, official schedules, and verification guides.',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.metallicLight : AppColors.slateGrey),
              ),
              const SizedBox(height: 20),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryBlue,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  const Tab(icon: Icon(Icons.shopping_cart_outlined, size: 18), text: 'Buy Examination PIN'),
                  Tab(
                    icon: const Icon(Icons.vpn_key_outlined, size: 18),
                    text: 'My PIN Vault (${edu.purchasedPins.length})',
                  ),
                  const Tab(icon: Icon(Icons.event_note_outlined, size: 18), text: 'Exam Calendar & Guide'),
                ],
              ),
              const SizedBox(height: 24),

              // Tab View Content
              SizedBox(
                height: 800,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductsTab(isDesktop, isDark),
                    _buildPinVaultTab(edu, isDark),
                    _buildCalendarAndGuideTab(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsTab(bool isDesktop, bool isDark) {
    return ListView(
      children: [
        // Security Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F6EC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFF059669), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '100% Genuine Board Tokens: Authorized directly by WAEC, NECO, and JAMB. Tokens are stored encrypted in your vault.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 2 : 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isDesktop ? 2.1 : 1.8,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final p = _products[index];

            return AvotekCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: p.brandColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.school, color: p.brandColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            p.examType,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: p.brandColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₦${NumberFormat("#,##0.00").format(p.price)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    p.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    p.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StatusBadge(label: 'Instant Delivery', icon: Icons.bolt),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _handleBuyPin(p),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                        label: const Text('Purchase PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPinVaultTab(EducationProvider edu, bool isDark) {
    final pins = edu.purchasedPins;

    if (pins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vpn_key_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Your PIN Vault is Empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Purchased WAEC, NECO, and JAMB tokens will appear here securely.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Buy Examination PIN'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: pins.length,
      itemBuilder: (context, index) {
        final pin = pins[index];
        final isRevealed = _revealedPins.contains(pin.id);
        final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AvotekCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        StatusBadge.academic(pin.examType),
                        const SizedBox(width: 8),
                        Text(
                          pin.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    StatusBadge.success(pin.status),
                  ],
                ),
                const SizedBox(height: 14),

                // Protected Token Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardVariant : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PIN / Token Code', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            isRevealed ? pin.pinCode : '•••• - •••• - •••• - ••••',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: isRevealed ? 1.0 : 2.0,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                if (isRevealed) {
                                  _revealedPins.remove(pin.id);
                                } else {
                                  _revealedPins.add(pin.id);
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18, color: AppColors.primaryBlue),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: pin.pinCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PIN copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Serial: ${pin.serialNumber} • ${dateFormat.format(pin.purchaseDate)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '₦${NumberFormat("#,##0.00").format(pin.amount)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarAndGuideTab(bool isDark) {
    final events = [
      {
        'title': 'WAEC WASSCE 2026 Registration Window',
        'date': 'Closing: December 15, 2026',
        'desc': 'Candidates must register with biometric NIN capture and obtain registration voucher.',
        'color': const Color(0xFF0070F3),
      },
      {
        'title': 'JAMB UTME / DE 2026 Examination',
        'date': 'Scheduled: April 18 – April 28, 2026',
        'desc': 'CBT examination across accredited national centres. Ensure your profile code is generated.',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'NECO SSCE Internal Examinations',
        'date': 'Commencing: June 2026',
        'desc': 'Secondary schools nationwide submit continuous assessment and candidate portfolios.',
        'color': const Color(0xFF059669),
      },
    ];

    return ListView(
      children: [
        const Text(
          'Official 2026 Examination Dates & Deadlines',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...events.map((e) {
          final col = e['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AvotekCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(e['date'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: col)),
                        const SizedBox(height: 4),
                        Text(e['desc'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
        const Text(
          'How to Check WAEC Results Online',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        AvotekCard(
          padding: const EdgeInsets.all(16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Obtain your 10-digit PIN & Serial Number from the Exam Centre.', style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text('2. Visit the official portal: www.waecdirect.org.', style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text('3. Enter your 10-digit WAEC Examination Number.', style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text('4. Select Examination Year & Examination Type (School or Private Candidate).', style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text('5. Enter your PIN and Serial Number, then click Submit to view your grades.', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
