import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/tokens.dart';

/// Paystack's hosted checkout (sandbox), rendered in-app. Pops `true` once the
/// student finishes checkout (success *or* failure — the caller polls
/// GET /payments/:rrr/status to find out which), or `false` if they back out
/// without finishing.
///
/// Detection works by intercepting navigation to [AppConfig.paystackCallbackUrl]
/// — that URL never actually loads; the moment the WebView is *about* to
/// navigate there, checkout is done and this page closes itself.
class PaymentWebViewPage extends StatefulWidget {
  const PaymentWebViewPage({super.key, required this.authorizationUrl});
  final String authorizationUrl;

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _loadError;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => mounted ? setState(() => _loading = true) : null,
          onPageFinished: (_) => mounted ? setState(() => _loading = false) : null,
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _loadError = 'Could not load the payment page (${error.description}).';
            });
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith(AppConfig.paystackCallbackUrl)) {
              _close(finished: true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  void _close({required bool finished}) {
    if (_finished) return; // NavigationDelegate can fire more than once
    _finished = true;
    if (mounted) Navigator.of(context).pop(finished);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(finished: false);
      },
      child: Scaffold(
        backgroundColor: RoostColors.surface0,
        appBar: AppBar(
          backgroundColor: RoostColors.surface1,
          elevation: 0,
          leading: IconButton(
            icon: Icon(PhosphorIcons.x(), color: RoostColors.textPrimary),
            onPressed: () => _close(finished: false),
          ),
          title: Text('Pay with Paystack',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RoostColors.textPrimary)),
        ),
        body: Stack(
          children: [
            if (_loadError == null) WebViewWidget(controller: _controller),
            if (_loadError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(RoostSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.wifiSlash(), size: 40, color: RoostColors.textTertiary),
                      const SizedBox(height: RoostSpacing.md),
                      Text(_loadError!, textAlign: TextAlign.center,
                          style: TextStyle(color: RoostColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            if (_loading && _loadError == null)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
