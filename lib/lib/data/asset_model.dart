// 🔒 STATUS: EDITED (Added isPcfAccumulator & lastUpdateDate for Sinking-Growth logic)
class Asset {
  final int? id;
  final String name;
  final double value;
  final String type;
  final double yieldPercentage;
  final bool isPcfAccumulator;
  final String? lastUpdateDate;

  Asset({
    this.id,
    required this.name,
    required this.value,
    required this.type,
    this.yieldPercentage = 0.0,
    this.isPcfAccumulator = false,
    this.lastUpdateDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'type': type,
      'yieldPercentage': yieldPercentage,
      'isPcfAccumulator': isPcfAccumulator,
      'lastUpdateDate': lastUpdateDate,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'],
      name: map['name'] ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'השקעה',
      yieldPercentage: (map['yieldPercentage'] as num?)?.toDouble() ?? 0.0,
      isPcfAccumulator: map['isPcfAccumulator'] == true,
      lastUpdateDate: map['lastUpdateDate'],
    );
  }
}