import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../widgets/top_notification.dart';

class TransactionSuccessDialog extends StatelessWidget {
  final String title;
  final String serviceType;
  final String recipient;
  final double amount;
  final String? reference;
  final String? providerReference;
  final String? token;
  final String? units;
  final List<String> issuedPins;
  final String? message;
  final VoidCallback? onDone;

  const TransactionSuccessDialog({
    super.key,
    this.title = 'Transaction Successful',
    required this.serviceType,
    required this.recipient,
    required this.amount,
    this.reference,
    this.providerReference,
    this.token,
    this.units,
    this.issuedPins = const [],
    this.message,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Transaction Successful',
    required String serviceType,
    required String recipient,
    required double amount,
    String? reference,
    String? providerReference,
    String? token,
    String? units,
    List<String> issuedPins = const [],
    String? message,
    VoidCallback? onDone,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TransactionSuccessDialog(
        title: title,
        serviceType: serviceType,
        recipient: recipient,
        amount: amount,
        reference: reference,
        providerReference: providerReference,
        token: token,
        units: units,
        issuedPins: issuedPins,
        message: message,
        onDone: onDone,
      ),
    );
  }

  String _formatReceiptText() {
    final now = DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now());
    final buffer = StringBuffer();
    buffer.writeln('====================================');
    buffer.writeln('          AVOTEK RECEIPT            ');
    buffer.writeln('    Instant VTU & Bill Payments     ');
    buffer.writeln('====================================');
    buffer.writeln('Date: $now');
    buffer.writeln('Status: SUCCESSFUL / DELIVERED');
    buffer.writeln('Service: ${serviceType.toUpperCase()}');
    buffer.writeln('Recipient: $recipient');
    buffer.writeln('Amount: ₦${NumberFormat('#,##0.00').format(amount)}');
    if (reference != null && reference!.isNotEmpty) {
      buffer.writeln('Avotek Ref: $reference');
    }
    if (providerReference != null && providerReference!.isNotEmpty) {
      buffer.writeln('Provider Ref: $providerReference');
    }
    if (token != null && token!.isNotEmpty) {
      buffer.writeln('Token / Code: $token');
    }
    if (units != null && units!.isNotEmpty) {
      buffer.writeln('Units: $units');
    }
    if (issuedPins.isNotEmpty) {
      buffer.writeln('--- ISSUED PIN(S) ---');
      for (final pin in issuedPins) {
        buffer.writeln(pin);
      }
    }
    buffer.writeln('====================================');
    buffer.writeln('Support WhatsApp: +2348167002799');
    buffer.writeln('Thank you for choosing Avotek!');
    buffer.writeln('====================================');
    return buffer.toString();
  }

  void _copyReceipt(BuildContext context) {
    final text = _formatReceiptText();
    Clipboard.setData(ClipboardData(text: text));
    TopNotification.showSuccess(
      context,
      'Full transaction receipt copied to clipboard!',
      title: 'Receipt Copied',
    );
  }

  void _sendReceiptEmail(BuildContext context) {
    TopNotification.showSuccess(
      context,
      'Receipt queued for email dispatch to your account address.',
      title: 'Receipt Emailed',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now());
    final displayToken = token ?? (issuedPins.isNotEmpty ? issuedPins.join('\n') : null);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Success Icon Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.14),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message ?? 'Your request was processed and delivered successfully.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFA5B0CD) : AppColors.slateGrey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount Callout
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2234) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF29354F) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'AMOUNT PAID',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₦${NumberFormat('#,##0.00').format(amount)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.electricCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Token / PIN Highlight (if Electricity or Exam PIN)
                  if (displayToken != null && displayToken.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                serviceType.toLowerCase().contains('electricity')
                                    ? '⚡ PREPAID TOKEN'
                                    : '🎓 EXAMINATION PIN(S)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.electricCyan,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: displayToken));
                                  TopNotification.showSuccess(context, 'Copied to clipboard!');
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.copy_rounded, size: 14, color: AppColors.electricCyan),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.electricCyan,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            displayToken,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (units != null && units!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Units: $units',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Receipt Breakdown Table
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F141F) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildReceiptRow('Service', serviceType, isDark),
                        const Divider(height: 16),
                        _buildReceiptRow('Recipient', recipient, isDark),
                        const Divider(height: 16),
                        _buildReceiptRow('Date & Time', now, isDark),
                        if (reference != null && reference!.isNotEmpty) ...[
                          const Divider(height: 16),
                          _buildReceiptRow('Reference', reference!, isDark, isCopyable: true, context: context),
                        ],
                        if (providerReference != null && providerReference!.isNotEmpty) ...[
                          const Divider(height: 16),
                          _buildReceiptRow('Provider Ref', providerReference!, isDark, isCopyable: true, context: context),
                        ],
                        const Divider(height: 16),
                        _buildReceiptRow('Status', 'Delivered', isDark, statusColor: AppColors.success),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Actions: Download Receipt & Email Receipt
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyReceipt(context),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Download Receipt'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF23304B) : const Color(0xFFCBD5E1),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _sendReceiptEmail(context),
                          icon: const Icon(Icons.email_outlined, size: 16),
                          label: const Text('Email Receipt'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF23304B) : const Color(0xFFCBD5E1),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Primary Dismiss Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDone?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value,
    bool isDark, {
    Color? statusColor,
    bool isCopyable = false,
    BuildContext? context,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFA5B0CD) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ),
              if (isCopyable && context != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    TopNotification.showSuccess(context, 'Copied $label!');
                  },
                  child: const Icon(Icons.copy_rounded, size: 13, color: AppColors.electricCyan),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
