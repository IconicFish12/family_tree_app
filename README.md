# Tali Silsilah

Frontend Flutter untuk mengelola dan menampilkan silsilah Dzurriyah Bani KH. Ibrohim Ghozali. Aplikasi memakai REST API sebagai sumber kebenaran untuk identitas anggota, relasi parent-child, pernikahan, dan struktur pohon.

## Ringkasan

- Jenis project: aplikasi Flutter lintas platform; Android adalah target utama.
- Arsitektur data: View/Form → `ChangeNotifier` Provider → Repository → Dio → REST API → `Either<Failure, T>` → Provider → UI.
- Autentikasi: NIT, password, dan `device_name`.
- Routing: GoRouter.
- Visualisasi: GraphView dengan layout Buchheim-Walker.
- Penyimpanan sesi: SharedPreferences.
- Model generated: Freezed dan `json_serializable`.

Repository ini hanya berisi frontend. Backend Laravel, dokumentasi API, Postman Collection, serta data PDF silsilah dikelola sebagai sumber terpisah.

## Fitur Utama

- Login anggota inti menggunakan NIT.
- Pemulihan sesi dan validasi profil ketika aplikasi dibuka kembali.
- Daftar, pencarian, detail, edit, dan penghapusan anggota dalam connected family.
- Tambah pasangan dengan peran anggota yang eksplisit: suami atau istri.
- Peran pertama anggota dikunci pada seluruh riwayat pernikahannya: suami dapat
  mempunyai beberapa istri, sedangkan istri hanya dapat mempunyai satu suami.
- Validasi role dilakukan ulang dari response marriage terbaru sebelum create;
  data legacy atau role yang sudah bercampur diblokir agar relasi tidak semakin
  bias.
- Tambah anak kandung yang wajib terkait pernikahan.
- Tambah anak adopsi dengan atau tanpa kaitan ke pernikahan.
- NIT anak, `family_tree_id`, level, dan urutan relasi dibuat oleh backend.
- Gender person nullable: laki-laki, perempuan, atau belum diisi.
- Pernikahan legacy tetap terbaca tanpa menebak role.
- Metadata kepala keluarga ditampilkan berdasarkan participant marriage yang ditunjuk backend.
- Pohon keluarga rekursif untuk `marriages[].children` dan `adopted_children`.
- Detail pasangan, anak, cucu, dan status kegagalan pemuatan yang dapat dicoba ulang.
- Edit profil serta avatar pengguna yang sedang login.
- Export data keluarga ke Excel.

## Kontrak Domain

### Identifier

Identifier berikut tidak boleh dipertukarkan:

| Field | Fungsi |
| --- | --- |
| `user_id` | Identitas stabil person untuk route, self-check, dan target mutation. |
| `nit` | Nomor resmi anggota inti dan credential login; spouse eksternal dapat tidak mempunyai NIT. |
| `family_tree_id` | Posisi teknis/visual yang sepenuhnya dikelola backend dan dapat berubah saat struktur dikoreksi. |
| `marriage_id` | Identitas marriage. |
| `relation_id` | Identitas relasi parent-child. |

Frontend tidak membuat NIT atau `family_tree_id`, tidak menghitung identifier dari urutan, dan tidak menyimpulkan authorization dari prefix NIT. Backend adalah sumber akhir untuk authorization dan dapat mengembalikan `403` tanpa membuat sesi pengguna logout.

### Person dan gender

Nilai API untuk gender:

| API | UI |
| --- | --- |
| `male` | Laki-laki |
| `female` | Perempuan |
| `null` | Belum diisi/Belum diketahui |

Gender tidak pernah ditebak dari nama, gelar, NIT, posisi node, role pernikahan, atau data PDF.

### Relasi anak

Nilai `relationship_type`:

| API | UI | Aturan |
| --- | --- | --- |
| `biological` | Anak Kandung | `marriage_id` wajib. |
| `adopted` | Anak Adopsi | `marriage_id` opsional. |

Payload create child hanya berisi fakta yang diizinkan:

```json
{
  "relationship_type": "biological",
  "marriage_id": 10,
  "full_name": "Nama Anak",
  "gender": null,
  "address": null,
  "birth_year": null
}
```

Untuk adopsi personal, `marriage_id` tidak dikirim. Response backend menentukan NIT, `family_tree_id`, `relation_id`, `lineage_order`, dan `child_order` final.

### Pernikahan

`member_role` selalu merupakan role person yang menjadi perspektif response, bukan asumsi bahwa kolom member selalu suami. `spouse_role` adalah role participant lain.

