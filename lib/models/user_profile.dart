class UserProfile {
  final String id;
  final double height;
  final double weight;
  final String gender;
  final DateTime date;
  final String heightUnit; // 'cm' or 'in'
  final String weightUnit; // 'kg' or 'lbs'

  UserProfile({
    required this.id,
    required this.height,
    required this.weight,
    required this.gender,
    required this.date,
    this.heightUnit = 'cm',
    this.weightUnit = 'kg',
  });

  // Convert to kg and cm for BMI calculation
  double get weightInKg {
    if (weightUnit == 'lbs') {
      return weight * 0.453592;
    }
    return weight;
  }

  double get heightInCm {
    if (heightUnit == 'in') {
      return height * 2.54;
    }
    return height;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'height': height,
      'weight': weight,
      'gender': gender,
      'date': date.toIso8601String(),
      'heightUnit': heightUnit,
      'weightUnit': weightUnit,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      height: (map['height'] ?? 0).toDouble(),
      weight: (map['weight'] ?? 0).toDouble(),
      gender: map['gender'] ?? 'Other',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      heightUnit: map['heightUnit'] ?? 'cm',
      weightUnit: map['weightUnit'] ?? 'kg',
    );
  }

  UserProfile copyWith({
    String? id,
    double? height,
    double? weight,
    String? gender,
    DateTime? date,
    String? heightUnit,
    String? weightUnit,
  }) {
    return UserProfile(
      id: id ?? this.id,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      date: date ?? this.date,
      heightUnit: heightUnit ?? this.heightUnit,
      weightUnit: weightUnit ?? this.weightUnit,
    );
  }
}
