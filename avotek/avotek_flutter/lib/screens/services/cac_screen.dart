import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/avotek_logo.dart';

class CacServicePlan {
  final String id;
  final String title;
  final String subtitle;
  final double fee;
  final String turnaround;
  final List<String> deliverables;
  final IconData icon;

  const CacServicePlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.fee,
    required this.turnaround,
    required this.deliverables,
    required this.icon,
  });
}

class CacScreen extends StatefulWidget {
  const CacScreen({super.key});

  @override
  State<CacScreen> createState() => _CacScreenState();
}

class _CacScreenState extends State<CacScreen> {
  int _currentStep = 0;

  static const List<CacServicePlan> _plans = [
    CacServicePlan(
      id: 'bn',
      title: 'Business Name',
      subtitle: 'Sole Proprietorship / Enterprise',
      fee: 16500.0,
      turnaround: '3 - 5 Business Days',
      deliverables: [
        'CAC Certificate of Registration',
        'Official CAC Status Report',
        'Tax Identification Number (TIN)',
        'Eligible for Corporate Bank Account',
      ],
      icon: Icons.storefront_rounded,
    ),
    CacServicePlan(
      id: 'ltd',
      title: 'Company Limited by Shares (LTD)',
      subtitle: 'Private Limited Liability Company',
      fee: 48000.0,
      turnaround: '5 - 7 Business Days',
      deliverables: [
        'Certificate of Incorporation',
        'Status Report with 1M Share Capital',
        'Standard MEMART Constitution',
        'Federal TIN for Corporate FIRS',
      ],
      icon: Icons.corporate_fare_rounded,
    ),
    CacServicePlan(
      id: 'it',
      title: 'Incorporated Trustee (NGO)',
      subtitle: 'Churches, Foundations & Clubs',
      fee: 85000.0,
      turnaround: '10 - 14 Business Days',
      deliverables: [
        'Trustee Registration Certificate',
        'Newspaper Gazette Publication',
        'Approved Trustee Constitution',
        'Official NGO Seal Verification',
      ],
      icon: Icons.volunteer_activism_rounded,
    ),
  ];

  late CacServicePlan _selectedPlan;

  // Step 2: Proposed Business Names
  final _nameOption1Controller = TextEditingController();
  final _nameOption2Controller = TextEditingController();
  final _natureOfBizController = TextEditingController();

  // Step 3: Proprietor Details
  final _proprietorNameController = TextEditingController();
  final _proprietorPhoneController = TextEditingController();
  final _proprietorEmailController = TextEditingController();
  final _proprietorNinController = TextEditingController();
  final _addressController = TextEditingController();

