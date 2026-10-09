# Aplikasi Absensi Karyawan (Flutter + Node.js)

Struktur project ini mengikuti alur (user flow) yang kamu kirim: splash → onboarding →
login → dashboard (karyawan / admin) → absen masuk/pulang (foto + validasi GPS),
pengajuan & persetujuan cuti, laporan, dan data karyawan (CRUD).

## Struktur folder

```
backend/        # REST API - Node.js, Express, Sequelize (MySQL)
flutter_app/    # Aplikasi mobile - Flutter
```

## Menjalankan Backend

```bash
cd backend
copy .env.example .env    # di Windows (atau: cp .env.example .env di Mac/Linux)
npm install
npm run dev
```

> **Catatan Database:** Pastikan MySQL di XAMPP / Laragon sudah **START**. Server akan **otomatis membuat database** (`absensi_db`) dan akun default demo:
> - **Admin**: `admin@mail.com` | Password: `admin123`
> - **Karyawan**: `karyawan@mail.com` | Password: `karyawan123`

## Menjalankan Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

Sebelum run, sesuaikan `lib/core/constants.dart`:
- `baseUrl` → alamat backend kamu (`10.0.2.2` untuk emulator Android yang backend-nya
  jalan di localhost, atau IP lokal laptop kalau tes di HP fisik dalam satu jaringan wifi).

Untuk setiap lokasi kerja, admin perlu mengisi latitude, longitude, dan radius
melalui menu **Jadwal Karyawan → Kelola lokasi**. Jadwal baru tidak dapat dibuat
sebelum geofence lokasi disetel; jadwal lama dengan lokasi yang belum disetel
akan menolak absensi sampai admin melengkapinya. Koordinat harus menunjuk ke
lokasi kerja, bukan lokasi perangkat admin.

App butuh izin **Kamera** dan **Lokasi**. Tambahkan permission berikut:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Aplikasi memerlukan kamera untuk absen</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Aplikasi memerlukan lokasi untuk validasi absen</string>
```

## Yang sudah diimplementasikan (sesuai flow)

**Karyawan:** splash → onboarding → login → dashboard (Home, Pengajuan Cuti,
Riwayat Absen, Laporan, Profile) → absen masuk/pulang sesuai slot dan lokasi
yang ditugaskan admin (foto + validasi GPS geofence lokasi) → form pengajuan
cuti + informasi status cuti → form laporan → edit profile → logout.

**Admin:** login → dashboard (Data Karyawan, Rekap Absensi, Persetujuan Cuti,
Profile, Jadwal Karyawan, Master Jenis Kegiatan) → CRUD data karyawan → lihat
rekap absensi semua karyawan → kelola jadwal per karyawan/lokasi → kelola pilihan
jenis kegiatan laporan → lihat daftar pengajuan cuti, periksa detail,
setujui/tolak → logout.

Saat menambahkan jadwal, admin dapat memilih beberapa karyawan untuk lokasi
dan jam kerja yang sama. Backend membuat penugasan terpisah per akun karyawan
dan menyimpan notifikasi jadwal baru pada masing-masing akun; perubahan dan
pembatalan jadwal juga menghasilkan notifikasi dalam aplikasi.

Jenis kegiatan laporan disimpan sebagai master data. Admin dapat menambah,
mengubah, dan menonaktifkan jenis kegiatan melalui menu **Master Jenis Kegiatan**
di aplikasi admin. Laporan tetap menyimpan nama jenis kegiatan saat laporan
dibuat; menonaktifkan atau mengganti nama master tidak mengubah label laporan
yang sudah tersimpan.

**Admin Web:** tambah akun menggunakan nama lengkap, email, password, dan role
Admin atau Karyawan. Dashboard web tetap menampilkan Tren Luas dan Rekap Data
Karyawan dengan filter harian, mingguan, dan bulanan.

## Yang belum / perlu kamu lanjutkan

- UI masih polos (Material default) — tinggal disesuaikan begitu desain Figma final
  selesai (warna, font, komponen custom, dsb).
- Belum ada halaman "Rekap Laporan" khusus di sisi admin (endpoint backend-nya
  sudah ada: `GET /api/laporan/rekap`), tinggal dibuatkan screen-nya.
- Belum ada endpoint register/seed admin pertama — perlu ditambahkan atau insert manual.
- Koordinat dan radius geofence harus dikonfigurasi sendiri untuk setiap lokasi
  kerja; nilai koordinat lama dari `OFFICE_LAT/LNG` tidak otomatis disalin karena
  satu titik global tidak mewakili semua cabang.
