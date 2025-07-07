import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaPickerWidget extends StatefulWidget {
  final String? imagePath;
  final String? audioPath;
  final Duration? audioDuration;
  final Function(String) onImageSelected;
  final Function(String, Duration?) onAudioSelected;
  final VoidCallback onImageRemoved;
  final VoidCallback onAudioRemoved;

  const MediaPickerWidget({
    super.key,
    this.imagePath,
    this.audioPath,
    this.audioDuration,
    required this.onImageSelected,
    required this.onAudioSelected,
    required this.onImageRemoved,
    required this.onAudioRemoved,
  });

  @override
  State<MediaPickerWidget> createState() => _MediaPickerWidgetState();
}

class _MediaPickerWidgetState extends State<MediaPickerWidget> {
  final ImagePicker _picker = ImagePicker();
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedAudioPath;
  Duration? _currentAudioDuration;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initRecorder();
    if (widget.audioPath != null) {
      _recordedAudioPath = widget.audioPath;
    }
  }

  Future<void> _initRecorder() async {
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorder = null;
    _player?.closePlayer();
    _player = null;
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      widget.onImageSelected(pickedFile.path);
    }
  }

  Future<void> _startRecording() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mikrofon izni gerekli')));
      return;
    }

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String path =
          '${tempDir.path}/flutter_sound-${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
      setState(() {
        _isRecording = true;
        _recordedAudioPath = null; // Clear previous recording if any
        widget.onAudioRemoved(); // Notify parent about removal of old audio
      });
    } catch (e) {
      print('Kayıt başlatılamadı: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayıt başlatılamadı: $e')));
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder!.stopRecorder();
      if (path != null) {
        final duration = await _getAudioDuration(path);
        setState(() {
          _isRecording = false;
          _recordedAudioPath = path;
          _currentAudioDuration = duration;
        });
        widget.onAudioSelected(path, duration);
      }
    } catch (e) {
      print('Kayıt durdurulamadı: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kayıt durdurulamadı: $e')));
    }
  }

  Future<Duration?> _getAudioDuration(String path) async {
    try {
      final player = AudioPlayer();
      final duration = await player.setFilePath(path);
      await player.dispose();
      return duration;
    } catch (e) {
      print('Ses dosyası süresi alınamadı: $e');
      return null;
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _playAudio() async {
    if (_recordedAudioPath != null &&
        await File(_recordedAudioPath!).exists()) {
      if (_isPlaying) {
        await _player!.stopPlayer();
        setState(() => _isPlaying = false);
      } else {
        await _player!.startPlayer(
          fromURI: _recordedAudioPath!,
          whenFinished: () {
            setState(() => _isPlaying = false);
          },
        );
        setState(() => _isPlaying = true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oynatılacak ses dosyası bulunamadı.')),
      );
    }
  }

  void _removeAudio() {
    if (_isPlaying) {
      _player?.stopPlayer();
      _isPlaying = false;
    }
    setState(() {
      _recordedAudioPath = null;
    });
    widget.onAudioRemoved();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Görsel Ekle'),
        const SizedBox(height: 8),
        _buildImagePicker(),
        const SizedBox(height: 24),
        _buildSectionTitle('Ses Kaydı Ekle'),
        const SizedBox(height: 8),
        _buildAudioRecorder(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.image_outlined),
            label: const Text('Galeriden Seç'),
            onPressed: () => _pickImage(ImageSource.gallery),
            style: _buttonStyle(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Kameradan Çek'),
            onPressed: () => _pickImage(ImageSource.camera),
            style: _buttonStyle(),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioRecorder() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(
                  _isRecording
                      ? Icons.stop_circle_outlined
                      : Icons.mic_none_outlined,
                ),
                label: Text(_isRecording ? 'Durdur' : 'Kayıt Başlat'),
                onPressed: _isRecording ? _stopRecording : _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isRecording
                          ? Colors.redAccent
                          : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_recordedAudioPath != null || widget.audioPath != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.audiotrack_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Row(
                  children: [
                    Text(
                      'Ses Kaydı',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    if (_currentAudioDuration != null ||
                        widget.audioDuration != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDuration(
                            _currentAudioDuration ?? widget.audioDuration,
                          ),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFFF6B35),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  _getFileName(widget.audioPath ?? _recordedAudioPath),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled_outlined
                            : Icons.play_circle_filled_outlined,
                      ),
                      onPressed: _playAudio,
                      tooltip: _isPlaying ? 'Duraklat' : 'Oynat',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _removeAudio,
                      tooltip: 'Sesi Sil',
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (widget.imagePath != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seçilen Görsel:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(widget.imagePath!),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.white70),
                      onPressed: widget.onImageRemoved,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getFileName(String? path) {
    if (path == null) return 'Mevcut değil';
    return path.split('/').last;
  }

  ButtonStyle _buttonStyle() {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
