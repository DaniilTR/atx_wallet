// lib/WalletSecureStorage/history_model/transaction_storage.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'transaction_record.dart';

/// Локальное хранилище истории операций.
///
/// история хранится в SharedPreferences
/// (на всех платформах одинаково) под ключом, зависящим от `storageId`.
class TransactionStorage {
  static const String _prefix = 'tx_history_v1__';

  String _key(String storageId) => '$_prefix$storageId';

  Future<List<TransactionRecord>> loadHistory(String storageId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(storageId));
    if (raw == null || raw.isEmpty) return const <TransactionRecord>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <TransactionRecord>[];

    final out = <TransactionRecord>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        out.add(TransactionRecord.fromJson(item));
      } else if (item is Map) {
        out.add(TransactionRecord.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return out;
  }

  Future<void> saveHistory(
    String storageId,
    List<TransactionRecord> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = records.map((e) => e.toJson()).toList(growable: false);
    await prefs.setString(_key(storageId), jsonEncode(data));
  }

  Future<void> clearHistory(String storageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(storageId));
  }
}
