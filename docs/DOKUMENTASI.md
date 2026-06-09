# Dokumentasi Pemula Smart Building App

Dokumen ini menjelaskan isi proyek berdasarkan kode yang benar-benar ada pada
workspace tanggal **9 Juni 2026**. Anggap aplikasi ini seperti panel kontrol
sekolah: Firebase menjadi satpam yang memeriksa identitas pengguna, InfluxDB
menjadi buku catatan sekaligus kotak perintah, dan Flutter menjadi layar panel
yang dilihat serta disentuh pengguna.

## 1. Ringkasan Sangat Sederhana

Aplikasi ini dipakai untuk:

- Login menggunakan email dan password Firebase.
- Membaca daftar ruang kelas dari InfluxDB.
- Melihat status ruang, sensor, peringatan, dan kelas aktif.
- Mengubah status LED, proyektor, serta AC dengan menulis data ke InfluxDB.
- Membaca dan mengubah jadwal mingguan setiap kelas.
- Mengganti URL dan token InfluxDB selama aplikasi sedang berjalan.

Hal yang sangat penting:

- **Proyek versi sekarang tidak menggunakan MQTT.**
- Komunikasi status dan kontrol perangkat memakai **HTTP API InfluxDB 2.x**.
- Firebase hanya dipakai untuk autentikasi pengguna.
- Tombol kontrol lampu seluruh kampus di Home masih **dummy**: tombol hanya
  mengubah tampilan lokal dan menampilkan pesan, tidak mengirim perintah.
- Konfigurasi Firebase saat ini hanya tersedia untuk **Android**.
- URL dan token InfluxDB bawaan ditulis langsung di source code. Ini praktis
  untuk pengembangan, tetapi tidak aman untuk aplikasi produksi.

## 2. Gambaran Arsitektur

```text
Pengguna
  |
  | mengetik email dan password
  v
AuthScreen
  |
  | memanggil signIn()
  v
AuthService -----------------------> Firebase Authentication
  |
  | memberitahu AuthGate bahwa login berhasil
  v
AppShell
  |
  +----> HomeScreen
  +----> ScheduleScreen
  +----> DevicesScreen
  +----> SettingsScreen
              |
              v
        InfluxDbService ------------> InfluxDB HTTP API
```

Tidak ada state-management package seperti Riverpod, Provider, atau Bloc.
State disimpan langsung di dalam `StatefulWidget` memakai `setState()`.
Analogi sederhananya: setiap layar membawa buku catatan kecilnya sendiri.

## 3. Struktur Proyek Lengkap

Workspace berisi lebih dari 2.000 file jika cache seperti `build/`,
`.dart_tool/`, `.git/`, dan `.gradle/` ikut dihitung. File cache dibuat otomatis
oleh Flutter, Dart, Gradle, atau Git dan bukan source code aplikasi. Daftar di
bawah mencakup semua folder penting dan semua file proyek non-cache.

### 3.1 Folder dan file root

| Path | Fungsi |
|---|---|
| `.dart_tool/` | Cache dan metadata yang dibuat Dart/Flutter otomatis. |
| `.git/` | Riwayat versi Git; tidak ikut menjalankan aplikasi. |
| `.idea/` | Pengaturan IDE Android Studio/IntelliJ. |
| `build/` | Hasil kompilasi sementara; boleh dibuat ulang oleh Flutter. |
| `android/` | Pembungkus native agar aplikasi dapat berjalan sebagai aplikasi Android. |
| `docs/` | FSD, changelog, catatan agen, dan dokumentasi lama proyek. |
| `ios/` | Pembungkus native iOS yang masih sangat minimal/generated. |
| `lib/` | Source code Dart utama aplikasi. Ini folder paling penting untuk dipelajari. |
| `macos/` | Pembungkus native macOS yang masih minimal/generated. |
| `test/` | Automated test Flutter. |
| `web/` | File pembungkus untuk menjalankan Flutter di browser. |
| `windows/` | Pembungkus native untuk menjalankan Flutter di Windows. |
| `.flutter-plugins-dependencies` | Daftar plugin native yang dibuat Flutter otomatis. |
| `.gitignore` | Daftar file yang tidak boleh dimasukkan ke Git. |
| `.metadata` | Metadata versi dan migrasi proyek Flutter. |
| `analysis_options.yaml` | Aturan pemeriksaan kualitas/lint Dart. |
| `devtools_options.yaml` | Pengaturan Flutter DevTools. |
| `firebase.json` | Menunjukkan konfigurasi FlutterFire untuk proyek Firebase Android. |
| `firebase-debug.log` | Log debug Firebase CLI; bukan bagian logika aplikasi. |
| `pubspec.yaml` | Identitas proyek dan daftar package yang diminta aplikasi. |
| `pubspec.lock` | Versi package yang benar-benar dipilih saat `flutter pub get`. |
| `README.md` | Ringkasan proyek dan petunjuk menjalankan aplikasi. |
| `smart_building_app.iml` | Metadata module untuk IDE. |
| `DOKUMENTASI.md` | Dokumen penjelasan yang sedang dibaca ini. |

### 3.2 Folder `lib/`: source code utama

```text
lib/
|-- main.dart
|-- app.dart
|-- firebase_options.dart
|-- models/
|   |-- class_room_config.dart
|   `-- influx_room_data.dart
|-- screens/
|   |-- auth_screen.dart
|   |-- home_screen.dart
|   |-- schedule_screen.dart
|   |-- devices_screen.dart
|   `-- settings_screen.dart
|-- services/
|   |-- auth_service.dart
|   `-- influxdb_service.dart
|-- theme/
|   |-- app_colors.dart
|   |-- app_text_styles.dart
|   `-- app_theme.dart
|-- utils/
`-- widgets/
    |-- app_badge.dart
    |-- app_button.dart
    `-- app_card.dart
```

