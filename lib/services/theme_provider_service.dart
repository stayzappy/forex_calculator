import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Define your theme modes
  static const String whiteYellowTheme = 'white_yellow';
  static const String blackYellowTheme = 'black_yellow';

  String _currentTheme = whiteYellowTheme;
  String get currentTheme => _currentTheme;

  // White and Yellow Theme
  ThemeData get whiteYellowThemeData => ThemeData(
    primaryColor: Colors.yellow.shade700,
    colorScheme: ColorScheme.light(
      primary: Colors.yellow.shade700,
      secondary: Colors.yellowAccent,
      background: Colors.white,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.yellow.shade900,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.yellow.shade900),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // Black and Yellow Theme
  ThemeData get blackYellowThemeData => ThemeData(
    primaryColor: Colors.yellow.shade700,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.yellow.shade700,
      secondary: Colors.yellowAccent,
      background: Colors.black87,
      surface: Colors.grey.shade900,
    ),
    scaffoldBackgroundColor: Colors.black87,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black87,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.yellow.shade700,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.yellow.shade700),
    ),
    cardTheme: CardTheme(
      color: Colors.grey.shade900,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // Change theme method
  Future<void> changeTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', themeName);
    _currentTheme = themeName;
    notifyListeners();
  }

  // Load saved theme on app start
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTheme = prefs.getString('app_theme') ?? whiteYellowTheme;
    notifyListeners();
  }

  // Get current theme data
  ThemeData getThemeData() {
    return _currentTheme == whiteYellowTheme 
      ? whiteYellowThemeData 
      : blackYellowThemeData;
  }
}