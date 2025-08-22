# HabitFit MVP

A Flutter-based habit tracking and fitness management application.

## 🚀 Project Status

**Current Status**: ✅ **Successfully Running on iOS 18.6 Simulator**

## 📱 Platform Support

- **iOS**: ✅ iOS 18.6+ (iPhone 16 Plus Simulator tested)
- **Android**: 🔄 Ready for testing
- **Web**: 🔄 Ready for testing

## 🛠️ Tech Stack

- **Framework**: Flutter 3.35.1
- **Language**: Dart 3.9.0
- **State Management**: Flutter Riverpod 2.6.1
- **Backend**: Firebase (currently disabled for testing)
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth
- **Push Notifications**: Firebase Cloud Messaging
- **Remote Config**: Firebase Remote Config
- **ML**: TFLite Flutter (pose estimation - temporarily disabled)

## 📋 Features

### ✅ Implemented & Working
- **Habit Tracking**: Daily habit management with checkboxes
- **Navigation**: 4-tab bottom navigation (Habit, Workout, Meals, Report)
- **UI Components**: Modern Material Design interface
- **Cross-platform**: iOS, Android, Web ready

### 🔄 Partially Implemented
- **Workout**: Camera integration and pose estimation UI
- **Meals**: Food logging interface
- **Report**: Data visualization framework

### ⏸️ Temporarily Disabled
- **Firebase Services**: Authentication, Firestore, FCM, Remote Config
- **TFLite Pose Estimation**: Due to API changes in latest version

## 🚧 Current Limitations

- Firebase backend services are temporarily disabled for testing
- Pose estimation uses dummy implementation
- Data persistence is local-only

## 🏃‍♂️ Getting Started

### Prerequisites
- Flutter 3.35.1+
- Dart 3.9.0+
- Xcode 16.4+ (for iOS development)
- Android Studio (for Android development)

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd habitfit_mvp

# Install dependencies
flutter pub get

# Run on iOS Simulator
flutter run -d "your-simulator-id"

# Run on Android
flutter run -d "your-android-device-id"
```

### iOS Setup
```bash
cd ios
pod install
cd ..
```

## 🔧 Configuration

### Firebase Setup (When Ready)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

### iOS Deployment Target
- **Current**: iOS 18.6
- **Minimum**: iOS 17.0
- **Recommended**: iOS 18.0+

## 📁 Project Structure

```
lib/
├── app.dart                 # Main app configuration
├── main.dart               # App entry point
├── common/
│   ├── services/          # Firebase services
│   └── widgets/           # Shared UI components
└── features/
    ├── habit/             # Habit tracking
    ├── workout/           # Exercise and pose estimation
    ├── meals/             # Food logging
    └── report/            # Data visualization
```

## 🐛 Known Issues

1. **Firebase Services**: Currently disabled for testing
2. **TFLite Integration**: Needs update to latest API
3. **iOS 18.5 Platform**: Requires Xcode Components installation

## 🎯 Roadmap

### Phase 1: Core Functionality ✅
- [x] Basic UI and navigation
- [x] Habit tracking interface
- [x] Cross-platform setup

### Phase 2: Backend Integration 🔄
- [ ] Firebase configuration
- [ ] User authentication
- [ ] Data persistence

### Phase 3: Advanced Features 📋
- [ ] Pose estimation with TFLite
- [ ] Real-time notifications
- [ ] Advanced analytics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

For support and questions, please open an issue in the repository.

---

**Last Updated**: August 22, 2025
**Flutter Version**: 3.35.1
**Dart Version**: 3.9.0
**iOS Tested**: iPhone 16 Plus iOS 18.6 Simulator
