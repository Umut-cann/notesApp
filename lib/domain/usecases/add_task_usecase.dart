import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';
import '../../core/utils/result.dart';

/// Use case for adding a new task
class AddTaskUseCase {
  final TaskRepository repository;

  AddTaskUseCase(this.repository);

  /// Add a new task and return the ID if successful
  Future<Result<int>> call(TaskEntity task) async {
    return await repository.addTask(task);
  }
}
