import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../controllers/task_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TaskController taskController = Get.find<TaskController>();
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              'Bildirimler',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Obx(() {
        // Get tasks due today
        final tasksDueToday = taskController.getTasksDueToday();
        
        // Get overdue tasks
        final overdueTasks = taskController.getOverdueTasks();
        
        if (tasksDueToday.isEmpty && overdueTasks.isEmpty) {
          return _buildEmptyState(context);
        }
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overdue tasks section
            if (overdueTasks.isNotEmpty) ...[
              const _SectionHeader(title: 'Gecikmiş Görevler', icon: Icons.warning_rounded, color: Colors.red),
              const SizedBox(height: 8),
              ...overdueTasks.map((task) => _NotificationCard(
                title: task.title,
                description: task.description,
                dateTime: task.dateTime,
                isOverdue: true,
                onTap: () {
                  // Navigate to task detail
                  // Get.to(() => TaskDetailScreen(task: task));
                },
              )),
              const SizedBox(height: 16),
            ],
            
            // Tasks due today section
            if (tasksDueToday.isNotEmpty) ...[
              const _SectionHeader(title: 'Bugün', icon: Icons.today_rounded, color: Colors.blue),
              const SizedBox(height: 8),
              ...tasksDueToday.map((task) => _NotificationCard(
                title: task.title,
                description: task.description,
                dateTime: task.dateTime,
                isOverdue: false,
                onTap: () {
                  // Navigate to task detail
                  // Get.to(() => TaskDetailScreen(task: task));
                },
              )),
            ],
          ],
        );
      }),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bildirim Yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Bugün için planlanmış göreviniz yok',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isOverdue;
  final VoidCallback onTap;
  
  const _NotificationCard({
    required this.title,
    required this.description,
    required this.dateTime,
    required this.isOverdue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat timeFormat = DateFormat('HH:mm', 'tr_TR');
    final DateFormat dateFormat = DateFormat('dd MMM', 'tr_TR');
    final theme = Theme.of(context);
    final cardColor = isOverdue ? Colors.red : theme.colorScheme.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isOverdue 
              ? Colors.red.withOpacity(0.3)
              : theme.colorScheme.primary.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: cardColor.withOpacity(0.1),
            highlightColor: cardColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isOverdue ? Icons.warning_amber_rounded : Icons.notifications_active_rounded,
                          color: cardColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: cardColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${dateFormat.format(dateTime)} - ${timeFormat.format(dateTime)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cardColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isOverdue ? 'Gecikti' : 'Bugün',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: cardColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              if (isOverdue) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        size: 16,
                        color: Colors.red[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Gecikmiş görev - Hemen tamamlayın',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
              ]) ),
                  ],
                  if (isOverdue) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high_rounded,
                            size: 16,
                            color: Colors.red[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Gecikmiş görev - Hemen tamamlayın',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ));
    }
  }