| File/folder | Fungsi satu baris |
|---|---|
| `lib/main.dart` | Pintu masuk pertama yang menyalakan aplikasi Flutter. |
| `lib/app.dart` | Akar aplikasi, gerbang login, navigasi tab, dan pemilik service bersama. |
| `lib/firebase_options.dart` | Konfigurasi Firebase Android hasil FlutterFire CLI. |
| `lib/models/` | Bentuk data yang dipakai aplikasi. |
| `lib/models/class_room_config.dart` | Menyimpan identitas dan nama tampilan sebuah kelas. |
| `lib/models/influx_room_data.dart` | Mengubah nilai mentah InfluxDB menjadi data ruang yang mudah dipakai UI. |
| `lib/screens/` | Kumpulan halaman yang dilihat pengguna. |
| `lib/screens/auth_screen.dart` | Form login email dan password. |
| `lib/screens/home_screen.dart` | Dashboard ringkasan seluruh kampus. |
| `lib/screens/schedule_screen.dart` | Pembaca dan editor jadwal mingguan kelas. |
| `lib/screens/devices_screen.dart` | Daftar kelas, detail sensor, dan kontrol perangkat. |
| `lib/screens/settings_screen.dart` | Form pengaturan server InfluxDB dan tombol logout. |
| `lib/services/` | Kode yang berbicara dengan layanan luar. |
| `lib/services/auth_service.dart` | Penghubung aplikasi dengan Firebase Authentication. |
| `lib/services/influxdb_service.dart` | Penghubung aplikasi dengan HTTP API InfluxDB. |
| `lib/theme/` | Aturan warna, font, dan tampilan global. |
| `lib/theme/app_colors.dart` | Daftar warna bernama agar seluruh UI konsisten. |
| `lib/theme/app_text_styles.dart` | Daftar ukuran dan ketebalan teks. |
| `lib/theme/app_theme.dart` | Menggabungkan warna dan teks menjadi `ThemeData`. |
| `lib/utils/` | Folder kosong yang disiapkan untuk helper umum. |
| `lib/widgets/` | Komponen UI kecil yang dapat dipakai ulang. |
| `lib/widgets/app_badge.dart` | Label status kecil seperti online, warning, dan error. |
| `lib/widgets/app_button.dart` | Tombol, input, dropdown, switch pengaturan, loading, dan toast bersama. |
| `lib/widgets/app_card.dart` | Kotak kartu putih dengan padding dan border konsisten. |

### 3.3 Folder `test/`

| File | Fungsi |
|---|---|
| `test/widget_test.dart` | Smoke test yang memastikan halaman Sign In tampil dan Sign Up tidak ada. |

### 3.4 Folder `docs/`

| File/folder | Fungsi |
|---|---|
| `docs/smart_building_app_fsd_v_2_FIXED_schedule.md` | Functional Specification Document atau aturan perilaku aplikasi. |
| `docs/presentation_widget.md` | Materi lama untuk menjelaskan widget saat presentasi. |
| `docs/CHANGELOG_v2.1.0.md` | Catatan perubahan versi 2.1.0. |
| `docs/CHANGELOG_v2.1.1.md` | Catatan perubahan versi 2.1.1. |
| `docs/CHANGELOG_v2.2.0.md` | Catatan penghapusan Sign Up dan perubahan versi 2.2.0. |
| `docs/CHANGELOG_v2.3.0.md` | Catatan integrasi langsung InfluxDB dan penghapusan MQTT lama. |
| `docs/CHANGELOG_v2.4.0.md` | Catatan penyederhanaan source code. |
| `docs/agent docs/agent_definitions.md` | Definisi tugas agen dokumentasi/diagnostik. |
| `docs/agent docs/orchestrator_rules.md` | Aturan koordinasi agen. |
| `docs/agent docs/project_context_briefing.md` | Ringkasan konteks proyek untuk agen. |
| `docs/agent docs/sync_agent_database_sync_results.md` | Hasil pemeriksaan sinkronisasi database. |
| `docs/agent docs/sync_agent_diag_briefing.md` | Instruksi pemeriksaan diagnostik. |
| `docs/agent docs/sync_agent_diag_results.md` | Hasil pemeriksaan diagnostik. |
| `docs/agent docs/sync_agent_log_briefing.md` | Instruksi pemeriksaan log. |
| `docs/agent docs/sync_agent_log_results.md` | Hasil pemeriksaan log. |
| `docs/agent docs/sync_agent_org_log_briefing.md` | Instruksi pemeriksaan organisasi InfluxDB. |
| `docs/agent docs/sync_agent_org_log_results.md` | Hasil pemeriksaan organisasi InfluxDB. |
| `docs/agent docs/sync_agent_query_org_briefing.md` | Instruksi query organisasi InfluxDB. |
| `docs/agent docs/sync_agent_query_org_results.md` | Hasil query organisasi InfluxDB. |
| `docs/agent docs/sync_agent_restore_briefing.md` | Instruksi pemulihan konfigurasi. |
| `docs/agent docs/sync_agent_restore_results.md` | Hasil pemulihan konfigurasi. |
| `docs/agent docs/sync_agent_task_briefing.md` | Ringkasan tugas sinkronisasi agen. |

### 3.5 Folder Android

