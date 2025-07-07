import '../../core/utils/result.dart';
import '../../domain/repositories/theme_repository.dart';
import '../datasources/local/theme_local_datasource.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  final ThemeLocalDataSource localDataSource;

  ThemeRepositoryImpl(this.localDataSource);

  @override
  Future<Result<bool>> isDarkMode() async {
    return await localDataSource.isDarkMode();
  }

  @override
  Future<Result<bool>> toggleTheme() async {
    // Get current theme mode
    final currentThemeResult = await localDataSource.isDarkMode();
    if (!currentThemeResult.isSuccess) {
      return currentThemeResult;
    }

    // Toggle theme mode
    final newThemeMode = !currentThemeResult.data!;
    return await localDataSource.setDarkMode(newThemeMode);
  }

  @override
  Future<Result<bool>> setDarkTheme() async {
    return await localDataSource.setDarkMode(true);
  }

  @override
  Future<Result<bool>> setLightTheme() async {
    return await localDataSource.setDarkMode(false);
  }

  @override
  Future<Result<bool>> initTheme() async {
    return await localDataSource.init();
  }
}
