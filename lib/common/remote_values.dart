import 'dart:developer';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfig {
  static String apiKey = "";

  static final RemoteConfig _instance = RemoteConfig._internal();

  factory RemoteConfig() => _instance;

  RemoteConfig._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(seconds: 1),
        ),
      );

      await _remoteConfig.fetchAndActivate();
      await updateRemoteData();

      log("✅ Remote Config fetched successfully");
    } catch (e) {
      log("❌ Remote Config fetch failed: $e");
    }
  }

  Future<void> updateRemoteData() async {
    apiKey = _remoteConfig.getString(RemoteConfigKeys.keyApiKey);
  }
}

class RemoteConfigKeys {
  static const keyApiKey = "api_key";
}