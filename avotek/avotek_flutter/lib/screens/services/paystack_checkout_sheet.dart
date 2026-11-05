import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaystackCheckoutSheet extends StatefulWidget {
  const PaystackCheckoutSheet({
    super.key,
    required this.checkoutUri,
    required this.isDark,
    required this.onClose,
  });

  final Uri checkoutUri;
  final bool isDark;
  final VoidCallback onClose;

  @override
  State<PaystackCheckoutSheet> createState() => _PaystackCheckoutSheetState();
}

class _PaystackCheckoutSheetState extends State<PaystackCheckoutSheet> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _loadError = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _loadError =
                    'Checkout could not load. Check your connection and retry.';
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            return uri != null && uri.scheme == 'https'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(widget.checkoutUri);
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.isDark ? const Color(0xFF0D1422) : Colors.white;
    final foreground = widget.isDark ? Colors.white : const Color(0xFF172033);

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.84,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: background,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF0052FF),
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Secure Paystack Checkout',
                          style: GoogleFonts.figtree(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Return to Avotek',
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close_rounded),
                        color: foreground,
                      ),
                    ],
                  ),
                ),
                if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: _loadError == null
                      ? WebViewWidget(controller: _controller)
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  color: foreground.withValues(alpha: 0.65),
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _loadError!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.figtree(
                                    color: foreground,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton(
                                  onPressed: () => _controller.reload(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Text(
                    'Your payment is verified securely by Paystack. Avotek will return here when it is complete.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      fontSize: 11,
                      color: foreground.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
