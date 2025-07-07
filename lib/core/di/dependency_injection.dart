import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/datasources/local/task_local_datasource.dart';
import '../../data/datasources/local/theme_local_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../data/repositories/theme_repository_impl.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../domain/usecases/add_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_all_tasks_usecase.dart';
import '../../domain/usecases/toggle_task_status_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../presentation/controllers/theme_controller.dart';

/// Manages application-wide dependencies using GetX
class DependencyInjection {
  
  /// Initialize all dependencies
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Initialize data sources
    final taskLocalDataSource = await TaskLocalDataSourceImpl.init();
    final themeLocalDataSource = ThemeLocalDataSourceImpl();
    
    // Register repositories
    Get.lazyPut<TaskRepository>(
      () => TaskRepositoryImpl(taskLocalDataSource),
      fenix: true,
    );
    
    Get.lazyPut<ThemeRepository>(
      () => ThemeRepositoryImpl(themeLocalDataSource),
      fenix: true,
    );
    
    // Register use cases
    Get.lazyPut(() => GetAllTasksUseCase(Get.find<TaskRepository>()), fenix: true);
    Get.lazyPut(() => AddTaskUseCase(Get.find<TaskRepository>()), fenix: true);
    Get.lazyPut(() => UpdateTaskUseCase(Get.find<TaskRepository>()), fenix: true);
    Get.lazyPut(() => ToggleTaskStatusUseCase(Get.find<TaskRepository>()), fenix: true);
    Get.lazyPut(() => DeleteTaskUseCase(Get.find<TaskRepository>()), fenix: true);
    
    // Register controllers
    Get.lazyPut<ThemeController>(
      () => ThemeController(Get.find<ThemeRepository>()),
      fenix: true,
    );
    
    Get.lazyPut<TaskController>(
      () => TaskController(
        getAllTasksUseCase: Get.find<GetAllTasksUseCase>(),
        addTaskUseCase: Get.find<AddTaskUseCase>(),
        updateTaskUseCase: Get.find<UpdateTaskUseCase>(),
        toggleTaskStatusUseCase: Get.find<ToggleTaskStatusUseCase>(),
        deleteTaskUseCase: Get.find<DeleteTaskUseCase>(),
      ),
      fenix: true,
    );
  }
}
