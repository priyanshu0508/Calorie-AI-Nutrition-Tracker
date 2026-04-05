class UserModel {
  final String name;
  final double dailyCalorieGoal;
  final int? age;
  final double? height; // in cm
  final double? weight; // in kg
  final String? gender;
  final String? profileImagePath;

  UserModel({
    required this.name,
    required this.dailyCalorieGoal,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.profileImagePath,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'dailyCalorieGoal': dailyCalorieGoal,
        'age': age,
        'height': height,
        'weight': weight,
        'gender': gender,
        'profileImagePath': profileImagePath,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        name: json['name'] as String? ?? 'Guest User',
        dailyCalorieGoal: (json['dailyCalorieGoal'] as num?)?.toDouble() ?? 2000.0,
        age: json['age'] as int?,
        height: (json['height'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        gender: json['gender'] as String?,
        profileImagePath: json['profileImagePath'] as String?,
      );

  UserModel copyWith({
    String? name,
    double? dailyCalorieGoal,
    int? age,
    double? height,
    double? weight,
    String? gender,
    String? profileImagePath,
  }) {
    return UserModel(
      name: name ?? this.name,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}
