import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Serves the bundled React webapp assets on a local HTTP server.
class WebappServer {
  HttpServer? _server;
  int? _port;

  /// The port the server is running on, null if not started.
  int? get port => _port;

  /// The base URL to access the webapp.
  String? get url => _port != null ? 'http://localhost:$_port' : null;

  /// Starts the server on an available port.
  /// Returns the port number.
  Future<int> start() async {
    if (_server != null) {
      return _port!;
    }

    // Create the handler that serves from asset bundle
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addHandler(_assetHandler);

    // Find an available port
    _server = await shelf_io.serve(handler, 'localhost', 0);
    _port = _server!.port;

    print('WebappServer: Serving at http://localhost:$_port');
    return _port!;
  }

  /// Stops the server.
  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _port = null;
  }

  /// Handles requests by loading from Flutter assets.
  Future<Response> _assetHandler(Request request) async {
    var path = request.url.path;
    
    // Default to index.html for root
    if (path.isEmpty || path == '/') {
      path = 'index.html';
    }

    // Remove leading slash
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    final assetPath = 'assets/webapp/$path';

    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      
      return Response.ok(
        bytes,
        headers: {
          'Content-Type': _getMimeType(path),
        },
      );
    } catch (e) {
      // If not found, try to serve index.html for SPA routing
      if (!path.contains('.')) {
        try {
          final data = await rootBundle.load('assets/webapp/index.html');
          final bytes = data.buffer.asUint8List();
          return Response.ok(
            bytes,
            headers: {'Content-Type': 'text/html'},
          );
        } catch (_) {}
      }
      
      return Response.notFound('Not found: $path');
    }
  }

  /// CORS middleware for local development.
  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': '*',
  };

  /// Gets the MIME type for a file path.
  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'json':
        return 'application/json';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'svg':
        return 'image/svg+xml';
      case 'woff':
        return 'font/woff';
      case 'woff2':
        return 'font/woff2';
      default:
        return 'application/octet-stream';
    }
  }
}
