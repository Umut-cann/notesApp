import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/task_entity.dart';
import '../presentation/controllers/task_controller.dart';
import '../services/notification_service.dart';

class NotificationTestUtils {
  // Tüm bildirimleri test et
  static Future<void> runAllTests() async {
    if (!kDebugMode) return;

    debugPrint('🔔 Bildirim testleri başlatılıyor...');

    // 0. İzinleri ve ayarları kontrol et
    await checkPermissionsAndSettings();

    // 1. Anında bildirim testi
    await testInstantNotification();

    // 2. 10 saniye sonra bildirim testi
    await testScheduledNotification();

    // 3. Gerçek görev bildirimi testi
    await testTaskNotification();

    // 4. Gerçek görev oluşturma testi
    await testRealTaskCreation();

    // 5. Bildirim durumunu kontrol et
    await NotificationService.debugNotifications();

    debugPrint('✅ Bildirim testleri tamamlandı');
  }

  // Anında bildirim testi
  static Future<void> testInstantNotification() async {
    try {
      await NotificationService.showInstantNotification(
        id: 77777,
        title: '🚀 Anında Test',
        body: 'Bu bildirim hemen geldi!',
        payload: 'instant_test',
      );
      debugPrint('✅ Anında bildirim gönderildi');
    } catch (e) {
      debugPrint('❌ Anında bildirim hatası: $e');
    }
  }

  // Zamanlanmış bildirim testi - daha detaylı
  static Future<void> testScheduledNotification() async {
    try {
      debugPrint('📅 Zamanlanmış bildirim testi başlatılıyor...');

      // 10 saniye sonra bildirim ayarla
      final testTime = DateTime.now().add(const Duration(seconds: 10));
      debugPrint('Bildirim zamanı: ${testTime.toString()}');
      debugPrint('Şu anki zaman: ${DateTime.now().toString()}');

      await NotificationService.scheduleNotification(
        id: 12345,
        title: '⏰ 10 Saniye Test',
        body: 'Bu bildirim 10 saniye sonra gelecek!',
        scheduledTime: testTime,
        payload: 'test_10_sec',
      );

      debugPrint('✅ Zamanlanmış bildirim ayarlandı');

      // Bekleyen bildirimleri kontrol et
      await Future.delayed(const Duration(milliseconds: 500));
      await NotificationService.debugNotifications();
    } catch (e) {
      debugPrint('❌ Zamanlanmış bildirim hatası: $e');
    }
  }

  // Gerçek görev bildirimi testi
  static Future<void> testTaskNotification() async {
    debugPrint('🎯 Görev bildirimi testi başlatılıyor...');

    try {
      // 30 saniye sonra hatırlatma zamanı olan test görevi oluştur
      final testTime = DateTime.now().add(const Duration(seconds: 30));

      // TaskModel oluştur (gerçek görev oluşturma süreci gibi)
      debugPrint('Test görev oluşturuluyor:');
      debugPrint('  Hatırlatma zamanı: ${testTime.toString()}');

      // Doğrudan NotificationService kullanarak test et
      await NotificationService.scheduleNotification(
        id: 99999,
        title: '🎯 Test Görev Hatırlatması',
        body: 'Bu gerçek bir görev bildirimi testi!',
        scheduledTime: testTime,
        payload: 'task_test_99999',
      );

      debugPrint('✅ Görev bildirimi test edildi');

      // Bekleyen bildirimleri kontrol et
      await Future.delayed(const Duration(milliseconds: 500));
      await NotificationService.debugNotifications();
    } catch (e) {
      debugPrint('❌ Görev bildirimi test hatası: $e');
    }
  }

  // Gerçek görev oluşturma test fonksiyonu
  static Future<void> testRealTaskCreation() async {
    if (!kDebugMode) return;

    debugPrint('🏗️ Gerçek görev oluşturma testi başlatılıyor...');

    try {
      // Get ile task controller'ı bul
      final taskController = Get.find<TaskController>();

      // Test görevi oluştur
      final testTask = TaskEntity(
        title: 'Test Görev - Bildirim Kontrolü',
        description: 'Bu görev bildirim sistemini test etmek için oluşturuldu',
        dateTime: DateTime.now().add(
          const Duration(minutes: 1),
        ), // 1 dakika sonra
        reminderTime: DateTime.now().add(
          const Duration(seconds: 45),
        ), // 45 saniye sonra hatırlatma
        isTask: true,
        isDone: false,
        category: 'Test',
        createdAt: DateTime.now(),
      );

      debugPrint('Test görev bilgileri:');
      debugPrint('  Başlık: ${testTask.title}');
      debugPrint('  Görev zamanı: ${testTask.dateTime.toString()}');
      debugPrint('  Hatırlatma zamanı: ${testTask.reminderTime.toString()}');

      // Görevi ekle
      final success = await taskController.addTask(testTask);

      if (success) {
        debugPrint('✅ Test görev başarıyla oluşturuldu');
        debugPrint('📋 Repository içinden bildirimler zamanlanmış olmalı');

        // Bildirim durumunu kontrol et
        await Future.delayed(const Duration(seconds: 1));
        await NotificationService.debugNotifications();
      } else {
        debugPrint('❌ Test görev oluşturulamadı');
      }
    } catch (e) {
      debugPrint('❌ Gerçek görev oluşturma test hatası: $e');
    }
  }

  // İzin durumunu ve bildirim ayarlarını kontrol et
  static Future<void> checkPermissionsAndSettings() async {
    debugPrint('🔍 Bildirim izinleri ve ayarları kontrol ediliyor...');

    // Bildirim izni kontrolü
    final hasPermission = await NotificationService.hasNotificationPermission();
    debugPrint('Bildirim izni: $hasPermission');

    // Android spesifik kontroller
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Exact alarm izni kontrolü (Android 12+)
      try {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        debugPrint('Exact alarm izni: $exactAlarmStatus');

        if (exactAlarmStatus.isDenied) {
          final result = await Permission.scheduleExactAlarm.request();
          debugPrint('Exact alarm izni isteği sonucu: $result');
        }
      } catch (e) {
        debugPrint('Exact alarm izni kontrolü hatası: $e');
      }
    }

    // Aktif ve bekleyen bildirimleri kontrol et
    await NotificationService.debugNotifications();
  }

  // Bildirimleri temizle
  static Future<void> clearAllNotifications() async {
    await NotificationService.cancelAllNotifications();
    debugPrint('🧹 Tüm bildirimler temizlendi');
  }
}
