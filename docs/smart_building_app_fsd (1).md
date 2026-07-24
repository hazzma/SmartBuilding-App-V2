# Smart Building App FSD

## 0. Core Rule

### Rule 1 — Every Code Block Must Explain Its Edit Purpose

Setiap kali menulis atau mengubah kode, bagian kode wajib diberi komentar command yang menjelaskan kode itu dipakai untuk mengedit bagian apa.

Format wajib:

```dart
// EDIT_TARGET: <nama_file_atau_bagian>
// EDIT_PURPOSE: <apa_yang_diubah>
// EDIT_REASON: <kenapa_perubahan_ini_dibutuhkan>
```

Contoh:

```dart
// EDIT_TARGET: app_button.dart
// EDIT_PURPOSE: Membuat reusable button utama untuk seluruh aplikasi
// EDIT_REASON: Supaya semua tombol punya style konsisten dan gampang diubah dari satu tempat
class AppButton extends StatelessWidget {
  const AppButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {},
      child: const Text('Save'),
    );
  }
}
```

Tujuan rule ini adalah supaya proses debug, review, dan modifikasi manual tetap jelas. Jadi saat kode makin besar, developer tidak perlu menebak-nebak bagian itu dibuat untuk apa. Karena menebak isi hati manusia saja sudah cukup melelahkan.

---

# 1. App Requirement Alignment

Dokumen ini disesuaikan untuk Flutter app yang mengontrol dan memonitor Smart Building Master melalui MQTT.

App SHALL:

- Connect ke broker MQTT yang sama dengan master.
- Subscribe state dari semua master.
- Menampilkan daftar master yang online atau terakhir terlihat.
- Membiarkan user memilih satu active master.
- Mengirim command JSON hanya ke selected master.
- Menampilkan kontrol hanya jika `available == true` dari latest state.
- Menganggap publish state berikutnya sebagai confirmation command.

Core data flow:

```txt
Flutter App
  ↓ connect
MQTT Broker
  ↓ subscribe
smart-building/master/+/state
  ↓ parse
Master Registry
  ↓ select
Active Master Dashboard
  ↓ publish command
smart-building/master/<selected_master>/command
```

---

## 1.1 MQTT Topic Requirement

Default topic:

```txt
Master → App:
smart-building/master/+/state

App → Master:
smart-building/master/+/command
```

App harus support wildcard subscription:

```txt
smart-building/master/+/state
```

Jika master memakai custom topic preset, app harus menyediakan setting topic di Broker Setup / Connection screen.

---

## 1.2 Master Registry Requirement

App harus membuat registry master dari payload state yang diterima.

Priority identity key:

```txt
1. device_id, if present
2. device_name + master_mac
3. device_name
```

Setiap master card minimal menampilkan:

- Device name
- Firmware version
- MQTT online / last seen
- WiFi / LAN status
- RS485 status
- Slave count
- Short room / sensor summary

User hanya boleh memilih satu active master dalam satu waktu.

Semua command harus dikirim hanya ke active master.

Stale rule:

```txt
If no state payload is received for > 3 publish intervals,
mark master as stale/offline.
```

---

## 1.3 State Payload Parsing Requirement

App harus parse payload state master dengan shape utama:

```txt
network
slaves
sensor data
controls
```

Parsing rules:

- Unknown fields harus diabaikan.
- Missing optional object dianggap unavailable.
- Sensor value `null` berarti unavailable/stale.
- App tidak boleh menganggap placeholder seperti `-100` sebagai data valid.
- `lights.channels` adalah source of truth untuk jumlah lampu dan state lampu.

---

## 1.4 Command Payload Requirement

App mengirim JSON command ke selected master.

Command rules:

- `target` sebaiknya sama dengan selected `device_name` atau `device_id`.
- `command_id` harus unik per action.
- App harus mengirim explicit final state, bukan toggle-only command.
- App boleh mengirim satu control object saja per action.
- App hanya menampilkan control jika `available == true`.
- Lamp channels memakai `id` 1 sampai 4.

Command example direction:

```txt
Turn lamp 2 on
Set AC target temperature
Turn projector on/off
Turn all lamps off only through explicit All Lamps action
```

---

## 1.5 UI Requirement from Master Device

