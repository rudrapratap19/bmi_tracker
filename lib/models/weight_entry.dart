class WeightEntry {
  final String? id; // Firestore doc id
  final double weight;
  final String weightUnit; // 'kg' or 'lbs'
  final DateTime date;

  WeightEntry({
    this.id,
    required this.weight,
    required this.weightUnit,
    required this.date,
  });

  double get weightInKg => weightUnit == 'lbs' ? weight * 0.453592 : weight;

  Map<String, dynamic> toMap() => {
        'weight': weight,
        'weightUnit': weightUnit,
        'date': date.toIso8601String(),
      };

  factory WeightEntry.fromMap(Map<String, dynamic> map) => WeightEntry(
        weight: (map['weight'] ?? 0).toDouble(),
        weightUnit: map['weightUnit'] ?? 'kg',
        date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      );

  factory WeightEntry.fromFirestore(String id, Map<String, dynamic> map) => WeightEntry(
        id: id,
        weight: (map['weight'] ?? 0).toDouble(),
        weightUnit: map['weightUnit'] ?? 'kg',
        date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      );
}
