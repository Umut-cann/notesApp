import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/repositories/task_repository.dart';
import '../models/task_model.dart';
import '../presentation/pages/task_detail_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  // Bildirimleri başlat
  static Future<void> init() async {
    // Timezone'ı başlat
    tz.initializeTimeZones();

    // Türkiye timezone'ını ayarla
    try {
      final location = tz.getLocation('Europe/Istanbul');
      tz.setLocalLocation(location);
      debugPrint('Timezone ayarlandı: ${tz.local.name}');
    } catch (e) {
      debugPrint('Timezone ayarlama hatası: $e');
      // Fallback olarak sistem timezone'ını kullan
      debugPrint('Sistem timezone kullanılıyor: ${tz.local.name}');
    }

    // Android ayarları
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS ayarları
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Genel ayarlar
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Bildirimleri başlat
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Bildirim kanallarını oluştur
    await createNotificationChannels();

    // İzinleri kontrol et
    await _requestPermissions();

    debugPrint('Notification service başlatıldı');
  }

  // İzinleri iste
  static Future<void> _requestPermissions() async {
    // Android 13+ için bildirim izni
    final notificationStatus = await Permission.notification.status;
    debugPrint('Bildirim izni durumu: $notificationStatus');

    if (notificationStatus.isDenied) {
      final result = await Permission.notification.request();
      debugPrint('Bildirim izni isteği sonucu: $result');
    }

    // iOS için bildirim izni
    final iosPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (iosPlugin != null) {
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('iOS bildirim izni sonucu: $result');
    }

    // Test bildirimi gönder
    // await _sendTestNotification();
  }

  // Bildirime tıklandığında
  static void _onNotificationTapped(NotificationResponse response) async {
    if (response.payload == null) return;

    // Bildirim türüne göre işlem yap
    if (response.payload!.startsWith('task_')) {
      // Görev bildirimi
      final taskId = int.tryParse(response.payload!.split('_')[1]);
      if (taskId != null) {
        // Get the task repository and find the task
        try {
          final taskRepository = Get.find<TaskRepository>();
          final taskResult = await taskRepository.getTaskById(taskId);

          if (taskResult.isSuccess && taskResult.data != null) {
            // Navigate to the task detail screen
            Get.to(() => TaskDetailScreen(task: taskResult.data!));
          } else {
            debugPrint(
              'Task not found or error: ${taskResult.failure?.message}',
            );
          }
        } catch (e) {
          debugPrint('Error navigating to task: $e');
        }
      }
    } else if (response.payload == 'daily_summary') {
      // Günlük özet bildirimi
      debugPrint('Günlük özet bildirimi tıklandı');
      // TODO: İstatistik sayfasına yönlendir
    }
  }

  // Anında bildirim gönder
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_notifications',
        'Anında Bildirimler',
        channelDescription: 'Anında gönderilen bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Zamanlanmış bildirim
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      // Önce mevcut bildirimi iptal et
      await _notifications.cancel(id);

      final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );
      final tz.TZDateTime nowTZ = tz.TZDateTime.now(tz.local);

      // Zaman dilimine duyarlı geçmiş tarih kontrolü
      if (scheduledTZ.isBefore(nowTZ)) {
        debugPrint('⚠️ Geçmiş tarih için bildirim ayarlanamıyor:');
        debugPrint('  Zamanlanmış: $scheduledTZ');
        debugPrint('  Şu an: $nowTZ');
        return;
      }

      const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_notifications',
          'Zamanlanmış Bildirimler',
          channelDescription: 'Zamanlanmış görev bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      debugPrint('📅 Bildirim zamanlanıyor:');
      debugPrint('  ID: $id');
      debugPrint('  Başlık: $title');
      debugPrint('  İçerik: $body');
      debugPrint('  Tarih: ${scheduledTime.toString()}');
      debugPrint('  TZ Tarih: ${scheduledTZ.toString()}');
      debugPrint('  Şu an (TZ): ${nowTZ.toString()}');
      debugPrint('  Timezone: ${tz.local.name}');
      debugPrint('  Fark: ${scheduledTZ.difference(nowTZ).inSeconds} saniye');

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('✅ Bildirim başarıyla zamanlandı');

      // Kontrol amaçlı bekleyen bildirimleri listele
      await Future.delayed(const Duration(milliseconds: 100));
      final pending = await getPendingNotifications();
      debugPrint('📋 Bekleyen bildirim sayısı: ${pending.length}');

      final targetNotification = pending.where((n) => n.id == id).firstOrNull;
      if (targetNotification != null) {
        debugPrint('✅ Bildirim listede bulundu: ${targetNotification.title}');
      } else {
        debugPrint('⚠️ Bildirim listede bulunamadı!');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Bildirim zamanlama hatası: $e');
      debugPrint('Stack trace: $stackTrace');

      // Basit mod ile tekrar dene
      try {
        debugPrint('🔄 Basit mod ile yeniden deneniyor...');
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'scheduled_notifications',
              'Zamanlanmış Bildirimler',
              importance: Importance.high,
            ),
          ),
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        debugPrint('✅ Basit mod ile bildirim zamanlandı');
      } catch (e2) {
        debugPrint('❌ Basit mod da başarısız: $e2');
      }
    }
  }

  // Görev için bildirim zamanla
  static Future<void> scheduleTaskNotification(TaskModel task) async {
    if (task.reminderTime == null) return;

    debugPrint('Görev bildirimi zamanlanıyor: ${task.title}');
    debugPrint('Hatırlatma zamanı: ${task.reminderTime.toString()}');

    await scheduleNotification(
      id: task.key ?? 0,
      title: task.isTask ? '🔔 Görev Hatırlatması' : '📝 Not Hatırlatması',
      body: task.title,
      scheduledTime: task.reminderTime!, // Artık direct kullanıyoruz
      payload: 'task_${task.key}',
    );
  }

  // Tekrarlayan bildirim
  static Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
    String? payload,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'repeating_notifications',
        'Tekrarlayan Bildirimler',
        channelDescription: 'Tekrarlayan görev bildirimleri',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.periodicallyShow(
      id,
      title,
      body,
      repeatInterval,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Belirli bildirimi iptal et
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Tüm bildirimleri iptal et
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Bekleyen bildirimleri al
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Aktif bildirimleri al
  static Future<List<ActiveNotification>> getActiveNotifications() async {
    return await _notifications.getActiveNotifications();
  }

  // Bildirim kanalları oluştur (Android)
  static Future<void> createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'instant_notifications',
        'Anında Bildirimler',
        description: 'Anında gönderilen bildirimler',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'scheduled_notifications',
        'Zamanlanmış Bildirimler',
        description: 'Zamanlanmış görev bildirimleri',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'repeating_notifications',
        'Tekrarlayan Bildirimler',
        description: 'Tekrarlayan görev bildirimleri',
        importance: Importance.high,
      ),
    ];

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      for (final channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  // Bildirim izni var mı kontrol et
  static Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Bildirim ayarlarını aç
  static Future<void> openNotificationSettings() async {
    // Her durumda sistem ayarlarını aç - en güvenilir çözüm
    await openAppSettings();
  }

  // Görev süresi dolduğunda bildirim zamanla
  static Future<void> scheduleTaskDueDateNotification(TaskModel task) async {
    // Görevin bir bitiş tarihi yoksa veya zaten tamamlanmışsa bildirim planlama
    if (task.isDone) return;

    // Bildirim ID'sini görev anahtarı + sabit bir değer yaparak benzersiz hale getiriyoruz
    // Bu, hatırlatma bildirimleriyle çakışmayı önler.
    final notificationId = (task.key ?? 0) + 1000000;

    await scheduleNotification(
      id: notificationId,
      title: '⏰ Görev Süresi Doldu!',
      body: '"${task.title}" görevinin süresi doldu.',
      scheduledTime: task.dateTime, // Görevin kendi dateTime alanı kullanılır
      payload: 'due_task_${task.key}',
    );
  }

  // Görev süresi doldu bildirimini iptal et
  static Future<void> cancelDueDateNotification(int taskKey) async {
    final notificationId = taskKey + 1000000;
    await _notifications.cancel(notificationId);
  }

  // Günlük özet bildirimi
  static Future<void> showDailySummaryNotification({
    required int completedTasks,
    required int pendingTasks,
  }) async {
    await showInstantNotification(
      id: 999999,
      title: '📊 Günlük Özet',
      body:
          'Bugün $completedTasks görev tamamladınız, $pendingTasks görev bekliyor.',
      payload: 'daily_summary',
    );
  }

  // Bildirim debug yardımcıları
  static Future<void> debugNotifications() async {
    final pending = await getPendingNotifications();
    final active = await getActiveNotifications();

    debugPrint('=== Bildirim Debug ===');
    debugPrint('Bekleyen bildirimler: ${pending.length}');
    for (final notification in pending) {
      debugPrint('  ID: ${notification.id}, Başlık: ${notification.title}');
    }

    debugPrint('Aktif bildirimler: ${active.length}');
    for (final notification in active) {
      debugPrint('  ID: ${notification.id}, Başlık: ${notification.title}');
    }

    final hasPermission = await hasNotificationPermission();
    debugPrint('Bildirim izni var mı: $hasPermission');
  }


}