Required app areas from MQTT requirement are mapped into simplified navigation:

```txt
Broker Setup / Connection -> Settings
Master List -> Devices
Master Dashboard -> Home
Master Detail / Slave List -> Devices > Advanced
Control Panel -> Home
Debug / Developer Mode -> Devices > Advanced Debug
Settings -> Settings
```

Master Dashboard harus menampilkan:

- Average room temperature
- CO2
- Human presence
- AC state and target
- Projector state
- Lamp channel 1-4 states
- Slave online/offline summary

Lamp UI rule:

```txt
If 1 channel:
show one large ON/OFF control.

If 2-4 channels:
show individual controls for Lamp 1, Lamp 2, Lamp 3, Lamp 4.

Do not use one generic lamp toggle to control all lamps
unless user explicitly chooses "All Lamps".
```

---

## 1.6 Error Handling Requirement

App SHALL:

- Show MQTT disconnected state.
- Show selected master stale/offline state.
- Disable unavailable controls.
- Keep last known values visible but visually marked stale.
- Show malformed JSON errors only in developer/debug mode.
- Treat next valid state publish as command confirmation.

---

# 2. Flutter Widget Usage Summary

## 2.1 Total Flutter Widgets Used

Total Flutter widget bawaan yang dipakai langsung sebagai dasar reusable component:

**26 Flutter widgets**

Daftar Flutter widget dasar:

1. `FilledButton`
2. `ElevatedButton`
3. `IconButton`
4. `TextField`
5. `DropdownButtonFormField`
6. `Switch`
7. `Slider`
8. `Card`
9. `Container`
10. `Divider`
11. `Text`
12. `Dialog`
13. `AlertDialog`
14. `SnackBar`
15. `CircularProgressIndicator`
16. `Column`
17. `Row`
18. `Icon`
19. `ListTile`
20. `DataRow`
21. `DataTable`
22. `Scaffold`
23. `AppBar`
24. `NavigationBar`
25. `Drawer`
26. `SingleChildScrollView`

## 2.2 External Package Widget Used

Untuk grafik sensor terhadap waktu, app memakai package chart eksternal:

| Package | Widget | Fungsi |
|---|---|---|
| `fl_chart` | `LineChart` | Plot data sensor terhadap waktu |

Catatan: grafik hanya memakai `LineChart`. Tidak memakai `BarChart`, `DonutChart`, `GaugeChart`, atau chart lain karena kebutuhan utama hanya plotting data sensor terhadap waktu.

---

# 3. Reusable Widget Mapping

## 3.1 Base Widgets

| Nama Widget Kita | Flutter Widget yang Dipakai | Fungsi |
|---|---|---|
| `AppButton` | `FilledButton` / `ElevatedButton` | Tombol aksi utama seperti save, apply, scan, pair |
| `AppIconButton` | `IconButton` | Tombol kecil berbasis ikon seperti refresh, edit, delete |
| `AppTextInput` | `TextField` | Input teks seperti nama device, nama room, label |
| `AppNumberInput` | `TextField` + `TextInputType.number` | Input angka seperti address, threshold, delay |
| `AppDropdown` | `DropdownButtonFormField` | Pilihan role, room, protocol, mode |
| `AppSwitch` | `Switch` | ON/OFF device, enable/disable fitur, mode manual |
| `AppSlider` | `Slider` | Kontrol nilai kontinu seperti brightness, speed, threshold |
| `AppCard` | `Card` / `Container` | Pembungkus konten utama |
| `AppDivider` | `Divider` | Pemisah antar section |
| `AppSectionTitle` | `Text` | Judul bagian pada halaman |
| `AppModal` | `Dialog` / `AlertDialog` | Popup pairing, edit config, confirmation |
| `AppToast` | `SnackBar` | Notifikasi singkat |
| `AppBadge` | `Container` + `Text` | Label status seperti online, offline, warning, error |
| `AppLoading` | `CircularProgressIndicator` | Indikator loading |
| `AppEmptyState` | `Column` + `Icon` + `Text` | Tampilan saat data kosong |

## 3.2 Smart Building Widgets

