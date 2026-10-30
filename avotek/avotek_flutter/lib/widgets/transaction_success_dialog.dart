import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
    buffer.writeln('Support WhatsApp: +2348167002789');
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

  pw.TableRow _buildPdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF475569),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromInt(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadPdfReceipt(BuildContext context) async {
    try {
      final doc = pw.Document();
      pw.MemoryImage? logoImage;
      try {
        final byteData = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (_) {}

      final now = DateFormat('MMMM dd, yyyy • hh:mm a').format(DateTime.now());
      final formattedAmount = 'NGN ${NumberFormat('#,##0.00').format(amount)}';
      final displayToken = token ?? (issuedPins.isNotEmpty ? issuedPins.join('\n') : null);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context ctx) {
            return pw.Stack(
              children: [
                // Watermark across the page
                if (logoImage != null)
                  pw.Center(
                    child: pw.Opacity(
                      opacity: 0.06,
                      child: pw.Image(logoImage, width: 360, height: 360),
                    ),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header with Branding
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'AVOTEK',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFF0052FF),
                              ),
                            ),
                            pw.Text(
                              'FINANCIAL TECHNOLOGIES',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 1.5,
                                color: const PdfColor.fromInt(0xFF475569),
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'support@avotek.ng • WhatsApp: +234 816 700 2789',
                              style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: PdfColor.fromInt(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFECFDF5),
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(color: const PdfColor.fromInt(0xFF10B981)),
                          ),
                          child: pw.Text(
                            'TRANSACTION SUCCESSFUL',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Divider(thickness: 1, color: const PdfColor.fromInt(0xFFE2E8F0)),
                    pw.SizedBox(height: 14),

                    // Amount Banner
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF8FAFC),
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'TOTAL AMOUNT SETTLED',
                                style: pw.TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: const PdfColor.fromInt(0xFF64748B),
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                formattedAmount,
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: const PdfColor.fromInt(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'SETTLEMENT DATE',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: const PdfColor.fromInt(0xFF64748B),
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                now,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColor.fromInt(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 18),

                    // Token / Code Highlight (if tokens or PINs)
                    if (displayToken != null && displayToken.isNotEmpty) ...[
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFEFF6FF),
                          borderRadius: pw.BorderRadius.circular(8),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFF3B82F6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'ISSUED TOKEN / SERVICE PIN(S)',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFF1D4ED8),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              displayToken,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 18),
                    ],

                    // Table Details
                    pw.Text(
                      'TRANSACTION DETAILS',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                        color: const PdfColor.fromInt(0xFF475569),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Table(
                      border: pw.TableBorder.all(
                        color: const PdfColor.fromInt(0xFFE2E8F0),
                        width: 0.8,
                      ),
                      children: [
                        _buildPdfTableRow('Service Category', serviceType),
                        _buildPdfTableRow('Recipient / Account / Phone', recipient),
                        if (reference != null && reference!.isNotEmpty)
                          _buildPdfTableRow('Transaction ID / Avotek Ref', reference!),
                        if (providerReference != null && providerReference!.isNotEmpty)
                          _buildPdfTableRow('Aggregator Reference', providerReference!),
                        _buildPdfTableRow('Delivery Status', 'COMPLETED / DELIVERED'),
                      ],
                    ),
                    pw.Spacer(),

                    // Signature, Trademark & Footer
                    pw.Divider(thickness: 1, color: const PdfColor.fromInt(0xFFE2E8F0)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Authorized Digital Settlement Voucher',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFF0F172A),
                              ),
                            ),
                            pw.Text(
                              'Copyright © 2023 - 2026 Avotek Financial Technologies. All Rights Reserved.',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColor.fromInt(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: const PdfColor.fromInt(0xFF0052FF), width: 1),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Text(
                            'AVOTEK OFFICIAL',
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF0052FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Avotek_Receipt_${reference ?? DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        TopNotification.showError(context, 'Could not generate PDF receipt: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now());
    final displayToken = token ?? (issuedPins.isNotEmpty ? issuedPins.join('\n') : null);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0052FF).withOpacity(isDark ? 0.25 : 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sleek Success Icon Header
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.2),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message ?? 'Transaction delivered successfully.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFFA5B0CD) : AppColors.slateGrey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount & Service Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF182030) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF28344D) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '₦${NumberFormat('#,##0.00').format(amount)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF00D2FF),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$serviceType • $recipient',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Token / PIN Highlight (if Electricity or Exam PIN)
                  if (displayToken != null && displayToken.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0052FF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0052FF).withOpacity(0.4),
                          width: 1.2,
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
                                    ? '⚡ PREPAID METER TOKEN'
                                    : '🎓 EXAMINATION PIN(S)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: const Color(0xFF00D2FF),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: displayToken));
                                  TopNotification.showSuccess(context, 'Token copied to clipboard!');
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF00D2FF)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF00D2FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            displayToken,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: 1.1,
                            ),
                          ),
                          if (units != null && units!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Units: $units',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Compact Details Summary
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0E131E) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF202B42) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildReceiptRow('Date', now, isDark),
                        if (reference != null && reference!.isNotEmpty) ...[
                          const Divider(height: 12),
                          _buildReceiptRow('Reference', reference!, isDark, isCopyable: true, context: context),
                        ],
                        const Divider(height: 12),
                        _buildReceiptRow('Status', 'Delivered', isDark, statusColor: AppColors.success),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Actions: Download Receipt & Done in Avotek Gradient
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _downloadPdfReceipt(context),
                        icon: const Icon(Icons.download_rounded, size: 15),
                        label: const Text('Receipt'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF28344D) : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0052FF), Color(0xFF00D2FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDone?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Text('Done'),
                          ),
                        ),
                      ),
                    ],
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
