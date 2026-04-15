# LocalTunnel Quick Start

Gunakan ini agar backend bisa diakses publik tanpa IP lokal laptop.

## 1) Isi `.env` backend

Tambahkan variabel opsional berikut:

```env
PORT=5000
LT_SUBDOMAIN=smartlife-demo
LT_HOST=
LT_RETRY_MS=5000
```

`LT_SUBDOMAIN` opsional. Jika kosong, LocalTunnel akan memberikan URL acak.
`LT_HOST` opsional untuk custom LocalTunnel server.
`LT_RETRY_MS` opsional untuk jeda retry otomatis jika tunnel terputus.

## 2) Jalankan backend + tunnel

```bash
npm run dev:tunnel
```

Script ini akan:

- Menjalankan backend (`npm run dev`)
- Membuka LocalTunnel ke port backend
- Auto reconnect kalau tunnel putus
- Otomatis update `../mobile/.env`:
  - `API_BASE_URL=<url_localtunnel>`
  - `SOCKET_URL=<url_localtunnel>`

## 3) Jalankan ulang Flutter app

Setelah URL di `mobile/.env` berubah, restart aplikasi Flutter (bukan hot reload) agar env baru terbaca.

---

## Alternatif lebih stabil: Cloudflare Tunnel

Jika LocalTunnel sering `Tunnel Unavailable` atau `408`, gunakan:

```bash
npm run dev:cloudflare
```

Script ini:

- Menjalankan backend (`npm run dev`)
- Menjalankan `cloudflared tunnel --url http://127.0.0.1:PORT`
- Otomatis update `../mobile/.env` untuk `API_BASE_URL` dan `SOCKET_URL`
