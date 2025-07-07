import '../../core/utils/result.dart';
import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  final TaskRepository repository;

  DeleteTaskUseCase(this.repository);

  /// Delete a task by its ID
  Future<Result<bool>> call(int id) async {
    return await repository.deleteTask(id);
  }
}
