import '../repositories/task_repository.dart';
import '../../core/utils/result.dart';

/// Use case for toggling task completion status
class ToggleTaskStatusUseCase {
  final TaskRepository repository;

  ToggleTaskStatusUseCase(this.repository);

  /// Toggle the completion status of a task
  Future<Result<bool>> call(int id, bool newStatus) async {
    return await repository.toggleTaskStatus(id, newStatus);
  }
}