  // Step 4: Documents state
  bool _idUploaded = true;
  bool _passportUploaded = true;
  bool _signatureUploaded = true;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPlan = _plans[0];
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _proprietorNameController.text = user.name;
      _proprietorPhoneController.text = user.phone;
      if (user.email != null) _proprietorEmailController.text = user.email!;
    }
  }

  @override
  void dispose() {
    _nameOption1Controller.dispose();
    _nameOption2Controller.dispose();
    _natureOfBizController.dispose();
    _proprietorNameController.dispose();
    _proprietorPhoneController.dispose();
    _proprietorEmailController.dispose();
    _proprietorNinController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handlePaymentAndSubmission() async {
    final wallet = context.read<WalletProvider>();
    final auth = context.read<AuthProvider>();

    if (wallet.balance < _selectedPlan.fee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance (₦${NumberFormat('#,##0.00').format(wallet.balance)}). Please fund your wallet.',
          ),
          action: SnackBarAction(
            label: 'Fund Wallet',
            onPressed: () => context.push('/wallet/fund'),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    // Simulate instant atomic debit
    if (auth.user?.id != null) {
      wallet.applyLocalDebit(
        amount: _selectedPlan.fee,
        service: 'CAC Registration (${_selectedPlan.title})',
        reference: 'CAC-${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackingRef = 'CAC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, size: 36, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'Application Submitted!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${_selectedPlan.title} reservation has been forwarded to the Corporate Affairs Commission legal desk.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tracking Ref:', style: TextStyle(fontSize: 11, color: AppColors.slateGrey)),
                      Text(trackingRef, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Est. Delivery:', style: TextStyle(fontSize: 11, color: AppColors.slateGrey)),
                      Text(_selectedPlan.turnaround, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fee Paid:', style: TextStyle(fontSize: 11, color: AppColors.slateGrey)),
                      Text('₦${NumberFormat('#,##0.00').format(_selectedPlan.fee)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/dashboard');
                },
                child: const Text('Back to Dashboard', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            AvotekBrandAsset(height: 26, isDark: isDark),
            const SizedBox(width: 8),
            const Text(
              'CAC Portal',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppColors.primaryCyan),
                const SizedBox(width: 6),
                Text(
                  '₦${NumberFormat('#,##0').format(wallet.balance)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Step Progress Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ),
                child: Row(
                  children: [
                    _buildStepIndicator(0, 'Plan', isDark),
                    _buildStepDivider(isDark, 0),
                    _buildStepIndicator(1, 'Name', isDark),
                    _buildStepDivider(isDark, 1),
                    _buildStepIndicator(2, 'KYC Details', isDark),
                    _buildStepDivider(isDark, 2),
                    _buildStepIndicator(3, 'Review & Pay', isDark),
                  ],
                ),
              ),

              // Step Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrentStepContent(isDark),
                ),
              ),

              // Bottom Navigation Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (_currentStep < 3) {
                                  setState(() => _currentStep++);
                                } else {
                                  _handlePaymentAndSubmission();
                                }
                              },
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _currentStep == 3
                                    ? 'Pay ₦${NumberFormat('#,##0').format(_selectedPlan.fee)} & Submit'
                                    : 'Continue',
                                style: const TextStyle(fontSize: 13),
                              ),
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

  Widget _buildStepIndicator(int stepIndex, String title, bool isDark) {
    final isActive = _currentStep >= stepIndex;
    final isCurrent = _currentStep == stepIndex;

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppColors.primaryCyan : AppColors.primaryBlue)
                : (isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${stepIndex + 1}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? (isDark ? const Color(0xFF002B47) : Colors.white) : AppColors.slateGrey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isDark, int priorStep) {
    final isPassed = _currentStep > priorStep;
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isPassed
            ? (isDark ? AppColors.primaryCyan : AppColors.primaryBlue)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildPlanSelectionStep(isDark);
      case 1:
        return _buildNameOptionsStep(isDark);
      case 2:
        return _buildKycDetailsStep(isDark);
      case 3:
        return _buildReviewStep(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlanSelectionStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Registration Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Legally vetted and filed directly with the Corporate Affairs Commission (CAC) Nigeria.',
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
          ),
        ),
        const SizedBox(height: 14),
        ..._plans.map((plan) {
          final isSelected = plan.id == _selectedPlan.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedPlan = plan),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.primaryCyan.withValues(alpha: 0.08) : AppColors.primaryBlue.withValues(alpha: 0.05))
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppColors.primaryCyan : AppColors.primaryBlue)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(plan.icon, size: 20, color: AppColors.primaryCyan),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              plan.subtitle,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₦${NumberFormat('#,##0').format(plan.fee)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.primaryCyan : AppColors.primaryBlue,
                            ),
                          ),
                          Text(
                            plan.turnaround,
                            style: const TextStyle(fontSize: 9.5, color: AppColors.success, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: plan.deliverables.map((d) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            d,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNameOptionsStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Name Reservation',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Provide two name preferences in case your first choice is already registered.',
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameOption1Controller,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Preferred Name (Option 1) *',
            hintText: 'e.g. AVOTEK ACADEMIC LOGISTICS',
            prefixIcon: Icon(Icons.looks_one_rounded, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameOption2Controller,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Alternative Name (Option 2) *',
            hintText: 'e.g. AVOTEK EDU TECH ENTERPRISES',
            prefixIcon: Icon(Icons.looks_two_rounded, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _natureOfBizController,
          maxLines: 3,
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            labelText: 'Nature of Business / Objective *',
            hintText: 'e.g. General merchant, digital utility services, educational consultancy...',
          ),
        ),
      ],
    );
  }

  Widget _buildKycDetailsStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proprietor / Director Information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Must match your official government identification slip (NIN / Voter Card / Passport).',
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _proprietorNameController,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Full Legal Name *',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _proprietorPhoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _proprietorNinController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'NIN (11 Digits) *',
                  counterText: '',
                  prefixIcon: Icon(Icons.badge_outlined, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _proprietorEmailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Email for CAC Certificates *',
            prefixIcon: Icon(Icons.email_outlined, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Official Business Address *',
            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'DOCUMENT VERIFICATION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
          ),
        ),
        const SizedBox(height: 8),
        _buildDocumentCheckItem('NIN Slip / Government ID', _idUploaded, (val) => setState(() => _idUploaded = val), isDark),
        _buildDocumentCheckItem('Passport Photograph (White BG)', _passportUploaded, (val) => setState(() => _passportUploaded = val), isDark),
        _buildDocumentCheckItem('Signature Specimen on White Paper', _signatureUploaded, (val) => setState(() => _signatureUploaded = val), isDark),
      ],
    );
  }

  Widget _buildDocumentCheckItem(String label, bool isChecked, ValueChanged<bool> onChanged, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.primaryCyan),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          Switch(
            value: isChecked,
            activeColor: AppColors.primaryCyan,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(bool isDark) {
    final name1 = _nameOption1Controller.text.trim().isEmpty ? 'Option 1 Not Specified' : _nameOption1Controller.text.trim();
    final name2 = _nameOption2Controller.text.trim().isEmpty ? 'Option 2 Not Specified' : _nameOption2Controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary & Fee Breakdown',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Selected Category:', _selectedPlan.title, isDark, bold: true),
              const Divider(height: 16),
              _buildSummaryRow('Primary Name:', name1, isDark),
              _buildSummaryRow('Secondary Name:', name2, isDark),
              _buildSummaryRow('Applicant Name:', _proprietorNameController.text.trim(), isDark),
              _buildSummaryRow('Applicant NIN:', _proprietorNinController.text.trim(), isDark),
              _buildSummaryRow('Turnaround Time:', _selectedPlan.turnaround, isDark, highlight: true),
              const Divider(height: 16),
              _buildSummaryRow(
                'Total Filing & Gazetting Fee:',
                '₦${NumberFormat('#,##0.00').format(_selectedPlan.fee)}',
                isDark,
                bold: true,
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, size: 20, color: AppColors.primaryCyan),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '100% Guaranteed Filing. In the rare event of name rejection by the CAC Registrar General, one complimentary alternative resubmission is included.',
                  style: TextStyle(fontSize: 10.5, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool bold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: highlight
                  ? AppColors.primaryCyan
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
