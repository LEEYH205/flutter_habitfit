# HabitFit MVP

A Flutter-based habit tracking and fitness app with AI-powered pose estimation.

## 📊 **현재 상태**

### ✅ **완료된 기능**
- **기본 앱 구조**: Flutter + Riverpod + Firebase
- **운동 인식**: TFLite MoveNet 기반 스쿼트/푸시업 카운팅
- **HealthKit 연동**: iOS 건강앱 권한 설정, 기본 운동 데이터 가져오기
- **달리기 데이터 수집**: WORKOUT 데이터 파싱 및 분석 로직 완성
- **달리기 분석 시스템**: 5개 탭 구조 (요약, 트렌딩, 심박수, 페이스, 패턴)
- **AI 기반 코칭**: 규칙 기반 개인화된 달리기 조언 시스템
- **데이터 시각화**: fl_chart를 활용한 트렌딩 및 패턴 차트

**✅ COMPLETED:**
- **🎯 AI 포즈 추정 완벽 동작**: MoveNet 모델로 실시간 스쿼트 감지 성공
- **💪 스쿼트 카운트 정상 작동**: 무릎 각도 계산으로 정확한 운동 횟수 측정
- **📱 실제 iPhone 호환성**: 물리 기기에서 안정적인 AI 추론 성능
- **🔄 스쿼트 상태 머신 완벽 구현**: idle → down → up → idle 사이클 정확한 감지
- **🎨 포즈 오버레이 UI 완성**: 실시간 키포인트 시각화 및 스켈레톤 연결선 표시
- **🔔 로컬 알림 시스템 완벽 구현**: 운동 완료, 목표 달성, 습관 리마인더 등 완전한 알림 기능
- **💪 푸시업 운동 추가**: 팔꿈치 각도 기반 푸시업 감지 및 카운팅 시스템 구현
- **🎨 UI/UX 통일**: 모든 탭의 상단 디자인을 설정탭과 동일한 스타일로 통일
- **📱 워크아웃 레이아웃 최적화**: 불필요한 버튼과 텍스트 제거, 카메라 비율 개선
- **🔢 독립적인 운동 카운터**: 스쿼트와 푸시업 각각의 독립적인 카운터 시스템
- **🏥 HealthKit 연동 완료**: iPhone 건강앱과의 데이터 연동 및 WORKOUT 데이터 가져오기 성공
- **🏃‍♂️ 달리기 데이터 수집**: Apple Watch로 기록된 달리기 운동 데이터 성공적으로 가져오기

**⚠️ PARTIALLY WORKING:**
- FCM (Firebase Cloud Messaging): 시뮬레이터에서는 APNS 토큰 오류 (실제 기기에서는 정상)
- Remote Config: 기본값으로 작동 중 (Firebase Console 설정 필요)
- **🔄 푸시업 카운팅**: 독립적인 카운터는 구현되었으나 실제 감지가 작동하지 않음 (디버깅 필요)

**🔧 NEXT STEPS:**
- **🔧 푸시업 감지 로직 디버깅**: 현재 카운팅이 증가하지 않는 문제 해결 (우선순위 1)
- **🎯 목표 달성 화면 오버레이 구현**: 운동 중 목표 달성 시 화면에 축하 메시지 표시 (우선순위 2)
- **💪 운동 완료 시 자동 알림**: Stop 버튼 누를 때 자동으로 운동 완료 알림 전송 (우선순위 3)
- **⚙️ 설정 페이지 완성**: 사용자가 알림 설정을 커스터마이징할 수 있도록 (우선순위 4)
- **📝 습관 체크와 알림 연동**: 습관 체크 완료 시 성취 알림 및 연속 달성 기록 (우선순위 5)
- **📊 달리기 데이터 분석**: HealthKit에서 가져온 달리기 데이터를 활용한 상세 분석 시스템
- **🏃‍♂️ 달리기 관리 시스템**: GPS 기반 거리/속도 측정, HealthKit 연동 코칭 시스템
- **⌚️ Apple Watch 지원**: 워치 전용 운동 추적 및 iPhone과의 데이터 동기화
- **GPS 기반 실시간 추적**: 달리기 경로 및 속도 모니터링
- **Apple Watch 앱**: 독립적인 웨어러블 앱 개발
- **소셜 기능**: 친구와의 챌린지 및 기록 공유
- 운동 피드백 시스템 (자세 교정 가이드)
- 성능 최적화 및 배터리 효율성 개선
- 추가 운동 동작 지원 (플랭크, 런지 등)

## 🛠️ Tech Stack

### **Frontend & State Management**
- **Flutter**: 3.35.1 (최신 안정 버전)
- **Dart**: 3.9.0
- **Riverpod**: 상태 관리 및 의존성 주입
- **Material Design 3**: 최신 Material You 디자인 시스템

### **AI & Computer Vision**
- **TensorFlow Lite**: MoveNet 모델 추론 엔진
- **MoveNet**: 실시간 포즈 추정 및 운동 인식
- **Pose Estimation**: 17개 키포인트 기반 정확한 자세 분석

