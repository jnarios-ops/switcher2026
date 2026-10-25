import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../config.dart';
import '../native_shell.dart';
import '../theme.dart';

class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> with WidgetsBindingObserver {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _controller == null && !_loading) {
      _boot();
    }
  }

  Future<void> _boot() async {
    await Permission.locationWhenInUse.request();
    final info = await PackageInfo.fromPlatform();
    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setBackgroundColor(SwColors.bg);
    controller.setUserAgent(
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 SwitcherGPS/${info.version}',
    );
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) {
            setState(() {
              _loading = true;
              _error = null;
            });
          }
        },
        onPageFinished: (_) async {
          try {
            await controller.runJavaScript(NativeShell.injectJs);
          } catch (_) {}
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (err) {
          if (err.isForMainFrame == false) return;
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = 'No se pudo cargar el portal. Revisa tu conexión.';
          });
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          if (_openExternally(uri)) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          if (_leaveClientArea(uri)) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );

    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      await android.setMediaPlaybackRequiresUserGesture(false);
      android.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          final status = await Permission.locationWhenInUse.request();
          return GeolocationPermissionsResponse(
            allow: status.isGranted,
            retain: true,
          );
        },
      );
      android.setOnPlatformPermissionRequest((request) {
        request.grant();
      });
    }

    await controller.loadRequest(Uri.parse(AppConfig.portalUrl));
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  bool _openExternally(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'tel' || scheme == 'mailto' || scheme == 'sms') return true;
    if (scheme == 'whatsapp' || scheme == 'intent') return true;
    final host = uri.host.toLowerCase();
    if (host.contains('wa.me') || host.contains('whatsapp.com')) return true;
    if (host.contains('maps.google.') ||
        (host.contains('google.com') && uri.path.contains('/maps'))) {
      return true;
    }
    if (host.contains('play.google.com') || host.contains('apps.apple.com')) {
      return true;
    }
    return false;
  }

  bool _leaveClientArea(Uri uri) {
    final host = uri.host.toLowerCase();
    if (!host.contains('switcher.cl')) return false;
    final path = uri.path.isEmpty ? '/' : uri.path;
    if (path.startsWith('/clientes') ||
        path.startsWith('/seguir') ||
        path.startsWith('/assets') ||
        path.startsWith('/uploads')) {
      return false;
    }
    return true;
  }

  Future<void> _handleBack() async {
    final c = _controller;
    if (c != null && await c.canGoBack()) {
      await c.goBack();
      return;
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: SwColors.bg,
        body: Stack(
          children: [
              if (controller != null && _error == null)
                WebViewWidget(controller: controller),
              if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _loading = true;
                            });
                            controller?.reload();
                            if (controller == null) _boot();
                          },
                          style: FilledButton.styleFrom(
                              backgroundColor: SwColors.accent),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_loading && _error == null)
                const ColoredBox(
                  color: SwColors.bg,
                  child: Center(
                    child: CircularProgressIndicator(color: SwColors.accent),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
