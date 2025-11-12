# 🖼️ Asset Image Setup Guide

## Status: ✅ CONFIGURED

Folder `assets/` sudah di-konfigurasi di `pubspec.yaml`

```yaml
flutter:
  assets:
    - assets/images/
    - assets/photos/
```

## File yang Diharapkan

```
assets/
├── images/
│   └── family_logo.png  ← File gambar yang sedang digunakan
└── photos/
    └── (untuk foto anggota keluarga nanti)
```

## Troubleshooting: Gambar Tidak Muncul

Jika gambar tidak muncul di aplikasi, lakukan:

### Option 1: Clean & Rebuild (Rekomendasi)
```bash
flutter clean
flutter pub get
flutter run
```

### Option 2: Restart Hot Reload
1. Tekan `R` di terminal (full restart)
2. Atau tekan `Shift+R` (jika available)

### Option 3: Manual Reinstall
```bash
flutter clean
rm -rf build/
flutter pub get
flutter run
```

## Verifikasi File

Pastikan file `family_logo.png` sudah di:
```
c:\Users\Deva\Desktop\Kodingan\Pak isa\family_tree_app\assets\images\family_logo.png
```

## Path yang Digunakan di Code

```dart
Image.asset(
  'assets/images/family_logo.png',  // Path yang benar
  fit: BoxFit.cover,
),
```

## Tips

- ✅ Semua path di Flutter selalu relatif dari root project
- ✅ Gambar di-cache oleh Flutter, jadi `flutter clean` kadang perlu
- ✅ Format yang di-support: PNG, JPG, GIF, WebP
- ✅ Ukuran gambar direkomendasikan: 800x400px atau lebih besar

## Troubleshooting Lanjutan

Jika masih tidak muncul, cek:

1. **File exists**: Buka file manager, navigasi ke folder `assets/images/`
2. **File name spelling**: Pastikan nama file **persis** `family_logo.png` (case-sensitive)
3. **File format**: Pastikan file benar-benar PNG (buka dengan image viewer)
4. **Pubspec syntax**: Cek kembali indentation di `pubspec.yaml`
