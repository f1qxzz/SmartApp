# 📱 SmartLife App — Flutter UI Premium

> Aplikasi mobile premium: Finance Tracker + Real-time Chat + AI Assistant
> **Stack: Flutter + Riverpod | UI-only (no backend)**

---

## 🎨 Design System

| Token | Value |
|-------|-------|
| Primary | `#5B67F1` |
| Secondary | `#00C9A7` |
| Accent | `#FFB800` |
| Background Light | `#F8F9FD` |
| Background Dark | `#0F1222` |
| Card Dark | `#1A1D2E` |
| Font | Poppins + Inter |
| Border Radius | 16–24px |

---

## 📂 Struktur Proyek

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart      # Mock data, categories
│   └── theme/
│       └── app_theme.dart          # Design system lengkap
│
├── presentation/
│   ├── screens/
│   │   ├── auth/
│   │   │   └── auth_screen.dart    # Login & Register
│   │   ├── chat/
│   │   │   ├── chat_list_screen.dart
│   │   │   └── chat_detail_screen.dart
│   │   ├── finance/
│   │   │   └── finance_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── ai/
│   │   │   └── ai_screen.dart
│   │   └── main_screen.dart        # Bottom navigation
│   │
│   └── widgets/
│       └── reusable_widgets.dart   # Semua reusable widgets
│
└── main.dart
```

---

## 🚀 Cara Install & Run

### 1. Prasyarat

```bash
# Install Flutter (https://flutter.dev/docs/get-started/install)
flutter --version  # minimal 3.10+

# Verify
flutter doctor
```

### 2. Clone & Setup

```bash
# Clone atau extract project
cd smartlife_app

# Install dependencies
flutter pub get
```

### 3. Run App

```bash
# Android emulator / physical device
flutter run

# Web (preview)
flutter run -d chrome
```

### 4. Build Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

---

## 📦 Dependencies

```yaml
# State Management
flutter_riverpod: ^2.4.9

# UI & Animation
google_fonts: ^6.1.0
flutter_animate: ^4.3.0
shimmer: ^3.0.0

# Charts
fl_chart: ^0.66.1

# Navigation
go_router: ^12.1.3

# Utils
intl: ^0.19.0
uuid: ^4.3.3
```

---

## 🖥️ Screens

### 1. Auth Screen
- Gradient background (biru-ungu)
- Animated logo entrance
- Tab toggle Login/Register
- Input email, password, nama
- Social login (Google)
- Form validation

### 2. Chat Screen (WhatsApp Style)
- Story/avatar horizontal scroll
- Chat list dengan unread badge
- Online indicator (hijau dot)
- Chat detail dengan bubble gradient
- Typing indicator animasi (3 dots bounce)
- Send/receive animation

### 3. Finance Screen (Fintech)
- Balance card besar dengan gradient
- Progress bar budget
- Quick action buttons
- Filter chip kategori
- Transaction list dengan swipe-to-delete
- Pull-to-refresh

### 4. Dashboard Screen
- Summary cards (2 kolom)
- Pie chart kategori interaktif
- Line chart tren mingguan
- Top 3 kategori paling boros
- Progress bar per kategori

### 5. AI Screen (ChatGPT Style)
- Welcome view dengan suggestion prompts
- Chat bubbles AI vs user
- Loading indicator (typing)
- Konteks jawaban berdasarkan data finance

---

## 🧩 Reusable Widgets

| Widget | Fungsi |
|--------|--------|
| `CustomButton` | Tombol gradient dengan press animation |
| `InputField` | Input dengan focus shadow |
| `ChatBubble` | Bubble chat kiri/kanan dengan timestamp |
| `FinanceCard` | Card transaksi + swipe delete |
| `BalanceCard` | Card balance dengan progress budget |
| `LoadingSkeleton` | Shimmer loading placeholder |
| `TypingIndicator` | Animated 3-dots typing |
| `GlassCard` | Glassmorphism card container |

---

## 🌙 Dark Mode

Toggle dark/light mode menggunakan ikon moon/sun di pojok kanan Bottom Navigation. Theme tersimpan in-memory (untuk persistensi tambah SharedPreferences).

---

## 📋 Roadmap Integration (Backend)

Untuk connect ke backend Node.js:

1. Ganti mock data di `app_constants.dart` dengan Dio HTTP calls
2. Tambahkan `data/` layer: models, datasources, repositories
3. Tambahkan socket.io-client untuk real-time chat
4. Simpan JWT di Hive (local storage)

```dart
// Contoh Dio setup (tambahkan ke core/utils/dio_client.dart)
final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:5000/api',
  headers: {'Authorization': 'Bearer $token'},
));
```

---

## 🎯 Tips Customization

- **Ganti warna**: Edit `AppColors` di `app_theme.dart`
- **Ganti font**: Edit `GoogleFonts.poppins()` → font lain
- **Tambah screen**: Buat di `screens/`, daftarkan di `main_screen.dart`
- **Tambah kategori**: Edit `financeCategories` di `app_constants.dart`

---

*Made with ❤️ using Flutter + Clean Architecture*

---

## OpenAI API Setup (Real AI Response)

AI screen sekarang bisa jalan ke OpenAI API lewat `Responses API`.
Supaya aman, API key **tidak disimpan di source code**.

Jalankan app dengan:

```bash
flutter run --dart-define=OPENAI_API_KEY=YOUR_OPENAI_API_KEY
```

Opsional model:

```bash
flutter run --dart-define=OPENAI_API_KEY=YOUR_OPENAI_API_KEY --dart-define=OPENAI_MODEL=gpt-4o-mini
```

Jika `OPENAI_API_KEY` tidak diisi, app otomatis fallback ke mode AI lokal.
