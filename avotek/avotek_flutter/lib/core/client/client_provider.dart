import 'package:avotek_client/avotek_client.dart';
import 'package:flutter/foundation.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

class ClientProvider {
  static late final Client client;

  static String get defaultServerUrl {
    if (kIsWeb) {
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

    client = Client(serverUrl)
      ..connectivityMonitor = FlutterConnectivityMonitor();
  }
}
