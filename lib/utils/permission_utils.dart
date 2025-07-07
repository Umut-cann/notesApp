import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PermissionUtils {
  // İzin isteklerinin üst üste binmesini önlemek için kilitleme mekanizması
  static bool _isRequestingPermission = false;
  static final Completer<void> _requestCompleter = Completer<void>();
  
  /// Hassas alarm iznini kontrol eder ve gerekirse dialog gösterir
  static Future<void> checkAndRequestExactAlarmPermission(BuildContext context) async {
    // Eğer zaten bir izin isteği işlemde ise, tamamlanmasını bekle
    if (_isRequestingPermission) {
      debugPrint('Zaten devam eden bir izin isteği var, tamamlanması bekleniyor.');
      return _requestCompleter.future;
    }
    if (!Platform.isAndroid) return;

    _isRequestingPermission = true;
    
    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final canScheduleExactAlarms = await androidPlugin?.canScheduleExactNotifications() ?? false;

      if (!canScheduleExactAlarms) {
        // İzin henüz verilmemiş, kullanıcıya açıklayıcı bir dialog göster
        if (context.mounted) {
          final shouldRequest = await _showExactAlarmPermissionDialog(context);
          if (shouldRequest && context.mounted) {
            await androidPlugin?.requestExactAlarmsPermission();
          }
        }
      }
    } catch (e) {
      debugPrint('Hassas alarm izni kontrolü hatası: $e');
    } finally {
      _isRequestingPermission = false;
      if (!_requestCompleter.isCompleted) {
        _requestCompleter.complete();
      }
    }
  }

  /// Hassas alarm izni için açıklayıcı dialog gösterir
  static Future<bool> _showExactAlarmPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Bildirim İzni Gerekli'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.alarm,
                size: 48,
                color: Color(0xFFFF6B35),
              ),
              SizedBox(height: 16),
              Text(
                'Tam zamanında bildirim alabilmeniz için uygulamanın hassas alarm iznine ihtiyacı var.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Bu izin, görevlerinizin son teslim tarihinde ve hatırlatıcılarda tam zamanında bildirim almanızı sağlar.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Daha Sonra'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('İzin Ver'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
