import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<Result<List<TaskModel>>> getAllTasks();
  Future<Result<TaskModel>> getTaskById(int id);
  Future<Result<int>> addTask(TaskModel task);
  Future<Result<bool>> updateTask(TaskModel task);
  Future<Result<bool>> deleteTask(int id);
  Future<Result<List<TaskModel>>> getTasksByCategory(String category);
  Future<Result<List<TaskModel>>> searchTasks(String query);
  Future<Result<bool>> clearAllTasks();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Box<dynamic> _tasksBox;

  TaskLocalDataSourceImpl(this._tasksBox);

  /// Initialize the data source
  static Future<TaskLocalDataSourceImpl> init() async {
    Box<dynamic> box;
    
    try {
      // Kutu zaten açıksa, onu al; değilse yeni bir kutu aç
      if (Hive.isBoxOpen(AppConstants.tasksBoxName)) {
        box = Hive.box<dynamic>(AppConstants.tasksBoxName);
        debugPrint('Using already open tasks box');
      } else {
        box = await Hive.openBox<dynamic>(AppConstants.tasksBoxName);
        debugPrint('Opened new tasks box');
      }
    } catch (e) {
      debugPrint('Hive error opening box: $e');
      // Box zaten açıksa ve farklı bir tipteyse, tüm kutuları kapatıp tekrar deneyelim
      await Hive.close();
      box = await Hive.openBox<dynamic>(AppConstants.tasksBoxName);
      debugPrint('Reopened tasks box after closing all');
    }
    
    return TaskLocalDataSourceImpl(box);
  }

  @override
  Future<Result<List<TaskModel>>> getAllTasks() async {
    try {
      final tasksMap = _tasksBox.toMap();
      final List<TaskModel> tasks = [];
      
      for (var value in tasksMap.values) {
        // Handle the case where the value might be a TaskModel or a Map
        if (value is TaskModel) {
          tasks.add(value);
        } else if (value is Map) {
          try {
            tasks.add(TaskModel.fromJson(Map<String, dynamic>.from(value)));
          } catch (e) {
            debugPrint('Error converting map to TaskModel: $e');
            // Skip invalid entries
          }
        }
      }
      
      debugPrint('Before filtering: ${tasks.length} tasks');
      return Result.success(tasks);
    } catch (e) {
      debugPrint('Error getting all tasks: $e');
      return Result.failure(DatabaseFailure('Failed to retrieve tasks: $e'));
    }
  }

  @override
  Future<Result<TaskModel>> getTaskById(int id) async {
    try {
      final taskJson = _tasksBox.get(id);
      if (taskJson == null) {
        return Result.failure(DatabaseFailure('Task not found'));
      }
      
      final task = TaskModel.fromJson(Map<String, dynamic>.from(taskJson));
      return Result.success(task);
    } catch (e) {
      debugPrint('Error getting task by id: $e');
      return Result.failure(DatabaseFailure('Failed to retrieve task: $e'));
    }
  }

  @override
  Future<Result<int>> addTask(TaskModel task) async {
    try {
      // Generate a unique key if none provided, ensuring it's within Hive's valid range (0 to 0xFFFFFFFF)
      int id;
      if (task.id != null) {
        id = task.id!;
      } else {
        // Use a timestamp-based approach but ensure it's within the valid range
        // Limit to the last 8 digits to stay within Hive's range
        int timestamp = DateTime.now().millisecondsSinceEpoch;
        id = timestamp % 0xFFFFFFFF; // Ensure ID is within valid range
        
        // Avoid ID collisions by checking if the ID already exists
        if (_tasksBox.containsKey(id)) {
          // Try a different approach - use a counter starting from the current time
          int counter = 0;
          while (_tasksBox.containsKey(id) && counter < 1000) {
            id = (timestamp + counter) % 0xFFFFFFFF;
            counter++;
          }
          
          if (_tasksBox.containsKey(id)) {
            // If we still have a collision, use a random number as a last resort
            id = Random().nextInt(0xFFFFFFFF);
            while (_tasksBox.containsKey(id)) {
              id = Random().nextInt(0xFFFFFFFF);
            }
          }
        }
      }
      
      final taskWithId = task.copyWith(id: id);
      await _tasksBox.put(id, taskWithId.toJson());
      return Result.success(id);
    } catch (e) {
      debugPrint('Error adding task: $e');
      return Result.failure(DatabaseFailure('Failed to add task: $e'));
    }
  }

  @override
  Future<Result<bool>> updateTask(TaskModel task) async {
    try {
      if (task.id == null) {
        return Result.failure(DatabaseFailure('Task ID is required for updates'));
      }
      
      await _tasksBox.put(task.id, task.toJson());
      return Result.success(true);
    } catch (e) {
      debugPrint('Error updating task: $e');
      return Result.failure(DatabaseFailure('Failed to update task: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteTask(int id) async {
    try {
      await _tasksBox.delete(id);
      return Result.success(true);
    } catch (e) {
      debugPrint('Error deleting task: $e');
      return Result.failure(DatabaseFailure('Failed to delete task: $e'));
    }
  }

  @override
  Future<Result<List<TaskModel>>> getTasksByCategory(String category) async {
    try {
      final Result<List<TaskModel>> allTasksResult = await getAllTasks();
      
      if (!allTasksResult.isSuccess) {
        return allTasksResult;
      }
      
      final filteredTasks = allTasksResult.data!
          .where((task) => task.category == category)
          .toList();
          
      return Result.success(filteredTasks);
    } catch (e) {
      debugPrint('Error getting tasks by category: $e');
      return Result.failure(DatabaseFailure('Failed to filter tasks: $e'));
    }
  }

  @override
  Future<Result<List<TaskModel>>> searchTasks(String query) async {
    try {
      final Result<List<TaskModel>> allTasksResult = await getAllTasks();
      
      if (!allTasksResult.isSuccess) {
        return allTasksResult;
      }
      
      final searchQuery = query.toLowerCase();
      final filteredTasks = allTasksResult.data!
          .where((task) => 
              task.title.toLowerCase().contains(searchQuery) || 
              task.description.toLowerCase().contains(searchQuery))
          .toList();
          
      return Result.success(filteredTasks);
    } catch (e) {
      debugPrint('Error searching tasks: $e');
      return Result.failure(DatabaseFailure('Failed to search tasks: $e'));
    }
  }

  @override
  Future<Result<bool>> clearAllTasks() async {
    try {
      await _tasksBox.clear();
      return Result.success(true);
    } catch (e) {
      debugPrint('Error clearing all tasks: $e');
      return Result.failure(DatabaseFailure('Failed to clear tasks: $e'));
    }
  }
}
