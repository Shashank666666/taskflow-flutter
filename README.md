# TaskFlow Flutter Application

A mobile task management application built with Flutter that runs on both iOS and Android devices, with cloud synchronization using Firebase.

## Features

- Create, view, and manage tasks
- Set task priorities (High, Medium, Low)
- Categorize tasks (Personal, Work, Shopping, Health, Education, Entertainment)
- Mark tasks as completed
- Filter tasks by status (All, Active, Completed)
- Set due dates for tasks
- Cloud storage using Firebase Firestore
- Real-time synchronization across devices
- Anonymous authentication

## Prerequisites

- Flutter SDK (v3.0 or higher)
- Dart SDK (comes with Flutter)
- For development: Android Studio, VS Code, or command line tools
- For building APK: Android SDK and build tools
- Firebase project (free tier available)

## Installation

1. Clone or download this repository
2. Navigate to the project directory
3. Get dependencies:

```bash
flutter pub get
```

## Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Register your app (Android/iOS) with your project
4. Download the configuration file (`google-services.json` for Android, `GoogleService-Info.plist` for iOS)
5. Place the configuration file in the appropriate directory:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

## Running the Application

### Development

```bash
flutter run
```

### Building for Release

#### Android APK
```bash
flutter build apk --release
```
The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`

#### iOS IPA
```bash
flutter build ios --release
```

### Web Version
```bash
flutter run -d chrome
```

## Tech Stack

- Flutter: Cross-platform mobile development framework
- Dart: Programming language for Flutter
- Firebase: Cloud storage and authentication
- Cloud Firestore: NoSQL document database
- Firebase Auth: Authentication service
- Material Design: UI components and theming

## Project Structure

```
lib/
├── main.dart           # Application entry point
├── models/
│   └── task.dart       # Task data model
├── widgets/
│   └── task_list.dart  # Task listing widget
├── services/
│   └── firebase_service.dart  # Firebase integration
└── screens/
    ├── home_screen.dart          # Main screen
    └── task_creation_screen.dart # Task creation screen
```

## Building the APK

To generate an APK for your phone:

1. Connect your Android device via USB or use an emulator
2. Run: `flutter build apk --release`
3. The APK will be created in `build/app/outputs/flutter-apk/app-release.apk`
4. Transfer this file to your phone and install it

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test on multiple devices/screen sizes
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request