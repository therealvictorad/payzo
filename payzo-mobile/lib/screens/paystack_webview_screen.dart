import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/service_providers.dart';
import '../providers/wallet_provider.dart';

class PaystackWebViewScreen extends ConsumerStatefulWidget {
  final String authorizationUrl;
  final String reference;

  const PaystackWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  @override
  ConsumerState<PaystackWebViewScreen> createState() =>
      _PaystackWebViewScreenState();
}

class _PaystackWebViewScreenState extends ConsumerState<PaystackWebViewScreen> {
  late final WebViewController _controller;

  bool _pageLoading = true;
  bool _verifying   = false;
  bool _done        = false; // ensures verify + pop happen exactly once

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted:    (url) => _onUrlChange(url),
        onPageFinished:   (url) {
          if (mounted) setState(() => _pageLoading = false);
          _onUrlChange(url);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() => _pageLoading = false);
        },
        onNavigationRequest: (req) {
          _onUrlChange(req.url);
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  // ── Detect Paystack callback URLs ─────────────────────────────────────────
  void _onUrlChange(String url) {
    final lower = url.toLowerCase();
    final isCallback = lower.contains('callback') ||
        lower.contains('success') ||
        lower.contains('paystack.co/close') ||
        lower.contains('trxref=');

    if (isCallback && !_done) {
      // Small delay so the page finishes rendering before we pop
      Future.delayed(const Duration(milliseconds: 600), _verifyAndPop);
    }
  }

  // ── Single verify + pop — called from URL detection OR close button ───────
  Future<void> _verifyAndPop() async {
    if (_done || _verifying) return;
    if (mounted) setState(() => _verifying = true);
    _done = true;

    bool success = false;
    try {
      final status = await ref
          .read(paymentServiceProvider)
          .verifyPayment(widget.reference);
      success = status == 'success';
      if (success) {
        await ref.read(walletProvider.notifier).fetch();
      }
    } catch (_) {
      success = false;
    }

    if (mounted) Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        // Intercept back gesture — run verify before allowing pop
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _verifyAndPop();
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Secure Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _verifying ? null : _verifyAndPop,
            ),
            actions: [
              if (_verifying)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              WebViewWidget(controller: _controller),

              if (_pageLoading)
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading secure payment...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

              if (_verifying)
                Container(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Verifying payment...',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Please wait, do not close the app.',
                          style: Theme.of(context).textTheme.bodySmall,
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

/// Push the WebView and return true/false to the caller.
Future<bool> openPaystackWebView({
  required BuildContext context,
  required String authorizationUrl,
  required String reference,
}) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => PaystackWebViewScreen(
        authorizationUrl: authorizationUrl,
        reference:        reference,
      ),
    ),
  );
  return result ?? false;
}
