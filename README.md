<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Mobile_App-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Node.js-Backend-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js">
  <img src="https://img.shields.io/badge/MongoDB-Database-47A248?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB">
  <img src="https://img.shields.io/badge/Socket.io-Realtime-010101?style=for-the-badge&logo=socketdotio&logoColor=white" alt="Socket.io">
  <img src="https://img.shields.io/badge/Gemini-AI_Assistant-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="Gemini AI">
</p>

<h1 align="center">SmartLife</h1>

<p align="center">
  SmartLife is a modern mobile app that brings together personal finance, realtime chat, reminders, and AI assistance in one connected experience.
</p>

<p align="center">
  A polished all-in-one mobile workspace for finance, communication, and AI-assisted daily planning.
</p>

<p align="center">
  Built with Flutter on the client side and Node.js + MongoDB on the backend, SmartLife is designed to feel practical, polished, and ready for real daily use.
</p>

---

## Overview

SmartLife is not just a finance tracker and not just a chat app. It is a life management workspace where users can:

- manage spending and monthly budget
- monitor savings goals and recurring subscriptions
- chat in realtime with multimedia support
- get AI-powered financial insights
- stay organized with reminders and a central dashboard

The current product direction focuses on a cleaner and more realistic app flow:

- Welcome, Login, and Register are separated into clearer screens
- Dashboard acts as the main hub for SmartLife AI, reminders, and financial overview
- Finance and Wealth are merged into one more useful flow
- Profile and social links are styled to match the modern SmartLife visual system

---

## Core Features

### 1. Smart Dashboard

- Central home for finance snapshot, reminders, quick actions, and AI entry points
- SmartLife AI is accessible directly from the dashboard
- Analytics and budget context are surfaced without making the app feel crowded

### 2. Finance and Wealth in One Place

- Track transactions with categories and descriptions
- Manage monthly budget and monitor spending progress
- Handle savings goals and recurring subscriptions from a single menu
- View a more realistic finance planning flow instead of disconnected finance screens

### 3. Realtime Chat

- One-to-one messaging with Socket.io
- Message search inside conversations
- Reply, reaction, and conversation summary support
- Voice notes, image sharing, camera upload, and document sharing
- Online state, typing indicator, and user profile preview

### 4. SmartLife AI

- AI financial assistant powered by Gemini
- Uses transaction context to give more actionable responses
- Can also summarize chat history for faster understanding
- Has a fallback analysis mode when AI configuration is unavailable

### 5. Auth and User Experience

- Dedicated Welcome, Login, and Register flow
- Google Sign-In support
- Forgot password support
- Cleaner modern auth UI aligned with the SmartLife design language

### 6. Profile and Personalization

- Editable profile information
- Social media links that open correctly in the browser
- Refined profile card styling with a cleaner and more professional look

---

## Product Structure

SmartLife currently revolves around these main mobile sections:

- `Chat`
- `Finance`
- `Dashboard`
- `Profile`

Supporting flows and modules include:

- `Auth`
- `Reminder`
- `AI`
- `Staff / user management`
- `Realtime backend services`

---

## Tech Stack

### Mobile App

- Flutter
- Riverpod
- Dio
- Hive
- Socket.IO client
- Google Fonts
- Flutter Animate
- FL Chart
- Google Sign-In
- URL Launcher

### Backend API

- Node.js
- Express.js
- MongoDB with Mongoose
- Socket.IO
- JWT authentication
- Bcrypt
- Gemini API
- Nodemailer
- Cloudinary / Multer for uploads

---

## Repository Structure

```text
smartlife_app/
|-- assets/                     # README visuals and shared assets
|-- backend/                    # Node.js API and realtime services
|   |-- scripts/
|   |-- src/
|   |   |-- middleware/
|   |   |-- modules/
|   |   |-- sockets/
|   |   `-- app.js
|   |-- .env.example
|   `-- package.json
|-- mobile/                     # Flutter app
|   |-- lib/
|   |   |-- core/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |-- .env.example
|   `-- pubspec.yaml
|-- test_report.md
`-- README.md
```

---

## Getting Started

### Prerequisites

Make sure you have:

- Flutter SDK 3.x
- Dart SDK
- Node.js 18+ recommended
- MongoDB Atlas or local MongoDB
- Gemini API key
- Android Studio or a connected Android device

### 1. Clone the repository

```bash
git clone https://github.com/f1qxzz/SmartApp.git
cd SmartApp
```

### 2. Setup backend

```bash
cd backend
npm install
cp .env.example .env
```

Fill the backend `.env` with your values:

```env
PORT=5000
MONGO_URI=your_mongodb_uri
JWT_SECRET=your_jwt_secret
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-2.5-flash
GOOGLE_WEB_CLIENT_ID=your_google_web_client_id
GOOGLE_ANDROID_CLIENT_ID=your_google_android_client_id
SMTP_ENABLED=false
```

Run the backend:

```bash
npm run dev
```

### 3. Setup mobile app

```bash
cd ../mobile
flutter pub get
cp .env.example .env
```

Fill the mobile `.env`:

```env
API_BASE_URL=http://10.0.2.2:5000
SOCKET_URL=http://10.0.2.2:5000
GOOGLE_WEB_CLIENT_ID=your_google_web_client_id
MONTHLY_BUDGET=5000000
```

Notes:

- For Android emulator, `10.0.2.2` points to your local machine
- For a physical device, replace it with your local IP address
- If you use tunnel mode, use the HTTPS URL generated for your backend

Run the app:

```bash
flutter run
```

### 4. Build release APK

```bash
cd mobile
flutter build apk
```

The release APK will be generated at:

```text
mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## Environment Files

This repo already includes:

- `backend/.env.example`
- `mobile/.env.example`

Use them as your starting point instead of creating environment files from scratch.

---

## Realtime and AI Notes

- Chat uses Socket.IO for realtime messaging
- AI responses are generated with Gemini models configured on the backend
- If the Gemini service is unavailable, SmartLife can still return fallback finance analysis
- Search, summarization, and media messaging are already wired into the chat experience

---

## Current Direction

Recent improvements in the project include:

- cleaner auth flow with dedicated welcome, login, and register pages
- dashboard and SmartLife AI connected into one main experience
- finance and wealth merged into a more realistic planning flow
- improved profile card styling and social link behavior
- better in-chat search experience

This README is aligned with that current direction so the repository looks closer to the actual product.

---

## Author

Built and evolved by [@f1qxzz](https://github.com/f1qxzz)
