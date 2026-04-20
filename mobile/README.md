# <p align="center">✨ SmartLife — The Ultimate SuperApp ✨</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" />
  <img src="https://img.shields.io/badge/Express.js-000000?style=for-the-badge&logo=express&logoColor=white" />
  <img src="https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white" />
</p>

<p align="center">
  <b>SmartLife</b> adalah superapp modern yang menggabungkan smart finance management, real-time communication, dan AI assistance dalam satu premium interface yang memukau.
</p>

<p align="center">
  <a href="https://github.com/f1qxzz/SmartApp/releases/download/v1.2.0/SmartLife_Stable.apk">
    <img src="https://img.shields.io/badge/Download-APK-success?style=for-the-badge&logo=android&logoColor=white" alt="Download APK">
  </a>
</p>

---

## 🚀 Fitur Utama | Key Features

| 💰 Finance Tracker | 💬 Real-time Chat | 🤖 AI Assistant | 🏠 Smart Home |
| :--- | :--- | :--- | :--- |
| Manage expenses & budget bulanan dengan praktis menggunakan grafik interaktif. | Ngobrol instan dengan dukungan multimedia, status online, dan typing indicator. | Dapatkan AI-powered financial insights & saran cerdas berbasis data kamu. | Kontrol perangkat rumah pintar langsung dari ponsel dalam satu dashboard. |

---

## 💎 Key Highlights

> [!IMPORTANT]
> **SmartLife** bukan sekadar template UI biasa. Ini adalah fondasi aplikasi production-ready yang mengutamakan performa tinggi dan keamanan data.

- 🛠️ **Clean Architecture**: Pemisahan layer Domain, Data, dan Presentation yang ketat untuk skalabilitas maksimal.
- ⚡ **Riverpod Driven**: State management reaktif yang memudahkan pengujian dan pemeliharaan kode.
- 🔒 **Secure Offline Storage**: Menggunakan Hive yang dienkripsi untuk menyimpan data sensitif secara lokal.
- 🎨 **Pixel Perfect Design**: Implementasi sistem desain yang konsisten hingga ke detail terkecil.

---

## 🛡️ Performa & Keamanan | Performance & Security

| Feature | Description | Status |
| :--- | :--- | :---: |
| **JWT Authentication** | Autentikasi aman menggunakan JSON Web Tokens. | ✅ |
| **Data Encryption** | Enkripsi data sensitif pada penyimpanan lokal Hive. | ✅ |
| **Optimized Rendering** | Penggunaan const constructor dan pemisahan widget secara modular. | ✅ |
| **Input Sanitization** | Validasi dan pembersihan input pada sisi klien maupun server. | ✅ |
| **Real-time Sync** | Sinkronisasi data instan melalui WebSockets (Socket.io). | ✅ |

---

## 🗺️ Roadmap Pengembangan | Roadmap

- [x] **v1.0**: Core features (Finance, Chat, Basic AI).
- [ ] **v1.1**: Integrasi Smart Home yang lebih mendalam dengan MQTT.
- [ ] **v1.2**: Dukungan Multi-bahasa (i18n) dinamis.
- [ ] **v1.3**: AI Voice Command (Perintah suara berbasis AI).
- [ ] **v1.4**: Widget Home Screen untuk Android & iOS.

---

## 🤝 Kontribusi | Contribution

Kontribusi selalu terbuka! Jika kamu punya ide keren atau menemukan bug, silakan buat Pull Request atau buka Issue.

1. Fork repo ini.
2. Buat branch baru: `git checkout -b fitur-keren`.
3. Commit perubahan kamu: `git commit -m 'Menambah fitur baru'`.
4. Push ke branch: `git push origin fitur-keren`.
5. Buat Pull Request.

---

## 🎨 Tampilan Premium | Premium UI/UX

Aplikasi ini didesain dengan standar visual tinggi menggunakan:
- **Glassmorphism**: Efek kaca transparan yang elegan bagi user.
- **Fluid Animations**: Transisi layar yang smooth berkat flutter_animate.
- **Dynamic Backgrounds**: Mesh gradient yang bergerak memberikan kesan premium vibe.
- **Dark Mode Support**: Tema gelap yang dioptimalkan untuk kenyamanan mata.

---

## 🛠️ Stack Teknologi | Tech Stack

### Frontend (Mobile)
- **Framework**: Flutter 3.x & Dart SDK
- **State Management**: Riverpod (Functional & Reactive)
- **Local Database**: Hive (Lightning Fast)
- **Networking**: Client Socket.IO & Dio
- **Animations**: Flutter Animate & Lottie

### Backend
- **Runtime**: Node.js & Express.js
- **Database**: MongoDB dengan Mongoose
- **Real-time**: Socket.io Server
- **AI Engine**: OpenAI & Google Gemini API
- **Cloud Media**: Cloudinary

---

## 📂 Struktur Proyek | Project Structure

```text
smartlife_app/
├── mobile/                 # Flutter Application
│   ├── lib/
│   │   ├── core/           # Theme, Config, Utils
│   │   ├── domain/         # Entities & Logic
│   │   ├── presentation/   # Screens, Widgets, Providers
│   │   └── routes/         # App Routing
│   └── assets/             # Images & Fonts
└── backend/                # Node.js Server
```

---

## 🏁 Memulai | Getting Started

### 📱 Frontend (Mobile)
1. Pergi ke direktori mobile: `cd mobile`
2. Install dependencies: `flutter pub get`
3. Buat file `.env` (copy dari `.env.example`) dan isi API-nya.
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

### 💻 Backend
1. Pergi ke direktori backend: `cd backend`
2. Install dependencies: `npm install`
3. Konfigurasi `.env` dengan kredensial MongoDB & AI Keys.
4. Jalankan server:
   ```bash
   npm run dev
   ```

---

## 📸 Screenshots
<p align="center">
  <img src="assets/images/app_logo.png" width="220" alt="Logo" />
</p>

> [!TIP]
> **Pro Tip:** Gunakan perintah `flutter build apk --release` untuk mendapatkan performa animasi yang paling maksimal di perangkat fisik.

---

## 📄 Lisensi | License
Didistribusikan di bawah Lisensi MIT. Lihat file `LICENSE` untuk informasi lebih lanjut.

---

<p align="center">
  <img src="https://img.shields.io/github/stars/f1qxzz/SmartLife?style=social" />
  <img src="https://img.shields.io/github/forks/f1qxzz/SmartLife?style=social" />
  <br />
  Made with ❤️ by [@f1qxzz](https://github.com/f1qxzz)
</p>