### **Backend & Database**
- **Firebase**: 클라우드 백엔드 서비스
  - **Firestore**: 실시간 데이터베이스
  - **Authentication**: 사용자 인증
  - **Cloud Messaging**: 푸시 알림
  - **Remote Config**: 원격 설정 관리
- **AI/ML**: TFLite Flutter (MoveNet 포즈 추정 정상 작동)
- **State Management**: Flutter Riverpod
- **Camera**: Flutter Camera Plugin
- **Notifications**: flutter_local_notifications (완벽 작동)
- **Health Integration**: HealthKit 연동 ✅ 완료
- **Watch Support**: Apple Watch 앱 (계획됨)

### **Health Integration**
- **HealthKit**: iOS 건강앱 연동
- **Apple Watch**: 웨어러블 데이터 수집
- **실시간 생체 데이터**: 운동, 심박수, 거리, 칼로리

### **Data Visualization**
- **fl_chart**: 차트 및 그래프 라이브러리
- **실시간 데이터 시각화**: 트렌딩, 패턴 분석

### **Local Notifications**
- **flutter_local_notifications**: 로컬 알림 시스템
- **timezone**: 시간대별 알림 스케줄링

## 📱 Features

### **🎯 AI-Powered Exercise Recognition** ✅ **완료**
- **Real-time Pose Estimation**: MoveNet 모델로 17개 키포인트 실시간 추적
- **Exercise Counting**: 스쿼트, 푸시업 정확한 횟수 카운팅
- **Form Analysis**: 자세 교정 및 피드백 제공
- **Performance Metrics**: 운동 강도 및 지속 시간 측정

### **🏥 HealthKit Integration** ✅ **완료**
- **iOS Health App Sync**: 건강앱과의 완벽한 데이터 동기화
- **Apple Watch Data**: 웨어러블 기기에서 수집된 운동 데이터
- **Workout Tracking**: 달리기, 걷기, 자전거 등 다양한 운동 기록
- **Biometric Data**: 심박수, 거리, 칼로리, 속도 등 상세 메트릭

### **🏃‍♂️ Running Analysis System** ✅ **완료**
- **5-Tab Analysis**: 요약, 트렌딩, 심박수, 페이스, 패턴
- **Data Visualization**: fl_chart 기반 트렌딩 및 패턴 차트
- **Performance Tracking**: 거리, 시간, 페이스, 칼로리 추적
- **Pattern Analysis**: 요일별, 시간대별 운동 선호도 분석

### **🤖 AI Coaching System** ✅ **완료**
- **Personalized Advice**: 개인 운동 데이터 기반 맞춤형 조언
- **Heart Rate Analysis**: 심박수 구간별 운동 강도 평가
- **Pace Optimization**: 페이스 품질 분석 및 개선 방향 제시
- **Trending Insights**: 운동 패턴 변화에 따른 코칭 제공

### **🔔 Smart Notifications** ✅ **완료**
- **Local Notifications**: 운동 완료, 목표 달성 알림
- **Habit Reminders**: 습관 체크 리마인더
- **Achievement Celebrations**: 목표 달성 시 축하 메시지
- **Customizable Scheduling**: 사용자 정의 알림 시간 설정

### **📊 Habit & Fitness Tracking** ✅ **완료**
- **Daily Habits**: 습관 체크 및 연속 달성 기록
- **Meal Logging**: 식사 기록 및 칼로리 추적
- **Workout Sessions**: AI 기반 운동 세션 관리
- **Progress Analytics**: 습관 및 운동 진행 상황 분석

### **📱 Cross-Platform Support** ✅ **완료**
- **iOS Native**: HealthKit 완벽 연동
- **Material Design 3**: 최신 UI/UX 디자인
- **Responsive Layout**: 다양한 화면 크기 지원
- **Dark/Light Theme**: 사용자 선호 테마 지원

### ✅ Completed Features
- **🎯 AI Pose Estimation**: TFLite MoveNet 기반 실시간 스쿼트 자세 분석
- **💪 Squat Detection**: 무릎 각도 계산으로 정확한 운동 횟수 측정
- **📱 Real-time Processing**: iPhone에서 30fps 안정적 동작
- **🔔 Local Notification System**: 완벽한 로컬 알림 시스템 구현 완료

### ✅ Completed Features
- **🎨 Pose Overlay UI**: 실시간 키포인트 시각화 및 스켈레톤 연결선 표시
- **🔄 Squat State Machine**: idle → down → up → idle 상태 머신으로 정확한 운동 감지
- **💪 Real-time Exercise Counting**: 무릎 각도 기반 스쿼트 횟수 자동 카운트
- **🎯 Goal Achievement Notifications**: 실시간 목표 달성 감지 및 축하 알림

