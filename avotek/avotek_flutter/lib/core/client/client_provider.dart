import 'package:avotek_client/avotek_client.dart';
import 'package:flutter/foundation.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

class ClientProvider {
  static late final Client client;

  static String get defaultServerUrl {
    // 1. Allow build-time override via --dart-define=SERVER_URL=... or API_URL=...
    const fromServerEnv = String.fromEnvironment('SERVER_URL');
    if (fromServerEnv.isNotEmpty) return fromServerEnv;

    const fromApiEnv = String.fromEnvironment('API_URL');
    if (fromApiEnv.isNotEmpty) return fromApiEnv;

    if (kIsWeb) {
      final uri = Uri.base;
      // If deployed on web (not localhost/127.0.0.1)
      if (uri.host.isNotEmpty && uri.host != 'localhost' && uri.host != '127.0.0.1') {
        if (uri.scheme == 'https') {
          return 'https://${uri.host}:8080/';
        }
        return 'http://${uri.host}:8080/';
      }
      return 'http://127.0.0.1:8080/';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 is the Android emulator loopback alias to host machine localhost
      return 'http://10.0.2.2:8080/';
    } else {
      return 'http://127.0.0.1:8080/';
    }
  }

  static Future<void> initialize({String? overrideUrl}) async {
    final serverUrl = overrideUrl ?? defaultServerUrl;

    client = Client(serverUrl);
    // On web, FlutterConnectivityMonitor can fail/hang; only attach on native platforms
    if (!kIsWeb) {
      try {
        client.connectivityMonitor = FlutterConnectivityMonitor();
      } catch (_) {}
    }
  }
}
