// lib/models/transaction_record.dart
// Модель записи транзакции в кошельке.
/// Используется для DEV-хранилища и отображения истории.

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.tokenSymbol,
    required this.amount,
    required this.incoming,
    required this.timestamp,
    this.txHash,
    this.note,
  });

  final String id;
  final String tokenSymbol;
  final double amount;
  final bool incoming;
  final DateTime timestamp;
  final String? txHash;
  final String? note;

  TransactionRecord copyWith({
    String? id,
    String? tokenSymbol,
    double? amount,
    bool? incoming,
    DateTime? timestamp,
    String? txHash,
    String? note,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      amount: amount ?? this.amount,
      incoming: incoming ?? this.incoming,
      timestamp: timestamp ?? this.timestamp,
      txHash: txHash ?? this.txHash,
      note: note ?? this.note,
    );
  }

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String,
      tokenSymbol: json['tokenSymbol'] as String,
      amount: (json['amount'] as num).toDouble(),
      incoming: json['incoming'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      txHash: json['txHash'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tokenSymbol': tokenSymbol,
      'amount': amount,
      'incoming': incoming,
      'timestamp': timestamp.toIso8601String(),
      'txHash': txHash,
      'note': note,
    };
  }
}