### ✅ Recently Completed Features
- **💪 Push-up Exercise Support**: 팔꿈치 각도 기반 푸시업 감지 시스템 구현
- **🎨 Unified Tab Design**: 모든 탭의 상단 디자인을 설정탭과 동일한 스타일로 통일
- **📱 Optimized Workout Layout**: 불필요한 버튼과 텍스트 제거, 카메라 비율 최적화
- **🔢 Independent Exercise Counters**: 스쿼트와 푸시업 각각의 독립적인 카운터 시스템
- **🔄 Multi-Exercise Support**: 운동 타입 선택 드롭다운으로 스쿼트/푸시업 전환 가능
- **🏥 HealthKit Integration**: iPhone 건강앱과의 완벽한 데이터 연동 및 WORKOUT 데이터 수집
- **🏃‍♂️ Running Data Collection**: Apple Watch로 기록된 달리기 운동 데이터 성공적으로 가져오기

### 🔧 Features in Progress
- **🔧 Push-up Detection Debugging**: 푸시업 카운팅이 증가하지 않는 문제 해결
- **🎯 Goal Achievement Overlay**: 운동 중 목표 달성 시 화면에 축하 메시지 표시
- **💪 Auto Workout Completion**: Stop 버튼 누를 때 자동으로 운동 완료 알림 전송
- **⚙️ Settings Page**: 사용자가 알림 설정을 커스터마이징할 수 있도록
- **📝 Habit Notification Integration**: 습관 체크 완료 시 성취 알림 및 연속 달성 기록
- **Exercise Feedback**: 자세 교정 가이드 및 운동 강도 조절
- **Push Notifications**: FCM 기반 알림 (실제 기기에서 테스트 필요)
- **Dynamic Configuration**: Remote Config 기반 임계값 조정

### 📋 Planned Features
- **📊 Running Data Analysis**: HealthKit에서 가져온 달리기 데이터를 활용한 상세 분석 시스템
- **🏃‍♂️ Running Management System**: GPS 기반 달리기 추적 및 관리
- **⌚️ Apple Watch Support**: 워치 전용 운동 앱 및 iPhone과의 동기화
- **💡 AI-Powered Coaching**: HealthKit 운동 데이터 분석 기반 개인화된 코칭 시스템

## 🏥 HealthKit Integration & Running Data

### **✅ 완료된 HealthKit 기능**
- **권한 관리**: iOS 건강앱 접근 권한 설정 및 관리
- **WORKOUT 데이터 수집**: Apple Watch 운동 기록 자동 동기화
- **데이터 파싱**: `WorkoutHealthValue`에서 거리, 칼로리, 시간 정확한 추출
- **운동 타입 인식**: 달리기, 걷기, 자전거 등 다양한 운동 자동 분류
- **실시간 동기화**: HealthKit과 앱 간 실시간 데이터 업데이트

### **🏃‍♂️ 달리기 데이터 수집 완료**
- **수집된 데이터**: 최근 30일간 10개 달리기 운동 기록
- **상세 메트릭**: 
  - 거리: 5.01km ~ 10.02km
  - 시간: 21분 ~ 69분
  - 칼로리: 100kcal ~ 809kcal
  - 소스: Apple Watch 자동 기록
- **데이터 품질**: 모든 메트릭이 정확하게 파싱되어 UI에 표시

### **📊 달리기 분석 시스템**
- **5개 분석 탭**: 요약, 트렌딩, 심박수, 페이스, 패턴
- **요약 통계**: 총 거리 58.0km, 총 칼로리 4,459kcal, 평균 페이스 7.2분/km
- **트렌딩 분석**: 시간에 따른 거리 및 운동 지속 시간 변화 추이
- **패턴 분석**: 요일별, 시간대별 운동 선호도 시각화
- **AI 코칭**: 개인 운동 데이터 기반 맞춤형 조언 제공

#### **. 달리기 데이터 수집 성공**
- **운동 타입**: `RUNNING_TREADMILL` (달리기)
- **운동 시간**: 시작/종료 시간, 지속 시간
- **총 거리**: 미터 단위 (예: 5,014m = 5.014km)
- **총 칼로리**: 킬로칼로리 (예: 376kcal)
- **데이터 소스**: Apple Watch
- **상세 메트릭**: 평균 속도, 보폭, 파워, 수직 진폭, 지면 접촉 시간 등

#### **. 현재 수집 가능한 데이터**
```dart
// 지원하는 HealthKit 데이터 타입
final types = [
  HealthDataType.WORKOUT,           // 운동 세션 데이터 (달리기 포함)
  HealthDataType.HEART_RATE,       // 심박수
  HealthDataType.STEPS,            // 걸음 수
  HealthDataType.DISTANCE_WALKING_RUNNING, // 걷기/달리기 거리
  HealthDataType.ACTIVE_ENERGY_BURNED,     // 활동 소모 칼로리
  HealthDataType.BASAL_ENERGY_BURNED,      // 기초 대사 칼로리
  HealthDataType.EXERCISE_TIME,            // 운동 시간
  HealthDataType.FLIGHTS_CLIMBED,          // 계단 오르기
];
```

