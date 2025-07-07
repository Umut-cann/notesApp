import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';
import '../../core/utils/result.dart';

/// Use case for updating an existing task
class UpdateTaskUseCase {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  /// Update an existing task and return success status
  Future<Result<bool>> call(TaskEntity task) async {
    return await repository.updateTask(task);
  }
}
