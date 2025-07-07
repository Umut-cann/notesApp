import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';
import '../../core/utils/result.dart';

/// Use case for getting all tasks
class GetAllTasksUseCase {
  final TaskRepository repository;

  GetAllTasksUseCase(this.repository);

  Future<Result<List<TaskEntity>>> call() async {
    return await repository.getAllTasks();
  }
}