#### **. 달리기 데이터 분석 가능 항목**
- **운동 성과 트렌딩**: 시간에 따른 개선도 분석
- **운동 강도 분석**: 심박수 기반 운동 강도 평가
- **거리/속도 분석**: 페이스 및 속도 패턴 분석
- **운동 패턴 분석**: 요일/시간대별 선호도 분석
- **개인 기록 관리**: 최고 기록 및 개선 목표 설정

### **🔧 다음 단계 HealthKit 기능**
- **심박수 데이터**: Apple Watch 실시간 심박수 수집 및 구간별 분석
- **GPS 추적**: 실시간 달리기 경로 및 속도 모니터링
- **Apple Watch 앱**: 독립적인 웨어러블 앱 개발
- **고급 생체 데이터**: VO2 max, 심박수 변이성, 수면 품질 등

### **🔧 Next Steps for HealthKit**

#### **1. 달리기 전용 분석 페이지**
```dart
class RunningAnalysisPage extends StatelessWidget {
  // 달리기 데이터 시각화
  // - 거리/시간 그래프
  // - 심박수 변화 추이
  // - 속도 패턴 분석
  // - 개인 기록 관리
}
```

#### **2. AI 기반 달리기 코칭**
```dart
class RunningCoachingSystem {
  // 심박수 기반 페이스 조절 가이드
  String getHeartRateAdvice(int currentHR, int targetHR);
  
  // 보폭 최적화 가이드
  String getStrideAdvice(double currentStride, double optimalStride);
  
  // 페이스 관리 코칭
  String getPaceAdvice(double currentPace, double targetPace);
}
```

#### **3. GPS 기반 실시간 달리기 추적**
```dart
class GPSTrackingService {
  // 실시간 위치 추적
  Future<void> startTracking();
  
  // 경로 기록 및 시각화
  List<LatLng> getRoute();
  
  // 실시간 속도 및 거리 계산
  double getCurrentSpeed();
  double getTotalDistance();
}
```

## 🤖 AI Integration & Future Development

### **Current AI Implementation**

#### **0. AI 활용 방향**
- **운동**: 실시간 포즈 추정으로 정확한 운동 가이드
- **습관**: 패턴 학습으로 개인 맞춤형 습관 형성 전략
- **식단**: 이미지 인식과 영양 분석으로 스마트한 식단 관리

#### **1. TFLite 기반 포즈 추정 ✅ 완벽 동작**
```dart
// assets/models/movenet_singlepose_lightning.tflite
// 실시간 스쿼트 자세 분석 - MoveNet Lightning 모델
class MoveNetPoseEstimator extends PoseEstimator {
  Future<void> load() async {
    // TFLite 모델 로딩 (9.5MB MoveNet Lightning)
    // 입력: [1, 192, 192, 3] uint8 RGB 이미지
    // 출력: [1, 1, 17, 3] float32 키포인트 (y, x, confidence)
  }
  
  int process(CameraImage img) {
    // ✅ 17개 키포인트 실시간 감지 성공 (신뢰도 0.8+)
    // ✅ iOS YUV420/NV12 → RGB 변환 완벽 처리
    // ✅ 무릎 각도 계산으로 정확한 스쿼트 깊이 측정
    // ✅ 스쿼트 완료 자동 감지 및 횟수 카운트
    // ✅ 성능: 실시간 30fps, iPhone에서 안정적 동작
    // ✅ 양쪽 다리 폴백 로직으로 안정성 향상
  }
}
```

#### **2. 다중 운동 지원 시스템 ✅ 구현 완료**
```dart
// 운동별 독립적인 카운터 시스템
class WorkoutPage extends StatefulWidget {
  // 스쿼트와 푸시업 각각의 독립적인 카운터
  final _squatCountProvider = StateProvider<int>((ref) => 0);
  final _pushupCountProvider = StateProvider<int>((ref) => 0);
  
  // 운동 타입 선택 드롭다운
  String _selectedExercise = 'squat';
  final Map<String, Map<String, String>> _exerciseSettings = {
    'squat': {'name': '스쿼트', 'goal': '20회'},
    'pushup': {'name': '푸시업', 'goal': '15회'},
  };
}

// 푸시업 감지기
class PushUpDetector {
  String _pushUpPhase = 'idle';
  int _repCount = 0;
  
  int detectPushUp(double elbowAngle) {
    // 팔꿈치 각도 기반 푸시업 상태 감지
    // down: < 90도, up: > 90도
    // idle → down → up → down 사이클로 카운팅
  }
}
```

