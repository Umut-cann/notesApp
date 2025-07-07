import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  DateTime dateTime;

  @HiveField(3)
  String? imagePath;

  @HiveField(4)
  String? audioPath;

  @HiveField(5)
  bool isDone;

  @HiveField(6)
  bool isTask; // true: görev, false: not

  @HiveField(7)
  String? category;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime? reminderTime;

  @HiveField(10)
  Duration? audioDuration;

  TaskModel({
    required this.title,
    required this.description,
    required this.dateTime,
    this.imagePath,
    this.audioPath,
    this.isDone = false,
    this.isTask = true,
    this.category,
    required this.createdAt,
    this.reminderTime,
    this.audioDuration,
  });

  // Görev mi not mu kontrol etmek için
  bool get isNote => !isTask;

  // Tamamlanma durumunu değiştir
  void toggleDone() {
    isDone = !isDone;
    save();
  }

  // Görev/not tipini değiştir
  void toggleType() {
    isTask = !isTask;
    save();
  }

  // Kategori güncelle
  void updateCategory(String? newCategory) {
    category = newCategory;
    save();
  }

  // Hatırlatma zamanı ayarla
  void setReminder(DateTime? reminder) {
    reminderTime = reminder;
    save();
  }

  @override
  String toString() {
    return 'TaskModel{title: $title, description: $description, dateTime: $dateTime, isDone: $isDone, isTask: $isTask}';
  }
}
