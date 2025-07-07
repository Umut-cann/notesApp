import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../../services/notification_service.dart';
import '../datasources/local/task_local_datasource.dart';
import '../models/task_model.dart';

/// Implementation of the TaskRepository from the domain layer
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl(this.localDataSource);

  @override
  Future<Result<List<TaskEntity>>> getAllTasks() async {
    final result = await localDataSource.getAllTasks();
    return result;
  }

  @override
  Future<Result<TaskEntity>> getTaskById(int id) async {
    final result = await localDataSource.getTaskById(id);
    return result;
  }

  @override
  Future<Result<int>> addTask(TaskEntity task) async {
    try {
      debugPrint('🏗️ Repository: Yeni görev ekleniyor: ${task.title}');
      debugPrint('   Görev türü: ${task.isTask ? "Görev" : "Not"}');
      debugPrint('   Görev zamanı: ${task.dateTime.toString()}');
      debugPrint(
        '   Hatırlatma zamanı: ${task.reminderTime?.toString() ?? "Yok"}',
      );

      // Convert domain entity to data model
      final taskModel = TaskModel.fromEntity(task);

      // Save to local data source
      final result = await localDataSource.addTask(taskModel);

      if (result.isSuccess) {
        debugPrint(
          '✅ Repository: Görev veritabanına kaydedildi, ID: ${result.data}',
        );

        // Schedule notifications if needed
        await _scheduleNotificationsForTask(
          taskModel.copyWith(id: result.data),
        );
      } else {
        debugPrint(
          '❌ Repository: Görev kaydedilemedi: ${result.failure?.message}',
        );
      }

      return result;
    } catch (e) {
      debugPrint('❌ Repository: addTask hatası: $e');
      return Result.failure(DatabaseFailure('Failed to add task: $e'));
    }
  }

  @override
  Future<Result<bool>> updateTask(TaskEntity task) async {
    try {
      // Convert domain entity to data model
      final taskModel = TaskModel.fromEntity(task);

      // First cancel any existing notifications
      if (taskModel.id != null) {
        await _cancelNotificationsForTask(taskModel.id!);
      }

      // Update task in local data source
      final result = await localDataSource.updateTask(taskModel);

      // Schedule new notifications if needed
      if (result.isSuccess) {
        await _scheduleNotificationsForTask(taskModel);
      }

      return result;
    } catch (e) {
      debugPrint('Error in updateTask repository: $e');
      return Result.failure(DatabaseFailure('Failed to update task: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteTask(int id) async {
    try {
      // First cancel any notifications for this task
      await _cancelNotificationsForTask(id);

      // Then delete from local data source
      return await localDataSource.deleteTask(id);
    } catch (e) {
      debugPrint('Error in deleteTask repository: $e');
      return Result.failure(DatabaseFailure('Failed to delete task: $e'));
    }
  }

  @override
  Future<Result<bool>> toggleTaskStatus(int id, bool isDone) async {
    try {
      // Get the task first
      final taskResult = await localDataSource.getTaskById(id);
      if (!taskResult.isSuccess) {
        return Result.failure(taskResult.failure!);
      }

      // Update the task with new status
      final updatedTask = taskResult.data!.copyWith(isDone: isDone);

      // Save the updated task
      return await updateTask(updatedTask);
    } catch (e) {
      debugPrint('Error in toggleTaskStatus repository: $e');
      return Result.failure(
        DatabaseFailure('Failed to toggle task status: $e'),
      );
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksByCategory(String category) async {
    return await localDataSource.getTasksByCategory(category);
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final tasksResult = await getAllTasks();

      if (!tasksResult.isSuccess) {
        return tasksResult;
      }

      final filteredTasks =
          tasksResult.data!
              .where(
                (task) =>
                    task.dateTime.isAfter(
                      start.subtract(const Duration(minutes: 1)),
                    ) &&
                    task.dateTime.isBefore(end.add(const Duration(minutes: 1))),
              )
              .toList();

      return Result.success(filteredTasks);
    } catch (e) {
      debugPrint('Error getting tasks by date range: $e');
      return Result.failure(
        DatabaseFailure('Failed to filter tasks by date: $e'),
      );
    }
  }

  @override
  Future<Result<List<TaskEntity>>> searchTasks(String query) async {
    return await localDataSource.searchTasks(query);
  }

  @override
  Future<Result<bool>> clearAllTasks() async {
    try {
      // Cancel all notifications first
      await NotificationService.cancelAllNotifications();

      // Then clear all tasks
      return await localDataSource.clearAllTasks();
    } catch (e) {
      debugPrint('Error clearing all tasks: $e');
      return Result.failure(DatabaseFailure('Failed to clear all tasks: $e'));
    }
  }

  // Helper methods for notifications

  /// Convert a task ID to a valid notification ID (32-bit signed integer)
  int _getNotificationId(int taskId, {bool isDueNotification = false}) {
    // Hash the task ID to fit in 32-bit signed integer range
    // Use a simple hash function that ensures we stay within valid range
    int hash = taskId.hashCode;

    // Ensure the hash is within 32-bit signed integer range (−2,147,483,648 to 2,147,483,647)
    // We'll use positive range only for simplicity: 0 to 2,147,483,647
    hash = hash.abs() % 2147483647;

    // If it's a due notification, add offset but keep within range
    if (isDueNotification) {
      hash = (hash + 1000000) % 2147483647;
    }

    return hash;
  }

  /// Schedule notifications for a task (reminder and due date if applicable)
  Future<void> _scheduleNotificationsForTask(TaskModel task) async {
    try {
      debugPrint('🔔 Repository: Bildirim zamanlama başlıyor');
      debugPrint('   Görev: ${task.title}');
      debugPrint('   Görev ID: ${task.id}');
      debugPrint('   İsTask: ${task.isTask}');
      debugPrint('   İsDone: ${task.isDone}');
      debugPrint('   DateTime: ${task.dateTime.toString()}');
      debugPrint('   ReminderTime: ${task.reminderTime?.toString() ?? "null"}');
      debugPrint('   Şu anki zaman: ${DateTime.now().toString()}');

      // Schedule reminder notification if set
      if (task.reminderTime != null && task.id != null) {
        debugPrint('📅 Hatırlatma kontrolü yapılıyor...');

        if (task.reminderTime!.isAfter(DateTime.now())) {
          final notificationId = _getNotificationId(task.id!);
          debugPrint('✅ Hatırlatma zamanı uygun, bildirim zamanlanıyor');
          debugPrint('   Orijinal Görev ID: ${task.id}');
          debugPrint('   Güvenli Bildirim ID: $notificationId');
          debugPrint('   Hatırlatma zamanı: ${task.reminderTime.toString()}');

          await NotificationService.scheduleNotification(
            id: notificationId,
            title:
                task.isTask ? '🔔 Görev Hatırlatması' : '📝 Not Hatırlatması',
            body: task.title,
            scheduledTime: task.reminderTime!,
            payload: 'task_${task.id}',
          );

          debugPrint('✅ Hatırlatma bildirimi zamanlandı');
        } else {
          debugPrint('⚠️ Hatırlatma zamanı geçmiş:');
          debugPrint('   Hatırlatma: ${task.reminderTime.toString()}');
          debugPrint('   Şu an: ${DateTime.now().toString()}');
          debugPrint(
            '   Fark: ${task.reminderTime!.difference(DateTime.now()).inSeconds} saniye',
          );
        }
      } else {
        if (task.reminderTime == null) {
          debugPrint('ℹ️ Hatırlatma zamanı ayarlanmamış');
        }
        if (task.id == null) {
          debugPrint('⚠️ Görev ID null!');
        }
      }

      // Schedule due date notification for tasks (not notes)
      if (task.isTask && task.id != null && !task.isDone) {
        debugPrint('⏰ Görev bitiş kontrolü yapılıyor...');

        if (task.dateTime.isAfter(DateTime.now())) {
          final dueNotificationId = _getNotificationId(
            task.id!,
            isDueNotification: true,
          );
          debugPrint('✅ Görev zamanı uygun, bitiş bildirimi zamanlanıyor');
          debugPrint('   Orijinal Görev ID: ${task.id}');
          debugPrint('   Güvenli Bitiş Bildirim ID: $dueNotificationId');
          debugPrint('   Görev zamanı: ${task.dateTime.toString()}');

          await NotificationService.scheduleNotification(
            id: dueNotificationId,
            title: '⏰ Görev Süresi Doldu!',
            body: '"${task.title}" görevinin süresi doldu.',
            scheduledTime: task.dateTime,
            payload: 'due_task_${task.id}',
          );

          debugPrint('✅ Görev bitiş bildirimi zamanlandı');
        } else {
          debugPrint('⚠️ Görev zamanı geçmiş:');
          debugPrint('   Görev zamanı: ${task.dateTime.toString()}');
          debugPrint('   Şu an: ${DateTime.now().toString()}');
          debugPrint(
            '   Fark: ${task.dateTime.difference(DateTime.now()).inSeconds} saniye',
          );
        }
      } else {
        if (!task.isTask) {
          debugPrint('ℹ️ Bu bir not, görev bitiş bildirimi gerekmiyor');
        }
        if (task.isDone) {
          debugPrint('ℹ️ Görev tamamlanmış, bitiş bildirimi gerekmiyor');
        }
      }

      debugPrint('✅ Repository: Bildirim zamanlama süreci tamamlandı');
    } catch (e) {
      debugPrint('❌ Repository: Bildirim zamanlama hatası: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Cancel all notifications for a task
  Future<void> _cancelNotificationsForTask(int taskId) async {
    try {
      debugPrint('🚫 Repository: Görev bildirimleri iptal ediliyor: $taskId');

      final reminderNotificationId = _getNotificationId(taskId);
      final dueNotificationId = _getNotificationId(
        taskId,
        isDueNotification: true,
      );

      debugPrint('   Hatırlatma Bildirim ID: $reminderNotificationId');
      debugPrint('   Bitiş Bildirim ID: $dueNotificationId');

      // Cancel reminder notification
      await NotificationService.cancelNotification(reminderNotificationId);

      // Cancel due date notification
      await NotificationService.cancelNotification(dueNotificationId);

      debugPrint('✅ Repository: Bildirim iptali tamamlandı');
    } catch (e) {
      debugPrint('❌ Repository: Bildirim iptal hatası: $e');
    }
  }
}