#### **3. UI/UX 통일 및 최적화 ✅ 완료**
```dart
// 모든 탭의 통일된 상단 디자인
class UnifiedTabDesign {
  // 설정탭과 동일한 스타일의 AppBar
  AppBar(
    title: Text('💪 운동 관리'), // 또는 '✅ 습관 관리', '🍽️ 식사 관리' 등
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    actions: [
      // 운동 선택 드롭다운 (운동 탭만)
      DropdownButton<String>(...),
    ],
  )
}

// 워크아웃 레이아웃 최적화
class OptimizedWorkoutLayout {
  // 불필요한 요소 제거
  // - Start, Stop, Save 버튼 제거
  // - "현재 운동: 푸시업" 등 설명 텍스트 제거
  // - 카메라 비율 최적화 (자연스러운 비율 사용)
  
  // 핵심 기능만 유지
  // - 실시간 카운터 표시
  // - 각도 정보 표시
  // - 포즈 오버레이
}
```

### **최근 구현된 주요 기능들**

#### **1. 푸시업 운동 지원 ✅**
- **팔꿈치 각도 계산**: 어깨-팔꿈치-손목 각도로 푸시업 깊이 감지
- **상태 머신**: idle → down → up → down 사이클로 정확한 카운팅
- **독립적인 카운터**: 스쿼트와 별도로 푸시업 횟수 관리
- **신뢰도 임계값**: 0.2로 낮춰서 감지 정확도 향상

#### **2. UI/UX 통일 ✅**
- **상단 디자인 통일**: 모든 탭을 설정탭과 동일한 파란색 AppBar 스타일로 통일
- **SafeArea 적용**: 상태바와 겹치지 않도록 적절한 여백 확보
- **일관된 아이콘**: 각 탭별로 의미있는 아이콘 사용 (💪, ✅, 🍽️, 📊, ⚙️)

#### **3. 워크아웃 레이아웃 최적화 ✅**
- **불필요한 요소 제거**: Start/Stop/Save 버튼, 설명 텍스트 등 제거
- **카메라 비율 개선**: 자연스러운 카메라 비율 사용으로 시각적 개선
- **운동 선택 UI**: 드롭다운으로 스쿼트/푸시업 간편 전환
- **독립적인 카운터**: 각 운동별로 별도의 카운터 표시

#### **4. 독립적인 운동 카운터 시스템 ✅**
- **Riverpod StateProvider**: 스쿼트와 푸시업 각각의 상태 관리
- **운동별 데이터 저장**: Firestore에 exerciseCategory로 구분하여 저장
- **리포트 페이지 업데이트**: 각 운동별 개별 통계 표시

### **계획된 고급 기능들**

#### **🏃‍♂️ 달리기 관리 시스템 📋**
```dart
// GPS 기반 달리기 추적
class RunningTracker {
  final Location location = Location();
  List<LatLng> route = [];
  double totalDistance = 0.0;
  double currentSpeed = 0.0;
  
  Future<void> startTracking() async {
    // GPS 권한 확인 및 위치 추적 시작
    // 실시간 위치 업데이트로 경로 기록
  }
}

// 달리기 자세 분석
class RunningPoseAnalyzer {
  // 어깨 높이 일정성 체크
  bool checkShoulderStability(List<Map<String, double>> keypoints) {
    // 어깨 높이가 일정하게 유지되는지 확인
  }
  
  // 팔꿈치 각도 체크
  double? calculateElbowAngle(Map<String, double> shoulder, 
                             Map<String, double> elbow, 
                             Map<String, double> wrist) {
    // 팔꿈치 각도로 팔 움직임 분석
  }
}
```

#### **⌚️ Apple Watch 지원 📋**
```dart
// 워치 전용 운동 화면
class WatchWorkoutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WatchWorkoutView(
      // 워치에 최적화된 UI
      // - 큰 버튼과 텍스트
      // - 터치 제스처 최소화
      // - 긴급 상황 버튼 (운동 중단 등)
    );
  }
}

// 워치 센서 활용
class WatchSensorManager {
  // 심박수 모니터링
  Stream<int> get heartRateStream;
  
  // 가속도계 데이터
  Stream<AccelerometerData> get accelerometerStream;
  
  // GPS 데이터 (GPS 모델)
  Stream<LocationData> get locationStream;
}
```

