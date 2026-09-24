import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/app_user.dart';

class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppUser _currentUser = AppUser(
    id: 'user_default',
    businessId: 'default',
    name: 'Owner Admin',
    role: 'Owner',
  );

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppUser get currentUser => _currentUser;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('app_is_dark');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_is_dark', _themeMode == ThemeMode.dark);
  }

  void setCurrentUserRole(String role) {
    _currentUser = AppUser(
      id: _currentUser.id,
      businessId: _currentUser.businessId,
      name: '$role User',
      role: role,
    );
    notifyListeners();
  }
}
