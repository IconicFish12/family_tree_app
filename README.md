# Tali Silsilah

Aplikasi Flutter untuk login berbasis token, pengelolaan data keluarga, pencarian anggota keluarga, dan visualisasi pohon keluarga berbasis API eksternal.

## Ringkasan

- Jenis project: Flutter app lintas platform, mobile-first
- Repository ini berisi frontend saja
- Backend berada di luar repository dan diakses melalui REST API
- State management utama: `Provider`
- Networking utama: `Dio`
- Routing utama: `GoRouter`
- Visualisasi tree: `GraphView`

## Fitur Utama

- Login berbasis credential token
- Restore session saat aplikasi dibuka ulang
- Auto logout ketika token invalid, expired, `401`, atau `403`
- Daftar keluarga dan pencarian anggota keluarga
- Tambah pasangan
- Tambah anak dengan pemilihan cabang pasangan
- Edit profil anggota login
- Visualisasi pohon keluarga dengan batas tampilan 3 tingkat per cabang

## Tech Stack

- Flutter
- Dart
- Provider
- Dio
- GoRouter
- GraphView
- Freezed
- json_serializable
- Shared Preferences

## Struktur Folder

```text
lib/
  components/        widget reusable
  config/            theme, environment, dio config
  core/              util app-level
  data/
    models/          DTO dan helper model
    provider/        app state dan UI-scoped state
    repository/      akses API dan mapping failure
  views/             halaman dan flow UI
test/                test Flutter
android/ ios/ ...    platform runner Flutter
```

## Setup Environment

Project ini menggunakan `--dart-define-from-file` bawaan Flutter. Tidak ada package dotenv tambahan.

### File environment

- `.env`: file lokal developer, tidak boleh di-commit
- `.env.example`: template aman untuk repository

### Variabel yang dipakai

```env
APP_NAME=Tali Silsilah
APP_ENV=development
API_BASE_URL=https://api-alusrah.oproject.id/api
API_STORAGE_URL=https://api-alusrah.oproject.id/storage/
NETWORK_TIMEOUT_SECONDS=20
```

### Langkah awal

1. Pastikan file `.env` tersedia di root project.
2. Jika belum ada, gunakan `.env.example` sebagai acuan.
3. Jalankan app dengan `--dart-define-from-file=.env`.

## Command

### Install dependency

```bash
flutter pub get
```

### Generate file model

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run development

```bash
flutter run --dart-define-from-file=.env
```

### Build Android release

```bash
flutter build apk --release --dart-define-from-file=.env
```

### Analyze

```bash
flutter analyze
```

### Test

```bash
flutter test
```

## Arsitektur Existing

Project ini memakai layered architecture ringan, bukan clean architecture penuh.

- `views`: render UI, event UI, controller input
- `provider`: state management dan orchestration antar layer
- `repository`: komunikasi API
- `models`: DTO response/request dan helper model
- `config`: theme, environment, dan konfigurasi `Dio`

## Aturan Development

### Penamaan

- File: `snake_case.dart`
- Class: `PascalCase`
- Variable dan method: `camelCase`

### State management

- Shared state masuk ke `lib/data/provider/`
- UI state yang memengaruhi tampilan sebaiknya juga dipindah ke provider/notifier kecil
- Hindari `setState` untuk state yang bisa dipisah dengan jelas
- `TextEditingController`, `FocusNode`, dan lifecycle widget boleh tetap berada di `StatefulWidget`
- Gunakan `context.select`, `Consumer`, atau provider lokal agar rebuild lebih sempit

### API dan konfigurasi

- Jangan hardcode base URL baru di file lain
- Semua request API sebaiknya lewat repository
- Gunakan `Config.dio` agar token dan unauthorized handler tetap konsisten
- Gunakan environment melalui `AppEnvironment`, bukan hardcoded string baru

### Widget dan screen

- `components/` hanya untuk widget reusable
- Jika sebuah screen mulai memegang terlalu banyak state UI, pecah ke provider/notifier terpisah
- Usahakan satu screen hanya fokus pada satu flow utama

### Routing

- Gunakan route name dari `GoRouter`
- Hati-hati dengan `state.extra`
- Jika mengubah shape `extra`, cek semua caller dan destination route

## Auth Flow

1. User login dengan credential
2. Token disimpan lokal
3. Semua request API menggunakan bearer token otomatis
4. Jika API mengembalikan `401` atau `403`, session dibersihkan dan user diarahkan kembali ke login

## Area Sensitif

Ubah dengan hati-hati:

- `lib/config/app_environment.dart`
- `lib/config/config.dart`
- `lib/data/provider/auth_provider.dart`
- `lib/data/provider/user_provider.dart`
- `lib/data/provider/tree_provider.dart`
- model API di `lib/data/models/`
- route utama di `lib/main.dart`

## File Sensitif yang Tidak Boleh Masuk Git

Sudah diatur di `.gitignore`, terutama:

- `.env`
- `.env.*` selain `.env.example`
- `key.properties`
- `*.jks`
- `*.keystore`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Jika ada file credential baru, update `.gitignore` sebelum file itu dipakai.

## Catatan untuk Developer Baru

- Repository ini adalah frontend client
- API adalah source of truth utama
- Sebelum refactor besar, cek route aktif dan provider yang dipakai
- Jika mengubah model `Freezed`, jalankan ulang `build_runner`
- Jangan ubah kontrak API tanpa cek provider, repository, dan UI yang bergantung padanya

## Command Cepat

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=.env
flutter analyze
flutter test
```
