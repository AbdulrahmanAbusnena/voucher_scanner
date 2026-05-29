// lib/core/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // usin the modern decoupled asynchronous storage API
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const String _historyKey = 'ly_voucher_history_log';

  /// this basically serializes
  Future<void> saveVoucherRawList(
    List<Map<String, dynamic>> rawJsonList,
  ) async {
    final String serializedString = jsonEncode(rawJsonList);
    await _prefs.setString(_historyKey, serializedString);
  }

  /// here we are extracting  string logs from persistence and we're parssing them back
  Future<List<Map<String, dynamic>>> getVoucherRawList() async {
    final String? serializedString = await _prefs.getString(_historyKey);

    if (serializedString == null) return [];

    try {
      final List<dynamic> decodedList = jsonDecode(serializedString);
      return decodedList
          .map((element) => Map<String, dynamic>.from(element))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
