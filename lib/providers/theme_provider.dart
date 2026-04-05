import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Box _box;
  static const _key = 'themeMode';

  ThemeNotifier(this._box) : super(_loadTheme(_box));

  static ThemeMode _loadTheme(Box box) {
    final String? themeStr = box.get(_key);
    if (themeStr == 'dark') return ThemeMode.dark;
    if (themeStr == 'light') return ThemeMode.light;
    return ThemeMode.system; // default
  }

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _box.put(_key, state == ThemeMode.dark ? 'dark' : 'light');
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    if (mode == ThemeMode.system) {
      _box.delete(_key);
    } else {
      _box.put(_key, mode == ThemeMode.dark ? 'dark' : 'light');
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final box = Hive.box('sessionBox'); // We can use sessionBox or a separate settings box
  return ThemeNotifier(box);
});