| File/folder | Fungsi |
|---|---|
| `android/app/build.gradle.kts` | Konfigurasi build aplikasi Android dan plugin Google Services. |
| `android/app/google-services.json` | Identitas proyek Firebase untuk Android. |
| `android/app/src/main/AndroidManifest.xml` | Meminta izin internet, mendefinisikan launcher, dan mengizinkan HTTP biasa. |
| `android/app/src/debug/AndroidManifest.xml` | Manifest tambahan untuk build debug. |
| `android/app/src/profile/AndroidManifest.xml` | Manifest tambahan untuk build profile. |
| `android/app/src/main/kotlin/com/example/smart_building_app/MainActivity.kt` | Activity Android utama yang membuka Flutter. |
| `android/app/src/main/kotlin/com/example/smartclass_v2/MainActivity.kt` | Activity lama/duplikat dari package sebelumnya; tidak cocok dengan namespace aktif. |
| `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` | Registrasi plugin yang dibuat Flutter otomatis. |
| `android/app/src/main/res/drawable/launch_background.xml` | Background splash Android lama. |
| `android/app/src/main/res/drawable-v21/launch_background.xml` | Background splash untuk Android API 21+. |
| `android/app/src/main/res/values/styles.xml` | Tema launch dan tema normal Android. |
| `android/app/src/main/res/values-night/styles.xml` | Tema Android ketika sistem memakai dark mode. |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | Ikon launcher Android resolusi mdpi. |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | Ikon launcher Android resolusi hdpi. |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | Ikon launcher Android resolusi xhdpi. |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | Ikon launcher Android resolusi xxhdpi. |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | Ikon launcher Android resolusi xxxhdpi. |
| `android/build.gradle.kts` | Konfigurasi build tingkat proyek Android. |
| `android/settings.gradle.kts` | Memuat Flutter SDK dan versi plugin Gradle/Kotlin/Google Services. |
| `android/gradle.properties` | Properti performa dan perilaku Gradle. |
| `android/gradle/wrapper/gradle-wrapper.properties` | Versi Gradle wrapper. |
| `android/gradle/wrapper/gradle-wrapper.jar` | Program wrapper Gradle. |
| `android/gradlew` dan `android/gradlew.bat` | Script menjalankan Gradle di Unix dan Windows. |
| `android/local.properties` | Path lokal Flutter/Android SDK; khusus komputer ini. |
| `android/.gradle/`, `android/.kotlin/` | Cache hasil build Android/Kotlin. |
| `android/.gitignore`, `android/smart_building_app_android.iml` | Aturan Git dan metadata IDE Android. |

`android:usesCleartextTraffic="true"` diperlukan karena URL InfluxDB bawaan
memakai `http://`, bukan `https://`.

### 3.6 iOS, macOS, Web, dan Windows

| File/folder | Fungsi |
|---|---|
| `ios/Flutter/Generated.xcconfig` | Konfigurasi iOS hasil generate Flutter. |
| `ios/Runner/GeneratedPluginRegistrant.h` | Header registrasi plugin iOS hasil generate. |
| `ios/Runner/GeneratedPluginRegistrant.m` | Implementasi registrasi plugin iOS hasil generate. |
| `ios/Flutter/ephemeral/` | File sementara iOS hasil generate. |
| `macos/Flutter/GeneratedPluginRegistrant.swift` | Registrasi plugin macOS hasil generate. |
| `macos/Flutter/ephemeral/` | File sementara macOS hasil generate. |
| `web/index.html` | Halaman HTML yang memuat aplikasi Flutter Web. |
| `web/manifest.json` | Nama, warna, orientasi, dan ikon Progressive Web App. |
| `web/favicon.png` | Ikon kecil tab browser. |
| `web/icons/Icon-192.png` | Ikon web ukuran 192 piksel. |
| `web/icons/Icon-512.png` | Ikon web ukuran 512 piksel. |
| `web/icons/Icon-maskable-192.png` | Ikon web maskable 192 piksel. |
| `web/icons/Icon-maskable-512.png` | Ikon web maskable 512 piksel. |
| `windows/CMakeLists.txt` | Konfigurasi build utama Windows. |
| `windows/flutter/CMakeLists.txt` | Konfigurasi build Flutter engine/plugin di Windows. |
| `windows/flutter/generated_plugin_registrant.cc` | Implementasi registrasi plugin Windows hasil generate. |
| `windows/flutter/generated_plugin_registrant.h` | Header registrasi plugin Windows hasil generate. |
| `windows/flutter/generated_plugins.cmake` | Daftar plugin Windows hasil generate. |
| `windows/runner/CMakeLists.txt` | Konfigurasi executable Windows. |
| `windows/runner/main.cpp` | Pintu masuk aplikasi native Windows. |
| `windows/runner/flutter_window.cpp` | Implementasi jendela yang menampilkan Flutter. |
| `windows/runner/flutter_window.h` | Header jendela yang menampilkan Flutter. |
| `windows/runner/win32_window.cpp` | Implementasi pembungkus dasar jendela Win32. |
| `windows/runner/win32_window.h` | Header pembungkus dasar jendela Win32. |
| `windows/runner/utils.cpp` | Implementasi helper native Windows. |
| `windows/runner/utils.h` | Header helper native Windows. |
| `windows/runner/Runner.rc` | Resource aplikasi Windows. |
| `windows/runner/resource.h` | ID resource Windows. |
| `windows/runner/runner.exe.manifest` | Manifest executable Windows. |
| `windows/runner/resources/app_icon.ico` | Ikon aplikasi Windows. |
| `windows/.gitignore` | Aturan file Windows yang tidak masuk Git. |

Walaupun pembungkus iOS, macOS, web, dan Windows ada, login Firebase akan
melempar pesan “not configured” pada platform tersebut karena
`firebase_options.dart` hanya berisi konfigurasi Android.

## 4. Urutan Aplikasi Menyala

```dart
void main() { // Fungsi pertama yang dijalankan ketika aplikasi dibuka.
  WidgetsFlutterBinding.ensureInitialized(); // Menyiapkan hubungan Flutter dengan platform native.
  runApp(const SmartBuildingApp()); // Memasang widget akar ke layar.
} // Menutup fungsi main.
```

