class Category {
  final int? id;
  final String name;

  /// 'expense' or 'income'
  final String type;
  final String iconName;
  final int colorValue;
  final int sortOrder;
  final bool isCustom;

  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorValue,
    this.sortOrder = 0,
    this.isCustom = false,
  });

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? iconName,
    int? colorValue,
    int? sortOrder,
    bool? isCustom,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'iconName': iconName,
        'colorValue': colorValue,
        'sortOrder': sortOrder,
        'isCustom': isCustom ? 1 : 0,
      };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String,
        iconName: m['iconName'] as String,
        colorValue: m['colorValue'] as int,
        sortOrder: (m['sortOrder'] as int?) ?? 0,
        isCustom: (m['isCustom'] as int?) == 1,
      );
}
