import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final Function(bool?)? onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusChanged,
  }) : super();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCard &&
          runtimeType == other.runtimeType &&
          task == other.task &&
          onTap == other.onTap &&
          onStatusChanged == other.onStatusChanged;

  @override
  int get hashCode => Object.hash(task, onTap, onStatusChanged);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Görev durumunu kontrol et
    final bool isPastDue =
        task.isTask &&
        !task.isDone &&
        task.dateTime.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        );

    // Renkleri belirle
    final Color primaryColor =
        task.isDone
            ? Colors.green
            : isPastDue
            ? colorScheme.error
            : task.isTask
            ? const Color(0xFFFF6B35)
            : const Color(0xFFFF8A50);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:
                              task.isDone
                                  ? const Color(0xFF8B5A3C).withOpacity(0.6)
                                  : const Color(0xFF8B5A3C),
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.isTask)
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: task.isDone,
                          onChanged: onStatusChanged,
                          activeColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    style: textTheme.bodyMedium?.copyWith(
                      color:
                          task.isDone
                              ? const Color(0xFF8B5A3C).withOpacity(0.4)
                              : const Color(0xFF8B5A3C).withOpacity(0.7),
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (task.description.isNotEmpty) const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      task.isTask
                          ? Icons.calendar_today_outlined
                          : Icons.notes_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(task.dateTime),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (task.category != null && task.category!.isNotEmpty)
                      Chip(
                        avatar: Icon(
                          Icons.label_outline,
                          size: 16,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        label: Text(task.category!),
                        backgroundColor: colorScheme.secondaryContainer
                            .withOpacity(0.7),
                        labelStyle: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
