# HabitFit MVP (Flutter Template)

> 한 앱에서 **습관 체크 + 스쿼트 카운트(카메라) + 식사 사진 1장 칼로리 기록**의 일일 루프를 검증하는 스켈레톤입니다.
> Firestore/FCM/Camera(이미지 스트림)/MoveNet(연동 자리)까지 기본 구조를 갖췄습니다.

## 📋 요구사항

- **Flutter**: 3.35.1 이상
- **Dart**: 3.9.0 이상
- **iOS**: 11.0 이상
- **Android**: API 21 (Android 5.0) 이상

## 1) 빠른 시작

```bash
# Flutter 버전 확인
flutter --version

# Flutter 프로젝트 뼈대 생성(플랫폼 폴더 생성)
flutter create .

# 의존성 설치
flutter pub get

# 프로젝트 분석 (에러 확인)
flutter analyze
```

> **Firebase 연결 필수**: 아래 2단계에서 `firebase_options.dart`를 생성해야 앱이 실행됩니다.

## 2) Firebase 연결(필수)

1. Firebase 콘솔에서 프로젝트 생성 → iOS/Android 앱 등록
2. FlutterFire CLI 설치 및 연결
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
- 위 명령으로 `lib/firebase_options.dart`가 생성됩니다. (본 템플릿의 placeholder 파일을 덮어씁니다)
- Cloud Firestore / Cloud Messaging(FCM) 활성화
- Android: `google-services.json` / iOS: `GoogleService-Info.plist` 자동 배치 확인

3. Android/iOS 권한 설정
   - **Android**: `android/app/src/main/AndroidManifest.xml`
     - 카메라 권한, POST_NOTIFICATIONS 권한 (Android 13+)
   - **iOS**: `ios/Runner/Info.plist`
     - `NSCameraUsageDescription`, 알림 권한 설명

## 3) MoveNet(포즈 인식) 연동

- 기본 코드는 **이미지 스트림**을 열고 `PoseEstimator` 인터페이스로 프레임을 전달합니다.
- **현재 상태**: TFLite Flutter API 호환성 문제로 임시 더미 구현으로 대체되어 있습니다.
- 실제 MoveNet을 사용하려면:
  1) TFLite Flutter 패키지 최신 API 문서 확인
  2) `pose_estimator.dart`의 주석 처리된 코드를 최신 API에 맞게 수정
  3) 모델 다운로드: MoveNet Lightning(TFLite) (예: `movenet_singlepose_lightning.tflite`)
  4) `assets/models/movenet.tflite`로 저장
  5) `pubspec.yaml`의 assets 경로가 이미 등록되어 있습니다.

> **참고**: `tflite_flutter` 패키지의 API가 크게 변경되어 기존 코드가 동작하지 않습니다. 최신 문서를 참고하여 업데이트가 필요합니다.

## 4) 기능 개요

- **Habit**: 하루 1개 습관 체크(완료/미완료) → Firestore 기록
- **Workout**: 카메라 프리뷰 + 이미지 스트림 → (Mock) 각도/rep 카운트 자리
- **Meals**: 사진 1장 업로드 → 라벨 선택 → 간단 kcal 매핑 → Firestore 저장
- **Report**: 오늘 요약(습관/스쿼트/칼로리) 조회

## 5) 빌드/실행

```bash
flutter run
```

웹 타겟으로 먼저 형태를 확인하고(카메라 권한 이슈는 모바일 권장), 모바일에서 권한/FCM 토큰 확인 후 푸시 실험을 진행하세요.

## 6) 문제 해결

### 일반적인 에러

```bash
# SDK 버전 충돌 시
flutter upgrade

# 의존성 충돌 시  
flutter pub deps
flutter clean
flutter pub get

# 분석 에러 확인
flutter analyze
```

### 주요 수정 사항 (v2025.1)

- **Flutter 3.35.1 호환성**: Dart 3.9.0 업데이트
- **API 변경 사항**:
  - `String.padStart()` → `String.padLeft()` 
  - `DropdownButtonFormField.value` → `initialValue`
  - TFLite Flutter API 호환성 문제로 임시 더미 구현
- **불필요한 코드 제거**: unused imports, type casts 정리

## 7) 주의 사항

- 본 템플릿은 **스켈레톤**입니다. 실제 배포 전 보안(익명 로그인→이메일 전환), 삭제/비식별화, 예외 처리 등을 보완하세요.
- 카메라 스트림/포즈 인식은 기기 성능과 빌드 설정에 따라 FPS가 달라질 수 있습니다.
- **TFLite 기능**: 현재 비활성화 상태입니다. 실제 포즈 인식을 사용하려면 최신 API 문서를 참고하여 구현해야 합니다.

---

© 2025 HabitFit MVP Template


## 8) MoveNet(TFLite) 구현 상태
- `lib/features/workout/pose_estimator.dart`에 **MoveNetPoseEstimator** 구조 준비됨
- **현재**: TFLite Flutter API 변경으로 인해 주석 처리 및 임시 더미 구현
- **원래 설계**:
  - 입력: CameraImage(YUV/BGRA) → RGB(192x192) 변환 → TFLite 추론 → 17 keypoints
  - 출력: 무릎 각도로 상태머신(down/up) → rep 카운트 증가
  - iOS: BGRA, Android: YUV420 경로 처리
- **복원 방법**: 최신 `tflite_flutter` API 문서를 참고하여 주석 처리된 코드를 업데이트
- **모델 파일**: `assets/models/movenet.tflite` (singlepose lightning 192x192 권장)


## 9) 스켈레톤 오버레이 + 히스테리시스/스무딩 + Remote Config AB 테스트

- **스켈레톤 오버레이**: `PoseOverlay`(CustomPainter)로 카메라 프리뷰 위에 17개 키포인트와 연결선 표시
- **히스테리시스**: `downEnter` / `upExit` 임계값을 분리해 노이즈에 강함
- **이동평균 스무딩**: 최근 N프레임(기본 5) 무릎각 평균으로 흔들림 감소
- **원격 임계값 주입**: `Remote Config`에서 다음 파라미터를 가져와 주입
  - `squat_down_enter` (기본 100.0)
  - `squat_up_exit` (기본 160.0)
  - `angle_smooth_window` (기본 5)

### AB 테스트 방법 예시
Firebase 콘솔 👉 Remote Config에서 Variant 생성:
- **Variant A**: `squat_down_enter=95`, `squat_up_exit=155`, `angle_smooth_window=7`
- **Variant B**: `squat_down_enter=105`, `squat_up_exit=165`, `angle_smooth_window=5`

앱 내 지표(오탐율/미탐율, rep 속도, 사용자 평가)를 Analytics 이벤트로 로깅하여 더 안정적인 설정을 선택하세요.