Setelah itu:

1. `SmartBuildingApp` membuat `MaterialApp`.
2. `MaterialApp` memakai `AppTheme.lightTheme`.
3. `_AuthGate` meminta `AuthService.load()` memeriksa sesi Firebase.
4. Selama pemeriksaan, layar menampilkan loading.
5. Jika belum login, tampil `AuthScreen`.
6. Jika sudah login, tampil `_AppShell` dengan empat tab.
7. `_AppShell` membaca daftar ruang dari InfluxDB dan membagikannya ke layar.

## 5. Penjelasan Setiap File Dart

### 5.1 `lib/main.dart`

**Tujuan:** tombol starter aplikasi. File ini sengaja kecil agar mudah ditemukan.

**Widget/konsep:** `WidgetsFlutterBinding` menyiapkan Flutter; `runApp` menaruh
`SmartBuildingApp` di layar.

**Terhubung ke:** mengimpor `app.dart`.

### 5.2 `lib/app.dart`

**Tujuan:** seperti lobi utama gedung. File ini menentukan apakah pengguna
melihat pintu login atau masuk ke panel utama.

**Bagian penting:**

- `SmartBuildingApp`: membuat `MaterialApp`.
- `_AuthGate`: mendengarkan perubahan login dari `AuthService`.
- `_AppShell`: menyimpan tab aktif, service InfluxDB aktif, daftar kelas, dan
  sinyal refresh.
- `_loadClassrooms()`: mengambil tag `room` dari InfluxDB lalu mengubahnya
  menjadi `ClassRoomConfig`.
- `_updateInfluxDb()`: mengganti service saat URL/token disimpan dari Settings.

**Widget yang dipakai:** `MaterialApp`, `FutureBuilder`, `Scaffold`, `AppBar`,
`IconButton`, `IndexedStack`, `NavigationBar`, dan `NavigationDestination`.
`IndexedStack` dipakai agar state setiap tab tetap hidup saat pindah tab.

**Terhubung ke:** seluruh screen, `AuthService`, `InfluxDbService`,
`ClassRoomConfig`, theme, dan `AppLoading`.

### 5.3 `lib/firebase_options.dart`

**Tujuan:** menyimpan identitas proyek Firebase. File ini dibuat otomatis oleh
FlutterFire CLI.

**Widget:** tidak ada.

**Perilaku:** hanya Android yang memiliki `FirebaseOptions`. Web, iOS, macOS,
Windows, dan Linux akan menghasilkan `UnsupportedError`.

**Terhubung ke:** `AuthService` saat menjalankan `Firebase.initializeApp()`.

### 5.4 `lib/models/class_room_config.dart`

**Tujuan:** kartu identitas sederhana untuk kelas.

Data yang disimpan:

- `id`: ID internal seperti `room-hd01`.
- `className`: tag room asli dari database, misalnya `HD01`.
- `displayName`: nama untuk UI, misalnya `Class HD01`.
- `buildingName`: dibuat dari karakter pertama nama ruang.
- `floorName`: dibuat dari karakter kedua jika karakter itu angka.

**Widget:** tidak ada. Ini model data biasa.

**Terhubung ke:** `app.dart`, Home, Schedule, dan Devices.

### 5.5 `lib/models/influx_room_data.dart`

**Tujuan:** penerjemah data mentah InfluxDB. InfluxDB dapat mengirim angka,
string, boolean, atau `-1`; model ini mengubah semuanya menjadi bentuk yang
lebih mudah dipahami UI.

**Field utama:** `temp`, `lux`, `human`, `led`, `projector`, `ac`, `alert`,
dan `active`.

**Perilaku penting:**

- `-1` dianggap “tidak ada data” dan ditampilkan sebagai `-`.
- Presence dapat berasal dari field `presence`, `human`, atau `motion`.
- Nilai AC dapat berbentuk `01/24/02/99` atau `01240299`.
- `hasAlert`, `isActive`, dan `isOccupied` menyederhanakan pengecekan status.
- `InfluxHomeSummary` menyimpan jumlah total kelas, kelas aktif, dan alert.

**Widget:** tidak ada.

**Terhubung ke:** `InfluxDbService`, Home, dan Devices.

### 5.6 `lib/screens/auth_screen.dart`

**Tujuan:** halaman login satu arah. Tidak ada registrasi akun.

**Widget yang dipakai dan alasannya:**

- `Scaffold` dan `SafeArea`: kerangka layar yang aman dari notch/status bar.
- `SingleChildScrollView`: form tetap dapat digulir ketika keyboard muncul.
- `Form`: mengelompokkan validasi email/password.
- `TextEditingController`: membaca teks yang diketik pengguna.
- `AppTextInput`: input konsisten dengan theme.
- `AppButton`: tombol Sign In bersama.
- `AppCard`: membungkus form dalam kartu.

**Alur:** validasi form -> panggil `AuthService.signIn()` -> Firebase memeriksa
email/password -> jika gagal tampil `SnackBar` -> jika berhasil `_AuthGate`
otomatis mengganti layar.

### 5.7 `lib/screens/home_screen.dart`

**Tujuan:** dashboard ringkas seluruh kampus.

**Yang dibaca dari InfluxDB:**

- Daftar ruang untuk menghitung total.
- Field `human`, `presence`, `motion`, `alert`, dan `active`.
- Kelas dengan `active == true` masuk daftar Ongoing Classes.
- Kelas dengan alert aktif masuk daftar Active Alerts.

**Widget utama:** `ListView`, `LinearProgressIndicator`, `Row`, `Column`,
`Expanded`, `LayoutBuilder`, `FilledButton`, `AppCard`, dan `AppBadge`.
`LayoutBuilder` membuat tombol lampu tersusun vertikal pada layar sempit.

