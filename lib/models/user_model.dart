class UserProfile {
  final String id;
  final double height;
  final double weight;
  final String gender;
  final DateTime date;

  UserProfile({
    required this.id,
    required this.height,
    required this.weight,
    required this.gender,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'height': height,
      'weight': weight,
      'gender': gender,
      'date': date.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      height: map['height'],
      weight: map['weight'],
      gender: map['gender'],
      date: DateTime.parse(map['date']),
    );
  }
}
