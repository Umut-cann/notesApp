# 📝 Notes App - Akıllı Görev ve Not Yöneticisi

Modern, güvenilir ve kullanıcı dostu Flutter tabanlı görev ve not yönetim uygulaması. Gelişmiş bildirim sistemi ve sezgisel arayüzü ile günlük görevlerinizi ve notlarınızı kolayca organize edin.

## 🚀 Özellikler

### 📋 Gelişmiş Görev Yönetimi
- ✅ Görev oluşturma, düzenleme ve silme
- ⏰ Zamanlanmış görevler ve hassas hatırlatıcılar
- 📅 Esnek tarih ve saat belirleme
- 🔔 **Güvenilir bildirim sistemi** (32-bit ID optimizasyonu ile)
- ✨ Görev tamamlama durumu takibi
- 🏷️ Kategori bazlı görev organizasyonu
- ⚡ Anlık ve zamanlanmış bildirimler
- 🎯 Gecikmiş görev takibi

### 📝 Kapsamlı Not Yönetimi
- 📄 Hızlı not oluşturma ve düzenleme
- 🖼️ Fotoğraf ekleme desteği
- 🎤 Ses kaydı ekleme ve oynatma
- 🔍 Gelişmiş arama ve filtreleme
- 🗂️ Kategori bazlı not organizasyonu
- 📱 Responsive not görüntüleme

### 🎨 Modern Kullanıcı Arayüzü
- 🌙 Dinamik koyu/açık tema desteği
- 📱 Tam responsive tasarım
- ✨ Animasyonlu ve sezgisel arayüz
- 🎯 Minimalist ve temiz tasarım
- 📊 Detaylı istatistik dashboard'u
- 🔄 Gerçek zamanlı veri güncellemeleri

### 🔧 Güçlü Teknik Özellikler
- 📱 Android ve iOS tam desteği
- 💾 Hızlı yerel veri saklama (Hive NoSQL)
- 🔔 **Gelişmiş bildirim sistemi** (Türkiye saat dilimi optimizasyonu)
- 🌍 Türkçe yerelleştirme ve tarih formatları
- 🏗️ Clean Architecture mimarisi
- 🧪 Kapsamlı test coverage
- ⚡ Performans optimizasyonları
- 🔒 Güvenli veri yönetimi

## 📱 Ekran Görüntüleri

| Ana Sayfa | Görev Ekleme | Ayarlar |
|-----------|--------------|---------|
| ![Ana Sayfa](screenshots/home.png) | ![Görev Ekleme](screenshots/add_task.png) | ![Ayarlar](screenshots/settings.png) |

## 🛠️ Teknolojiler

### Framework ve Dil
- **Flutter** 3.7.2+
- **Dart** 3.7.2+

### State Management
- **GetX** - Reactive state management

### Veritabanı
- **Hive** - NoSQL yerel veritabanı
- **Hive Flutter** - Flutter entegrasyonu

### Bildirimler ve Zaman Yönetimi
- **Flutter Local Notifications** - Yerel bildirimler
- **Timezone** - Türkiye saat dilimi optimizasyonu (Europe/Istanbul)
- **Permission Handler** - Akıllı izin yönetimi
- **Exact Alarm Permission** - Android 12+ için hassas bildirimler

### Medya
- **Image Picker** - Fotoğraf seçimi
- **Flutter Sound** - Ses kaydı
- **Just Audio** - Ses oynatma
- **Record** - Ses kaydı
- **Audioplayers** - Ses oynatma

### UI/UX
- **Intl** - Uluslararasılaştırma
- **Flutter Slidable** - Kaydırılabilir liste öğeleri
- **Table Calendar** - Takvim widget'ı

### Dosya İşlemleri
- **Path Provider** - Dosya yolu yönetimi
- **File Picker** - Dosya seçimi

## 🏗️ Mimari

Bu proje **Clean Architecture** prensiplerini takip eder ve katmanlı mimari yaklaşımı benimser:

```
lib/
├── core/                    # Çekirdek modüller
│   ├── constants/          # Uygulama sabitleri
│   ├── di/                 # Dependency injection
│   ├── errors/             # Hata yönetimi
│   └── utils/              # Yardımcı sınıflar
├── data/                    # Veri katmanı
│   ├── datasources/        # Veri kaynakları (local/remote)
│   ├── models/             # Veri modelleri
│   └── repositories/       # Repository implementasyonları
├── domain/                  # İş mantığı katmanı
│   ├── entities/           # Domain varlıkları
│   ├── repositories/       # Repository arayüzleri
│   └── usecases/           # İş mantığı use case'leri
├── presentation/            # Sunum katmanı
│   ├── controllers/        # GetX state management
│   ├── pages/              # UI sayfaları
│   └── widgets/            # Yeniden kullanılabilir widget'lar
├── services/                # Servisler
│   ├── database_service.dart    # Hive veritabanı servisi
│   ├── notification_service.dart # Bildirim servisi
│   └── media_service.dart       # Medya yönetim servisi
├── utils/                   # Yardımcı araçlar
│   ├── notification_test_utils.dart # Bildirim test araçları
│   └── permission_utils.dart        # İzin yönetimi
└── main.dart                # Uygulama giriş noktası
```