**Catatan nyata:** tombol `All Lights On`, `All Lights Off`, dan
`All Lights Match Schedule` belum memanggil InfluxDB. Tombol hanya menjalankan
`setState()` dan menampilkan teks “Dummy action”.

### 5.8 `lib/screens/schedule_screen.dart`

**Tujuan:** mengatur jadwal mingguan berulang per ruang.

**Cara jadwal disimpan:** setiap hari memiliki kode enam digit. Setiap digit
adalah sakelar untuk satu sesi.

```text
Kode 101000
     ||||||
     |||||`-- Sesi 6 mati
     ||||`--- Sesi 5 mati
     |||`---- Sesi 4 mati
     ||`----- Sesi 3 hidup
     |`------ Sesi 2 mati
     `------- Sesi 1 hidup
```

**Widget utama:** `Scaffold`, `AppDropdown`, `ListView.builder`, `Chip`,
`IconButton`, `AlertDialog`, `CheckboxListTile`, dan `AppButton`.

**Terhubung ke:** `ClassRoomConfig` untuk pilihan ruang dan `InfluxDbService`
untuk membaca/menulis measurement `classroom_schedule`.

**Jadwal sesi:** enam sesi, mulai `07:20 - 09:00` sampai `17:20 - 19:00`.

### 5.9 `lib/screens/devices_screen.dart`

**Tujuan:** halaman Classes untuk melihat kelas dan mengontrol perangkat.

**Alur penggunaan:**

1. Saat tab dibuka, aplikasi membaca indikator ringkas setiap ruang.
2. Pengguna mengetuk kartu kelas.
3. Aplikasi membaca detail ruang itu saja.
4. Pengguna mengetuk LED/proyektor untuk membalik nilai on/off.
5. Pengguna mengetuk AC untuk membuka dialog pengaturan.
6. Setelah write berhasil, detail dan indikator dibaca ulang.

**Widget utama:** `ListView`, `AppCard`, `Tooltip`, `Wrap`, `InkWell`, `Ink`,
`AppBadge`, `AlertDialog`, `SwitchListTile`, `Slider`,
`DropdownButtonFormField`, dan `FilledButton`.

**Format perintah AC:** `ppttffss`.

- `pp`: power, `01` hidup atau `00` mati.
- `tt`: suhu 16-30.
- `ff`: fan 00-05.
- `ss`: swing, saat ini selalu `99` yang berarti tidak diubah.
- Contoh: `01240299` berarti hidup, 24 derajat, fan medium, swing tidak diubah.

### 5.10 `lib/screens/settings_screen.dart`

**Tujuan:** mengganti koneksi InfluxDB selama aplikasi hidup dan logout.

**Widget utama:** `ListView`, `ConstrainedBox`, `Container`, `Column`,
`AppTextInput`, `AppButton`, dan `AppCard`.

**Alur simpan:** pengguna mengetik URL/token -> dibuat objek `InfluxDbService`
baru -> dikirim ke `_AppShell` -> seluruh tab diberi sinyal refresh -> daftar
kelas dibaca ulang.

**Batasan:** URL/token baru hanya tersimpan di memori. Ketika aplikasi ditutup,
pengaturan kembali ke nilai bawaan source code.

### 5.11 `lib/services/auth_service.dart`

**Tujuan:** satu-satunya pintu komunikasi Firebase Authentication.

Analogi: `AuthService` adalah petugas keamanan. Screen tidak berbicara langsung
dengan Firebase; screen hanya meminta petugas “coba login orang ini”.

**Yang dilakukan:**

- Menginisialisasi Firebase dengan batas waktu lima detik.
- Memeriksa sesi login lama.
- Login memakai `signInWithEmailAndPassword`.
- Logout memakai `signOut`.
- Mendengarkan `authStateChanges()`.
- Menerjemahkan error Firebase menjadi pesan yang mudah dibaca.
- Memanggil `notifyListeners()` agar `_AuthGate` memperbarui UI.

### 5.12 `lib/services/influxdb_service.dart`

**Tujuan:** pusat seluruh komunikasi HTTP InfluxDB.

**Konfigurasi bawaan:**

| Nilai | Isi |
|---|---|
| URL | `http://10.194.151.250:8086` |
| Bucket | `SmartClass` |
| Measurement status/perintah | `classroom` |
| Measurement jadwal | `classroom_schedule` |
| Tag identitas ruang | `room` |
| Autentikasi | Header `Authorization: Token ...` |

Token sengaja tidak ditulis ulang di dokumen ini. Token asli berada langsung
di constructor `InfluxDbService`.

**Endpoint HTTP yang dipakai:**

| Method dan endpoint | Tujuan | Data masuk/keluar |
|---|---|---|
| `GET /api/v2/orgs` | Menemukan organisasi pertama yang dapat dipakai token. | Keluar: JSON daftar organisasi. |
| `POST /api/v2/query?org=...` | Menjalankan query Flux. | Masuk: teks Flux; keluar: annotated CSV. |
| `POST /api/v2/write?org=...&bucket=...` | Menulis status/perintah/jadwal. | Masuk: Influx line protocol; keluar: status HTTP. |

**Query utama:**

- `loadRooms()`: memakai `schema.tagValues` untuk mengambil semua tag `room`
  dari measurement `classroom` selama 30 hari terakhir.
- `loadRoomIndicators()`: mengambil nilai terakhir `human`, `presence`,
  `motion`, `alert`, dan `active`.
- `loadRoomDetails(room)`: mengambil nilai terakhir sensor dan perangkat ruang.
- `loadClassroomSchedule(room)`: membaca nilai terakhir setiap field hari dari
  measurement `classroom_schedule`.

