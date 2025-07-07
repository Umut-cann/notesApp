import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/repositories/theme_repository.dart';

class ThemeController extends GetxController {
  final ThemeRepository repository;
  
  // Observable variables
  final _isDarkMode = false.obs;
  
  // Getters
  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  
  // Theme data definitions
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF6B35), // Canlı turuncu
        secondary: Color(0xFFFF8F65), // Açık turuncu
        tertiary: Color(0xFFFFB085), // Çok açık turuncu
        surface: Color(0xFFFFFFFF), // Beyaz
        background: Color(0xFFFFFBF8), // Çok açık turuncu-beyaz
        error: Color(0xFFE53E3E), // Kırmızı (hata rengi)
        onPrimary: Colors.white, // Beyaz
        onSecondary: Colors.white, // Beyaz
        onSurface: Color(0xFF2D3748), // Koyu gri
        onBackground: Color(0xFF2D3748), // Koyu gri
        onError: Colors.white, // Beyaz
        outline: Color(0xFFFFE4D6), // Açık turuncu
        surfaceVariant: Color(0xFFFFF8F5), // Çok açık turuncu
        onSurfaceVariant: Color(0xFF8B5A3C), // Kahverengi-turuncu
        inversePrimary: Color(0xFFFFB085),
        primaryContainer: Color(0xFFFFE4D6),
        onPrimaryContainer: Color(0xFF8B2500),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF8F65), // Açık turuncu
        secondary: Color(0xFFFFB085), // Çok açık turuncu
        tertiary: Color(0xFFFF6B35), // Canlı turuncu
        surface: Color(0xFF1A1A1A), // Koyu gri-siyah
        background: Color(0xFF121212), // Siyah
        error: Color(0xFFE53E3E), // Kırmızı (hata rengi)
        onPrimary: Colors.white, // Beyaz
        onSecondary: Colors.white, // Beyaz
        onSurface: Color(0xFFECECEC), // Çok açık gri
        onBackground: Color(0xFFECECEC), // Çok açık gri
        onError: Colors.white, // Beyaz
        outline: Color(0xFF452C1F), // Koyu kahverengi
        surfaceVariant: Color(0xFF252525), // Açık siyah
        onSurfaceVariant: Color(0xFFFFD6C2), // Açık turuncu-beyaz
        inversePrimary: Color(0xFF8B5A3C),
        primaryContainer: Color(0xFF502F1F),
        onPrimaryContainer: Color(0xFFFFD6C2),
      ),
    );
  }

  // Constructor
  ThemeController(this.repository);
  
  @override
  void onInit() {
    super.onInit();
    loadThemeSettings();
  }
  
  // Load theme settings from repository
  Future<void> loadThemeSettings() async {
    // Initialize theme repository
    final initResult = await repository.initTheme();
    if (!initResult.isSuccess) {
      return;
    }
    
    // Get current theme mode
    final result = await repository.isDarkMode();
    if (result.isSuccess) {
      _isDarkMode.value = result.data!;
      
      // Apply theme immediately
      Get.changeThemeMode(themeMode);
    }
  }
  
  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    final result = await repository.toggleTheme();
    if (result.isSuccess) {
      _isDarkMode.value = !_isDarkMode.value;
      
      // Apply theme immediately
      Get.changeThemeMode(themeMode);
    }
  }
  
  // Set dark theme explicitly
  Future<void> setDarkTheme() async {
    if (!_isDarkMode.value) {
      final result = await repository.setDarkTheme();
      if (result.isSuccess) {
        _isDarkMode.value = true;
        
        // Apply theme immediately
        Get.changeThemeMode(themeMode);
      }
    }
  }
  
  // Set light theme explicitly
  Future<void> setLightTheme() async {
    if (_isDarkMode.value) {
      final result = await repository.setLightTheme();
      if (result.isSuccess) {
        _isDarkMode.value = false;
        
        // Apply theme immediately
        Get.changeThemeMode(themeMode);
      }
    }
  }
}
