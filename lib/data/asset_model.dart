class Asset {
  final int? id;
  final String name;
  final double value;
  final String type;
  final double yieldPercentage;

  Asset({
    this.id,
    required this.name,
    required this.value,
    required this.type,
    this.yieldPercentage = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'type': type,
      'yieldPercentage': yieldPercentage,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'],
      name: map['name'],
      value: map['value'],
      type: map['type'],
      yieldPercentage: map['yieldPercentage'],
    );
  }
}