| Nama Widget Kita | Dibangun dari Widget | Fungsi |
|---|---|---|
| `DeviceCard` | `AppCard`, `AppBadge`, `AppSwitch`, `AppIconButton` | Card utama untuk satu device |
| `SensorCard` | `AppCard`, `Text`, `Icon`, `AppBadge` | Menampilkan nilai sensor terbaru |
| `RoomCard` | `AppCard`, `Text`, `AppBadge` | Ringkasan satu room atau zone |
| `ControlTile` | `ListTile`, `AppSwitch`, `AppSlider` | Kontrol device sederhana |
| `ConfigField` | `AppTextInput`, `AppNumberInput`, `AppDropdown` | Field config reusable |
| `StatusRow` | `Row`, `Icon`, `Text`, `AppBadge` | Baris status device atau koneksi |
| `DebugPanel` | `AppCard`, `DataTable`, `DebugLogItem`, `CommandInput` | Panel debug utama |
| `BrokerStatusCard` | `AppCard`, `StatusRow`, `AppButton` | Status koneksi MQTT broker |
| `MasterCard` | `AppCard`, `AppBadge`, `StatusRow`, `MiniSensorGraph` | Card ringkasan master di Master List |
| `ActiveMasterHeader` | `AppCard`, `Text`, `AppBadge`, `StatusRow` | Header selected master pada dashboard |
| `NetworkStatusPanel` | `StatusRow`, `AppBadge` | Status WiFi, LAN, MQTT |
| `SlaveSummaryPanel` | `AppCard`, `StatusRow`, `Text` | Ringkasan slave online/offline dan jumlah slave |
| `AcControlPanel` | `AppCard`, `AppSwitch`, `AppNumberInput`, `AppButton` | Kontrol AC power dan target temperature |
| `ProjectorControlPanel` | `AppCard`, `AppSwitch`, `AppButton` | Kontrol projector power |
| `LampChannelControl` | `ControlTile`, `AppSwitch` | Kontrol satu channel lampu berdasarkan `lights.channels` |
| `AllLampAction` | `AppButton`, `AppModal` | Explicit action untuk semua lampu, bukan generic toggle default |
| `RegisterRow` | `DataRow` / `ListTile` | Satu baris data register |
| `DebugLogItem` | `Container`, `Text` | Satu item log TX/RX/error |
| `CommandInput` | `AppTextInput`, `AppButton` | Input command manual untuk debug |
| `SensorGraph` | `fl_chart.LineChart` | Grafik utama data sensor terhadap waktu |
| `MiniSensorGraph` | `fl_chart.LineChart` | Grafik kecil untuk preview trend sensor |

## 3.3 Screen Structure Widgets

| Nama Widget Kita | Flutter Widget yang Dipakai | Fungsi |
|---|---|---|
| `AppShell` | `Scaffold` | Struktur utama aplikasi |
| `TopBar` | `AppBar` | Header aplikasi |
| `BottomNav` | `NavigationBar` | Navigasi utama 3 tab: Home, Devices, Settings |
| `SideDrawer` | `Drawer` | Navigasi samping untuk layar besar/debug |
| `PageScrollView` | `SingleChildScrollView` | Scroll utama halaman |

---

# 4. Widget Simplification Rules

## 4.1 Avoid Duplicate Widget Logic

Widget yang fungsinya mirip harus disatukan.

| Jangan Buat Terpisah | Pakai Widget Ini |
|---|---|
| `RelayControl`, `LampControl`, `FanControl` | `ControlTile` |
| `DeviceAddressInput`, `DeviceRoleSelector`, `RoomSelector` | `ConfigField` |
| `ConnectionIndicator`, `BatteryIndicator`, `SignalStrengthBar` | `StatusRow` |
| `MqttStatus`, `WifiStatus`, `LanStatus`, `Rs485Status` | `NetworkStatusPanel` |
| `AcPowerControl`, `AcTargetControl` | `AcControlPanel` |
| `Lamp1Control`, `Lamp2Control`, `Lamp3Control`, `Lamp4Control` | `LampChannelControl` |
| `RegisterTable`, `PacketViewer`, `ResponseViewer` | `DebugPanel` |
| `PairingModal`, `EditModal`, `ConfirmModal` | `AppModal` |

## 4.2 Chart Rule

App hanya memakai grafik time-series sensor.

