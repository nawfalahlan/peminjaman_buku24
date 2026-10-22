# Aplikasi Peminjaman Buku (Flutter)

Aplikasi perpustakaan sekolah dengan dua hak akses: **Petugas** dan **Anggota (Siswa)**.
Detail perancangan & uji coba: [docs/PERANCANGAN.md](docs/PERANCANGAN.md).

## Akun contoh
| Peran | Username | Password |
|---|---|---|
| Petugas | `admin` | `admin123` |
| Siswa | `1001` | `1001` |
| Siswa | `1002` | `1002` |

## Langkah menjalankan
1. **Pasang Flutter SDK** (https://docs.flutter.dev/get-started/install), lalu cek: `flutter doctor`
2. **Buka folder proyek ini** di terminal: `cd perpustakaan_app`
3. **Buat folder platform** (android/ios/web/windows), tidak menimpa `lib/`:
   `flutter create --project-name perpustakaan_app .`
4. **Unduh dependensi**: `flutter pub get`
5. **Sambungkan perangkat**: emulator Android / HP (USB debugging) / `flutter devices`
6. **Jalankan**: `flutter run` (atau `flutter run -d windows` / `-d chrome` bila tidak ada emulator)
7. **Uji**: `flutter test`
8. **Dokumentasi kode** (opsional): `dart doc .`
9. **Build APK** (opsional): `flutter build apk --release` → `build/app/outputs/flutter-apk/`

> Penyimpanan: file JSON (`path_provider`) di Android/iOS/desktop, dan localStorage browser di web.
> Untuk mengembalikan data awal: hapus data aplikasi (Android) / file `perpustakaan.json`.
