import 'package:flutter/foundation.dart';
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
      final displayToken =
          token ?? (issuedPins.isNotEmpty ? issuedPins.join('\n') : null);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context ctx) {
            return pw.Stack(
              children: [
                // Tilted 45-degree rounded border-radius transparent logo watermark pattern
                if (logoImage != null)
                  pw.Positioned.fill(
                    child: pw.Opacity(
                      opacity: 0.045,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (rowIdx) {
                          return pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (colIdx) {
                              return pw.Transform.rotate(
                                angle: -0.785398,
                                child: pw.ClipRRect(
                                  horizontalRadius: 10,
                                  verticalRadius: 10,
                                  child: pw.Image(
                                    logoImage!,
                                    width: 52,
                                    height: 52,
                                    fit: pw.BoxFit.contain,
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header with Branding
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            if (logoImage != null)
                              pw.Container(
                                width: 44,
                                height: 44,
                                padding: const pw.EdgeInsets.all(5),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.white,
                                  borderRadius: pw.BorderRadius.circular(10),
                                  border: pw.Border.all(
                                    color: const PdfColor.fromInt(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                child: pw.ClipRRect(
                                  horizontalRadius: 6,
                                  verticalRadius: 6,
                                  child: pw.Image(
                                    logoImage,
                                    fit: pw.BoxFit.contain,
                                  ),
                                ),
                              ),
                            pw.SizedBox(width: 10),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'AVOTEK',
                                  style: pw.TextStyle(
                                    fontSize: 20,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor.fromInt(0xFF0052FF),
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'support@avotek.com.ng • WhatsApp: +234 816 700 2789',
                                  style: const pw.TextStyle(
                                    fontSize: 8.5,
                                    color: PdfColor.fromInt(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFECFDF5),
                            borderRadius: pw.BorderRadius.circular(8),
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
                    pw.SizedBox(height: 14),

                    // Amount Banner
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF8FAFC),
                        borderRadius: pw.BorderRadius.circular(12),
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
                      border: null,
                      children: [
                        _buildPdfTableRow('Service Category', serviceType),
                        _buildPdfTableRow(
                          'Recipient / Account / Phone',
                          recipient,
                        ),
                        if (reference != null && reference!.isNotEmpty)
                          _buildPdfTableRow(
                            'Transaction ID / Avotek Ref',
                            reference!,
                          ),
                        if (providerReference != null &&
                            providerReference!.isNotEmpty)
                          _buildPdfTableRow(
                            'Aggregator Reference',
                            providerReference!,
                          ),
                        _buildPdfTableRow(
                          'Delivery Status',
                          'COMPLETED / DELIVERED',
                        ),
                      ],
                    ),
                    pw.Spacer(),

                    // Signature, Trademark & Footer
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
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
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
        name:
            'Avotek_Receipt_${reference ?? DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        TopNotification.showError(
          context,
          'Could not generate PDF receipt: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now());
    final displayToken =
        token ?? (issuedPins.isNotEmpty ? issuedPins.join('\n') : null);

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.none,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Opacity(
                      opacity: isDark ? 0.025 : 0.035,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (r) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(2, (c) {
                              return Transform.rotate(
                                angle: -0.785398,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 58,
                                    height: 58,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
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
                    style: GoogleFonts.figtree(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message ?? 'Transaction delivered successfully.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      fontSize: 12.5,
                      color: isDark
                          ? const Color(0xFFA5B0CD)
                          : AppColors.slateGrey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0E131E)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '₦${NumberFormat('#,##0.00').format(amount)}',
                          style: GoogleFonts.figtree(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0052FF),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$serviceType • $recipient',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.figtree(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Token / PIN details remain plain text instead of a large panel.
                  if (displayToken != null && displayToken.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            serviceType.toLowerCase().contains('electricity')
                                ? 'PREPAID METER TOKEN'
                                : 'EXAMINATION PIN(S)',
                            style: GoogleFonts.figtree(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: const Color(0xFF0052FF),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: displayToken),
                            );
                            TopNotification.showSuccess(
                              context,
                              'Token copied to clipboard.',
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 13),
                          label: const Text('Copy'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0052FF),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      displayToken,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.figtree(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (units != null && units!.isNotEmpty)
                      Text(
                        'Units: $units',
                        style: GoogleFonts.figtree(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 14),
                  ],

                  // Compact Details Summary
                  Column(
                    children: [
                      _buildReceiptRow('Date', now, isDark),
                      if (reference != null && reference!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildReceiptRow(
                          'Reference',
                          reference!,
                          isDark,
                          isCopyable: true,
                          context: context,
                        ),
                      ],
                      if (providerReference != null && providerReference!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildReceiptRow(
                          'Aggregator Ref',
                          providerReference!,
                          isDark,
                          isCopyable: true,
                          context: context,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildReceiptRow(
                        'Status',
                        'Delivered',
                        isDark,
                        statusColor: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Actions: Download Receipt, Share Link & Done in Avotek Gradient
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _downloadPdfReceipt(context),
                        icon: const Icon(Icons.download_rounded, size: 15),
                        label: Text(
                          'Receipt',
                          style: GoogleFonts.figtree(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF28344D)
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          final origin = kIsWeb
                              ? '${Uri.base.origin}${Uri.base.path}'
                              : 'https://adevictorolu.github.io/Avotek/';
                          final cleanOrigin = origin.endsWith('/')
                              ? origin.substring(0, origin.length - 1)
                              : origin;
                          final refParam = reference != null && reference!.isNotEmpty
                              ? '?ref=$reference'
                              : '';
                          final receiptLink = '$cleanOrigin/#/transactions$refParam';
                          Clipboard.setData(ClipboardData(text: receiptLink));
                          TopNotification.showSuccess(
                            context,
                            'Receipt link copied to clipboard!',
                          );
                        },
                        icon: const Icon(Icons.link_rounded, size: 15),
                        label: Text(
                          'Share Link',
                          style: GoogleFonts.figtree(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF28344D)
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
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
                              textStyle: GoogleFonts.figtree(
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
          ],
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
          style: GoogleFonts.figtree(
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
                  style: GoogleFonts.figtree(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color:
                        statusColor ??
                        (isDark ? Colors.white : const Color(0xFF0F172A)),
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
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: AppColors.electricCyan,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
