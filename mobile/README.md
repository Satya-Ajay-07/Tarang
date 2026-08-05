# Tarang Mobile Application 🌊

Official Flutter mobile application for Tarang. This project implements the production-ready frontend, communicating directly with the FastAPI backend.

---

## 🚀 Tech Stack & Core Libraries
- **Flutter SDK:** Material 3 ready design systems.
- **State Management:** Riverpod (`flutter_riverpod`) for clean, unidirectional data flows and modularity.
- **Routing:** GoRouter (`go_router`) with deep-linking support, authentication guards, and path parameter mapping.
- **Networking:** Dio (`dio`) equipped with JWT auto-injection interceptors, refresh tokens, and network error maps.
- **Secure Storage:** Secure Storage (`flutter_secure_storage`) for credentials and caching.
- **Image Caching:** Cached Network Image (`cached_network_image`) for high performance.
- **Native Polish:** Native haptic impacts (`HapticFeedback`) and native share sheets (`share_plus`).

---

## 📂 Folder Structure
This application follows a **Clean Feature-First Architecture** for maximum scalability:
```
mobile/
├── .github/workflows/   # CI/CD pipelines
├── lib/
│   ├── core/
│   │   ├── config/      # API configurations and routing
│   │   ├── constants/   # App-wide assets, storage keys
│   │   ├── exceptions/  # Domain error parsing
│   │   ├── models/      # Shared domain entities (UserModel, WaveModel)
│   │   ├── network/     # Dio Client configuration
│   │   ├── providers/   # Global provider dependencies
│   │   ├── repositories/# Domain repository implementations
│   │   ├── services/    # Cache, connectivity, haptics, queues, drafts
│   │   └── theme/       # App themes (Light, Dark, System)
│   └── features/
│       ├── splash/      # App startup status route
│       ├── authentication/# Register, login, forgot password screens
│       ├── home/        # Infinite feed lists and composer modals
│       ├── explore/     # Search bars and tag page feeds
│       └── profile/     # Sliver appbar banners and follow statistics
└── test/                # Feature test suites
```

---

## 🛠️ Developer Setup & Setup Guides

### 1. Requirements
- Flutter SDK `3.16.x` or higher
- Android SDK / Xcode for iOS
- Active backend instance (FastAPI running locally or on staging)

### 2. Installation
Run the following commands inside the `mobile` directory:
```bash
flutter pub get
```

### 3. Run Locally
To run the debug application on your emulator or connected device:
```bash
flutter run
```

---

## 📦 Build & Release Guides

### 1. Build APK
Generate a release-ready APK binary:
```bash
flutter build apk --release
```

### 2. Build Android App Bundle (AAB)
Generate the Google Play Store upload bundle:
```bash
flutter build appbundle --release
```

### 3. Signing Configurations
To build signed production releases, create a `key.properties` file in `android/` containing your upload keystore credentials:
```properties
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=<path-to-keystore-file>
```

---

## 🔌 API Integration Guide

All network interactions pass through `ApiClient`. The backend endpoints consumed in the app:
- **Auth:** `/auth/login`, `/auth/register`, `/auth/verify-email`, `/auth/resend-verification`
- **Waves:** `/waves` (stream feed), `/waves/{id}` (detail), `/waves/{id}/ripple`, `/waves/{id}/spread`, `/waves/{id}/bookmark`
- **Explore:** `/explore` (global search query), `/explore/suggested-riders` (users to follow), `/waves/rising` (trending)
- **Profiles:** `/users/profile/{username}`, `/users/me` (profile edits), `/users/{id}/riders` (followers), `/users/{id}/riding` (following), `/users/ride/{id}` (follow toggle)
- **Media:** `/media/upload` (multipart photo uploading)