Allowed:

```txt
SensorGraph
MiniSensorGraph
```

Not allowed for first version:

```txt
BarChart
DonutChart
GaugeChart
Heatmap
RadarChart
PieChart
```

Alasan: data utama adalah data sensor terhadap waktu, bukan data power, statistik komposisi, atau dashboard analytics kompleks.

---

# 5. Color Palette

## 5.1 Design Direction

Tema visual app:

- Clean
- Calm
- Technical
- Tidak terlalu ramai
- Cocok untuk smart building dashboard
- Mudah dibaca saat debugging

## 5.2 Main Colors

| Token | Hex | Fungsi |
|---|---|---|
| `primary` | `#2563EB` | Aksi utama, button utama, active navigation |
| `primaryDark` | `#1D4ED8` | Hover/pressed primary |
| `secondary` | `#14B8A6` | Accent untuk sensor/connection |
| `background` | `#F8FAFC` | Background utama light mode |
| `surface` | `#FFFFFF` | Card, modal, panel |
| `surfaceSoft` | `#F1F5F9` | Section ringan atau inactive area |
| `textPrimary` | `#0F172A` | Teks utama |
| `textSecondary` | `#64748B` | Teks pendukung |
| `border` | `#CBD5E1` | Border input/card |

## 5.3 Status Colors

| Token | Hex | Fungsi |
|---|---|---|
| `success` | `#22C55E` | Online, connected, success |
| `warning` | `#F59E0B` | Warning, unstable, attention |
| `error` | `#EF4444` | Error, failed, disconnected critical |
| `offline` | `#94A3B8` | Offline, inactive |
| `debug` | `#8B5CF6` | Debug mode, raw packet, developer tools |

## 5.4 Chart Colors

Chart dibuat sederhana.

| Token | Hex | Fungsi |
|---|---|---|
| `chartLine` | `#2563EB` | Garis utama sensor graph |
| `chartLineSecondary` | `#14B8A6` | Garis sensor kedua jika diperlukan |
| `chartGrid` | `#E2E8F0` | Grid chart |
| `chartText` | `#64748B` | Label axis chart |

---

# 6. Font Template

## 6.1 Font Family

Default font:

```txt
Inter
```

Fallback:

```txt
Roboto
```

## 6.2 Text Style Tokens

| Token | Size | Weight | Fungsi |
|---|---:|---:|---|
| `displayTitle` | 28 | 700 | Judul dashboard utama |
| `pageTitle` | 24 | 700 | Judul halaman |
| `sectionTitle` | 18 | 600 | Judul section |
| `cardTitle` | 16 | 600 | Judul card |
| `body` | 14 | 400 | Teks normal |
| `bodyMedium` | 14 | 500 | Teks normal lebih tegas |
| `caption` | 12 | 400 | Teks kecil, hint, metadata |
| `debugText` | 12 | 400 | Log/debug/register |

---

# 7. App Structure Draft

## 7.1 Simplified Main Navigation

App navigation disederhanakan menjadi 3 tab utama:

```txt
1. Home
2. Devices
3. Settings
```

Tujuannya supaya UI terasa ringan dan tidak membingungkan. Broker setup, master detail, control panel, debug, dan topic setting tetap ada, tapi tidak semuanya muncul sebagai menu utama.

Prinsip:

```txt
User biasa melihat Home.
Developer/config user masuk Devices atau Settings.
Debug hanya muncul sebagai advanced section.
```

---

## 7.2 Home

Home adalah halaman utama untuk memilih kelas/room dan melihat dashboard kontrol dari kelas tersebut.

Home flow:

```txt
Open app
  ↓
Home
  ↓
Choose classroom / room
  ↓
Room dashboard appears
  ↓
Show sensor summary + available controls
```

Home berisi:

| Area | Isi |
|---|---|
| Room/Class Selector | Pilih kelas atau ruangan yang ingin dilihat |
| Active Room Dashboard | Dashboard ringkas ruangan terpilih |
| Sensor Summary | Temperature, CO2, presence, sensor lain yang enabled |
| Control Panel | AC, projector, lampu sesuai config yang enabled |
| Stale Warning | Warning jika master atau sensor sudah stale/offline |

Rule:

```txt
Home only shows controls and info enabled from Devices configuration.
Home does not show raw MQTT, raw JSON, register, or debug log.
```

Jika belum ada master/room aktif:

```txt
Show AppEmptyState:
"No active room selected"
Button: Go to Devices
```

---

## 7.3 Devices

Devices adalah halaman untuk mengatur master apa saja yang ditemukan dari MQTT dan menentukan master/room mana yang muncul di Home.

Devices berisi:

| Area | Isi |
|---|---|
| MQTT Master Discovery List | Semua master yang muncul dari `smart-building/master/+/state` |
| Master Visibility Toggle | Pilih master mana yang ditampilkan di app |
| Display Name Setting | Rename master/room agar lebih human-readable |
| Info Visibility Setting | Pilih info apa saja yang muncul di Home |
| Control Visibility Setting | Pilih control apa saja yang aktif di Home |
| Master Detail Advanced | Firmware, device_id, network, slave list, stale status |
| Debug Advanced | Raw state JSON, last command JSON, MQTT RX/TX log |

Devices flow:

```txt
Devices
  ↓
Detected masters from MQTT
  ↓
Select master
  ↓
Set display name / room name
  ↓
Choose visible info and controls
  ↓
Save
  ↓
Master appears in Home room selector
```

Device config should include:

| Config | Fungsi |
|---|---|
| `showInHome` | Menentukan apakah master/room muncul di Home |
| `displayName` | Nama tampilan manual |
| `roomName` | Nama kelas/ruangan |
| `enabledSensors` | Sensor yang ditampilkan di Home |
| `enabledControls` | Control yang ditampilkan di Home |
| `debugEnabled` | Menampilkan advanced debug section untuk master ini |

Important rule:

```txt
Devices does not directly control the room.
Devices configures what Home is allowed to show/control.
```

---

## 7.4 Settings

Settings hanya untuk konfigurasi global app dan MQTT.

Settings berisi:

| Area | Isi |
|---|---|
| Broker Config | Host, port, username/password optional |
| Topic Config | State topic, command topic, preset/custom topic |
| MQTT Connection | Connect, disconnect, reconnect |
| Theme Config | Light/dark, color theme optional |
| App Behavior | Stale interval, auto reconnect, debug mode global |
| Import/Export Config | Backup app config |

Settings flow:

```txt
Settings
  ↓
Set broker + topic
  ↓
Connect MQTT
  ↓
App subscribes to state topic
  ↓
Devices receives discovered masters
```

Settings rule:

```txt
Settings handles connection and global behavior only.
Settings does not configure per-master display/control visibility.
```

---

## 7.5 Hidden / Nested Screens

Beberapa screen tetap ada secara internal, tapi tidak muncul sebagai main navigation.

| Internal Screen/Section | Dibuka Dari | Fungsi |
|---|---|---|
| `MasterDetailSection` | Devices > selected master | Detail firmware, device_id, network, slave |
| `DebugSection` | Devices > selected master > Advanced | Raw JSON, MQTT log, command preview |
| `ControlPanelSection` | Home > selected room | Kontrol AC, projector, lampu |
| `SensorGraphSection` | Home > selected room | Grafik sensor terhadap waktu |
| `BrokerSetupSection` | Settings | Konfigurasi broker MQTT |

Jadi secara code masih boleh modular, tapi secara UX tidak perlu jadi menu utama semua.

---

## 7.6 Simplified Navigation Summary

Final app navigation:

```txt
AppShell
├── Home
│   ├── Room/Class Selector
│   ├── Sensor Summary
│   ├── SensorGraph
│   └── Control Panel
│
├── Devices
│   ├── MQTT Master Discovery
│   ├── Master Visibility Config
│   ├── Display Name / Room Name Config
│   ├── Enabled Info / Control Config
│   └── Advanced Debug Section
│
└── Settings
    ├── MQTT Broker Config
    ├── MQTT Topic Config
    ├── App Behavior
    └── Theme / Config Backup
```

---

# 8. Architecture Direction

## 8.1 Device Philosophy

Slave device bersifat generic.

Slave tidak langsung dianggap sebagai lampu, sensor, relay, atau aktuator tertentu. Role device ditentukan oleh master melalui proses pairing/configuration.

