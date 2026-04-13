# SmartLife App - QA Report (Android + Backend)

> Tanggal: 13 April 2026 (Asia/Jakarta)
> Catatan: Fitur Apple/iOS login telah dihapus sesuai permintaan.

## Ringkasan
- Login manual: aktif
- Login Google: aktif
- Forgot password: aktif (email reset link)
- Login Apple/iOS: **dihapus**

## Hasil Uji API
- `GET /health` -> 200
- `POST /api/auth/register` -> 201
- `POST /api/auth/login` (valid) -> 200
- `POST /api/auth/login` (invalid) -> 401
- `POST /api/auth/google` (tanpa token) -> 400
- `POST /api/auth/forgot-password` -> 200
- `POST /api/auth/reset-password` -> 200

## Hasil Uji Fitur
----------------------------------------
📱 NAMA FITUR: Login Manual
📸 Screenshot: `screenshots/auth_login_result_1775999517891.png`
🧪 Hasil Testing: PASS (valid masuk, invalid ditolak)
❌ Bug: tidak ada bug blocker
💡 Solusi: validasi credential di backend tetap ketat
----------------------------------------

----------------------------------------
📱 NAMA FITUR: Login Google
📸 Screenshot: (runtime baru menunggu env OAuth valid)
🧪 Hasil Testing: PASS untuk route/validasi backend, flow frontend aktif
❌ Bug: jika OAuth belum diisi, login ditolak dengan pesan konfigurasi
💡 Solusi: isi `GOOGLE_WEB_CLIENT_ID` + setup Firebase SHA-1
----------------------------------------

----------------------------------------
📱 NAMA FITUR: Forgot Password
📸 Screenshot: `screenshots/authorized_profile_check_1776000137532.png`
🧪 Hasil Testing: PASS (request reset + apply reset password)
❌ Bug: sebelumnya reset langsung tanpa token
💡 Solusi: sudah pakai token reset + expiry
----------------------------------------

----------------------------------------
📱 NAMA FITUR: Login Apple/iOS
📸 Screenshot: N/A
🧪 Hasil Testing: REMOVED
❌ Bug: fitur dinonaktifkan permanen sesuai permintaan
💡 Solusi: endpoint, dependency, env, dan UI Apple sudah dihapus
----------------------------------------
