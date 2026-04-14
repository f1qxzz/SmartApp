# 📱 SmartLife — All-in-One Finance, Chat & AI Assistant

![SmartLife Banner](assets/banner.png)

> **SmartLife** adalah aplikasi mobile premium yang mengintegrasikan pelacakan keuangan, komunikasi real-time, dan asisten AI cerdas untuk membantu Anda mengelola hidup dengan lebih baik.

---

## ✨ Fitur Unggulan

### 💰 Finance Tracker (Real-time Stats)
- **Daily, Weekly, Monthly Stats**: Pantau pengeluaran Anda dengan ringkasan otomatis.
- **Category Breakdown**: Lihat visualisasi pengeluaran berdasarkan kategori.
- **Transaction Management**: Catat, edit, dan hapus transaksi dengan mudah.
- **Budget Alerts**: Notifikasi otomatis jika pengeluaran melebihi budget yang ditentukan.

### 💬 Real-time Chat
- **Instant Messaging**: Kirim dan terima pesan secara real-time menggunakan Socket.io.
- **WhatsApp Style Multimedia**:
    - **Voice Notes**: Rekam suara dengan indikator durasi dan ikon mic berkedip.
    - **Image Sharing & Preview**: Pratinjau gambar dengan fitur caption sebelum dikirim.
- **Message Management**: Hapus pesan (*Delete for Everyone*) dan hapus seluruh percakapan.
- **Interactive UI**: Typing indicator dan online presence.

### 🤖 SmartLife AI (Financial Consultant)
- **Deep Analysis**: AI menganalisis pola pengeluaran Anda dan memberikan saran konkret.
- **Natural Language**: Tanya apa saja tentang finansial dalam Bahasa Indonesia.
- **Context Aware**: Jawaban didasarkan pada data transaksi aktual Anda di aplikasi.

---

## 🛠️ Tech Stack

### Mobile (Flutter)
- **State Management**: flutter_riverpod
- **Networking**: Dio
- **Storage**: Hive (Local Cache)
- **Real-time**: socket_io_client
- **UI/UX**: flutter_animate, fl_chart, google_fonts

### Backend (Node.js)
- **Framework**: Express.js
- **Database**: MongoDB (Mongoose)
- **Real-time**: Socket.io
- **AI Engine**: OpenAI API (GPT-4o mini)
- **Security**: JWT (JSON Web Token), Bcrypt, Helmet

---

## 🚀 Cara Menjalankan Project

### 1. Prasyarat
- Flutter SDK (minimal 3.10+)
- Node.js & npm (minimal 16+)
- Akun MongoDB Atlas (atau Local MongoDB)
- OpenAI API Key

### 2. Setup Backend
1. Masuk ke folder backend:
   ```bash
   cd backend
   ```
2. Install dependensi:
   ```bash
   npm install
   ```
3. Copy `.env.example` menjadi `.env` dan isi variabelnya:
   ```env
   PORT=5000
   MONGO_URI=your_mongodb_uri
   JWT_SECRET=your_jwt_secret
   OPENAI_API_KEY=your_openai_api_key
   OPENAI_MODEL=gpt-4o-mini
   ```
4. Jalankan backend:
   ```bash
   npm run dev
   ```

### 3. Setup Mobile (Flutter)
1. Masuk ke folder mobile:
   ```bash
   cd mobile
   ```
2. Install dependensi:
   ```bash
   flutter pub get
   ```
3. Sesuaikan `API_BASE_URL` di folder `mobile/.env`:
   - Emulator Android: `http://10.0.2.2:5000`
   - HP Fisik: Gunakan IP Lokal komputer (contoh: `http://192.168.1.5:5000`)
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## 📂 Struktur Proyek
```text
SmartLife/
├── backend/           # Node.js Express API
│   ├── src/
│   │   ├── modules/   # Auth, Chat, Finance, AI
│   │   ├── config/    # Database & Environment
│   │   └── sockets/   # Real-time logic
│   └── uploads/       # Directory untuk upload gambar
│
└── mobile/            # Flutter Mobile App
    ├── lib/
    │   ├── core/      # Theme, Config, Utils
    │   ├── data/      # Services & Repositories
    │   ├── domain/    # Entities & UseCases
    │   └── presentation/ # Providers & Screens
```

---

*Dibuat dengan ❤️ oleh Antigravity Assistant.*