## 8.2 Temporary Pairing Register

Untuk versi awal diskusi, pairing/config register sementara memakai:

```txt
0x00F0
0x00F1
```

Catatan: address ini bersifat sementara sampai architecture document final menentukan register map yang lebih proper.

## 8.3 UX Goal

App harus bisa dipakai oleh dua jenis user:

1. Normal user
   - Butuh kontrol cepat
   - Butuh status jelas
   - Tidak peduli raw register

2. Developer/debug user
   - Butuh register view
   - Butuh TX/RX log
   - Butuh command manual
   - Butuh state inspection

Maka UI harus punya dua lapisan:

```txt
Simple Control Layer
Advanced Debug Layer
```

---

# 9. Data Model Direction

## 9.1 Core App Models

Flutter app should have these core models:

| Model | Fungsi |
|---|---|
| `MqttConnectionConfig` | Broker host, port, username/password optional, topic preset/custom |
| `MasterState` | Parsed state payload dari satu master |
| `MasterRegistryItem` | Data ringkas master untuk list dan stale status |
| `NetworkState` | WiFi, LAN, MQTT priority/status |
| `SlaveInfo` | Address, UID, MAC, name, capability, enabled, relay count |
| `SensorData` | Temperature avg, temperature points, CO2, lux, human presence |
| `ControlState` | AC, projector, lights availability and current state |
| `LightChannelState` | Lamp channel id, name, power |
| `MasterCommand` | Command JSON yang akan dipublish ke selected master |
| `DebugLogEntry` | MQTT RX/TX/malformed/error log |

## 9.2 State Management Requirement

App state minimal dibagi menjadi:

```txt
MqttConnectionState
MasterRegistryState
ActiveMasterState
ControlCommandState
DebugLogState
```

Tujuan pembagian ini supaya UI, MQTT logic, dan command builder tidak saling campur seperti kabel jumper habis dipinjam satu angkatan lab.

---

# 10. MQTT UX Flow

## 10.1 First Launch Flow

```txt
Open app
  ↓
If broker not configured:
  Settings > Broker Config
  ↓
Connect MQTT
  ↓
App subscribes to state topic
  ↓
Devices discovers masters
  ↓
User enables master and assigns room/class name
  ↓
Home shows room/class selector
  ↓
User selects room/class
  ↓
Dashboard and control panel appear
```

## 10.2 Command Flow

```txt
User changes control
  ↓
Build explicit final-state command JSON
  ↓
Generate unique command_id
  ↓
Publish to selected master command topic
  ↓
Show pending/optimistic UI carefully
  ↓
Wait for next state publish
  ↓
Update UI from new state
```

## 10.3 Debug Flow

DebugScreen should show:

- MQTT connection status
- Subscribed topic
- Selected master command topic
- Last received raw state JSON
- Last sent command JSON
- Malformed JSON errors
- TX/RX timestamp
- Selected master stale/offline status

---

# 11. Control Visibility Rules

## 11.1 AC

Show `AcControlPanel` only if:

```txt
controls.ac.available == true
```

If unavailable:

```txt
Hide control from main dashboard
Optionally show disabled item in debug/detail only
```

## 11.2 Projector

Show `ProjectorControlPanel` only if:

```txt
controls.projector.available == true
```

## 11.3 Lights

Source of truth:

```txt
controls.lights.channels
```

Rules:

```txt
If lights.available != true:
  hide lamp controls

If channel count == 1:
  show one large LampChannelControl

If channel count is 2..4:
  show one LampChannelControl per channel

AllLampAction is allowed only as explicit user action
```

---

# 12. Sensor Display Rules

## 12.1 Temperature

Display average temperature from:

```txt
data.temperature.avg_c
```

Plot temperature points/history using:

```txt
SensorGraph
MiniSensorGraph
```

## 12.2 CO2

Display CO2 only if value is not `null`.

```txt
data.co2_ppm
```

## 12.3 Human Presence

Display as status badge:

```txt
data.human_presence == true  -> Present
data.human_presence == false -> Not Present
data.human_presence == null  -> Unknown
```

## 12.4 Invalid Sensor Values

Rules:

```txt
null = unavailable/stale
placeholder value like -100 = invalid, do not display as real data
```