### 🎯 Önemli Servisler

#### NotificationService
- Türkiye saat dilimi (Europe/Istanbul) optimizasyonu
- 32-bit güvenli bildirim ID yönetimi
- Hatırlatma ve görev süresi dolum bildirimleri
- Test ve debug yardımcıları

#### DatabaseService  
- Hive NoSQL yerel veritabanı
- Otomatik veri saklama ve geri yükleme
- Kategori ve tarih bazlı filtreleme

#### MediaService
- Ses kaydı ve oynatma
- Fotoğraf çekme ve galeri seçimi
- Dosya yönetimi optimizasyonu

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK 3.7.2 veya üzeri
- Dart SDK 3.7.2 veya üzeri
- Android Studio veya VS Code
- Android SDK (Android için)
- Xcode (iOS için)

### Adımlar

1. **Repository'yi klonlayın:**
```bash
git clone https://github.com/kullaniciadi/notes_app.git
cd notes_app
```

2. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

3. **Hive adaptörlerini oluşturun:**
```bash
flutter packages pub run build_runner build
```

4. **Uygulamayı çalıştırın:**
```bash
flutter run
```

## 📋 Kurulum Sonrası

### Android için ek yapılandırma

1. **Minimum SDK versiyonu:** `android/app/build.gradle` dosyasında `minSdkVersion 21` olarak ayarlayın

2. **İzinler:** `android/app/src/main/AndroidManifest.xml` dosyasına aşağıdaki izinleri ekleyin:
```xml
<!-- Temel izinler -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />

<!-- Bildirim izinleri (Android 12+ için kritik) -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- Android 13+ bildirim izni -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

3. **Bildirim kanalları:** Uygulama otomatik olarak gerekli bildirim kanallarını oluşturur.

### iOS için ek yapılandırma

1. **Info.plist:** `ios/Runner/Info.plist` dosyasına aşağıdaki izinleri ekleyin:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Bu uygulama ses kaydı için mikrofon erişimi gerektirir.</string>
<key>NSCameraUsageDescription</key>
<string>Bu uygulama fotoğraf çekme için kamera erişimi gerektirir.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Bu uygulama fotoğraf seçme için galeri erişimi gerektirir.</string>
```

## 🧪 Test

### Unit testleri çalıştırma:
```bash
flutter test
```

### Widget testleri çalıştırma:
```bash
flutter test test/widget_test.dart
```

### Integration testleri çalıştırma:
```bash
flutter drive --target=test_driver/app.dart
```

## 📝 Kullanım

### Görev Oluşturma
1. Ana sayfada '+' butonuna tıklayın
2. "Görev" sekmesini seçin
3. Başlık ve açıklama girin
4. Tarih ve saat belirleyin
5. İsteğe bağlı olarak hatırlatıcı ayarlayın
6. Kategori seçin
7. Kaydet butonuna tıklayın

### Not Oluşturma
1. Ana sayfada '+' butonuna tıklayın
2. "Not" sekmesini seçin
3. Başlık ve içerik girin
4. İsteğe bağlı olarak fotoğraf veya ses kaydı ekleyin
5. Kaydet butonuna tıklayın

### Hatırlatıcı Ayarlama
- Görev oluştururken "Hatırlatıcı" bölümünden zamanı seçin
- Mevcut seçenekler: 5 dk, 15 dk, 30 dk, 1 saat, 1 gün önce

## 🔧 Yapılandırma

### Bildirim Ayarları
Uygulamanın bildirim gönderebilmesi için cihaz ayarlarından bildirim izni verilmelidir.

### Tema Ayarları
Uygulama otomatik olarak sistem temasını takip eder. Manuel olarak değiştirmek için sağ üst köşedeki tema butonunu kullanın.

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Değişikliklerinizi commit edin (`git commit -am 'Yeni özellik eklendi'`)
4. Branch'inizi push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 📞 İletişim

- **Geliştirici:** [Adınız Soyadınız]
- **E-posta:** your.email@example.com
- **GitHub:** [github.com/kullaniciadi](https://github.com/kullaniciadi)

## 📚 Daha Fazla Bilgi

### Flutter Kaynakları
- [Flutter Dokümantasyonu](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Dart Dili](https://dart.dev/)

### Kullanılan Paketler
- [GetX](https://pub.dev/packages/get)
- [Hive](https://pub.dev/packages/hive)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

## 🔄 Güncellemeler

### v1.0.0 (Mevcut)
- ✅ Temel görev ve not yönetimi
- ✅ Bildirim sistemi
- ✅ Tema desteği
- ✅ Medya ekleme desteği
- ✅ Kategori sistemi

### Gelecek Güncellemeler
- 🔄 Bulut senkronizasyonu
- 🔄 Çoklu dil desteği
- 🔄 Widget desteği
- 🔄 İleri düzey filtreleme
- 🔄 Veri dışa aktarma

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!
