import '../../core/utils/result.dart';

/// Repository interface for theme operations
abstract class ThemeRepository {
  /// Get current theme mode (dark/light)
  Future<Result<bool>> isDarkMode();
  
  /// Toggle theme mode
  Future<Result<bool>> toggleTheme();
  
  /// Set dark theme explicitly
  Future<Result<bool>> setDarkTheme();
  
  /// Set light theme explicitly
  Future<Result<bool>> setLightTheme();
  
  /// Initialize theme settings
  Future<Result<bool>> initTheme();
}
