import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import 'top_notification.dart';

class PayForMeDialog extends StatelessWidget {
  final String serviceName;
  final String recipient;
  final double amount;
  final String? note;
  final String paymentLink;

  const PayForMeDialog({
    super.key,
    required this.serviceName,
    required this.recipient,
    required this.amount,
    this.note,
    required this.paymentLink,
  });

  static Future<void> show(
    BuildContext context, {
    required String serviceName,
    required String recipient,
    required double amount,
    String? examCode,
    int? quantity,
    String? note,
  }) async {
    final ref = 'PFM${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    final encService = Uri.encodeComponent(serviceName);
    final encRecip = Uri.encodeComponent(recipient);
    final examParam =
        examCode != null && examCode.isNotEmpty ? '&exam=${Uri.encodeComponent(examCode)}' : '';
    final qtyParam = quantity != null ? '&qty=$quantity' : '&qty=1';
    final noteParam =
        note != null && note.isNotEmpty ? '&note=${Uri.encodeComponent(note)}' : '';

    final origin =
        kIsWeb ? '${Uri.base.origin}${Uri.base.path}' : 'https://adevictorolu.github.io/Avotek/';
    final cleanOrigin = origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
    final link =
        '$cleanOrigin/#/pay?ref=$ref&service=$encService$examParam$qtyParam&amt=${amount.toInt()}&to=$encRecip$noteParam';

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PayForMeDialog(
        serviceName: serviceName,
        recipient: recipient,
        amount: amount,
        note: note,
        paymentLink: link,
      ),
    );
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    final text =
        'Hi! Please help me pay ₦${amount.toStringAsFixed(0)} for $serviceName ($recipient) on Avotek using this secure link:\n\n$paymentLink';
    final url = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        Clipboard.setData(ClipboardData(text: text));
        TopNotification.showSuccess(context, 'Payment request copied to clipboard!');
      }
    } catch (_) {
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: text));
        TopNotification.showSuccess(context, 'Payment request copied to clipboard!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0047FF), Color(0xFF0038B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D2FF).withOpacity(0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.share_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pay For Me Link Ready',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Share this link with a sponsor, friend, or family member to pay on your behalf.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // Bill summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2030) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: null,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Service', style: GoogleFonts.figtree(fontSize: 12.5, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                          Text(serviceName, style: GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recipient', style: GoogleFonts.figtree(fontSize: 12.5, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                          Text(recipient, style: GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Amount', style: GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                          Text(
                            '₦${amount.toStringAsFixed(2)}',
                            style: GoogleFonts.figtree(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0052FF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Copyable Link Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF151926) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: null,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 18, color: Color(0xFF0052FF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          paymentLink,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.figtree(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy Payment Link',
                        icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF0052FF)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: paymentLink));
                          TopNotification.showSuccess(context, 'Payment link copied to clipboard!');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Actions: Share to WhatsApp & Close
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareToWhatsApp(context),
                        icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF25D366)),
                        label: Text(
                          'WhatsApp',
                          style: GoogleFonts.figtree(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            Clipboard.setData(ClipboardData(text: paymentLink));
                            TopNotification.showSuccess(context, 'Link copied! Send it to your sponsor.');
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Copy & Done',
                            style: GoogleFonts.figtree(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
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
    );
  }
}