**Contoh write dengan komentar setiap baris:**

```text
classroom,room=HD01 led=1
# classroom adalah nama measurement.
# room=HD01 adalah tag yang menunjuk kelas tujuan.
# led adalah nama field yang ingin diubah.
# 1 berarti LED diminta hidup.
```

Catatan: contoh di atas sebenarnya satu baris line protocol. Baris komentar
hanya ditambahkan untuk penjelasan.

**Tidak ada topic MQTT:** karena tidak ada package MQTT, koneksi broker,
subscribe, publish, atau string topic dalam source code.

### 5.13 `lib/theme/app_colors.dart`

**Tujuan:** satu lemari cat bersama. Daripada setiap screen menebak warna biru
sendiri, semua mengambil warna bernama dari file ini.

**Widget:** tidak ada; isinya konstanta `Color`.

### 5.14 `lib/theme/app_text_styles.dart`

**Tujuan:** menetapkan gaya teks bersama.

Font utama adalah `Inter`, dengan fallback `Roboto`. Namun `pubspec.yaml` tidak
mendaftarkan file font Inter sebagai asset, jadi ketersediaannya bergantung
pada platform; jika tidak tersedia, Flutter memakai Roboto.

Gaya yang tersedia: `displayTitle`, `pageTitle`, `sectionTitle`, `cardTitle`,
`body`, `bodyMedium`, `caption`, dan `labelSmall`.

### 5.15 `lib/theme/app_theme.dart`

**Tujuan:** merakit warna dan teks menjadi tema Material 3.

**Yang diatur:** `ColorScheme`, background Scaffold, warna Card, Divider,
TextTheme, AppBar, bentuk Card, dan border input.

**Terhubung ke:** `SmartBuildingApp` melalui `theme: AppTheme.lightTheme`.

### 5.16 `lib/widgets/app_badge.dart`

**Tujuan:** membuat label status kecil yang konsisten.

**Widget:** `Container`, `BoxDecoration`, dan `Text`.

Tipe badge: `online`, `offline`, `warning`, dan `error`. Setiap tipe memilih
warna dari `AppColors`.

### 5.17 `lib/widgets/app_button.dart`

**Tujuan:** gudang beberapa kontrol UI yang sering dipakai.

| Komponen | Fungsi |
|---|---|
| `AppButton` | Tombol utama berwarna biru. |
| `AppTextInput` | Input teks bersama. |
| `AppNumberInput` | Input teks dengan keyboard angka. Saat ini tidak dipakai. |
| `AppDropdown<T>` | Dropdown generik. |
| `AppSwitch` | Switch untuk Settings; saat ini tidak dipakai screen. |
| `AppLoading` | Loading spinner biru. |
| `showAppToast` | Menampilkan `SnackBar`. |

### 5.18 `lib/widgets/app_card.dart`

**Tujuan:** kartu putih reusable dengan border abu-abu dan radius delapan.

**Widget:** `Padding`, `InkWell`, dan `Card`. Jika `onTap` diberikan, kartu
menjadi dapat diketuk.

### 5.19 `test/widget_test.dart`

**Tujuan:** memastikan aplikasi minimal dapat membuka halaman login.

Test mencari teks `Sign In`, `Email`, dan `Password`, lalu memastikan
`Create account` serta `Sign Up` tidak ada.

## 6. HTTP dan Aliran Data InfluxDB

### 6.1 Membaca data

```text
Screen memanggil InfluxDbService
  -> Service mencari org melalui GET /api/v2/orgs
  -> Service mengirim Flux ke POST /api/v2/query
  -> InfluxDB membalas annotated CSV
  -> Service memecah CSV menjadi Map
  -> InfluxRoomData mengubah tipe data mentah
  -> Screen menyimpan hasil dengan setState()
  -> Flutter menggambar UI terbaru
```

`_org` disimpan dalam cache di dalam service. Jadi pencarian organisasi biasanya
hanya dilakukan sekali per objek `InfluxDbService`.

### 6.2 Menulis kontrol perangkat

```text
Pengguna mengetuk LED/Projector/Apply AC
  -> DevicesScreen menentukan nilai baru
  -> writeRoomField(room, field, value)
  -> POST /api/v2/write?org=...&bucket=SmartClass
  -> InfluxDB menyimpan line protocol
  -> DevicesScreen membaca ulang detail dan indikator
  -> UI menunjukkan nilai terakhir dari database
```

Contoh data keluar:

```text
classroom,room=HD01 projector=0
classroom,room=HD01 ac="01240299"
classroom_schedule,room=HD01 Monday=101000
```

### 6.3 Data yang dibaca

| Measurement | Field/tag | Arti |
|---|---|---|
| `classroom` | tag `room` | Nama/identitas kelas. |
| `classroom` | `temp` | Suhu ruang. |
| `classroom` | `lux` | Tingkat cahaya. |
| `classroom` | `human`, `presence`, atau `motion` | Apakah manusia terdeteksi. |
| `classroom` | `led` | Status/perintah lampu. |
| `classroom` | `projector` | Status/perintah proyektor. |
| `classroom` | `ac` | Status/perintah AC. |
| `classroom` | `alert` | Kode peringatan. |
| `classroom` | `active` | Apakah kelas sedang aktif. |
| `classroom_schedule` | Monday-Sunday | Kode enam sesi tiap hari. |

## 7. Firebase Authentication

Firebase hanya menjawab pertanyaan: “pengguna ini boleh masuk atau tidak?”
Firebase tidak menyimpan status sensor, perangkat, atau jadwal.

```text
AuthScreen
  -> validasi format email dan password tidak kosong
  -> AuthService memastikan Firebase siap
  -> FirebaseAuth.signInWithEmailAndPassword()
  -> Firebase mengembalikan User atau error
  -> AuthService.notifyListeners()
  -> AuthGate memilih AuthScreen atau AppShell
```

