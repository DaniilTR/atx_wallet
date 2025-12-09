import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/transaction_record.dart';
import '../services/config.dart';

class DevTransactionStorage {
  DevTransactionStorage({required this.devEnabled});

  final bool devEnabled;

  Uri _historyUri(String userId) {
    final base = kApiBaseUrl.endsWith('/')
        ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 1)
        : kApiBaseUrl;
    return Uri.parse(
      '$base/api/dev-wallet-history/${Uri.encodeComponent(userId)}',
    );
  }

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
      if (!devEnabled) return const [];
      final response = await http.get(_historyUri(userId));
      if (response.statusCode == 404) return const [];
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to load history: HTTP ${response.statusCode}');
      }
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .cast<Map<String, dynamic>>()
          .map(TransactionRecord.fromJson)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
      if (!devEnabled) return;
      final response = await http.put(
        _historyUri(userId),
        headers: const {'Content-Type': 'application/json'},
        body: payload,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to save history: HTTP ${response.statusCode}');
      }
      return;
    }

    final path = await _filePathFor(userId);
    final file = File(path);
    await file.writeAsString(payload, flush: true);
    debugPrint('[DEV] History saved: $path');
  }
}
