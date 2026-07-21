# Tali Silsilah

Frontend Flutter untuk mengelola dan menampilkan silsilah keluarga Bani KH Ibrohim Ghozali. Aplikasi menggunakan REST API eksternal sebagai sumber data utama dan autentikasi berbasis NIT.

## Gambaran Project

- Jenis: aplikasi Flutter lintas platform, dengan Android sebagai target utama.
- Repository: frontend saja; backend tidak berada di repository ini.
- State management: `Provider` dan `ChangeNotifier`.
- HTTP client: `Dio`.
- Routing: `GoRouter`.
- Model generation: `Freezed` dan `json_serializable`.
- Visualisasi silsilah: `GraphView`.
- Penyimpanan sesi: `SharedPreferences`.

## Fitur

- Login menggunakan NIT dan password keluarga.
- Pemulihan session ketika aplikasi dibuka kembali.
- Daftar dan pencarian seluruh anggota dalam keluarga yang sama.
- Visualisasi pohon keluarga per cabang.
- Tambah, edit, dan hapus pasangan sesuai hak akses pengguna.
- Tambah, edit, dan hapus keturunan sesuai hak akses pengguna.
- Pemilihan marriage asal ketika menambahkan anak.
- Pembuatan NIT anak secara otomatis di frontend.
- Edit profil dan foto anggota yang sedang login.
- Tampilan pasangan, anak, dan cucu pada detail anggota.
- Export data keluarga ke dokumen Excel.

## Aturan Domain Penting

### Identitas pengguna

- Identitas aktor selalu berasal dari bearer token hasil login.
- ID dari route hanya digunakan untuk memilih data target, bukan menentukan siapa pengguna yang sedang login.
- Pengguna dapat mengelola dirinya, pasangan miliknya, dan seluruh keturunannya.
- Pengguna tidak dapat mengubah ancestor atau cabang saudara.
- Data diri pengguna yang login sengaja tidak ditampilkan dalam Daftar Keluarga. Pengelolaan pasangan sendiri dapat dibuka dari Beranda.

### NIT dan `family_tree_id`

Keduanya memiliki fungsi berbeda dan tidak boleh dipertukarkan.

- `nit` adalah nomor resmi keturunan, misalnya `1`, `1.1`, dan `1.1.1`.
- `family_tree_id` adalah identifier struktur pohon yang sepenuhnya dibuat backend.
- Angka `0` pada `family_tree_id` menandai struktur pasangan dan bukan bagian dari aturan NIT.
- Flutter tidak membuat atau mengirim `family_tree_id`, `level`, `child_order`, `parent_id`, atau `marriage_order` ketika menambahkan anak.

Generator NIT di frontend bersifat sementara. NIT berikutnya dihitung dari suffix terbesar seluruh anak langsung milik parent pada semua marriage. Ketika backend sudah menghasilkan NIT, logika terpusat di `NitGeneratorService` dapat dilepas tanpa mengubah widget.

## Struktur Repository

```text
lib/
  components/        Widget reusable dan dialog bersama
  config/            Environment, theme, dan konfigurasi Dio
  core/              Service dan utilitas lintas fitur
  data/
    models/          DTO API dan generated model
    provider/        Shared state dan UI-scoped ChangeNotifier
    repository/      Request API dan mapping error
  views/             Halaman dan alur UI
test/
  components/        Widget test
  core/              Unit test service dan permission
  data/              Test kontrak repository/API
android/ ios/ web/   Runner platform Flutter
```

## Alur Data

```text
Widget/View
    -> Provider
        -> Repository
            -> Config.dio
                -> REST API
```

Response berjalan kembali melalui repository dan provider sebelum dirender widget. Request berstatus `401` membersihkan session dan mengarahkan pengguna ke login. Respons `403` diperlakukan sebagai penolakan izin dan tidak otomatis menghapus session.

State tampilan yang berubah menggunakan provider lokal atau shared provider. Project saat ini tidak menggunakan `setState`. `TextEditingController` tetap boleh dipakai, tetapi lifecycle-nya harus dimiliki widget atau provider yang hidup selama field terkait masih berada di widget tree.

## Prasyarat

- Flutter SDK yang mendukung Dart `^3.9.2`.
- Android Studio dan Android SDK untuk build Android.
- Emulator atau perangkat Android untuk menjalankan aplikasi.
- Backend API yang dapat diakses dari perangkat pengembangan.

Periksa instalasi:

```bash
flutter doctor
flutter --version
```

## Setup Project

1. Clone repository dan masuk ke folder project.
2. Install dependency:

   ```bash
   flutter pub get
   ```

3. Buat `.env` dari template.

   PowerShell:

   ```powershell
   Copy-Item .env.example .env
   ```

   Bash:

   ```bash
   cp .env.example .env
   ```

4. Sesuaikan URL API untuk environment pengembangan.
5. Generate ulang model jika file Freezed atau JSON model berubah:

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. Jalankan aplikasi:

   ```bash
   flutter run --dart-define-from-file=.env
   ```

## Environment

