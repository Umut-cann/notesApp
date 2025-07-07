import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../../services/media_service.dart';
import '../controllers/task_controller.dart';

class AddTaskScreen extends StatefulWidget {
  final TaskEntity? taskToEdit;

  const AddTaskScreen({super.key, this.taskToEdit});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen>
    with SingleTickerProviderStateMixin {
  final TaskController _taskController = Get.find<TaskController>();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<Map<String, dynamic>> _predefinedCategories = [
    {'name': 'İş', 'icon': Icons.work, 'color': Colors.blue},
    {'name': 'Kişisel', 'icon': Icons.person, 'color': Colors.purple},
    {'name': 'Alışveriş', 'icon': Icons.shopping_cart, 'color': Colors.green},
    {'name': 'Sağlık', 'icon': Icons.favorite, 'color': Colors.red},
    {
      'name': 'Finans',
      'icon': Icons.account_balance_wallet,
      'color': Colors.amber,
    },
    {'name': 'Eğitim', 'icon': Icons.school, 'color': Colors.indigo},
    {'name': 'Seyahat', 'icon': Icons.flight, 'color': Colors.teal},
    {'name': 'Eğlence', 'icon': Icons.celebration, 'color': Colors.pink},
  ];

  late AnimationController _animationController;
  late Animation<double> _animation;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  String? _selectedCategory;
  bool _isTask = true;
  DateTime? _reminderTime;
  Duration? _reminderDuration; // Used for the new reminder picker display

  String? _imagePath;
  String? _audioPath;
  Duration?
  _audioDuration; // This will store the duration of the recorded audio
  bool _isRecording = false;
  bool _isPlaying = false;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });

    if (_isEditing) {
      // Editing existing task - use the task's stored datetime (assumed to be in local time)
      _selectedDate = widget.taskToEdit!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.taskToEdit!.dateTime);

      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description;
      _isTask = widget.taskToEdit!.isTask;
      _selectedCategory = widget.taskToEdit!.category;

      if (widget.taskToEdit!.reminderTime != null) {
        _reminderTime = widget.taskToEdit!.reminderTime;
      } else {
        _reminderTime = null;
      }

      if (widget.taskToEdit!.imagePath != null) {
        _imagePath = widget.taskToEdit!.imagePath;
      }

      if (widget.taskToEdit!.audioPath != null) {
        _audioPath = widget.taskToEdit!.audioPath;
        _audioDuration = widget.taskToEdit!.audioDuration;
      }

      // If editing and reminderTime exists, calculate _reminderDuration for display
      if (_reminderTime != null) {
        final taskDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        if (_reminderTime!.isBefore(taskDateTime)) {
          _reminderDuration = taskDateTime.difference(_reminderTime!);
        }
      }
    } else {
      // New task: initialize with current date and time
      final now = DateTime.now();
      _selectedDate = now;
      _selectedTime = TimeOfDay.fromDateTime(now);
      _isTask = true; // Default to task
      // _reminderTime and _reminderDuration will be null by default for new tasks
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recordingTimer?.cancel();
    _animationController.dispose();
    if (_isPlaying) {
      MediaService.stopAudio();
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    // Clear previous recording if any
    if (_audioPath != null) {
      _deleteAudio(); // Optionally ask user for confirmation
    }

    final success = await MediaService.startRecording();

    if (success) {
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _audioDuration = null; // Reset audio duration display
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          // Check if widget is still mounted
          timer.cancel();
          return;
        }
        setState(() {
          _recordingSeconds++;
        });
      });
    } else {
      Get.snackbar(
        'Hata',
        'Ses kaydı başlatılamadı',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    final path = await MediaService.stopRecording();
    _recordingTimer?.cancel();

    if (path != null) {
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _isRecording = false;
        _audioPath = path;
        _audioDuration = Duration(seconds: _recordingSeconds);
      });
    } else {
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _isRecording = false;
      });
      Get.snackbar(
        'Uyarı',
        'Ses kaydı kaydedilemedi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _playAudio() async {
    if (_audioPath == null || _isPlaying) return;

    MediaService.setOnPlaybackCompleted(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    if (!mounted) return;
    setState(() {
      _isPlaying = true;
    });

    final success = await MediaService.playAudio(_audioPath!);

    if (!success) {
      MediaService.clearOnPlaybackCompleted();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
      return;
    }

    // Fallback timer removed as setOnPlaybackCompleted should be primary
    // If issues persist, it can be added back with careful mount checks.
  }

  Future<void> _stopAudio() async {
    if (!_isPlaying) return;

    MediaService.clearOnPlaybackCompleted();
    await MediaService.stopAudio();

    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _deleteAudio() {
    if (_audioPath != null) {
      MediaService.deleteFile(_audioPath!);
      if (_isPlaying) {
        _stopAudio(); // Use the updated _stopAudio which handles callbacks and state
      }
      if (mounted) {
        setState(() {
          _audioPath = null;
          _audioDuration = null;
          // _isPlaying should be false if _stopAudio was called
          _recordingSeconds = 0;
        });
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 600,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Fotoğraf seçilirken bir hata oluştu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            // MODIFIED: Removed BackdropFilter, Icon is now direct child
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        title: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.2, 0),
            end: Offset.zero,
          ).animate(_animation),
          child: FadeTransition(
            opacity: _animation,
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // Using Container instead of BackdropFilter to avoid Impeller renderer crashes
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(
                          0.7,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isTask
                            ? Icons.task_alt_rounded
                            : Icons.note_alt_outlined,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEditing
                          ? (_isTask ? 'Görevi Düzenle' : 'Notu Düzenle')
                          : 'Yeni Ekle',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.2,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.2, 0),
              end: Offset.zero,
            ).animate(_animation),
            child: FadeTransition(
              opacity: _animation,
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // Using Container instead of BackdropFilter to avoid Impeller renderer crashes
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _saveTask,
                    icon: const Icon(Icons.save_rounded),
                    tooltip: 'Kaydet',
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceVariant.withOpacity(0.5),
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 30, 20, 20),
            children: [
              // Task or Note toggle
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  // Using Container instead of BackdropFilter
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(
                      24,
                    ), // Match outer or adjust as needed
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.category_rounded,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Tür Seçimi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(
                              0.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SegmentedButton<bool>(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color?>((
                                    Set<MaterialState> states,
                                  ) {
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return theme.colorScheme.primaryContainer;
                                    }
                                    return Colors
                                        .transparent; // For unselected segments
                                  }),
                              foregroundColor: MaterialStateProperty.resolveWith<
                                Color?
                              >((Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return theme.colorScheme.onPrimaryContainer;
                                }
                                return theme
                                    .colorScheme
                                    .onSurfaceVariant; // For unselected segments
                              }),
                              side: MaterialStateProperty.all(BorderSide.none),
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 16,
                                ),
                              ),
                              shape: MaterialStateProperty.all<
                                RoundedRectangleBorder
                              >(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    18.0,
                                  ), // Consistent rounded corners for segments
                                ),
                              ),
                            ),
                            segments: [
                              ButtonSegment<bool>(
                                value: true,
                                label: Text(
                                  'Görev',
                                  style: TextStyle(
                                    fontWeight:
                                        _isTask
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                                icon: Icon(Icons.task_alt_rounded, size: 22),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                label: Text(
                                  'Not',
                                  style: TextStyle(
                                    fontWeight:
                                        !_isTask
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                                icon: Icon(Icons.note_rounded, size: 22),
                              ),
                            ],
                            selected: {_isTask},
                            onSelectionChanged: (Set<bool> selected) {
                              if (mounted)
                                setState(() {
                                  _isTask = selected.first;
                                });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Title and Description
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
                  ),
                ),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.1, 0.5, curve: Curves.easeIn),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      // Using Container instead of BackdropFilter
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(
                          0.95,
                        ), // Or match outer's 0.9
                        borderRadius: BorderRadius.circular(
                          24,
                        ), // Match outer or adjust
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.edit_note_rounded,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Detaylar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _titleController,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Başlık',
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                                hintText: 'Başlık girin',
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.title,
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.8,
                                  ),
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.8),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceVariant
                                    .withOpacity(0.2),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Başlık boş olamaz';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              minLines: 3,
                              maxLines: 5,
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Açıklama',
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                                hintText: 'Açıklama girin',
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 0),
                                  child: Icon(
                                    Icons.description,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.8),
                                    size: 20,
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.8),
                                    width: 2,
                                  ),
                                ),
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: theme.colorScheme.surfaceVariant
                                    .withOpacity(0.2),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Açıklama boş olamaz';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Visibility(
                visible: _isTask,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(
                        0.15,
                        0.65,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.15, 0.55, curve: Curves.easeIn),
                    ),
                    // MODIFIED: "Zamanlama" section
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        // Added color here to replace BackdropFilter's effect
                        color: theme.colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      // REMOVED BackdropFilter, Padding is now direct child
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer
                                        .withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.schedule_rounded,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Zamanlama',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showDatePicker,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant
                                            .withOpacity(0.2),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withOpacity(0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.calendar_today,
                                              color: theme.colorScheme.primary,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Tarih',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Builder(
                                                  builder: (context) {
                                                    final DateTime
                                                    combinedDateTime = DateTime(
                                                      _selectedDate.year,
                                                      _selectedDate.month,
                                                      _selectedDate.day,
                                                      _selectedTime.hour,
                                                      _selectedTime.minute,
                                                    );
                                                    return Text(
                                                      DateFormat(
                                                        'dd MMMM yyyy',
                                                        'tr_TR',
                                                      ).format(
                                                        combinedDateTime,
                                                      ),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            theme
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showTimePicker,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant
                                            .withOpacity(0.2),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withOpacity(0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.access_time_rounded,
                                              color: theme.colorScheme.primary,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Saat',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Builder(
                                                  builder: (context) {
                                                    final DateTime
                                                    combinedDateTime = DateTime(
                                                      _selectedDate.year,
                                                      _selectedDate.month,
                                                      _selectedDate.day,
                                                      _selectedTime.hour,
                                                      _selectedTime.minute,
                                                    );
                                                    return Text(
                                                      DateFormat(
                                                        'HH:mm',
                                                        'tr_TR',
                                                      ).format(
                                                        combinedDateTime,
                                                      ),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            theme
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => _showReminderDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant
                                      .withOpacity(0.2),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color:
                                            _reminderDuration != null
                                                ? theme.colorScheme.tertiary
                                                    .withOpacity(0.2)
                                                : theme.colorScheme.primary
                                                    .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.notifications_active_rounded,
                                        color:
                                            _reminderDuration != null
                                                ? theme.colorScheme.tertiary
                                                : theme.colorScheme.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hatırlatıcı',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Builder(
                                            builder: (context) {
                                              if (_reminderTime != null) {
                                                return Text(
                                                  DateFormat(
                                                    'dd MMMM yyyy, HH:mm',
                                                    'tr_TR',
                                                  ).format(_reminderTime!),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurface,
                                                  ),
                                                );
                                              } else {
                                                return Text(
                                                  'Hatırlatma ekle',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurface,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_reminderDuration != null)
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: theme.colorScheme.error,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          if (mounted)
                                            setState(() {
                                              _reminderDuration = null;
                                              _reminderTime = null;
                                            });
                                        },
                                        style: IconButton.styleFrom(
                                          padding: const EdgeInsets.all(4),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Modern Categories Section
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  // Using Container instead of BackdropFilter
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(
                      24,
                    ), // Match outer or adjust
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.category_rounded,
                                color: theme.colorScheme.onTertiaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Kategori',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          children:
                              _predefinedCategories.map((category) {
                                final isSelected =
                                    _selectedCategory == category['name'];
                                return GestureDetector(
                                  onTap: () {
                                    if (mounted)
                                      setState(() {
                                        _selectedCategory = category['name'];
                                      });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? (category['color'] as Color)
                                                  .withOpacity(0.15)
                                              : theme.colorScheme.surfaceVariant
                                                  .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? (category['color'] as Color)
                                                : theme.colorScheme.outline
                                                    .withOpacity(0.2),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: (category['color']
                                                          as Color)
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                              : [],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? (category['color']
                                                            as Color)
                                                        .withOpacity(0.2)
                                                    : theme.colorScheme.surface
                                                        .withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow:
                                                isSelected
                                                    ? [
                                                      BoxShadow(
                                                        color:
                                                            (category['color']
                                                                    as Color)
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                      ),
                                                    ]
                                                    : [],
                                          ),
                                          child: Icon(
                                            category['icon'] as IconData,
                                            color:
                                                isSelected
                                                    ? (category['color']
                                                        as Color)
                                                    : theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.7),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          category['name'] as String,
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? (category['color']
                                                        as Color)
                                                    : theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.9),
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: (category['color']
                                                      as Color)
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check_rounded,
                                              color:
                                                  (category['color'] as Color),
                                              size: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        // REMOVED ERRONEOUS COMMENTS that were here
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Get.snackbar(
                              'Bilgi',
                              'Yeni kategori ekleme özelliği yakında gelecek',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              colorText: theme.colorScheme.onPrimaryContainer,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.4),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(
                            Icons.add_circle_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          label: Text(
                            'Yeni Kategori Ekle',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Media Section (Photo)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  // Using Container instead of BackdropFilter
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(
                      24,
                    ), // Match outer or adjust
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fotoğraf',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              'Fotoğraf Ekle:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.photo_library),
                              tooltip: 'Galeriden Seç',
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                            IconButton(
                              icon: const Icon(Icons.camera_alt),
                              tooltip: 'Kamera ile Çek',
                              onPressed: () => _pickImage(ImageSource.camera),
                            ),
                            if (_imagePath != null)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Fotoğrafı Kaldır',
                                onPressed: () {
                                  if (mounted)
                                    setState(() {
                                      _imagePath = null;
                                    });
                                },
                              ),
                          ],
                        ),
                        if (_imagePath != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            // Placeholder for image preview
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              // If you want to display the image:
                              // image: DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover)
                            ),
                            child: Column(
                              // Fallback if not displaying actual image
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fotoğraf eklendi',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                Text(
                                  _imagePath!.split('/').last,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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

              // Audio Recording section
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(
                      0.25,
                      0.75,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.25, 0.65, curve: Curves.easeIn),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      // Using Container instead of BackdropFilter
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(
                          0.95,
                        ), // Or match outer's 0.9
                        borderRadius: BorderRadius.circular(
                          24,
                        ), // Match outer or adjust
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer
                                        .withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.mic_rounded,
                                    color: theme.colorScheme.onErrorContainer,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Sesli Not',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color:
                                    _audioPath != null
                                        ? theme.colorScheme.primaryContainer
                                            .withOpacity(0.3)
                                        : theme.colorScheme.surfaceVariant
                                            .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      _audioPath != null
                                          ? theme.colorScheme.primary
                                              .withOpacity(0.3)
                                          : theme.colorScheme.outline
                                              .withOpacity(0.2),
                                  width: _audioPath != null ? 1.5 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          _audioPath != null
                                              ? theme.colorScheme.primary
                                                  .withOpacity(0.1)
                                              : theme
                                                  .colorScheme
                                                  .surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _isRecording
                                          ? Icons.fiber_manual_record_rounded
                                          : (_audioPath != null
                                              ? Icons.audio_file_rounded
                                              : Icons.mic_none_rounded),
                                      color:
                                          _isRecording
                                              ? theme.colorScheme.error
                                              : (_audioPath != null
                                                  ? theme.colorScheme.primary
                                                  : theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withOpacity(0.7)),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isRecording
                                              ? 'Ses kaydediliyor...'
                                              : (_audioPath != null
                                                  ? 'Ses kaydı hazır'
                                                  : 'Ses kaydı yok'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _isRecording
                                                    ? theme.colorScheme.error
                                                    : (_audioPath != null
                                                        ? theme
                                                            .colorScheme
                                                            .primary
                                                        : theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.8)),
                                          ),
                                        ),
                                        if (_isRecording)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              _formatDuration(
                                                _recordingSeconds,
                                              ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                          )
                                        else if (_audioPath != null &&
                                            _audioDuration != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              _formatDuration(
                                                _audioDuration!.inSeconds,
                                              ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_audioPath != null &&
                                          !_isRecording &&
                                          !_isPlaying)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            onPressed: _playAudio,
                                            icon: const Icon(
                                              Icons.play_arrow_rounded,
                                            ),
                                            color: theme.colorScheme.primary,
                                            tooltip: 'Oynat',
                                            style: IconButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      if (_audioPath != null && _isPlaying)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.error
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            onPressed: _stopAudio,
                                            icon: const Icon(
                                              Icons.stop_rounded,
                                            ),
                                            color: theme.colorScheme.error,
                                            tooltip: 'Durdur',
                                            style: IconButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      if (_audioPath != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.error
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              onPressed: _deleteAudio,
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                              ),
                                              color: theme.colorScheme.error,
                                              tooltip: 'Sil',
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!_isRecording && _audioPath == null)
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _startRecording,
                                  icon: const Icon(Icons.mic_rounded),
                                  label: const Text('Kayda Başla'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              )
                            else if (_isRecording)
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _stopRecording,
                                  icon: const Icon(Icons.stop_rounded),
                                  label: const Text('Kaydı Durdur'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: theme.colorScheme.onError,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              )
                            else if (_audioPath != null && !_isRecording)
                              Center(
                                child: OutlinedButton.icon(
                                  onPressed: _startRecording,
                                  icon: const Icon(Icons.mic_rounded),
                                  label: const Text('Yeni Kayıt'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                    side: BorderSide(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Submit Button
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
                  ),
                ),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isEditing
                                ? Icons.update_rounded
                                : Icons.save_rounded,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isEditing ? 'Güncelle' : 'Kaydet',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      if (!mounted) return;
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _showReminderDialog(BuildContext context) async {
    final List<Map<String, dynamic>> reminderOptions = [
      {'label': 'Yok', 'duration': null},
      {'label': 'Zamanında', 'duration': const Duration(minutes: 0)},
      {'label': '5 dakika önce', 'duration': const Duration(minutes: 5)},
      {'label': '15 dakika önce', 'duration': const Duration(minutes: 15)},
      {'label': '30 dakika önce', 'duration': const Duration(minutes: 30)},
      {'label': '1 saat önce', 'duration': const Duration(hours: 1)},
      {'label': '1 gün önce', 'duration': const Duration(days: 1)},
    ];

    Duration? selectedDuration = _reminderDuration;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hatırlatıcı Ayarla'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reminderOptions.length,
                  itemBuilder: (context, index) {
                    final option = reminderOptions[index];
                    return RadioListTile<Duration?>(
                      title: Text(option['label'] as String),
                      value: option['duration'] as Duration?,
                      groupValue: selectedDuration,
                      onChanged: (Duration? value) {
                        // No need to check mounted here, as setStateDialog is local to dialog
                        setStateDialog(() {
                          selectedDuration = value;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Ayarla'),
              onPressed: () {
                if (mounted) {
                  // Check mounted before calling main screen's setState
                  setState(() {
                    _reminderDuration = selectedDuration;
                    if (_reminderDuration != null) {
                      final taskDateTime = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedTime.hour,
                        _selectedTime.minute,
                      );
                      _reminderTime = taskDateTime.subtract(_reminderDuration!);
                    } else {
                      _reminderTime = null;
                    }
                  });
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _showOldReminderPicker() async {
    // ... (Implementation remains the same, ensure context is valid if used)
  }

  void _saveTask() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    debugPrint('💾 Görev kaydediliyor...');

    // Create a DateTime object from user's selection
    final DateTime selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    debugPrint('📅 Seçilen görev zamanı: ${selectedDateTime.toString()}');
    debugPrint(
      '⏰ Hatırlatma süresi (_reminderDuration): ${_reminderDuration?.toString() ?? "null"}',
    );
    debugPrint('🔔 İsTask: $_isTask');

    DateTime? reminderTime;

    // Reminder time'ı kullan (zaten dialog'da hesaplanmış)
    if (_isTask && _reminderTime != null) {
      reminderTime = _reminderTime;
      debugPrint(
        '✅ Mevcut hatırlatma zamanı kullanılıyor: ${reminderTime.toString()}',
      );
    } else if (_isTask && _reminderDuration != null) {
      // Fallback: Duration'dan hesapla
      reminderTime = selectedDateTime.subtract(_reminderDuration!);
      debugPrint(
        '🔄 Hatırlatma zamanı duration\'dan hesaplandı: ${reminderTime.toString()}',
      );
      debugPrint(
        '   (Görev zamanından ${_reminderDuration!.inMinutes} dakika önce)',
      );
    } else {
      debugPrint('ℹ️ Hatırlatma zamanı yok:');
      debugPrint('   İsTask: $_isTask');
      debugPrint('   ReminderTime: ${_reminderTime?.toString() ?? "null"}');
      debugPrint(
        '   ReminderDuration: ${_reminderDuration?.toString() ?? "null"}',
      );
    }

    final task = TaskEntity(
      id: _isEditing ? widget.taskToEdit!.id : null,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dateTime: selectedDateTime,
      isDone: _isEditing ? widget.taskToEdit!.isDone : false,
      isTask: _isTask,
      category: _selectedCategory,
      imagePath: _imagePath,
      audioPath: _audioPath,
      audioDuration: _audioDuration,
      createdAt: _isEditing ? widget.taskToEdit!.createdAt : DateTime.now(),
      reminderTime: _isTask ? reminderTime : null,
    );

    debugPrint('📝 TaskEntity oluşturuldu:');
    debugPrint('   Başlık: ${task.title}');
    debugPrint('   İsTask: ${task.isTask}');
    debugPrint('   DateTime: ${task.dateTime.toString()}');
    debugPrint('   ReminderTime: ${task.reminderTime?.toString() ?? "null"}');

    bool success;
    BuildContext currentContext = context;
    if (_isEditing) {
      debugPrint('🔄 Görev güncelleniyor...');
      success = await _taskController.updateTask(task, context: currentContext);
    } else {
      debugPrint('➕ Yeni görev ekleniyor...');
      success = await _taskController.addTask(task, context: currentContext);
    }

    if (!mounted) return;

    if (success) {
      debugPrint('✅ Görev başarıyla kaydedildi');
      Get.back();
      Get.snackbar(
        'Başarılı',
        _isEditing
            ? (_isTask ? 'Görev güncellendi' : 'Not güncellendi')
            : (_isTask ? 'Görev eklendi' : 'Not eklendi'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      debugPrint('❌ Görev kaydedilemedi');
    }
  }
}
