# Asset Management

## Folder Structure

```
assets/
├── images/          # Gambar umum (logo, icon, background, dll)
│   ├── logo.png
│   ├── bg_*.png
│   └── icon_*.png
└── photos/          # Foto anggota keluarga
    ├── members/
    │   ├── topan_namas.jpg
    │   ├── sinta_suke.jpg
    │   └── ...
    └── families/
        ├── keluarga_utama.jpg
        └── ...
```

## Cara Menggunakan Asset di Code

### 1. Untuk Foto Lokal (Asset Image)
```dart
Image.asset('assets/photos/members/topan_namas.jpg')
```

### 2. Untuk Foto dari Network/URL
```dart
Image.network('https://example.com/photo.jpg')
```

### 3. Menggunakan MemberAvatar Widget

```dart
// Dengan foto lokal
MemberAvatar(
  photoUrl: 'assets/photos/members/topan_namas.jpg',
  emoji: '👨',
  size: 50,
)

// Dengan foto network
MemberAvatar(
  photoUrl: 'https://example.com/photo.jpg',
  emoji: '👨',
  size: 50,
)

// Tanpa foto (fallback ke emoji)
MemberAvatar(
  emoji: '👨',
  size: 50,
)
```

## Catatan Penting

- **assets/images/** : Untuk aset umum aplikasi (logo, background, icon)
- **assets/photos/members/** : Untuk foto anggota keluarga individual
- **assets/photos/families/** : Untuk foto keluarga group (opsional)
- Semua asset sudah di-configure di `pubspec.yaml`
- Gunakan `Image.asset()` untuk asset lokal
- Gunakan `Image.network()` untuk foto dari server/API

## Format Foto yang Disupport
- JPG/JPEG
- PNG
- WebP
- GIF

## Rekomendasi Ukuran
- Avatar member: 200x200px minimum
- Background: 1920x1080px atau lebih
- Logo: 512x512px