| API | UI |
| --- | --- |
| `husband` | Suami |
| `wife` | Istri |
| `null` | Belum diklasifikasikan |

Payload create marriage:

```json
{
  "member_role": "husband",
  "spouse": {
    "full_name": "Nama Pasangan",
    "gender": null,
    "address": null,
    "birth_year": null
  }
}
```

Frontend tidak mengirim `spouse_role`, `spouse_id`, `marriage_order`, structural ID, ataupun metadata kepala keluarga.

#### Kebijakan konsistensi role

Sebelum form pasangan diaktifkan, frontend memuat ulang seluruh response
`GET /family-members/{id}/marriages`. Semua status marriage ikut dihitung;
frontend tidak menganggap record `divorced` sebagai record yang sudah hilang.

| Kondisi history anggota | Perilaku frontend |
| --- | --- |
| Belum mempunyai marriage | Pengguna wajib memilih Suami atau Istri dengan peringatan bahwa pilihan pertama akan dikunci. |
| Seluruh marriage classified sebagai Suami | Role otomatis Suami dan tidak dapat diubah; pasangan Istri berikutnya boleh ditambahkan. |
| Sudah mempunyai marriage classified sebagai Istri | Role otomatis Istri dan form pasangan baru diblokir. |
| Role anggota bercampur Suami dan Istri | Create pasangan dan anak baru diblokir; detail/tree menampilkan peringatan konflik. |
| Ada marriage legacy atau metadata role tidak lengkap | Create pasangan dan anak baru diblokir sampai data lama dirapikan. |
| History gagal dimuat | Form diblokir dan menampilkan aksi coba lagi; kegagalan tidak dianggap sebagai list kosong. |

Role tidak pernah diinferensikan dari gender. Gender yang sudah diketahui hanya
dipakai sebagai validasi kompatibilitas tambahan. Untuk mengubah klasifikasi
role setelah anggota mempunyai keluarga, hapus data anak pada marriage terkait
terlebih dahulu, lalu hapus seluruh data pasangannya, dan buat ulang relasi
dengan role yang benar. Urutan ini juga dijelaskan langsung pada UI untuk
mencegah pengguna mengubah struktur tanpa memahami akibatnya.

Frontend melakukan pemeriksaan yang sama lagi di `UserProvider` tepat sebelum
request create marriage. Pemeriksaan ini melindungi seluruh caller aplikasi,
dan mutation pasangan/anak diserialkan supaya dua ketukan cepat tidak memakai
snapshot history kosong yang sama. `forceRefresh` menunggu request marriage
yang sedang berjalan lalu benar-benar mengambil response baru sebelum mutation.
Form anak juga memakai policy yang sama: conflict/legacy memblokir biological,
adopted terkait marriage, maupun adopted personal. Jika endpoint marriage gagal
dimuat, adopted personal tetap dapat dibuat karena kontraknya tidak memerlukan
`marriage_id`; kegagalan tersebut tetap ditampilkan dan pemeriksaan diulang saat
submit.

Proteksi frontend mengurangi risiko dari satu instance aplikasi, tetapi
invariant lintas request yang benar-benar atomik tetap perlu ditegakkan backend.
Backend saat ini masih perlu ditingkatkan agar menolak mixed role pada
person bergender `null`; frontend menandai data lama semacam itu sebagai konflik
dan tidak menampilkannya seolah kondisi yang sah.

Marriage lama dengan `is_role_classified: false` tetap ditampilkan bersama spouse dan children. Aksi klasifikasi belum disediakan karena endpoint mutation saat ini memakai sisi canonical marriage sedangkan response publik diorientasikan terhadap person yang dilihat; tanpa canonical owner yang eksplisit, UI berisiko mengklasifikasikan participant yang salah.

### Struktur tree

```text
person
├── marriages[]
│   ├── spouse
│   └── children[]
└── adopted_children[]
```

- Child dalam `marriages[].children` tetap dikelompokkan pada marriage asalnya.
- `adopted_children` adalah adopsi personal tanpa marriage dan diproses pada setiap level secara rekursif.
- Cabang adopsi personal memakai branch presentasional sendiri, bukan marriage palsu.
- Layout Buchheim-Walker, zoom/pan, history subtree, dan batas tiga level visual dipertahankan.
- Badge kepala keluarga hanya mengikuti `family_head_position`; metadata tersebut bukan sumber authorization.
- Node dengan role anggota yang bercampur menampilkan badge `Konflik peran`,
  bukan badge Suami dan Istri sekaligus. Badge kepala keluarga agregat tidak
  ditampilkan pada data conflict/legacy agar visual tidak memberi kesan bahwa
  relasi tersebut sudah valid.

