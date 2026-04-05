import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final authProvider = StateNotifierProvider<AuthNotifier, String?>((ref) {
  final box = Hive.box('sessionBox');
  return AuthNotifier(box);
});

class AuthNotifier extends StateNotifier<String?> {
  final Box _box;

  AuthNotifier(this._box) : super(_box.get('currentUserId'));

  void login(String userId) {
    _box.put('currentUserId', userId);
    state = userId;
  }

  void logout() {
    _box.delete('currentUserId');
    state = null;
  }
}
