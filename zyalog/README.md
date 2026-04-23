# ZyaLog (Flutter)

ZyaLog adalah aplikasi mobile native Flutter untuk pengingat jadwal kuliah dan manajemen tugas mahasiswa.

## Stack

- State management: Riverpod
- Networking: Dio + interceptor Bearer token + auto refresh token
- Storage: flutter_secure_storage + shared_preferences
- Routing: go_router

## API Base URL

Default:

https://pabputs-git-main-kizzu200s-projects.vercel.app

Konfigurasi ada di [lib/src/core/constants/api_constants.dart](lib/src/core/constants/api_constants.dart).

Kamu bisa override saat run/build menggunakan `--dart-define`:

```bash
flutter run --dart-define=BASE_URL=https://your-api.example.com
```

## Menjalankan Project

```bash
flutter pub get
flutter analyze
flutter test
```

### Android

```bash
flutter run -d android
```

### Web

```bash
flutter run -d chrome
```

### Windows

Butuh Visual Studio dengan workload Desktop development with C++.

Jika belum terpasang, perintah `flutter run -d windows` akan gagal dengan error toolchain.

## Fitur Utama

- Authentication: login, register, logout
- Auto refresh access token saat 401
- Auto logout jika refresh token gagal
- CRUD jadwal kuliah
- CRUD tugas kuliah
- Filter tugas: semua, belum selesai, selesai
- Progress panel persentase tugas selesai
- Highlight tugas deadline < 24 jam
- Dashboard ringkasan tugas + daftar tugas + daftar jadwal
- Toggle tema light/dark
