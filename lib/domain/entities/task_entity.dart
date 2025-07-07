// Domain entity representing a task in the application
class TaskEntity {
  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isDone;
  final bool isTask; // True for task, false for note
  final String? category;
  final String? imagePath;
  final String? audioPath;
  final Duration? audioDuration;
  final DateTime createdAt;
  final DateTime? reminderTime;

  TaskEntity({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.isDone,
    required this.isTask,
    this.category,
    this.imagePath,
    this.audioPath,
    this.audioDuration,
    required this.createdAt,
    this.reminderTime,
  });
  
  /// Create a copy of this TaskEntity with the given fields replaced with new values
  TaskEntity copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isDone,
    bool? isTask,
    String? category,
    String? imagePath,
    String? audioPath,
    Duration? audioDuration,
    DateTime? createdAt,
    DateTime? reminderTime,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isDone: isDone ?? this.isDone,
      isTask: isTask ?? this.isTask,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      audioDuration: audioDuration ?? this.audioDuration,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