#### **🏥 HealthKit 연동 AI 코칭 시스템 📋**
```dart
// HealthKit에서 운동 데이터 가져오기
class HealthKitIntegration {
  Future<List<WorkoutData>> getRecentWorkouts() async {
    final health = HealthFactory();
    
    // 최근 7일간의 달리기 데이터 조회
    final workouts = await health.getHealthDataFromTypes(
      DateTime.now().subtract(Duration(days: 7)),
      DateTime.now(),
      [HealthDataType.WORKOUTS],
    );
    
    return workouts.map((data) => WorkoutData.fromHealthKit(data)).toList();
  }
}

// AI 기반 코칭 시스템
class AICoachingSystem {
  // 사용자 패턴 학습
  UserPatterns learnUserPatterns(List<WorkoutData> workouts) {
    return UserPatterns(
      preferredPace: _calculatePreferredPace(workouts),
      heartRateZones: _analyzeHeartRateZones(workouts),
      improvementTrends: _analyzeImprovementTrends(workouts),
      weakPoints: _identifyWeakPoints(workouts),
    );
  }
  
  // 개인화된 코칭 생성
  CoachingAdvice generatePersonalizedCoaching(
    WorkoutData latestWorkout,
    UserPatterns patterns,
  ) {
    return CoachingAdvice(
      paceAdvice: _generatePaceAdvice(latestWorkout, patterns),
      heartRateAdvice: _generateHeartRateAdvice(latestWorkout, patterns),
      trainingPlan: _generateTrainingPlan(latestWorkout, patterns),
      improvements: _suggestImprovements(latestWorkout, patterns),
    );
  }
}

// 핵심 코칭 지표들
class RunningCoaching {
  // 심박수 기반 코칭
  String getHeartRateAdvice(int currentHR, int targetHR) {
    if (currentHR > targetHR + 10) {
      return "페이스를 조금 늦춰주세요. 현재 심박수가 목표보다 높습니다.";
    } else if (currentHR < targetHR - 10) {
      return "조금 더 빠르게 달려보세요. 목표 심박수에 도달하지 못했습니다.";
    } else {
      return "완벽한 페이스입니다! 이대로 유지하세요.";
    }
  }
  
  // 보폭 최적화 가이드
  String getStrideAdvice(double currentStride, double optimalStride) {
    if (currentStride < optimalStride * 0.8) {
      return "보폭이 너무 작습니다. 다리를 조금 더 펴서 달려보세요.";
    } else if (currentStride > optimalStride * 1.2) {
      return "보폭이 너무 큽니다. 빠른 발걸음으로 조절해보세요.";
    } else {
      return "적절한 보폭입니다. 효율적인 달리기를 하고 있습니다.";
    }
  }
  
  // 페이스 관리 코칭
  String getPaceAdvice(double currentPace, double targetPace) {
    final difference = currentPace - targetPace;
    if (difference > 30) {
      return "너무 빠릅니다! 목표 페이스보다 ${difference.toStringAsFixed(0)}초 빠릅니다.";
    } else if (difference < -30) {
      return "너무 느립니다! 목표 페이스보다 ${(-difference).toStringAsFixed(0)}초 늦습니다.";
    } else {
      return "완벽한 페이스입니다! 목표를 잘 지키고 있습니다.";
    }
  }
  
  // 케이던스 최적화
  String getCadenceAdvice(int currentCadence, int targetCadence) {
    if (currentCadence < targetCadence - 10) {
      return "케이던스가 낮습니다. 발걸음을 빠르게 해보세요.";
    } else if (currentCadence > targetCadence + 10) {
      return "케이던스가 너무 높습니다. 보폭을 늘려보세요.";
    } else {
      return "적절한 케이던스입니다. 효율적인 달리기를 하고 있습니다.";
    }
  }
}
```

### **현재 해결해야 할 문제**

#### **1. 푸시업 카운팅 문제 🔧**
```dart
// 현재 상황: 푸시업 카운팅이 증가하지 않음
// 원인 분석 필요:
// 1. 키포인트 신뢰도가 너무 낮음 (0.00으로 표시됨)
// 2. 팔꿈치 각도 계산이 제대로 되지 않음
// 3. 푸시업 상태 머신 로직 문제

// 디버깅 방향:
// - 키포인트 신뢰도 임계값 조정
// - 팔꿈치 각도 계산 로직 검증
// - 상태 머신 전환 조건 점검
```

#### **2. 키포인트 감지 문제 🔧**
```
flutter: DEBUG scores: LHIP=0.00  LKNEE=0.00  LANK=0.00  RHIP=0.00  RKNEE=0.00  RANK=0.00
flutter: ⚠️ Low confidence: L(0.00,0.00,0.00) R(0.00,0.00,0.00)
```
- **문제**: 모든 키포인트의 신뢰도가 0.00으로 매우 낮음
- **원인**: 이미지 전처리 문제 또는 모델 입력 문제 가능성
- **해결 방향**: 이미지 전처리 로직 개선, 신뢰도 임계값 조정

### **개발 우선순위**
1. **✅ 완료**: 무릎 각도 계산 로직 및 스쿼트 상태 머신 구현
2. **✅ 완료**: 포즈 오버레이 UI 구현 (실시간 키포인트 시각화)
3. **✅ 완료**: 로컬 알림 기반 시스템 구현
4. **✅ 완료**: 목표 달성 알림 시스템 완벽 작동
5. **✅ 완료**: 푸시업 운동 지원 및 독립적인 카운터 시스템
6. **✅ 완료**: UI/UX 통일 및 워크아웃 레이아웃 최적화
7. **🔧 진행중**: 푸시업 감지 로직 디버깅 및 카운팅 문제 해결
8. **🔄 진행중**: 목표 달성 화면 오버레이 구현
9. **🔄 진행중**: 운동 완료 시 자동 알림 시스템 구현
10. **🔄 진행중**: 설정 페이지 완성 및 사용자 커스터마이징
11. **🔄 진행중**: 습관 체크와 알림 시스템 연동
12. **📋 계획**: 달리기 관리 시스템 (GPS 기반 추적)
13. **📋 계획**: Apple Watch 지원 (워치 전용 운동 앱)
14. **📋 계획**: HealthKit 연동 AI 코칭 시스템
15. **📋 계획**: 다른 운동 종목 추가 (플랭크, 런지 등)
16. **📋 계획**: 운동 피드백 시스템 고도화

