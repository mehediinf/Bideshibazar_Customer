// lib/presentation/payment/payment_webview.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:developer' as developer;

class PaymentWebView extends StatefulWidget {
  final String checkoutUrl;

  const PaymentWebView({
    super.key,
    required this.checkoutUrl,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  static const String TAG = "PaymentWebView";

  late final WebViewController _controller;
  bool _isLoading = false;
  bool _dashboardButtonInjected = false;

  @override
  void initState() {
    super.initState();

    developer.log("   PaymentWebViewActivity Started", name: TAG);
    developer.log("   Checkout URL: ${widget.checkoutUrl}", name: TAG);

    // Validate checkout URL
    if (!_isValidCheckoutUrl(widget.checkoutUrl)) {
      developer.log("Invalid checkout URL: ${widget.checkoutUrl}", name: TAG);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This payment link is not valid.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, 'cancelled');
      });
      return;
    }

    developer.log(" URL validation passed", name: TAG);

    _initializeWebView();
  }

  void _initializeWebView() {
    // Platform-specific parameters
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);

    // Android-specific settings
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _dashboardButtonInjected = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            developer.log(" Page loaded: $url", name: TAG);

            final uri = Uri.parse(url);

            // Check for bideshibazar.com pages (success/failure pages)
            if (uri.host.endsWith('bideshibazar.com')) {
              _injectDashboardButtonListener();

              // Check for success/failure ONLY on bideshibazar.com
              if (url.contains('payment-success') ||
                  url.contains('complete') ||
                  url.contains('success')) {
                developer.log("Payment Success page loaded - waiting for user action", name: TAG);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment Successful'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else if (url.contains('payment-failed') ||
                  url.contains('cancel') ||
                  url.contains('failed')) {

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment was not completed.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            final host = uri.host;


            // Allow mollie.com and bideshibazar.com inside WebView
            if (host != null &&
                (host.endsWith('mollie.com') || host.endsWith('bideshibazar.com'))) {
              return NavigationDecision.navigate;
            }

            developer.log("Blocked external redirect: ${request.url}", name: TAG);
            return NavigationDecision.prevent;
          },
          onWebResourceError: (WebResourceError error) {
            developer.log("WebView error: ${error.description}", name: TAG);
          },
        ),
      )
      ..addJavaScriptChannel(
        'AndroidBridge',
        onMessageReceived: (JavaScriptMessage message) {
          developer.log("JavaScript message received: ${message.message}", name: TAG);
          if (message.message == 'onDashboardClicked') {
            _onDashboardClicked();
          }
        },
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));

    _controller = controller;
  }

  /// Validate checkout URL - allow mollie.com and bideshibazar.com
  bool _isValidCheckoutUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final scheme = uri.scheme;
      final host = uri.host;

      developer.log("Validating URL - Scheme: $scheme, Host: $host", name: TAG);

      // Must be HTTPS
      if (scheme != 'https') {
        developer.log("Invalid scheme: $scheme", name: TAG);
        return false;
      }

      // Allow mollie.com (payment gateway) and bideshibazar.com (success/failure pages)
      if (host.endsWith('mollie.com') || host.endsWith('bideshibazar.com')) {
        return true;
      }

      return false;
    } catch (e) {
      developer.log("URL parsing error: $e", name: TAG);
      return false;
    }
  }

  /// Inject JavaScript to listen for dashboard button clicks
  void _injectDashboardButtonListener() {
    if (_dashboardButtonInjected) return;

    _controller.runJavaScript('''
      (function() {
        var buttons = document.getElementsByClassName('button');
        for (var i = 0; i < buttons.length; i++) {
          if (buttons[i].innerText.trim() === 'Go to Dashboard') {
            buttons[i].addEventListener('click', function(e) {
              e.preventDefault();
              AndroidBridge.postMessage('onDashboardClicked');
            });
          }
        }
      })();
    ''');

    setState(() {
      _dashboardButtonInjected = true;
    });
  }

  /// Handle dashboard button click
  void _onDashboardClicked() {
    developer.log("Dashboard button clicked", name: TAG);
    _goToDashboard();
  }

  /// Navigate to dashboard with payment status
  Future<void> _goToDashboard() async {

    // Determine payment status based on current URL
    final currentUrl = await _controller.currentUrl();
    String paymentStatus = 'cancelled'; // default

    if (currentUrl != null) {
      if (currentUrl.contains('payment-success') ||
          currentUrl.contains('complete') ||
          currentUrl.contains('success')) {
        paymentStatus = 'success';
        developer.log("Payment Status: SUCCESS", name: TAG);
      } else if (currentUrl.contains('payment-failed') ||
          currentUrl.contains('cancel') ||
          currentUrl.contains('failed')) {
        paymentStatus = 'failed';
        developer.log("Payment Status: FAILED", name: TAG);
      }
    }

    // Return result
    if (mounted) {
      Navigator.pop(context, paymentStatus);
    }
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    } else {
      if (mounted) {
        Navigator.pop(context, 'cancelled');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              await _onWillPop();
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading payment...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
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
}
