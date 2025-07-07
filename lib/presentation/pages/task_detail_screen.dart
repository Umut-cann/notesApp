import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../../services/media_service.dart';
import '../controllers/task_controller.dart';
import '../pages/add_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskEntity task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  DateTime _toGmtPlus3(DateTime dateTime) {
    return dateTime.toUtc().add(const Duration(hours: 3));
  }

  // Get task controller from dependency injection
  final TaskController _taskController = Get.find<TaskController>();

  bool _isPlaying = false;

  // Show a confirmation dialog before deleting a task
  void _showDeleteConfirmationDialog() {
    Get.defaultDialog(
      title: 'Görev Silme',
      middleText:
          '${widget.task.isTask ? "Görevi" : "Notu"} silmek istediğinizden emin misiniz?',
      textConfirm: 'Evet, Sil',
      textCancel: 'İptal',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        if (widget.task.id != null) {
          final result = await _taskController.deleteTask(widget.task.id!);
          if (result) {
            Get.back(); // Close the dialog
            Get.back(); // Return to the previous screen
            Get.snackbar(
              'Başarılı',
              '${widget.task.isTask ? "Görev" : "Not"} başarıyla silindi',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.7),
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          } else {
            Get.back(); // Close the dialog
            Get.snackbar(
              'Hata',
              'Silme işlemi başarısız oldu',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.withOpacity(0.7),
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task.isTask ? 'Görev Detayı' : 'Not Detayı',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.to(() => AddTaskScreen(taskToEdit: widget.task));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          widget.task.isTask
                              ? Icons.task_alt
                              : Icons.note_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.task.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (widget.task.category != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.category_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Chip(
                              label: Text(
                                widget.task.category!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final DateTime gmtPlus3DateTime = _toGmtPlus3(
                                widget.task.dateTime,
                              );
                              return Text(
                                DateFormat(
                                      'dd MMMM yyyy, HH:mm',
                                      'tr_TR',
                                    ).format(gmtPlus3DateTime) +
                                    ' (GMT+3)',
                                style: TextStyle(
                                  color:
                                      _isDatePassed(
                                            widget.task.dateTime,
                                          ) // Keep original logic for overdue color
                                          ? Colors.red
                                          : null,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    if (widget.task.reminderTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.alarm_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final DateTime gmtPlus3ReminderTime =
                                    _toGmtPlus3(widget.task.reminderTime!);
                                return Text(
                                  'Hatırlatma: ${DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(gmtPlus3ReminderTime)} (GMT+3)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (widget.task.isTask) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: widget.task.isDone,
                            onChanged: (value) {
                              if (value != null && widget.task.id != null) {
                                _taskController.toggleTaskStatus(
                                  widget.task.id!,
                                  value,
                                );
                                Navigator.pop(context);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.task.isDone ? 'Tamamlandı' : 'Tamamlanmadı',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              decoration:
                                  widget.task.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Description
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Açıklama',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.task.description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Media attachments section would go here
            if (widget.task.imagePath != null || widget.task.audioPath != null)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ekler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image attachment
                      if (widget.task.imagePath != null) ...[
                        const Text(
                          'Görsel',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildOptimizedImage(widget.task.imagePath!),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Audio attachment
                      if (widget.task.audioPath != null) ...[
                        const Text(
                          'Ses Kaydı',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.audiotrack_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ses kaydı (${_formatDuration(widget.task.audioDuration)})',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                color: Theme.of(context).primaryColor,
                                onPressed: () {
                                  _toggleAudioPlayback();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Metadata card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bilgiler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final DateTime gmtPlus3CreatedAt = _toGmtPlus3(
                                widget.task.createdAt,
                              );
                              return Text(
                                'Oluşturulma: ${DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(gmtPlus3CreatedAt)} (GMT+3)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text('Geri'),
        elevation: 2,
      ),
    );
  }

  bool _isDatePassed(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';

    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  // Optimized image builder that prevents Impeller renderer issues
  Widget _buildOptimizedImage(String imagePath) {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return _buildPlaceholderImage();
      }

      // Using a basic Image widget with precaching to avoid Impeller renderer issues
      // We'll load the image as a memory image with limited size to prevent mipmap generation issues
      return FutureBuilder<Uint8List>(
        future: _loadImageSafely(file),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingPlaceholder();
          } else if (snapshot.hasError || !snapshot.hasData) {
            return _buildPlaceholderImage();
          } else {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Error loading image: $e');
      return _buildPlaceholderImage();
    }
  }

  // Load image safely with limited size to prevent Impeller renderer issues
  Future<Uint8List> _loadImageSafely(File file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Error reading image file: $e');
      // Return a 1x1 transparent image as fallback
      return kTransparentImage;
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.grey[600],
          size: 50,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
          strokeWidth: 3,
        ),
      ),
    );
  }

  // 1x1 transparent image for use as placeholder
  static final Uint8List kTransparentImage = Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  Future<void> _toggleAudioPlayback() async {
    if (_isPlaying) {
      await MediaService.stopAudio();
      setState(() {
        _isPlaying = false;
      });
    } else if (widget.task.audioPath != null) {
      // Register completion callback before playing
      MediaService.setOnPlaybackCompleted(() {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });

      // Update UI first to show playing state
      setState(() {
        _isPlaying = true;
      });

      // Play audio with MediaService
      final success = await MediaService.playAudio(widget.task.audioPath!);

      // If playback couldn't start, reset UI and clear callback
      if (!success) {
        MediaService.clearOnPlaybackCompleted();
        setState(() {
          _isPlaying = false;
        });
        // Show error message
        Get.snackbar(
          'Hata',
          'Ses dosyası oynatılamadı',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  void dispose() {
    if (_isPlaying) {
      MediaService.stopAudio();
    }
    super.dispose();
  }
}