### Detail anak dan cucu

Detail anggota menggabungkan tiga response backend berdasarkan `user_id` dan
`relation_id`:

- `GET /family-members/{id}` untuk fakta person dan `parent_relation`;
- `GET /family-members/{id}/marriages` untuk pasangan serta child yang terkait
  marriage;
- `GET /family-tree` untuk `adopted_children` personal dengan
  `marriage_id: null` pada node yang berada di subtree actor.

Child hasil gabungan diurutkan memakai `lineage_order` dari backend dan tidak
pernah dideduplikasi memakai NIT atau `family_tree_id`. Cabang adopsi personal
juga digabungkan saat menampilkan cucu. Jika node tidak tersedia pada actor
subtree atau tree gagal dimuat, detail menampilkan status yang dapat dicoba
ulang dan tidak menyatakan bahwa jumlah anak adalah nol. Penghapusan anggota
dinonaktifkan sampai kelengkapan cabang tersebut dapat dipastikan.

## Struktur Repository

```text
lib/
  components/        Widget dan dialog reusable
  config/            Environment, tema, dan konfigurasi Dio
  core/              Session serta utilitas lintas fitur
  data/
    models/          DTO API, enum kontrak, dan generated model
    provider/        Shared dan UI-scoped ChangeNotifier
    repository/      Request REST, parsing, dan Failure mapping
  views/             Halaman serta form aplikasi
test/
  components/        Widget test komponen
  data/              Test model, repository, dan provider
  views/             Widget test tree dan detail anggota
android/ ios/ web/   Flutter platform runners
```

State UI yang berubah dikelola melalui Provider/`ChangeNotifier`. Widget boleh tetap `StatefulWidget` untuk lifecycle controller, tetapi tidak menggunakan `setState` untuk state aplikasi atau form.

## Environment

Konfigurasi dibaca saat kompilasi dengan `--dart-define-from-file`; package dotenv tidak digunakan.

| Key | Wajib | Keterangan |
| --- | --- | --- |
| `APP_NAME` | Ya | Nama aplikasi. |
| `APP_ENV` | Ya | Environment, misalnya `development` atau `production`. |
| `API_BASE_URL` | Ya | Base URL REST API tanpa trailing slash. |
| `API_STORAGE_URL` | Ya | Base URL avatar/storage; trailing slash disarankan. |
| `NETWORK_TIMEOUT_SECONDS` | Ya | Timeout koneksi Dio dalam detik. |

Perubahan kontrak silsilah tidak membutuhkan key environment baru. `.env` dan `.env.example` harus mempunyai lima key di atas.

Salin template:

```powershell
Copy-Item .env.example .env
```

atau:

```bash
cp .env.example .env
```

Jangan menyimpan password, bearer token, API key privat, private key, atau credential lain di file environment, source code, test, maupun dokumentasi. `.env` lokal diabaikan Git; hanya `.env.example` yang boleh di-commit.

## Setup

Prasyarat:

- Flutter SDK dengan Dart yang memenuhi `^3.9.2`.
- Android Studio/Android SDK untuk menjalankan target Android.
- Backend API yang dapat dijangkau perangkat atau emulator.

Install dependency:

```bash
flutter pub get
```

Jika source model Freezed atau JSON berubah, sinkronkan generated file:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Jalankan aplikasi:

```bash
flutter run --dart-define-from-file=.env
```

## Route Aktif

| Route | Fungsi |
| --- | --- |
| `/login` | Login NIT/password. |
| `/home` | Beranda. |
| `/family-search` | Direktori dan pencarian connected family. |
| `/member/:memberId` | Detail authoritative berdasarkan `user_id`. |
| `/add-family` | Tambah marriage/pasangan. |
| `/add-family-member` | Tambah child kandung/adopsi. |
| `/tree-visual` | Pohon actor subtree. |
| `/profile` | Profil actor dan export. |
| `/profile-edit` | Edit fakta profil dan avatar. |

Route internal memakai `user_id`, bukan NIT atau `family_tree_id`. Route `/family-info` dipertahankan sebagai compatibility entry point dan meneruskan tampilan ke detail anggota authoritative.

## Penanganan Error

- `400/422`: pesan validasi field backend diteruskan ke UI; sesi tidak dihapus.
- `401`: session dibersihkan melalui handler autentikasi existing.
- `403`: ditampilkan sebagai penolakan izin; tidak logout otomatis.
- `404`: data target tidak ditemukan.
- `409`: konflik struktur, misalnya record masih dipakai oleh relasi lain.
- Timeout/network error: tampilkan pesan dan retry; jangan mengubah error menjadi empty state.