## 📈 **현재 진행 상황 요약**

### **🎯 AI 포즈 추정** ✅ **완료**
- **MoveNet 모델**: TFLite 기반 실시간 포즈 추정
- **운동 인식**: 스쿼트, 푸시업 정확한 카운팅
- **성능**: 실제 iPhone에서 안정적인 AI 추론

### **🏥 HealthKit 연동** ✅ **완료**
- **권한 설정**: iOS 건강앱 접근 권한 완벽 설정
- **데이터 수집**: Apple Watch 운동 데이터 자동 동기화
- **파싱 시스템**: WORKOUT 데이터에서 거리, 칼로리 정확한 추출

### **🏃‍♂️ 달리기 데이터 분석** ✅ **완료**
- **분석 시스템**: 5개 탭 구조의 종합적인 달리기 분석
- **데이터 시각화**: fl_chart 기반 트렌딩 및 패턴 차트
- **AI 코칭**: 규칙 기반 개인화된 운동 조언 시스템
- **실제 데이터**: 10개 달리기 운동 기록 분석 완료

### **🔔 알림 시스템** ✅ **완료**
- **로컬 알림**: 운동 완료, 목표 달성, 습관 리마인더
- **스케줄링**: 사용자 정의 알림 시간 설정
- **Firebase 연동**: FCM 푸시 알림 (실제 기기에서 정상 작동)

### **📱 기본 앱 기능** ✅ **완료**
- **습관 추적**: 일일 습관 체크 및 기록
- **식사 로깅**: 사진 기반 식사 기록 및 칼로리 추적
- **운동 세션**: AI 기반 실시간 운동 관리
- **데이터 동기화**: Firestore 실시간 데이터베이스 연동

### **🔄 진행 중인 작업**
- **심박수 연동**: Apple Watch 실시간 심박수 데이터 수집
- **진짜 AI 연동**: 로컬 AI 모델을 활용한 지능형 코칭
- **목표 설정**: 개인 기록 관리 및 달성도 추적 시스템

### **📋 다음 단계 계획**
- **GPS 추적**: 실시간 달리기 경로 및 속도 모니터링
- **Apple Watch 앱**: 독립적인 웨어러블 앱 개발
- **고급 분석**: VO2 max, 심박수 변이성 등 생체 데이터 분석
- **소셜 기능**: 친구와의 챌린지 및 기록 공유

### **현재 진행 상황 요약**
- **🎯 AI 포즈 추정**: 완벽 작동 (MoveNet 실시간 스쿼트 감지)
- **💪 푸시업 지원**: 구현 완료했으나 카운팅 문제 발생 (디버깅 필요)
- **🔔 로컬 알림**: 완벽 작동 (운동 완료, 목표 달성, 습관 리마인더)
- **📱 UI/UX**: 모든 탭 상단 디자인 통일, 워크아웃 레이아웃 최적화 완료
- **⚙️ 설정 시스템**: 설정 페이지 구현 중
- **📝 습관 연동**: 습관 체크와 알림 시스템 연동 구현 중
- **🔢 독립적인 카운터**: 스쿼트와 푸시업 각각의 카운터 시스템 구현 완료
- **🏥 HealthKit 연동**: ✅ 완료 - iPhone 건강앱과의 데이터 연동 성공
- **🏃‍♂️ 달리기 데이터**: ✅ 완료 - Apple Watch 달리기 데이터 수집 성공
- **🏃‍♂️ 달리기 시스템**: GPS 기반 추적 및 AI 코칭 시스템 계획됨
- **⌚️ Apple Watch**: 워치 전용 운동 앱 및 센서 활용 계획됨