Tidak ada endpoint Firebase HTTP yang ditulis manual. Package `firebase_auth`
menangani komunikasi ke server Firebase di balik layar.

## 8. Data Flow Diagram Lengkap

```text
                         LOGIN FLOW

[Email + Password UI]
        |
        v
[AuthScreen local state]
        |
        v
[AuthService / ChangeNotifier]
        |
        v
[Firebase Authentication]
        |
        v
[AuthGate] -> [AppShell + 4 tabs]


                       INFLUXDB READ FLOW

[InfluxDB HTTP API]
        |
        | JSON org / CSV query result
        v
[InfluxDbService]
        |
        | Map<String, dynamic>
        v
[InfluxRoomData / ClassRoomConfig]
        |
        | setState()
        v
[Home / Schedule / Devices UI]


                       INFLUXDB WRITE FLOW

[Pengguna mengetuk kontrol]
        |
        v
[DevicesScreen atau ScheduleScreen]
        |
        | line protocol
        v
[InfluxDbService.write...()]
        |
        | POST /api/v2/write
        v
[InfluxDB]
        |
        | dibaca ulang
        v
[State layar] -> [UI terbaru]
```

## 9. Color dan Theme Breakdown

### 9.1 Palet warna aplikasi

| Nama | Hex | Penggunaan |
|---|---|---|
| `primary` | `#2563EB` | Tombol utama, tab aktif, fokus input, kontrol aktif. |
| `primaryDark` | `#1D4ED8` | Container primary yang lebih kuat. |
| `secondary` | `#14B8A6` | Aksen sekunder dan koneksi. |
| `background` | `#F8FAFC` | Background halaman. |
| `surface` | `#FFFFFF` | Kartu, AppBar, modal, dan teks di atas tombol berwarna. |
| `surfaceSoft` | `#F1F5F9` | Background lembut dan chip. |
| `textPrimary` | `#0F172A` | Teks utama. |
| `textSecondary` | `#64748B` | Caption, hint, dan metadata. |
| `border` | `#CBD5E1` | Border kartu/input dan divider. |
| `success` | `#22C55E` | Online, hidup, atau berhasil. |
| `warning` | `#F59E0B` | Peringatan. |
| `error` | `#EF4444` | Error, off, atau tindakan kritis. |
| `offline` | `#94A3B8` | Tidak aktif, tidak diketahui, atau disabled. |
| `chartLine` | `#2563EB` | Garis chart utama; chart belum dipakai sekarang. |
| `chartLineSecondary` | `#14B8A6` | Garis chart kedua; belum dipakai sekarang. |
| `chartGrid` | `#E2E8F0` | Grid chart; belum dipakai sekarang. |
| `chartText` | `#64748B` | Teks chart; belum dipakai sekarang. |

Web manifest juga memakai warna Flutter default `#0175C2`, bukan
`AppColors.primary`. Warna itu hanya memengaruhi metadata/PWA web.

### 9.2 Struktur theme

```text
app_colors.dart
  +-- menyediakan warna bernama

app_text_styles.dart
  +-- memakai AppColors untuk warna teks
  +-- menyediakan ukuran/ketebalan teks

app_theme.dart
  +-- menggabungkan warna dan teks
  +-- mengatur Material 3, AppBar, Card, Divider, dan Input

app.dart
  +-- memasang AppTheme.lightTheme pada MaterialApp
```

Theme yang tersedia hanya light theme. Tidak ada `darkTheme` atau tombol
pengganti tema.

## 10. Package dan Dependency

| Package | Fungsi |
|---|---|
| `flutter` | Framework utama untuk membuat UI lintas platform. |
| `cupertino_icons` | Kumpulan ikon bergaya iOS; tidak tampak dipakai langsung di source utama. |
| `uuid` | Pembuat ID unik; saat ini tidak dipakai source utama. |
| `firebase_core` | Menyalakan dan mengonfigurasi Firebase. |
| `firebase_auth` | Login/logout email-password dan sesi pengguna. |
| `flutter_test` | Alat membuat automated test Flutter. |
| `flutter_lints` | Kumpulan aturan gaya dan kualitas kode Dart. |

Tidak ada package HTTP karena kode memakai `dart:io` `HttpClient` bawaan Dart.
Tidak ada package MQTT.

## 11. Glosarium Pemula

