import '../../domain/entities/task_entity.dart';

/// Data model for tasks, extends the domain entity and adds Hive persistence
class TaskModel extends TaskEntity {
  TaskModel({
    int? id,
    required String title,
    required String description,
    required DateTime dateTime,
    bool isDone = false,
    required bool isTask,
    String? category,
    String? imagePath,
    String? audioPath,
    Duration? audioDuration,
    DateTime? createdAt,
    DateTime? reminderTime,
  }) : super(
          id: id,
          title: title,
          description: description,
          dateTime: dateTime,
          isDone: isDone,
          isTask: isTask,
          category: category,
          imagePath: imagePath,
          audioPath: audioPath,
          audioDuration: audioDuration,
          createdAt: createdAt ?? DateTime.now(),
          reminderTime: reminderTime,
        );

  /// Convert domain entity to data model
  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      dateTime: entity.dateTime,
      isDone: entity.isDone,
      isTask: entity.isTask,
      category: entity.category,
      imagePath: entity.imagePath,
      audioPath: entity.audioPath,
      audioDuration: entity.audioDuration,
      createdAt: entity.createdAt,
      reminderTime: entity.reminderTime,
    );
  }

  /// Convert to map for Hive storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'isDone': isDone,
      'isTask': isTask,
      'category': category,
      'imagePath': imagePath,
      'audioPath': audioPath,
      'audioDuration': audioDuration?.inMilliseconds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'reminderTime': reminderTime?.millisecondsSinceEpoch,
    };
  }

  /// Create from Hive storage map
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
      isDone: json['isDone'] ?? false,
      isTask: json['isTask'] ?? true,
      category: json['category'],
      imagePath: json['imagePath'],
      audioPath: json['audioPath'],
      audioDuration: json['audioDuration'] != null 
          ? Duration(milliseconds: json['audioDuration']) 
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      reminderTime: json['reminderTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['reminderTime']) 
          : null,
    );
  }

  /// Convenience getter to check if this is a note
  bool get isNote => !isTask;
  
  /// Get a copy of this model with different values
  TaskModel copyWith({
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
    return TaskModel(
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