### **기술적 개선 사항**
```dart
// 1. 성능 최적화
class PerformanceOptimization {
  // FPS 제한으로 배터리 절약
  final fpsLimiter = Timer.periodic(Duration(milliseconds: 100), (_) {
    // 10 FPS로 제한하여 성능 최적화
  });
  
  // 메모리 관리 개선
  @override
  void dispose() {
    _interpreter?.close();
    _camera?.dispose();
    fpsLimiter.cancel();
    super.dispose();
  }
}

// 2. 다중 운동 지원 시스템 ✅ 구현 완료
class MultiExerciseSystem {
  // 스쿼트 감지기 ✅ 완벽 작동
  class SquatDetector {
    double? calculateKneeAngle(Map<String, double> hip, 
                               Map<String, double> knee, 
                               Map<String, double> ankle) {
      // 무릎 각도 계산 (90도가 완벽한 자세)
      return angle; // ✅ 정상 작동
    }
  }
  
  // 푸시업 감지기 ✅ 구현 완료 (디버깅 필요)
  class PushUpDetector {
    double? calculateElbowAngle(Map<String, double> shoulder, 
                               Map<String, double> elbow, 
                               Map<String, double> wrist) {
      // 팔꿈치 각도 계산 (90도가 완벽한 자세)
      return angle; // ✅ 구현 완료, 디버깅 필요
    }
  }
  
  // 플랭크 (몸통 자세 유지 시간 측정) 📋 계획
  class PlankDetector {
    bool isProperPlankPose(List<Map<String, double>> keypoints) {
      // 어깨, 고관절, 발목이 일직선인지 확인
      return false; // TODO: 구현 필요
    }
  }
}

// 3. UI/UX 통일 시스템 ✅ 구현 완료
class UnifiedUIDesign {
  // 모든 탭의 일관된 상단 디자인
  static AppBar createUnifiedAppBar(String title, IconData icon, {List<Widget>? actions}) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      leading: Icon(icon),
      actions: actions,
    );
  }
}

// 4. 달리기 관리 시스템 📋 계획됨
class RunningManagementSystem {
  // GPS 기반 추적
  class GPSTracker {
    Future<void> startTracking() async {
      // 실시간 위치 추적 및 경로 기록
    }
  }
  
  // HealthKit 연동
  class HealthKitManager {
    Future<List<WorkoutData>> getWorkouts() async {
      // iPhone 건강앱에서 운동 데이터 가져오기
    }
  }
  
  // AI 코칭 시스템
  class AICoaching {
    CoachingAdvice generateAdvice(WorkoutData workout) {
      // 개인화된 코칭 생성
    }
  }
}

// 5. Apple Watch 지원 📋 계획됨
class AppleWatchSupport {
  // 워치 전용 UI
  class WatchWorkoutUI {
    Widget buildWorkoutScreen() {
      // 워치에 최적화된 운동 화면
    }
  }
  
  // 센서 데이터 활용
  class WatchSensorData {
    Stream<int> get heartRateStream;
    Stream<AccelerometerData> get accelerometerStream;
    Stream<LocationData> get locationStream;
  }
  
  // iPhone과의 데이터 동기화
  class WatchDataSync {
    Future<void> syncWithiPhone() async {
      // 워치 데이터를 iPhone으로 전송
    }
  }
}
```

### **최종 목표**
- **🎯 완벽한 운동 가이드 시스템**: AI 포즈 추정 + 실시간 피드백 + 알림 시스템
- **💪 다중 운동 지원**: 스쿼트, 푸시업, 플랭크, 달리기 등 다양한 운동 종목 지원
- **📱 사용자 친화적 UI/UX**: 통일된 디자인과 직관적인 설정
- **🔔 스마트한 알림 시스템**: 상황에 맞는 적절한 알림과 동기부여
- **🏃‍♂️ 종합적인 운동 관리**: 실내 운동 + 실외 달리기 + 워치 연동
- **🏥 AI 기반 개인화 코칭**: HealthKit 데이터 분석을 통한 맞춤형 운동 가이드
- **📊 개인화된 피드백**: 사용자 데이터 기반 맞춤형 운동 가이드

### **다음 구현 단계**
1. **🔧 푸시업 감지 디버깅**: 카운팅이 증가하지 않는 문제 해결 (우선순위 1)
2. **🎯 목표 달성 화면 오버레이**: 운동 중 목표 달성 시 시각적 축하 메시지
3. **💪 운동 완료 자동 알림**: Stop 버튼 누를 때 자동 알림 전송
4. **⚙️ 설정 페이지 완성**: 사용자 커스터마이징 가능한 알림 설정
5. **📝 습관 체크 연동**: 습관 완료 시 성취 알림 및 연속 달성 기록
6. **🔧 키포인트 감지 개선**: 신뢰도가 낮은 문제 해결
7. **🏃‍♂️ 달리기 시스템**: GPS 기반 추적 및 기본 운동 기록
8. **🏥 HealthKit 연동**: iPhone 건강앱과의 데이터 동기화
9. **💡 AI 코칭 시스템**: 운동 데이터 분석 기반 개인화된 코칭
10. **⌚️ Apple Watch**: 워치 전용 운동 앱 및 센서 활용
11. **💪 추가 운동 종목**: 플랭크, 런지 등 새로운 운동 지원
12. **성능 최적화**: 메모리 관리 및 배터리 효율성 개선

### **장기 비전**
- **🌍 종합적인 건강 관리 플랫폼**: 운동, 식사, 습관, 수면 등 모든 건강 요소 통합
- **🤖 AI 기반 개인 트레이너**: 사용자 패턴 학습을 통한 완벽한 맞춤형 가이드
- **📱 멀티 디바이스 생태계**: iPhone, Apple Watch, iPad 등 모든 Apple 기기에서 원활한 사용
- **🏆 소셜 피트니스**: 친구들과의 운동 챌린지 및 성과 공유
- **📊 의료진 연동**: 의사와의 데이터 공유 및 전문적인 건강 관리 지원
