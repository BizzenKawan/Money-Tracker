class MoneyTransaction {
  final int? id;

  /// 'expense', 'income' or 'transfer'
  final String type;
  final double amount;

  /// null for transfers
  final int? categoryId;

  /// Source account. null means "not associated with any account".
  final int? accountId;

  /// Destination account, only used by transfers.
  final int? toAccountId;

  final String note;

  /// Gregorian date, kept for accurate ordering and weekday lookups.
  final DateTime adDate;

  /// Bikram Sambat parts, used for all grouping and filtering.
  final int bsYear;
  final int bsMonth;
  final int bsDay;

  const MoneyTransaction({
    this.id,
    required this.type,
    required this.amount,
    this.categoryId,
    this.accountId,
    this.toAccountId,
    this.note = '',
    required this.adDate,
    required this.bsYear,
    required this.bsMonth,
    required this.bsDay,
  });

  MoneyTransaction copyWith({
    int? id,
    String? type,
    double? amount,
    int? categoryId,
    int? accountId,
    int? toAccountId,
    String? note,
    DateTime? adDate,
    int? bsYear,
    int? bsMonth,
    int? bsDay,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      note: note ?? this.note,
      adDate: adDate ?? this.adDate,
      bsYear: bsYear ?? this.bsYear,
      bsMonth: bsMonth ?? this.bsMonth,
      bsDay: bsDay ?? this.bsDay,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'amount': amount,
        'categoryId': categoryId,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'note': note,
        'adDate': adDate.toIso8601String(),
        'bsYear': bsYear,
        'bsMonth': bsMonth,
        'bsDay': bsDay,
      };

  factory MoneyTransaction.fromMap(Map<String, dynamic> m) => MoneyTransaction(
        id: m['id'] as int?,
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        categoryId: m['categoryId'] as int?,
        accountId: m['accountId'] as int?,
        toAccountId: m['toAccountId'] as int?,
        note: (m['note'] as String?) ?? '',
        adDate: DateTime.parse(m['adDate'] as String),
        bsYear: m['bsYear'] as int,
        bsMonth: m['bsMonth'] as int,
        bsDay: m['bsDay'] as int,
      );
}
