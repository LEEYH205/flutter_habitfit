# HabitFit MVP

A Flutter-based habit tracking and fitness app with AI-powered pose estimation.

## 🚀 Current Status

**✅ COMPLETED:**
- Flutter 3.35.1 + Dart 3.9.0 업그레이드
- Firebase 통합 완료 (Firestore, Authentication, Remote Config, Cloud Messaging)
- iOS 시뮬레이터 호환성 해결 (iOS 18.6)
- 모든 컴파일 오류 해결
- 기본 앱 기능 정상 작동

**⚠️ PARTIALLY WORKING:**
- FCM (Firebase Cloud Messaging): 시뮬레이터에서는 APNS 토큰 오류 (실제 기기에서는 정상)
- Remote Config: 기본값으로 작동 중 (Firebase Console 설정 필요)

**🔧 NEEDS ATTENTION:**
- Firestore 보안 규칙 설정 (permission-denied 오류 해결 필요)
- TFLite 포즈 추정 기능 복구 (API 변경으로 인한 임시 비활성화)

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.35.1, Dart 3.9.0
- **Backend**: Firebase
  - **Firestore**: 데이터베이스 (habits, meals, workouts)
  - **Authentication**: 사용자 인증
  - **Remote Config**: 동적 설정 관리
  - **Cloud Messaging**: 푸시 알림
- **AI/ML**: TFLite Flutter (포즈 추정, 임시 비활성화)
- **State Management**: Flutter Riverpod
- **Camera**: Flutter Camera Plugin

## 📱 Features

### ✅ Working Features
- **Habit Tracking**: 일일 습관 체크 및 Firestore 저장
- **Meal Logging**: 식사 사진 업로드, 칼로리 매핑, Firestore 저장
- **Workout Tracking**: 카메라 기반 운동 세션 (포즈 추정 임시 비활성화)
- **Progress Reports**: Firestore 데이터 기반 일일 리포트
- **Firebase Integration**: 실시간 데이터 동기화

### 🔧 Features in Progress
- **AI Pose Estimation**: TFLite 기반 스쿼트 자세 분석 (복구 필요)
- **Push Notifications**: FCM 기반 알림 (실제 기기에서 테스트 필요)
- **Dynamic Configuration**: Remote Config 기반 임계값 조정

## 🚀 Getting Started

### Prerequisites
- Flutter 3.35.1+
- Dart 3.9.0+
- Xcode 15+ (iOS 개발용)
- Firebase 프로젝트 설정

### Installation
```bash
# 프로젝트 클론
git clone <repository-url>
cd habitfit_mvp

# 의존성 설치
flutter pub get

# iOS 의존성 설치
cd ios && pod install && cd ..

# 앱 실행
flutter run
```

### Firebase Setup
1. Firebase Console에서 프로젝트 생성
2. `google-services.json` (Android) 및 `GoogleService-Info.plist` (iOS) 다운로드
3. 각 플랫폼 폴더에 배치
4. Firestore Database 활성화
5. Remote Config 활성화
6. Cloud Messaging 활성화

## 📁 Project Structure

```
lib/
├── app.dart                 # 메인 앱 구조
├── main.dart               # 앱 진입점 + Firebase 초기화
├── firebase_options.dart   # Firebase 설정
├── common/
│   ├── services/
│   │   ├── firestore_service.dart    # Firestore 데이터 액세스
│   │   ├── fcm_service.dart          # 푸시 알림
│   │   └── remote_config_service.dart # 동적 설정
│   └── widgets/
│       └── primary_button.dart       # 공통 UI 컴포넌트
└── features/
    ├── habit/              # 습관 추적
    ├── meals/              # 식사 로깅
    ├── workout/            # 운동 추적 + 포즈 추정
    └── report/             # 진행 상황 리포트
```

## 🔧 Configuration

### Remote Config Values
Firebase Console에서 다음 값들을 설정해야 합니다:
- `squat_down_enter`: 100.0 (스쿼트 내려갈 때 진입 각도)
- `squat_up_exit`: 160.0 (스쿼트 올라올 때 종료 각도)
- `angle_smooth_window`: 5 (각도 평활화 윈도우)

### iOS Deployment Target
- **현재**: iOS 18.6
- **Podfile**: `platform :ios, '18.6'`
- **Xcode**: `IPHONEOS_DEPLOYMENT_TARGET = 18.6`

## 🐛 Known Issues

1. **Firestore Permission Denied**: 보안 규칙 설정 필요
2. **TFLite API Changes**: 포즈 추정 기능 복구 필요
3. **FCM APNS Token**: 시뮬레이터에서는 정상적인 오류
4. **Camera on Simulator**: 시뮬레이터에서는 카메라 기능 제한

## 🚧 Roadmap

### Phase 1 (Current)
- [x] Firebase 통합 완료
- [x] 기본 앱 기능 정상화
- [ ] Firestore 보안 규칙 설정
- [ ] Remote Config 값 설정

### Phase 2 (Next)
- [ ] TFLite 포즈 추정 기능 복구
- [ ] FCM 푸시 알림 테스트 (실제 기기)
- [ ] 성능 최적화

### Phase 3 (Future)
- [ ] 사용자 인증 시스템
- [ ] 데이터 백업/복원
- [ ] 소셜 기능
- [ ] 고급 분석 대시보드

## 📊 Development Status

| Component | Status | Notes |
|-----------|--------|-------|
| Flutter App | ✅ Working | 모든 기본 기능 정상 |
| Firebase Core | ✅ Working | 초기화 및 연결 성공 |
| Firestore | ⚠️ Partial | 데이터 저장 성공, 권한 오류 있음 |
| Remote Config | ⚠️ Partial | 기본값으로 작동, 설정 필요 |
| FCM | ⚠️ Partial | 시뮬레이터 제한, 실제 기기에서 테스트 필요 |
| TFLite | 🔧 Disabled | API 변경으로 인한 임시 비활성화 |
| Camera | ✅ Working | 실제 기기에서 정상 작동 |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

- **Firebase Issues**: Firebase Console 및 문서 참조
- **Flutter Issues**: Flutter 공식 문서 및 커뮤니티
- **TFLite Issues**: TFLite Flutter 패키지 이슈 트래커

---

**Last Updated**: 2025-08-22
**Flutter Version**: 3.35.1
**Dart Version**: 3.9.0
**Firebase**: Integrated & Working
