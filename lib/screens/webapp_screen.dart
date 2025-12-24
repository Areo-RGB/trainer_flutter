import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';

import '../webapp_server.dart';

/// Screen that launches the React webapp in a WebView window.
class WebappScreen extends StatefulWidget {
  const WebappScreen({super.key});

  @override
  State<WebappScreen> createState() => _WebappScreenState();
}

class _WebappScreenState extends State<WebappScreen> {
  final WebappServer _server = WebappServer();
  bool _isLoading = true;
  String? _error;
  bool _webviewOpened = false;

  @override
  void initState() {
    super.initState();
    _initWebapp();
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  Future<void> _initWebapp() async {
    try {
      // Check if WebView is supported
      final isSupported = await WebviewWindow.isWebviewAvailable();
      if (!isSupported) {
        setState(() {
          _error = 'WebView not supported on this platform.\n'
              'Please install WebKitGTK (libwebkit2gtk-4.1-dev).';
          _isLoading = false;
        });
        return;
      }

      // Start server
      await _server.start();

      setState(() {
        _isLoading = false;
      });

      // Auto-open WebView immediately
      _openWebView();
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openWebView() async {
    if (_server.url == null) return;

    setState(() => _webviewOpened = true);

    final webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        title: 'Training',
        titleBarTopPadding: 0,
        windowWidth: 1200,
        windowHeight: 800,
      ),
    );

    webview.launch(_server.url!);

    // Exit app when WebView closes
    webview.onClose.whenComplete(() {
      exit(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show minimal UI - the WebView is the main interface
    // This Flutter window will be in background after WebView opens
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _initWebapp();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Simple loading screen - WebView opens automatically
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Starting...'),
          ],
        ),
      ),
    );
  }
}

