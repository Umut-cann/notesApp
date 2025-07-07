import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';

abstract class ThemeLocalDataSource {
  Future<Result<bool>> isDarkMode();
  Future<Result<bool>> setDarkMode(bool isDarkMode);
  Future<Result<bool>> init();
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  Box<dynamic>? _themeBox;
  bool _isInitialized = false;

  ThemeLocalDataSourceImpl();

  @override
  Future<Result<bool>> init() async {
    try {
      if (_isInitialized) {
        return Result.success(true);
      }
      
      // Kutu zaten açıksa, onu al; değilse yeni bir kutu aç
      try {
        if (Hive.isBoxOpen(AppConstants.themeBoxName)) {
          _themeBox = Hive.box<dynamic>(AppConstants.themeBoxName);
          debugPrint('Using already open theme box');
        } else {
          _themeBox = await Hive.openBox<dynamic>(AppConstants.themeBoxName);
          debugPrint('Opened new theme box');
        }
      } catch (e) {
        debugPrint('Hive error opening theme box: $e');
        // Box zaten açıksa ve farklı bir tipteyse, tüm kutuları kapatıp tekrar deneyelim
        await Hive.close();
        _themeBox = await Hive.openBox<dynamic>(AppConstants.themeBoxName);
        debugPrint('Reopened theme box after closing all');
      }
      
      _isInitialized = true;
      return Result.success(true);
    } catch (e) {
      debugPrint('Error initializing theme box: $e');
      return Result.failure(DatabaseFailure('Failed to initialize theme settings: $e'));
    }
  }

  @override
  Future<Result<bool>> isDarkMode() async {
    try {
      // Make sure theme box is initialized
      if (!_isInitialized) {
        final initResult = await init();
        if (!initResult.isSuccess) {
          return initResult;
        }
      }
      
      final isDarkMode = _themeBox?.get(AppConstants.themeKey, defaultValue: false) ?? false;
      return Result.success(isDarkMode);
    } catch (e) {
      debugPrint('Error getting theme mode: $e');
      return Result.failure(DatabaseFailure('Failed to get theme mode: $e'));
    }
  }

  @override
  Future<Result<bool>> setDarkMode(bool isDarkMode) async {
    try {
      // Make sure theme box is initialized
      if (!_isInitialized) {
        final initResult = await init();
        if (!initResult.isSuccess) {
          return initResult;
        }
      }
      
      await _themeBox?.put(AppConstants.themeKey, isDarkMode);
      return Result.success(true);
    } catch (e) {
      debugPrint('Error setting theme mode: $e');
      return Result.failure(DatabaseFailure('Failed to set theme mode: $e'));
    }
  }
}
