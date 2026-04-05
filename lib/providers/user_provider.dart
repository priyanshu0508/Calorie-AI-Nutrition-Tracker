import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

class UserNotifier extends StateNotifier<UserModel> {
  final Box _box;
  final String _userKey;

  UserNotifier(this._box, this._userKey) : super(_loadUser(box: _box, key: _userKey));

  static UserModel _loadUser({required Box box, required String key}) {
    final Map<dynamic, dynamic>? data = box.get(key);
    if (data != null) {
      try {
        final jsonMap = Map<String, dynamic>.from(data);
        return UserModel.fromJson(jsonMap);
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
    return UserModel(name: 'Guest User', dailyCalorieGoal: 2000.0);
  }

  void updateUser(UserModel user) {
    state = user;
    _box.put(_userKey, state.toJson());
  }

  void updateName(String name) {
    updateUser(state.copyWith(name: name));
  }

  void updateGoal(double goal) {
    updateUser(state.copyWith(dailyCalorieGoal: goal));
  }

  void updateBodyProfile({int? age, double? height, double? weight, String? gender}) {
    updateUser(state.copyWith(
      age: age,
      height: height,
      weight: weight,
      gender: gender,
    ));
  }

  void updateProfileImage(String path) {
    updateUser(state.copyWith(profileImagePath: path));
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel>((ref) {
  final box = Hive.box('diaryBox'); 
  final userId = ref.watch(authProvider) ?? 'guest';
  final userKey = 'profile_$userId';
  return UserNotifier(box, userKey);
});
