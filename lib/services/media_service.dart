import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaService {
  static final ImagePicker _imagePicker = ImagePicker();
  static FlutterSoundRecorder? _recorder;
  static FlutterSoundPlayer? _player;
  static VoidCallback? _onPlaybackCompleted;

  // Singleton pattern
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  // İzinleri kontrol et ve iste
  static Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ];

    // Tüm izinleri kontrol et
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    // Tüm izinlerin verilip verilmediğini kontrol et
    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    return allGranted;
  }

  // İzinleri kontrol et
  static Future<bool> checkPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ];

    // Tüm izinleri kontrol et
    bool allGranted = true;
    for (var permission in permissions) {
      if (!await permission.isGranted) {
        allGranted = false;
        break;
      }
    }

    return allGranted;
  }

  static bool _permissionsGranted = false;

  static bool get hasPermissions => _permissionsGranted;

  // Servisi başlat
  static Future<void> init() async {
    try {
      // İzinleri iste
      _permissionsGranted = await _requestPermissions();
      
      if (!_permissionsGranted) {
        debugPrint('Uyarı: Bazı izinler verilmedi. Medya özellikleri sınırlı olabilir.');
      }

      // İzinler verilmemiş olsa bile servisi başlat
      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();

      await _recorder!.openRecorder();
      await _player!.openPlayer();
    } catch (e) {
      debugPrint('MediaService başlatılırken hata: $e');
      // Hata durumunda servisi başlatma ama uygulamanın çalışmasına izin ver
      _permissionsGranted = false;
    }
  }

  // Servisi kapat
  static Future<void> dispose() async {
    await _recorder?.closeRecorder();
    await _player?.closePlayer();
  }

  // GÖRSEL İŞLEMLERİ

  // Kameradan fotoğraf çek
  static Future<String?> takePhoto() async {
    try {
      // Kamera izni kontrol et
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          throw Exception('Kamera izni gerekli');
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImageToAppDirectory(image);
      }
      return null;
    } catch (e) {
      debugPrint('Fotoğraf çekme hatası: $e');
      return null;
    }
  }

  // Galeriden fotoğraf seç
  static Future<String?> pickImageFromGallery() async {
    try {
      // Galeri izni kontrol et
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isDenied) {
        final result = await Permission.storage.request();
        if (result.isDenied) {
          throw Exception('Depolama izni gerekli');
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImageToAppDirectory(image);
      }
      return null;
    } catch (e) {
      debugPrint('Galeri seçme hatası: $e');
      return null;
    }
  }

  // Görsel seçim dialog'u göster
  static Future<String?> showImagePickerDialog(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Fotoğraf Seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    context,
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () async {
                      Navigator.pop(context);
                      final imagePath = await takePhoto();
                      Navigator.pop(context, imagePath);
                    },
                  ),
                  _buildImagePickerOption(
                    context,
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () async {
                      Navigator.pop(context);
                      final imagePath = await pickImageFromGallery();
                      Navigator.pop(context, imagePath);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildImagePickerOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Görseli uygulama dizinine kaydet
  static Future<String> _saveImageToAppDirectory(XFile image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/images');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = File('${imagesDir.path}/$fileName');

    await savedImage.writeAsBytes(await image.readAsBytes());
    return savedImage.path;
  }

  // SES İŞLEMLERİ

  // Ses kaydı başlat
  static Future<bool> startRecording() async {
    try {
      // Mikrofon izni kontrol et
      final micStatus = await Permission.microphone.status;
      if (micStatus.isDenied) {
        final result = await Permission.microphone.request();
        if (result.isDenied) {
          throw Exception('Mikrofon izni gerekli');
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/audio');

      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.aac';
      final audioPath = '${audioDir.path}/$fileName';

      await _recorder!.startRecorder(toFile: audioPath, codec: Codec.aacADTS);

      return true;
    } catch (e) {
      debugPrint('Ses kaydı başlatma hatası: $e');
      return false;
    }
  }

  // Ses kaydı durdur
  static Future<String?> stopRecording() async {
    try {
      final path = await _recorder!.stopRecorder();
      return path;
    } catch (e) {
      debugPrint('Ses kaydı durdurma hatası: $e');
      return null;
    }
  }

  // Ses çal
  static Future<bool> playAudio(String audioPath) async {
    try {
      if (!File(audioPath).existsSync()) {
        debugPrint('Ses dosyası bulunamadı: $audioPath');
        return false;
      }
      
      // Add a function subscription for player state changes
      _player!.setSubscriptionDuration(const Duration(milliseconds: 100));
      
      // Start playing the audio
      await _player!.startPlayer(
        fromURI: audioPath, 
        codec: Codec.aacADTS,
        whenFinished: () {
          // This callback will be called when audio playback completes
          debugPrint('Audio playback completed');
          if (_onPlaybackCompleted != null) {
            _onPlaybackCompleted!();
          }
        }
      );

      return true;
    } catch (e) {
      debugPrint('Ses çalma hatası: $e');
      return false;
    }
  }

  // Ses durdur
  static Future<void> stopAudio() async {
    try {
      await _player!.stopPlayer();
    } catch (e) {
      debugPrint('Ses durdurma hatası: $e');
    }
  }

  // Ses çalıyor mu kontrol et
  static bool get isPlaying => _player?.isPlaying ?? false;

  // Ses kaydediyor mu kontrol et
  static bool get isRecording => _recorder?.isRecording ?? false;
  
  // Player nesnesine erişim sağla
  static FlutterSoundPlayer? get player => _player;
  
  // Set a callback to be called when audio playback completes
  static void setOnPlaybackCompleted(VoidCallback callback) {
    _onPlaybackCompleted = callback;
  }
  
  // Clear the playback completion callback
  static void clearOnPlaybackCompleted() {
    _onPlaybackCompleted = null;
  }

  // DOSYA İŞLEMLERİ

  // Dosya sil
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Dosya silme hatası: $e');
      return false;
    }
  }

  // Dosya var mı kontrol et
  static Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  // Dosya boyutunu al
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Tüm medya dosyalarını temizle
  static Future<void> clearAllMediaFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Görsel dosyalarını temizle
      final imagesDir = Directory('${appDir.path}/images');
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }

      // Ses dosyalarını temizle
      final audioDir = Directory('${appDir.path}/audio');
      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Medya dosyaları temizleme hatası: $e');
    }
  }

  // Medya dosyalarının toplam boyutunu al
  static Future<int> getTotalMediaSize() async {
    try {
      int totalSize = 0;
      final appDir = await getApplicationDocumentsDirectory();

      // Görsel dosyaları
      final imagesDir = Directory('${appDir.path}/images');
      if (await imagesDir.exists()) {
        await for (final file in imagesDir.list(recursive: true)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      // Ses dosyaları
      final audioDir = Directory('${appDir.path}/audio');
      if (await audioDir.exists()) {
        await for (final file in audioDir.list(recursive: true)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Medya boyutu hesaplama hatası: $e');
      return 0;
    }
  }

  // Boyutu okunabilir formata çevir
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
