import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../history_model/transaction_record.dart';

class DevTransactionStorage {
  DevTransactionStorage({required this.devEnabled});

  final bool devEnabled;

  static const String _webKeyPrefix = 'tx_history_v1__';

  String _safeId(String userId) =>
      userId.replaceAll(RegExp(r'[^a-zA-Z0-9_.@-]'), '_');

  Future<Directory> _getDevDir() async {
    final dir = await getApplicationSupportDirectory();
    final historyDir = Directory('${dir.path}/dev_wallets');
    if (!await historyDir.exists()) {
      await historyDir.create(recursive: true);
    }
    return historyDir;
  }

  Future<String> _filePathFor(String userId) async {
    final dir = await _getDevDir();
    return '${dir.path}/${_safeId(userId)}.history.json';
  }

  Future<List<TransactionRecord>> loadHistory(String userId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_webKeyPrefix${_safeId(userId)}');
      if (raw == null || raw.isEmpty) return const <TransactionRecord>[];
      try {
        final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
        return data
            .cast<Map<String, dynamic>>()
            .map(TransactionRecord.fromJson)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } catch (e) {
        debugPrint('Failed to parse web history: $e');
        return const <TransactionRecord>[];
      }
    }

    final path = await _filePathFor(userId);
    final file = File(path);
    if (!await file.exists()) return const [];
    final jsonStr = await file.readAsString();
    final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(TransactionRecord.fromJson)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveHistory(
    String userId,
    List<TransactionRecord> history,
  ) async {
    final payload = jsonEncode(
      history.map((entry) => entry.toJson()).toList(growable: false),
    );

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_webKeyPrefix${_safeId(userId)}', payload);
      return;
    }

    final path = await _filePathFor(userId);
    final file = File(path);
    await file.writeAsString(payload, flush: true);
    debugPrint('[DEV] History saved: $path');
  }
}
