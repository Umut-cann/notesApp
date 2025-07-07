import 'package:hive_flutter/hive_flutter.dart';

import '../models/task_model.dart';

class DatabaseService {
  static const String _boxName = 'tasks';
  static Box<TaskModel>? _box;

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Hive'ı başlat
  static Future<void> init() async {
    await Hive.initFlutter();

    // Adapter'ı kaydet
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskModelAdapter());
    }

    // Box'ı aç
    _box = await Hive.openBox<TaskModel>(_boxName);
  }

  // Box'ı al
  Box<TaskModel> get box {
    if (_box == null) {
      throw Exception(
        'Database not initialized. Call DatabaseService.init() first.',
      );
    }
    return _box!;
  }

  // Tüm görevleri al
  List<TaskModel> getAllTasks() {
    return box.values.toList();
  }

  // Sadece görevleri al
  List<TaskModel> getTasks() {
    return box.values.where((task) => task.isTask).toList();
  }

  // Sadece notları al
  List<TaskModel> getNotes() {
    return box.values.where((task) => task.isNote).toList();
  }

  // Tamamlanan görevleri al
  List<TaskModel> getCompletedTasks() {
    return box.values.where((task) => task.isDone && task.isTask).toList();
  }

  // Bekleyen görevleri al
  List<TaskModel> getPendingTasks() {
    return box.values.where((task) => !task.isDone && task.isTask).toList();
  }

  // Kategoriye göre filtrele
  List<TaskModel> getTasksByCategory(String category) {
    return box.values.where((task) => task.category == category).toList();
  }

  // Tarihe göre filtrele
  List<TaskModel> getTasksByDate(DateTime date) {
    return box.values.where((task) {
      return task.dateTime.year == date.year &&
          task.dateTime.month == date.month &&
          task.dateTime.day == date.day;
    }).toList();
  }

  // Hatırlatması olan görevleri al
  List<TaskModel> getTasksWithReminders() {
    return box.values.where((task) => task.reminderTime != null).toList();
  }

  // Görev ekle
  Future<void> addTask(TaskModel task) async {
    await box.add(task);
  }

  // Görev güncelle
  Future<void> updateTask(TaskModel task) async {
    await task.save();
  }

  // Görev sil
  Future<void> deleteTask(TaskModel task) async {
    await task.delete();
  }

  // ID ile görev al
  TaskModel? getTaskById(int id) {
    return box.get(id);
  }

  // Arama yap
  List<TaskModel> searchTasks(String query) {
    final lowerQuery = query.toLowerCase();
    return box.values.where((task) {
      return task.title.toLowerCase().contains(lowerQuery) ||
          task.description.toLowerCase().contains(lowerQuery) ||
          (task.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Tüm verileri temizle
  Future<void> clearAllData() async {
    await box.clear();
  }

  // Veritabanını kapat
  Future<void> close() async {
    await box.close();
  }

  // Veritabanı boyutunu al
  int get taskCount => box.length;

  // Son eklenen görevleri al
  List<TaskModel> getRecentTasks({int limit = 10}) {
    final tasks = box.values.toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks.take(limit).toList();
  }

  // Bugünkü görevleri al
  List<TaskModel> getTodayTasks() {
    final today = DateTime.now();
    return getTasksByDate(today);
  }

  // Yarınki görevleri al
  List<TaskModel> getTomorrowTasks() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return getTasksByDate(tomorrow);
  }

  // Bu haftaki görevleri al
  List<TaskModel> getThisWeekTasks() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return box.values.where((task) {
      return task.dateTime.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          task.dateTime.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }
}