Project menggunakan compile-time configuration bawaan Flutter melalui `--dart-define-from-file`. Package dotenv tidak digunakan.

| Key | Wajib | Sensitif | Keterangan |
| --- | --- | --- | --- |
| `APP_NAME` | Ya | Tidak | Nama aplikasi yang ditampilkan. |
| `APP_ENV` | Ya | Tidak | Nama environment, misalnya `development` atau `production`. |
| `API_BASE_URL` | Ya | Tidak* | Base URL REST API tanpa trailing slash. |
| `API_STORAGE_URL` | Ya | Tidak* | Base URL file/avatar dengan trailing slash. |
| `NETWORK_TIMEOUT_SECONDS` | Ya | Tidak | Timeout Dio dalam detik. |

`*` URL bukan credential, tetapi URL internal tetap jangan dipublikasikan jika infrastrukturnya memang privat.

Jangan menaruh nilai berikut dalam `.env.example`, source code, atau dokumentasi:

- password keluarga;
- bearer token hasil login;
- API key privat;
- private key atau signing key;
- credential service eksternal.

Bearer token diperoleh saat login dan disimpan oleh mekanisme session aplikasi. Token bukan build configuration.

Setiap perubahan `.env` memerlukan restart atau rebuild karena nilainya dibaca saat kompilasi.

## Command Development

Format source dan test:

```bash
dart format lib test
```

Static analysis:

```bash
flutter analyze
```

Menjalankan seluruh test:

```bash
flutter test
```

Menjalankan satu test:

```bash
flutter test test/components/family_edit_dialog_test.dart
```

Build APK debug:

```bash
flutter build apk --debug --dart-define-from-file=.env
```

Build APK release:

```bash
flutter build apk --release --dart-define-from-file=.env
```

## Routing Utama

Route didefinisikan di `lib/main.dart`.

| Route | Fungsi |
| --- | --- |
| `/login` | Login dengan NIT. |
| `/home` | Beranda dan akses kelola keluarga sendiri. |
| `/family-search` | Daftar dan pencarian keluarga. |
| `/member/:memberId` | Detail anggota, pasangan, anak, cucu, dan aksi CRUD. |
| `/add-family` | Form tambah pasangan. |
| `/add-family-member` | Form tambah anak. |
| `/tree-visual` | Visualisasi pohon keluarga. |
| `/profile` | Profil anggota login dan export Excel. |
| `/profile-edit` | Edit profil anggota login. |

Gunakan named route dan parameter URL untuk identifier penting. Hindari menjadikan `state.extra` sebagai satu-satunya sumber data halaman karena nilainya tidak tahan refresh atau deep link.

## Konvensi Pengembangan

- File menggunakan `snake_case.dart`.
- Class menggunakan `PascalCase`.
- Variable dan method menggunakan `camelCase`.
- Request API hanya dilakukan melalui repository.
- Gunakan `Config.dio` agar bearer token dan penanganan `401` konsisten.
- Shared state ditempatkan di `lib/data/provider/`.
- State form/dialog yang terisolasi menggunakan provider lokal agar rebuild terbatas.
- Jangan menyimpan `BuildContext` di provider.
- Provider yang memiliki controller wajib melakukan `dispose` terhadap controller tersebut.
- Setelah mengubah model Freezed, jalankan `build_runner` dan commit generated file yang berubah.
- Pertahankan kontrak NIT, identifier struktur, dan response API yang sudah digunakan aplikasi.

## Testing yang Perlu Dipertahankan

Test saat ini mencakup:

- urutan auto-generate NIT;
- pembatasan akses berdasarkan hubungan NIT;
- payload create child dan create marriage;
- larangan pengiriman field struktur dari frontend;
- penggunaan NIT dan `family_tree_id` final dari response backend;
- lifecycle dialog edit ketika keyboard aktif dan tombol Batal ditekan.

Sebelum menyerahkan perubahan, minimal jalankan:

```bash
flutter analyze
flutter test
```

Untuk perubahan routing, plugin, konfigurasi platform, atau dependency, tambahkan verifikasi build Android.

## Security dan File Lokal

File berikut sudah diabaikan Git dan tidak boleh di-commit:

- `.env` dan variasinya selain `.env.example`;
- `key.properties`;
- file `*.jks`, `*.keystore`, `*.p8`, `*.p12`, dan `*.pem`;
- `android/app/google-services.json`;
- `ios/Runner/GoogleService-Info.plist`.

Jika integrasi baru membutuhkan secret, tambahkan key konfigurasi yang sesuai, buat placeholder aman di `.env.example`, dan pastikan file bernilai nyata tetap diabaikan Git.

## Batasan Saat Ini

- Backend API harus tersedia; repository ini tidak menyediakan server lokal.
- Auto-generate NIT masih dilakukan frontend sehingga pembuatan serentak dari beberapa perangkat tetap dapat mengalami konflik unique NIT. Backend tetap menjadi validator akhir.
- Penghapusan marriage yang masih memiliki anak ditolak oleh kontrak API. Hapus atau pindahkan relasi anak terlebih dahulu.
- Kredensial test tidak disediakan dalam repository.