Mutation yang gagal tidak mengubah cache seolah berhasil. Mutation yang berhasil menginvalidasi state terkait, memuat ulang direktori/detail bila dibutuhkan, dan menyegarkan tree bila tree sudah pernah dibuka.

Provider detail dan tree memakai request epoch agar response lama tidak dapat
menimpa refresh terbaru. `TreeProvider.reset()` menginvalidasi request aktif
saat sesi dibersihkan, sedangkan refresh tree mempertahankan current subtree
dan history berdasarkan `user_id` selama node tersebut masih tersedia.

## Development dan Verifikasi

Format:

```bash
dart format lib test
```

Static analysis:

```bash
flutter analyze
```

Seluruh test:

```bash
flutter test
```

Test terfokus:

```bash
flutter test test/data/family_model_parsing_test.dart
flutter test test/data/user_repository_contract_test.dart
flutter test test/data/provider/family_member_form_provider_test.dart
flutter test test/data/provider/member_detail_provider_test.dart
flutter test test/data/provider/tree_provider_test.dart
flutter test test/views/family_data/member_info_test.dart
flutter test test/views/family_data/tree_visual_test.dart
```

Pemeriksaan whitespace diff:

```bash
git diff --check
```

Build debug Android:

```bash
flutter build apk --debug --dart-define-from-file=.env
```

Build release tidak diperlukan untuk perubahan kontrak frontend biasa dan hanya dijalankan pada alur rilis.

## Konvensi Pengembangan

- File: `snake_case.dart`; class: `PascalCase`; member: `camelCase`.
- API call hanya melalui repository dan `Config.dio`.
- Pertahankan `Either<Failure, T>` untuk hasil repository.
- Shared state dan local form state memakai Provider/`ChangeNotifier`.
- Provider tidak menyimpan `BuildContext`.
- Provider/controller wajib di-`dispose` oleh pemilik lifecycle-nya.
- Gunakan `Consumer`, `Selector`, atau `context.select` untuk rebuild terbatas.
- Edit source Freezed, lalu jalankan generator; jangan mengedit `*.freezed.dart` atau `*.g.dart` secara manual.
- Parser harus toleran terhadap nullable, extra field, spouse null, list kosong, dan marriage legacy.
- Jangan menyimpulkan relationship, gender, role, ownership, atau permission dari nama, NIT, `family_tree_id`, maupun posisi visual.
- Pertahankan GraphView, layout, history/subtree, dan visual level limit existing kecuali ada task khusus untuk redesign.

## Cakupan Test Kontrak

Test terfokus meliputi:

- parsing gender nullable, marriage classified/legacy, spouse null, metadata head, child biological/adopted, serta recursive `adopted_children`;
- perbedaan NIT dan `family_tree_id`;
- payload create child tanpa NIT/structural field;
- payload create marriage dengan `member_role` dan tanpa `spouse_role`/`spouse_id`;
- pemilihan pesan validasi `422` dari `errors.*`;
- marriage loading error yang tetap berbeda dari empty success;
- biological wajib marriage dan adopted dapat tanpa marriage;
- role/gender compatibility, penguncian role, wife-one-husband, mixed-role,
  legacy/incomplete metadata, serta revalidasi sebelum submit marriage;
- serialisasi submit pasangan, force-refresh yang tidak memakai request lama,
  serta pemblokiran child baru pada history conflict/legacy;
- subtree/history, multiple marriage, cabang adopsi, legacy label, dan family-head badge pada tree;
- detail member authoritative, retry pemuatan descendant, adopted-only delete guard, serta perlindungan stale response/reset.

## Batasan yang Diketahui

- Backend wajib tersedia; repository ini tidak menyediakan server lokal.
- Login spouse eksternal dengan NIT null tidak termasuk cakupan aplikasi.
- Klasifikasi role marriage legacy masih display-only sampai kontrak backend menyediakan orientasi canonical yang aman untuk mutation frontend.
- Backend belum menyediakan endpoint collection direct-child untuk arbitrary member. `GET /family-tree` hanya mencakup subtree actor; detail memberi status tidak tersedia bila target berada di luar subtree tersebut, bukan empty state palsu.
- PDF silsilah 2022 adalah konteks/provenance data keluarga, bukan sumber inferensi runtime.
- Avatar hanya dapat diubah melalui profil actor; upload avatar spouse/child tidak termasuk fitur ini.
