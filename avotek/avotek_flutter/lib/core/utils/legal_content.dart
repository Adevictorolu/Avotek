import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AvotekLegalContent {
  static const String supportEmail = 'support@avotek.com.ng';
  static const String websiteUrl = 'https://avotek.com.ng';

  static const List<(String, String)> termsOfService = [
    (
      '1. Acceptance of Terms & Eligibility',
      'By registering an account, accessing, or utilizing any service on Avotek (available via avotek.com.ng and official mobile applications), you enter into a legally binding agreement with Avotek Financial Technologies. You must be at least 18 years of age or possess legal authorization under the laws of the Federal Republic of Nigeria to use this platform.',
    ),
    (
      '2. User Account, Identification & Security',
      'You are assigned a unique, immutable Avotek ID upon registration. You are solely responsible for maintaining the absolute confidentiality of your login credentials, transaction PIN, and biometric access. Any transaction authorized with your PIN or verified biometrics is presumed authorized by you. Notify Avotek immediately via $supportEmail if you detect unauthorized account activity.',
    ),
    (
      '3. VTU, Utility Bills & Examination PIN Settlements',
      'Avotek operates as an automated digital settlement gateway for telecommunications (MTN, Glo, Airtel, 9mobile), electricity distribution companies (DisCos), cable television (DStv, GOtv, StarTimes), and examination boards (WAEC, NECO, JAMB, NABTEB). You must ensure all recipient phone numbers, smartcard numbers, and prepaid meter numbers are correct prior to confirming orders. Transactions dispatched with incorrect recipient details supplied by the user cannot be recalled.',
    ),
    (
      '4. Wallet Funding, Ledger Reconciliation & Refunds',
      'Wallets are credited in real time through verified CBN-licensed payment channels including Paystack and dedicated virtual accounts. In the event an upstream provider fails to fulfill a transaction, our automated atomic ledger initiates an immediate auto-refund back to your Avotek wallet balance with zero deduction.',
    ),
    (
      '5. Anti-Fraud & Regulatory Compliance',
      'Avotek strictly enforces the guidelines of the Central Bank of Nigeria (CBN) and the Nigerian Financial Intelligence Unit (NFIU). The platform shall not be used for money laundering, fraudulent chargebacks, or illegal fund transmission. Accounts suspected of fraudulent activity are subject to immediate suspension and regulatory reporting.',
    ),
    (
      '6. Service Availability & Customer Support',
      'While Avotek maintains a 99.9% automated uptime target, scheduled maintenance or carrier downtime may occasionally affect delivery speed. For assistance, receipt inquiries, or technical support, reach our team at $supportEmail.',
    ),
  ];

  static const List<(String, String)> privacyPolicy = [
    (
      '1. Information We Collect',
      'To provide automated bill payment services, Avotek collects your full name, email address, phone number, unique Avotek ID, account username, and transaction records. For Tier 2 KYC verification, National Identity Number (NIN) data is validated securely against verified government identification databases.',
    ),
    (
      '2. Purpose & Legal Basis of Processing',
      'Your data is processed strictly in accordance with the Nigeria Data Protection Act (NDPA) and NDPR regulations to: (a) authenticate your identity; (b) execute telecom and utility bill orders; (c) maintain accurate financial accounting ledgers; (d) prevent identity theft and fraud; and (e) deliver essential transaction receipts.',
    ),
    (
      '3. Third-Party Disclosures & Integrations',
      'We only share minimum required purchase details with licensed carriers and utility partners (e.g. sending your meter number to the relevant DisCo to generate your token). We do NOT sell, rent, or trade your personal information to third-party marketing companies under any circumstances.',
    ),
    (
      '4. Security, Encryption & Storage',
      'All user communications and database storage utilize enterprise-grade 256-bit SSL encryption. Passwords and transaction PINs are stored exclusively as one-way cryptographic salted hashes. Raw passwords and sensitive authentication keys are never stored in plaintext.',
    ),
    (
      '5. User Rights & Data Protection Inquiries',
      'Under the NDPA, you have the right to request access, rectification, or deletion of your personal data, subject to statutory record-retention requirements for financial transactions. To exercise any data protection rights, submit a formal request from your registered email address to $supportEmail.',
    ),
  ];

  static void showLegalDialog(
    BuildContext context, {
    required String title,
    required List<(String, String)> sections,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 620),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: GoogleFonts.figtree(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final section in sections) ...[
                        Text(
                          section.$1,
                          style: GoogleFonts.figtree(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          section.$2,
                          style: GoogleFonts.figtree(
                            fontSize: 12.5,
                            height: 1.55,
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('I Understand & Agree'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
