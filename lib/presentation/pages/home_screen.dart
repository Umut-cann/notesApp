import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../../utils/notification_test_utils.dart';
import '../../utils/permission_utils.dart';
import '../../widgets/filter_chips.dart';
import '../controllers/task_controller.dart';
import '../controllers/theme_controller.dart';
import 'add_task_screen.dart';
import 'settings_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final RxInt _currentIndex = 0.obs;

  // Get controllers from dependency injection
  final TaskController _taskController = Get.find<TaskController>();
  final ThemeController _themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load tasks in background and check permissions
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load tasks
      await _taskController.fetchAllTasks();

      // Check and request exact alarm permission if needed
      // ignore: use_build_context_synchronously
      await PermissionUtils.checkAndRequestExactAlarmPermission(context);

      // Debug modunda bildirim testlerini çalıştır
      if (kDebugMode) {
        debugPrint('🔔 Debug modunda bildirim testleri başlatılıyor...');
        await NotificationTestUtils.runAllTests();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true, // Navigation bar için sayfa içeriğinin altını uzat
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 70,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.note_alt_outlined,
                color: theme.colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Not Uygulaması',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Tema değiştirme butonu
          Obx(
            () => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color:
                    _themeController.isDarkMode
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  _themeController.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color:
                      _themeController.isDarkMode
                          ? Colors.amber
                          : Colors.indigo,
                  size: 24,
                ),
                onPressed: () => _themeController.toggleTheme(),
                tooltip: 'Temayı değiştir',
                splashRadius: 24,
              ),
            ),
          ),
        ],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Obx(() {
        switch (_currentIndex.value) {
          case 0: // Ana Sayfa
            return Column(
              children: [
                // İstatistikler kartı
                _buildStatsSummary(),

                // Modern category filtering with animations
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuint,
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  height: 50,
                  width: double.infinity,
                  child: ClipRRect(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            theme.scaffoldBackgroundColor,
                            theme.scaffoldBackgroundColor.withOpacity(0.0),
                            theme.scaffoldBackgroundColor.withOpacity(0.0),
                            theme.scaffoldBackgroundColor,
                          ],
                          stops: const [0.0, 0.05, 0.95, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstOut,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: FilterChips(
                          categories: _taskController.getCategories(),
                          selectedCategories:
                              _taskController.selectedCategories,
                          onCategorySelected: (category) {
                            _taskController.toggleCategorySelection(category);
                            // Add haptic feedback for better UX
                            HapticFeedback.lightImpact();
                          },
                          onClearFilters: () {
                            _taskController.clearFilters();
                            // Add haptic feedback for better UX
                            HapticFeedback.mediumImpact();
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Ultra modern search bar with animations
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: 0,
                      ),
                    ],
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.07),
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Material(
                      color: Colors.transparent,
                      child: TextField(
                        controller: _searchController,
                        cursorColor: theme.colorScheme.primary,
                        cursorWidth: 1.5,
                        cursorRadius: const Radius.circular(2),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Görev veya not ara...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(left: 16, right: 8),
                            child: Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 12),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: theme
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.8),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _taskController.setSearchQuery('');
                                      },
                                      splashRadius: 20,
                                      padding: EdgeInsets.zero,
                                    ),
                                  )
                                  : null,
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        onChanged:
                            (value) => _taskController.setSearchQuery(value),
                      ),
                    ),
                  ),
                ),

                // Tab bar - Modern ve daha göz alıcı tasarım
                Container(
                  height: 56,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: theme.colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: theme.colorScheme.onPrimary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.all(4),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(fontSize: 14),
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) => Colors.transparent,
                      ),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: const [Tab(text: 'Görevler'), Tab(text: 'Notlar')],
                    ),
                  ),
                ),

                // Tab içeriği
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Görevler tabı
                      _buildTasksTab(),

                      // Notlar tabı
                      _buildNotesTab(),
                    ],
                  ),
                ),
              ],
            );
          case 1: // Bildirimler
            return _buildNotificationsTab();
          case 2: // Takvim
            return _buildCalendarTab();
          case 3: // Ayarlar
            return const SettingsScreen();
          default:
            return Column(
              children: [
                _buildStatsSummary(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildTasksTab(), _buildNotesTab()],
                  ),
                ),
              ],
            );
        }
      }),
      floatingActionButton: Obx(() {
        if (_currentIndex.value <= 1) {
          return FloatingActionButton(
            onPressed: () => Get.to(() => const AddTaskScreen()),
            elevation: 4,
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.add),
          );
        } else {
          return const SizedBox.shrink();
        }
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigationBar(theme),
    );
  }

  Widget _buildStatsSummary() {
    final theme = Theme.of(context);
    final completionRate =
        _taskController.totalTasks > 0
            ? (_taskController.completedTasks / _taskController.totalTasks)
            : 0.0;

    // Get screen width to make layout responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.secondary.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 12 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'İstatistikler',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 18 : 20,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(completionRate * 100).toStringAsFixed(0)}% Tamamlandı',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 11 : 12,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    label: 'Toplam',
                    value: '${_taskController.totalTasks}',
                    icon: Icons.task_alt,
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildStatItem(
                    label: 'Tamamlanan',
                    value: '${_taskController.completedTasks}',
                    icon: Icons.check_circle_outline,
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildStatItem(
                    label: 'Bekleyen',
                    value: '${_taskController.pendingTasks}',
                    icon: Icons.hourglass_empty,
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    bool isSmallScreen = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 40 : 46,
          height: isSmallScreen ? 40 : 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: isSmallScreen ? 22 : 24),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: isSmallScreen ? 12 : 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    final filteredTasks =
        _taskController.filteredTasks.where((task) => task.isTask).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz görev eklenmemiş',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      // Add sufficient bottom padding to avoid overlap with bottom navigation bar
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        // Enhanced animations for list items with slide and fade effect
        return AnimatedSlide(
          offset: Offset(0, 0),
          duration: Duration(milliseconds: 400 + (index * 50)),
          curve: Curves.easeOutQuint,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 500 + (index * 70)),
            curve: Curves.easeInOut,
            child: _buildTaskItem(task),
          ),
        );
      },
    );
  }

  Widget _buildNotesTab() {
    final filteredNotes =
        _taskController.filteredTasks.where((task) => !task.isTask).toList();

    if (filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz not eklenmemiş',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      // Add sufficient bottom padding to avoid overlap with bottom navigation bar
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        // Enhanced animations for list items with slide and fade effect
        return AnimatedSlide(
          offset: Offset(0, 0),
          duration: Duration(milliseconds: 400 + (index * 50)),
          curve: Curves.easeOutQuint,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 500 + (index * 70)),
            curve: Curves.easeInOut,
            child: _buildTaskItem(note),
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(TaskEntity task) {
    final theme = Theme.of(context);
    final String dateFormatted =
        task.isTask
            ? DateFormat('dd MMM, HH:mm', 'tr_TR').format(task.dateTime)
            : '';

    // Get category color for styling
    final categoryColor =
        task.category?.isNotEmpty == true
            ? _getCategoryColor(task.category!)
            : null;

    // Task status colors - used for icons and indicators
    final statusColor =
        task.isTask
            ? (task.isDone ? Colors.green : theme.colorScheme.primary)
            : theme.colorScheme.secondary;

    // Use the status color for the icon backgrounds and borders

    return Hero(
      tag: 'task-${task.id}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        decoration: BoxDecoration(
          color:
              task.isDone
                  ? theme.colorScheme.surfaceVariant.withOpacity(0.4)
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(task.isDone ? 0.04 : 0.08),
              blurRadius: task.isDone ? 6 : 10,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color:
                categoryColor != null
                    ? categoryColor.withOpacity(task.isDone ? 0.3 : 0.8)
                    : theme.colorScheme.outline.withOpacity(
                      task.isDone ? 0.05 : 0.1,
                    ),
            width: categoryColor != null ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Get.to(() => TaskDetailScreen(task: task)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Check circle or note icon
                      if (task.isTask)
                        InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            if (task.id != null) {
                              // Call with correct parameters: id and the new status (opposite of current)
                              _taskController.toggleTaskStatus(
                                task.id!,
                                !task.isDone,
                              );
                              // Add haptic feedback for better UX
                              HapticFeedback.mediumImpact();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  task.isDone
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              task.isDone
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color:
                                  task.isDone
                                      ? Colors.green
                                      : theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.note_outlined,
                            color: statusColor,
                            size: 24,
                          ),
                        ),

                      const SizedBox(width: 12),

                      // Task content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                decoration:
                                    task.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                decorationColor: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                                decorationThickness: 2,
                              ),
                            ),
                            if (task.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  task.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                            // Category and date row
                            Row(
                              children: [
                                if (task.category?.isNotEmpty == true)
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 8,
                                      right: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: categoryColor!.withOpacity(
                                        task.isDone ? 0.1 : 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      task.category!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: categoryColor.withOpacity(
                                          task.isDone ? 0.6 : 1.0,
                                        ),
                                      ),
                                    ),
                                  ),

                                if (task.isTask && dateFormatted.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateFormatted,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Ultra modern navigation bar oluşturan metod
  Widget _buildBottomNavigationBar(ThemeData theme) {
    // Responsive margin based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth < 360 ? 12.0 : 20.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? Colors.grey[900]!.withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Ana Sayfa', theme),
                _buildNavItem(
                  1,
                  Icons.notifications_rounded,
                  'Bildirimler',
                  theme,
                ),
                _buildNavItem(2, Icons.calendar_today_rounded, 'Takvim', theme),
                _buildNavItem(3, Icons.settings_rounded, 'Ayarlar', theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation bar içindeki öğeleri oluşturan metod
  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    ThemeData theme,
  ) {
    final isSelected = _currentIndex.value == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return InkWell(
      onTap: () => _currentIndex.value = index,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: 6,
          horizontal: isSmallScreen ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bildirimler sekmesi
  Widget _buildNotificationsTab() {
    final overdueOrDueTasks = [
      ..._taskController.getOverdueTasks(),
      ..._taskController.getTasksDueToday(),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bildirimler',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Geciken ve Bugünün Görevleri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                overdueOrDueTasks.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 70,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bildirim yok',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: overdueOrDueTasks.length,
                      itemBuilder: (context, index) {
                        final task = overdueOrDueTasks[index];
                        return _buildTaskItem(task);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Takvim sekmesi
  Widget _buildCalendarTab() {
    final theme = Theme.of(context);

    // Padding at the bottom to avoid overlap with navigation bar
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Takvim',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Calendar API integrations will be added later
          // For now, just showing a placeholder with additional bottom padding
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(
                          0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Takvim yakında eklenecek',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onBackground.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Takvim entegrasyonu için çalışmalar devam ediyor',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Görevlerin listesi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planlanmış Görevler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _taskController.tasks.isEmpty
                          ? Center(
                            child: Text(
                              'Planlanmış görev yok',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: _taskController.tasks.length,
                            itemBuilder: (context, index) {
                              final task = _taskController.tasks[index];
                              if (task.isTask) {
                                return _buildTaskItem(task);
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kategori rengini belirleyen yardımcı metod
  Color _getCategoryColor(String category) {
    // Kategori adına göre tutarlı bir renk üret
    final int hashCode = category.hashCode;
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    return colors[hashCode.abs() % colors.length];
  }
}
