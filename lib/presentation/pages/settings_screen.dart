import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../controllers/task_controller.dart';
import '../controllers/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeController _themeController = Get.find<ThemeController>();
  final TaskController _taskController = Get.find<TaskController>();
  
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Not Uygulaması',
    packageName: 'unknown',
    version: 'unknown',
    buildNumber: 'unknown',
    buildSignature: 'unknown',
  );
  
  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }
  
  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          // Theme settings
          _buildSection(
            title: 'Görünüm',
            icon: Icons.palette_rounded,
            children: [
              Obx(() => SwitchListTile(
                title: const Text('Karanlık Tema'),
                subtitle: const Text('Uygulamayı karanlık temada kullan'),
                value: _themeController.isDarkMode,
                onChanged: (value) {
                  if (value) {
                    _themeController.setDarkTheme();
                  } else {
                    _themeController.setLightTheme();
                  }
                },
                secondary: Icon(
                  _themeController.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
              )),
            ],
          ),
          
          // Notification settings
          _buildSection(
            title: 'Bildirimler',
            icon: Icons.notifications_rounded,
            children: [
              ListTile(
                title: const Text('Bildirim İzinleri'),
                subtitle: const Text('Görevler için bildirim izinlerini yönet'),
                leading: const Icon(Icons.notifications_active_rounded),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  // Navigate to system notification settings
                  // TODO: Implement navigation to system notification settings
                },
              ),
            ],
          ),
          
          // Data management
          _buildSection(
            title: 'Veri Yönetimi',
            icon: Icons.storage_rounded,
            children: [
              ListTile(
                title: const Text('Tüm Verileri Temizle'),
                subtitle: const Text('Tüm görev ve notları sil'),
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                onTap: () => _showDeleteConfirmationDialog(),
              ),
            ],
          ),
          
          // About
          _buildSection(
            title: 'Hakkında',
            icon: Icons.info_rounded,
            children: [
              ListTile(
                title: const Text('Uygulama Sürümü'),
                subtitle: Text('${_packageInfo.version} (${_packageInfo.buildNumber})'),
                leading: const Icon(Icons.android_rounded),
              ),
              const ListTile(
                title: Text('Geliştiriciler'),
                subtitle: Text('umut can Kurban'),
                leading: Icon(Icons.code_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
  
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tüm Verileri Sil'),
          content: const SingleChildScrollView(
            child: Text(
              'Tüm görevler ve notlar kalıcı olarak silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Sil',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                // Clear all tasks
                final result = await _taskController.clearAllTasks();
                if (result) {
                  Get.snackbar(
                    'Başarılı',
                    'Tüm veriler silindi',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Hata',
                    'Veriler silinirken bir hata oluştu',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
