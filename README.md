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

## 🤖 AI Integration & Future Development

### **Current AI Implementation**

#### **1. TFLite 기반 포즈 추정 (임시 비활성화)**
```dart
// assets/models/movenet.tflite
// 실시간 스쿼트 자세 분석
class MoveNetPoseEstimator extends PoseEstimator {
  Future<void> load() async {
    // TFLite 모델 로딩
  }
  
  Future<int> process(CameraImage img) async {
    // 17개 키포인트 감지 (눈, 어깨, 팔꿈치, 손목, 엉덩이, 무릎, 발목 등)
    // 무릎 각도 계산으로 스쿼트 깊이 측정
    // 운동 완료 감지 및 자동 횟수 카운트
  }
}
```

#### **2. AI 활용 방향**
- **운동**: 실시간 포즈 추정으로 정확한 운동 가이드
- **습관**: 패턴 학습으로 개인 맞춤형 습관 형성 전략
- **식단**: 이미지 인식과 영양 분석으로 스마트한 식단 관리

### **Planned AI Features**

#### **Phase 1: 기본 AI 분석 (데이터 수집 완료 후)**
- **습관 패턴 분석**: 사용자의 성공/실패 패턴 학습
- **식단 영양 균형 분석**: 전체 식단의 영양소 균형 분석
- **운동 효과 분석**: 운동 데이터 기반 효과 측정

#### **Phase 2: 컴퓨터 비전 (Computer Vision)**
```dart
// 음식 이미지 자동 분석
class FoodRecognitionService {
  Future<FoodInfo> analyzeFoodImage(File image) async {
    // AI 모델로 음식 종류, 칼로리, 영양성분 자동 인식
    return FoodInfo(
      name: "라면",
      calories: 450,
      protein: 12.5,
      carbs: 65.2,
      fat: 18.3
    );
  }
}
```

#### **Phase 3: 머신러닝 기반 추천 시스템**
```dart
// 개인화된 식단 추천
class PersonalizedRecommendationService {
  Future<List<Meal>> recommendMeals() async {
    // 사용자의 과거 식단, 목표, 선호도 분석
    // AI가 최적의 식단 조합 추천
    return recommendedMeals;
  }
}

// 습관 형성 AI 코치
class HabitFormationAI {
  Future<HabitStrategy> suggestStrategy() async {
    // 사용자의 성공/실패 패턴 분석
    // 개인에게 최적화된 습관 형성 전략 제안
    return strategy;
  }
}
```

#### **Phase 4: 고급 AI 기능**
- **예측 분석**: 습관 성공률, 체중 변화, 운동 효과 예측
- **부상 예방**: 잘못된 자세로 인한 부상 위험 감지
- **개인화된 알림**: AI가 최적의 시간에 알림 제공

### **AI 데이터 구조**

#### **습관 데이터 (AI 학습 기반)**
```json
{
  "date": "2025-08-22",
  "done": true,
  "uid": "anon",
  "ts": "2025-08-22T13:55:29Z"
}
```

#### **식단 데이터 (AI 학습 기반)**
```json
{
  "date": "2025-08-22",
  "label": "ramen",
  "kcal": 500,
  "imageUrl": null,
  "uid": "anon",
  "ts": "2025-08-22T13:55:35Z"
}
```

#### **운동 데이터 (AI 학습 기반)**
```json
{
  "date": "2025-08-22",
  "exercise": "squat",
  "reps": 10,
  "duration": 300,
  "accuracy": 0.85,
  "uid": "anon",
  "ts": "2025-08-22T13:55:29Z"
}
```

### **AI 모델 및 라이브러리 계획**

#### **현재 사용 중**
- **TFLite Flutter**: 포즈 추정 (MoveNet 모델)
- **Camera Plugin**: 실시간 이미지 스트리밍

#### **향후 추가 예정**
- **TensorFlow Lite**: 음식 인식, 습관 패턴 분석
- **ML Kit**: Firebase 기반 머신러닝 기능
- **Custom Models**: 사용자 데이터로 학습된 개인화 모델

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

assets/
└── models/
    └── movenet.tflite      # AI 포즈 추정 모델
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

### Phase 3 (AI Enhancement)
- [ ] 음식 이미지 자동 인식 시스템
- [ ] 습관 패턴 분석 AI
- [ ] 개인화된 식단 추천 시스템
- [ ] 운동 효과 예측 분석

### Phase 4 (Advanced Features)
- [ ] 사용자 인증 시스템
- [ ] 데이터 백업/복원
- [ ] 소셜 기능
- [ ] 고급 분석 대시보드
- [ ] 부상 예방 AI 시스템

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
| AI Food Recognition | 📋 Planned | Phase 2에서 구현 예정 |
| AI Habit Analysis | 📋 Planned | Phase 2에서 구현 예정 |
| AI Recommendation | 📋 Planned | Phase 3에서 구현 예정 |

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
- **AI/ML Questions**: TensorFlow, ML Kit 문서 참조

---

**Last Updated**: 2025-08-22
**Flutter Version**: 3.35.1
**Dart Version**: 3.9.0
**Firebase**: Integrated & Working
**AI Status**: Pose Estimation (Disabled), Food Recognition (Planned), Habit Analysis (Planned)