| Istilah | Penjelasan sederhana |
|---|---|
| Flutter | Framework untuk membuat aplikasi dari satu source code Dart. Seperti satu resep yang bisa disajikan di beberapa platform. |
| Dart | Bahasa pemrograman yang dipakai Flutter. |
| Widget | Balok penyusun UI Flutter. Teks, tombol, halaman, bahkan jarak adalah widget. |
| StatelessWidget | Widget yang tidak menyimpan perubahan internal. Seperti poster yang isinya tetap. |
| StatefulWidget | Widget yang dapat menyimpan dan memperbarui data lokal. Seperti papan tulis yang dapat dihapus dan ditulis ulang. |
| State | Data sementara yang menentukan tampilan saat ini. |
| `setState()` | Memberi tahu Flutter bahwa data berubah dan bagian layar perlu digambar ulang. |
| `BuildContext` | Alamat posisi widget di pohon UI; dipakai mencari theme, navigator, dan messenger. |
| MaterialApp | Pembungkus utama aplikasi bergaya Material Design. |
| Scaffold | Kerangka satu layar yang menyediakan AppBar, body, dan navigasi bawah. |
| AppBar | Bar judul di bagian atas layar. |
| NavigationBar | Menu tab di bagian bawah aplikasi. |
| IndexedStack | Menampilkan satu anak tetapi menjaga anak lain tetap hidup. |
| Future | Janji bahwa hasil akan tersedia nanti, biasanya setelah operasi internet selesai. |
| `async` / `await` | Cara menunggu operasi lambat tanpa membekukan UI. |
| `mounted` | Penanda apakah widget masih ada di layar sebelum memanggil `setState()`. |
| Model | Class yang mewakili bentuk data, bukan tampilan. |
| Service | Class yang menangani pekerjaan luar seperti Firebase atau InfluxDB. |
| Firebase | Layanan cloud Google. Di proyek ini hanya dipakai untuk login. |
| Firebase Authentication | Sistem pemeriksaan akun, email, password, dan sesi login. |
| InfluxDB | Database time-series, yaitu database yang cocok menyimpan nilai berdasarkan waktu seperti sensor dan status perangkat. |
| HTTP | Cara aplikasi mengirim permintaan ke server melalui jaringan. Seperti surat dengan format yang disepakati. |
| API | Pintu resmi yang disediakan layanan agar program lain dapat berbicara dengannya. |
| Endpoint | Alamat pintu API tertentu, misalnya `/api/v2/query`. |
| GET | Permintaan HTTP untuk mengambil data. |
| POST | Permintaan HTTP untuk mengirim data atau menjalankan aksi. |
| Header | Informasi tambahan pada permintaan HTTP, misalnya token autentikasi. |
| Token | Kunci rahasia yang memberi izin mengakses InfluxDB. |
| Bucket | Wadah data di InfluxDB, mirip database. Proyek memakai `SmartClass`. |
| Measurement | Kelompok data di InfluxDB, mirip nama tabel. |
| Tag | Label yang mudah dicari, misalnya `room=HD01`. |
| Field | Nilai aktual yang disimpan, misalnya `temp=25.3` atau `led=1`. |
| Flux | Bahasa query InfluxDB untuk memilih dan mengolah data. |
| Query | Pertanyaan yang dikirim ke database untuk meminta data. |
| Line protocol | Format satu baris yang dipakai untuk menulis data ke InfluxDB. |
| Annotated CSV | Format tabel teks hasil query InfluxDB beserta baris metadata. |
| JSON | Format data teks berbentuk pasangan nama dan nilai. |
| MQTT | Protokol pesan publish/subscribe seperti grup chat. **Tidak dipakai versi proyek ini.** |
| Topic MQTT | Nama ruang chat MQTT. Tidak ada topic MQTT dalam source saat ini. |
| ChangeNotifier | Class Flutter yang dapat memberitahu listener ketika datanya berubah. |
| Listener | Kode yang menunggu pemberitahuan perubahan. |
| Controller | Objek yang membaca/mengatur input, misalnya `TextEditingController`. |
| Form validation | Pemeriksaan input sebelum dikirim, misalnya email harus berbentuk valid. |
| SnackBar/toast | Pesan singkat yang muncul sementara di bawah layar. |
| Dialog | Kotak pop-up di atas layar, dipakai untuk edit jadwal dan AC. |
| ThemeData | Kumpulan aturan tampilan global Flutter. |
| Material 3 | Versi sistem desain Material yang digunakan aplikasi. |
| Lint | Aturan otomatis yang menandai gaya atau pola kode bermasalah. |
| Smoke test | Test sederhana untuk memastikan aplikasi dapat menyala dan fungsi paling dasar terlihat. |
| FSD | Functional Specification Document, dokumen yang menjelaskan perilaku yang seharusnya dimiliki aplikasi. |
| Cache | File sementara untuk mempercepat build. Biasanya bukan source yang perlu diedit. |
| Native wrapper | Kode platform Android/iOS/Windows yang menjadi wadah aplikasi Flutter. |

## 12. Hal yang Perlu Diingat Saat Membaca Kode

1. Mulai dari `main.dart`, lalu `app.dart`.
2. Ikuti tab yang ingin dipahami ke file dalam `screens/`.
3. Jika screen membutuhkan internet/database, ikuti panggilannya ke `services/`.
4. Jika bingung bentuk datanya, lihat `models/`.
5. Jika ingin mengubah tampilan umum, lihat `theme/` dan `widgets/`.
6. Jangan mengedit `build/`, `.dart_tool/`, atau file generated kecuali benar-benar
   memahami alasan teknisnya.

## 13. Kesimpulan

Source utama proyek ini relatif sederhana: satu gerbang login, satu shell dengan
empat tab, model data kecil, serta dua service utama. Firebase mengurus siapa
yang boleh masuk. InfluxDB menjadi sumber data dan tujuan perintah. UI memakai
`setState()` langsung, sehingga alurnya mudah diikuti tanpa lapisan arsitektur
tambahan.

Bagian paling penting untuk dipelajari lebih dahulu adalah:

```text
main.dart
  -> app.dart
  -> screens/
  -> services/influxdb_service.dart
  -> models/influx_room_data.dart
```

## 14. Hasil Verifikasi Dokumentasi

Pemeriksaan dilakukan setelah dokumen ini dibuat:

- Seluruh **19 file Dart** proyek, termasuk file test, telah disebut dan
  dijelaskan.
- Seluruh **94 file proyek non-cache** telah dicakup dalam inventaris. File
  hasil generate yang sejenis dijelaskan bersama agar tetap mudah dibaca.
- `flutter test` berhasil: **semua test lulus**.
- `flutter analyze` selesai tetapi melaporkan empat masalah lama pada source:
  tiga penggunaan API Flutter yang deprecated di `devices_screen.dart` dan
  satu import `app_badge.dart` yang tidak terpakai di `schedule_screen.dart`.
- Pembuatan dokumen ini tidak mengubah source Dart atau perilaku aplikasi.
