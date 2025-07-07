import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/add_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_all_tasks_usecase.dart';
import '../../domain/usecases/toggle_task_status_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import '../../utils/permission_utils.dart';

class TaskController extends GetxController {
  // Use cases
  final GetAllTasksUseCase getAllTasksUseCase;
  final AddTaskUseCase addTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final ToggleTaskStatusUseCase toggleTaskStatusUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  
  // Repository
  // Burada doğrudan TaskRepository kullanılıyor - Get.find<TaskRepository>() ile

  // Observable variables
  final _tasks = <TaskEntity>[].obs;
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final _searchQuery = ''.obs;
  final _filteredTasks = <TaskEntity>[].obs;
  final _selectedCategories = <String>[].obs;
  final _showCompletedTasks = true.obs;
  
  // Getters
  List<TaskEntity> get tasks => _tasks;
  List<TaskEntity> get filteredTasks => _filteredTasks;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  String get searchQuery => _searchQuery.value;
  List<String> get selectedCategories => _selectedCategories;
  bool get showCompletedTasks => _showCompletedTasks.value;
  
  // For task stats
  int get totalTasks => _tasks.where((task) => task.isTask).length;
  int get completedTasks => _tasks.where((task) => task.isTask && task.isDone).length;
  int get pendingTasks => _tasks.where((task) => task.isTask && !task.isDone).length;
  int get totalNotes => _tasks.where((task) => !task.isTask).length;
  double get completionRate => totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;
  
  // Constructor
  TaskController({
    required this.getAllTasksUseCase,
    required this.addTaskUseCase,
    required this.updateTaskUseCase,
    required this.toggleTaskStatusUseCase,
    required this.deleteTaskUseCase,
  });
  
  DateTime _utcToGmtPlus3(DateTime utcDateTime) {
    // Assumes utcDateTime is an actual UTC instant. Convert to GMT+3 wall clock time.
    return utcDateTime.add(const Duration(hours: 3));
  }

  @override
  void onInit() {
    super.onInit();
    fetchAllTasks();
  }
  
  // Fetch all tasks from repository
  Future<void> fetchAllTasks() async {
    _isLoading.value = true;
    _error.value = null;
    
    final result = await getAllTasksUseCase();
    
    if (result.isSuccess) {
      _tasks.value = result.data!;
      // Make sure to apply filters after fetching tasks
      _applyFilters();
      
      // Log for debugging
      debugPrint('Fetched ${_tasks.length} tasks, filtered to ${_filteredTasks.length} tasks');
      for (var task in _tasks) {
        debugPrint('Task: ${task.title}, isTask: ${task.isTask}, isDone: ${task.isDone}');
      }
    } else {
      _error.value = result.failure!.message;
    }
    
    _isLoading.value = false;
  }
  
  // Add a new task
  Future<bool> addTask(TaskEntity task, {BuildContext? context}) async {
    _isLoading.value = true;
    _error.value = null;
    
    // Check for exact alarm permission if this is a task with date/time
    if (context != null && task.isTask && task.dateTime.isAfter(DateTime.now())) {
      await PermissionUtils.checkAndRequestExactAlarmPermission(context);
    }
    
    final result = await addTaskUseCase(task);
    
    if (result.isSuccess) {
      // Refresh task list and reapply filters to ensure new task appears
      await fetchAllTasks();
      // Make sure we clear any filters that might hide the newly added task
      // or temporarily disable filtering to show the new task
      _searchQuery.value = '';
      _applyFilters();
      return true;
    } else {
      _error.value = result.failure!.message;
      _isLoading.value = false;
      return false;
    }
  }
  
  // Update an existing task
  Future<bool> updateTask(TaskEntity task, {BuildContext? context}) async {
    _isLoading.value = true;
    _error.value = null;
    
    // Check for exact alarm permission if this is a task with date/time
    if (context != null && task.isTask && task.dateTime.isAfter(DateTime.now())) {
      await PermissionUtils.checkAndRequestExactAlarmPermission(context);
    }
    
    final result = await updateTaskUseCase(task);
    
    if (result.isSuccess) {
      // Refresh task list
      await fetchAllTasks();
      return true;
    } else {
      _error.value = result.failure!.message;
      _isLoading.value = false;
      return false;
    }
  }
  
