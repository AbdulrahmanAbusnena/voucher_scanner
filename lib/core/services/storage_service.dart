// lib/core/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Use the modern, decoupled asynchronous storage API instance
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const String _historyKey = 'ly_voucher_history_log';

  /// Serializes and commits a structured raw JSON map array map to disk storage.
  Future<void> saveVoucherRawList(
    List<Map<String, dynamic>> rawJsonList,
  ) async {
    final String serializedString = jsonEncode(rawJsonList);
    await _prefs.setString(_historyKey, serializedString);
  }

  /// Extracts historical string logs from persistence disk and parses them back to map entities.
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
