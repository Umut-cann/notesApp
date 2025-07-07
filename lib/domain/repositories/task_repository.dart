import '../entities/task_entity.dart';
import '../../core/utils/result.dart';

/// Repository interface for task operations
/// This follows the Dependency Inversion principle from SOLID
abstract class TaskRepository {
  /// Get all tasks
  Future<Result<List<TaskEntity>>> getAllTasks();
  
  /// Get task by ID
  Future<Result<TaskEntity>> getTaskById(int id);
  
  /// Add a new task
  Future<Result<int>> addTask(TaskEntity task);
  
  /// Update an existing task
  Future<Result<bool>> updateTask(TaskEntity task);
  
  /// Delete a task
  Future<Result<bool>> deleteTask(int id);
  
  /// Toggle task completion status
  Future<Result<bool>> toggleTaskStatus(int id, bool isDone);
  
  /// Get tasks by category
  Future<Result<List<TaskEntity>>> getTasksByCategory(String category);
  
  /// Get tasks by date range
  Future<Result<List<TaskEntity>>> getTasksByDateRange(DateTime start, DateTime end);
  
  /// Search tasks by query
  Future<Result<List<TaskEntity>>> searchTasks(String query);
  
  /// Clear all task data
  Future<Result<bool>> clearAllTasks();
}
