class Account {
  final int? id;
  final String name;
  final String iconName;
  final int colorValue;
  final double openingBalance;
  final int sortOrder;

  const Account({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    this.openingBalance = 0,
    this.sortOrder = 0,
  });

  Account copyWith({
    int? id,
    String? name,
    String? iconName,
    int? colorValue,
    double? openingBalance,
    int? sortOrder,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      openingBalance: openingBalance ?? this.openingBalance,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'colorValue': colorValue,
        'openingBalance': openingBalance,
        'sortOrder': sortOrder,
      };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
        id: m['id'] as int?,
        name: m['name'] as String,
        iconName: m['iconName'] as String,
        colorValue: m['colorValue'] as int,
        openingBalance: (m['openingBalance'] as num?)?.toDouble() ?? 0,
        sortOrder: (m['sortOrder'] as int?) ?? 0,
      );
}
