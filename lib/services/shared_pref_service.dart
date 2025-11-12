import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  // --- Singleton pattern setup ---
  static final SharedPrefService _instance = SharedPrefService._internal();

  factory SharedPrefService() => _instance;

  SharedPrefService._internal();

  static SharedPreferences? _prefs;

  // --- Initialize once (call this in main.dart before runApp) ---
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Setters ---
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  Future<void> setList(String key, List<String> value) async {
    await _prefs?.setStringList(key, value);
  }

  // --- Getters ---
  String? getString(String key) => _prefs?.getString(key);
  int? getInt(String key) => _prefs?.getInt(key);
  bool? getBool(String key) => _prefs?.getBool(key);
  double? getDouble(String key) => _prefs?.getDouble(key);
  List<String>? getList(String key) => _prefs?.getStringList(key);

  // --- Remove & Clear ---
  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  Future<void> clear() async {
    await _prefs?.clear();
  }
}
