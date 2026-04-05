# 🌿 Cal AI – Calorie & Nutrition Tracker

A production-ready, AI-powered nutrition tracking application built with **Flutter**. Cal AI lets users log meals intelligently via camera AI, barcode scanning, QR codes, or manual search — and syncs all data natively to **Google Health Connect** and **Apple Health**.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📸 **AI Food Recognition** | Snap a photo of any food and get instant nutrition estimates powered by HuggingFace AI |
| 🔍 **Barcode Scanner** | Scan packaged food barcodes to pull nutrition data from OpenFoodFacts |
| 📦 **QR Code Support** | QR code scanning for bulk nutrition data entry |
| 🥗 **Manual Food Search** | Search millions of foods via the USDA Food Database API |
| 📓 **Daily Meal Diary** | Log Breakfast, Lunch, Dinner & Snacks with full macro breakdown |
| 📅 **Historical Data** | Navigate between dates to view past meal history |
| 💪 **Health Connect Sync** | Native read/write integration with Android Health Connect & Apple HealthKit |
| 🌙 **Dark Mode** | Full light and dark theme support |
| 🔒 **Offline-First** | All data persists locally using Hive — works without internet |

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Local Storage:** Hive
- **AI / ML:** HuggingFace Inference API, Google ML Kit
- **Food Database:** USDA FoodData Central API, OpenFoodFacts
- **Health Integration:** Android Health Connect, Apple HealthKit
- **Camera:** Flutter Camera, Image Picker
- **Barcode & QR:** Mobile Scanner

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Android SDK with API Level 26+ (for Health Connect)
- A `.env` file with your API keys (see below)

### Clone & Run
```bash
git clone https://github.com/priyanshu0508/Calorie-AI-Nutrition-Tracker.git
cd Calorie-AI-Nutrition-Tracker
flutter pub get
flutter run
```

### Environment Variables
Create a `.env` file in the project root:
```env
HUGGING_FACE_API_KEY=your_key_here
USDA_API_KEY=your_key_here
```

> ⚠️ **Never commit your `.env` file.** It is already protected by `.gitignore`.

---

## 🏥 Health Connect Setup (Android)

1. Install **Health Connect** from the Google Play Store on your device.
2. Open Cal AI → Go to **Profile** → Tap **Health Apps**.
3. Grant the requested permissions (Nutrition Read/Write, Active Calories).
4. All logged meals will automatically sync to Health Connect!

---

## 📦 Building for Release

**Android APK:**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Android App Bundle (Play Store):**
```bash
flutter build appbundle --release
```

**iOS (requires Mac + Apple Developer Account):**
```bash
flutter build ipa --release
```

---

## 📁 Project Structure

```
lib/
├── features/
│   ├── auth/         # Welcome & onboarding screen
│   ├── diary/        # Home screen & meal entry
│   ├── profile/      # User settings & health sync
│   └── scan/         # Camera, barcode, QR, photo AI
├── models/           # Meal, FoodItem, DiaryDay, UserModel
├── providers/        # Riverpod state management
└── services/         # Health, Nutrition, Barcode, Analysis APIs
```