  // Toggle task completion status
  Future<bool> toggleTaskStatus(int id, bool newStatus) async {
    _isLoading.value = true;
    _error.value = null;
    
    final result = await toggleTaskStatusUseCase(id, newStatus);
    
    if (result.isSuccess) {
      // Update local list without full refresh for better performance
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        final updatedTask = _tasks[index].copyWith(isDone: newStatus);
        _tasks[index] = updatedTask;
        _applyFilters(); // Re-apply filters to update filtered list
      }
      
      _isLoading.value = false;
      return true;
    } else {
      _error.value = result.failure!.message;
      _isLoading.value = false;
      return false;
    }
  }
  
  // Delete a task
  Future<bool> deleteTask(int id) async {
    _isLoading.value = true;
    _error.value = null;
    
    final result = await deleteTaskUseCase(id);
    
    if (result.isSuccess) {
      // Remove the task from local list
      _tasks.removeWhere((task) => task.id == id);
      _applyFilters(); // Re-apply filters to update filtered list
      _isLoading.value = false;
      return true;
    } else {
      _error.value = result.failure!.message;
      _isLoading.value = false;
      return false;
    }
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery.value = query;
    _applyFilters();
  }
  
  // Toggle showing completed tasks
  void toggleShowCompletedTasks() {
    _showCompletedTasks.value = !_showCompletedTasks.value;
    _applyFilters();
  }
  
  // Toggle category selection
  void toggleCategorySelection(String category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    _applyFilters();
  }
  
  // Clear all filters
  void clearFilters() {
    _searchQuery.value = '';
    _selectedCategories.clear();
    _showCompletedTasks.value = true;
    _applyFilters();
  }
  
  // Apply all active filters
  void _applyFilters() {
    // Start with all tasks
    List<TaskEntity> filtered = List.from(_tasks);
    
    // Debug log for total tasks before filtering
    debugPrint('Before filtering: ${filtered.length} tasks');
    
    // Apply search query filter
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(query) || 
               task.description.toLowerCase().contains(query);
      }).toList();
      debugPrint('After search filter: ${filtered.length} tasks');
    }
    
    // Apply category filter
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.category != null && 
               _selectedCategories.contains(task.category);
      }).toList();
      debugPrint('After category filter: ${filtered.length} tasks');
    }
    
    // Apply completed tasks filter
    if (!_showCompletedTasks.value) {
      filtered = filtered.where((task) => !task.isDone).toList();
      debugPrint('After completion filter: ${filtered.length} tasks');
    }
    
    // Update the filtered tasks observable
    _filteredTasks.value = filtered;
    
    // Force UI refresh by updating the observable
    _filteredTasks.refresh();
  }
  
  // Get all unique categories
  List<String> getCategories() {
    final categories = _tasks
        .map((task) => task.category)
        .where((category) => category != null && category.isNotEmpty)
        .toSet()
        .toList()
        .cast<String>();
    
    return categories;
  }
  
  // Get tasks due today
  List<TaskEntity> getTasksDueToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _tasks.where((task) {
      if (!task.isTask || task.isDone) return false;
      
      final taskDate = DateTime(
        task.dateTime.year, 
        task.dateTime.month, 
        task.dateTime.day
      );
      
      return taskDate.isAtSameMomentAs(today);
    }).toList();
  }
  
  // Get overdue tasks
  List<TaskEntity> getOverdueTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _tasks.where((task) {
      if (!task.isTask || task.isDone) return false;
      
      final taskDate = DateTime(
        task.dateTime.year, 
        task.dateTime.month, 
        task.dateTime.day
      );
      
      return taskDate.isBefore(today);
    }).toList();
  }
  
  // Clear all tasks and data
  Future<bool> clearAllTasks() async {
    _isLoading.value = true;
    _error.value = null;
    
    try {
      final result = await Get.find<TaskRepository>().clearAllTasks();
      
      if (result.isSuccess) {
        // Clear local lists
        _tasks.clear();
        _filteredTasks.clear();
        _selectedCategories.clear();
        _searchQuery.value = '';
        
        _isLoading.value = false;
        return true;
      } else {
        _error.value = result.failure!.message;
        _isLoading.value = false;
        return false;
      }
    } catch (e) {
      _error.value = 'Beklenmeyen bir hata oluştu: $e';
      _isLoading.value = false;
      return false;
    }
  }
}
