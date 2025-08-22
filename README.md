# HabitFit MVP (Flutter Template)

> 한 앱에서 **습관 체크 + 스쿼트 카운트(카메라) + 식사 사진 1장 칼로리 기록**의 일일 루프를 검증하는 스켈레톤입니다.
> Firestore/FCM/Camera(이미지 스트림)/MoveNet(연동 자리)까지 기본 구조를 갖췄습니다.

## 1) 빠른 시작

```bash
# Flutter 프로젝트 뼈대 생성(플랫폼 폴더 생성)
flutter create .

# 의존성 설치
flutter pub get
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
- 현재는 **MockEstimator**로 동작합니다. 실제 MoveNet을 쓰려면:
  1) 모델 다운로드: MoveNet Lightning(TFLite) (예: `movenet_singlepose_lightning.tflite`)
  2) `assets/models/movenet.tflite`로 저장
  3) `pose_estimator.dart`의 TODO 주석에 따라 `tflite_flutter`를 이용한 엔진 구현
  4) `pubspec.yaml`의 assets 경로가 이미 등록되어 있습니다.

> ML Kit Pose Detection을 쓰고 싶다면 패키지 교체 및 플랫폼 세팅을 진행하세요. 본 템플릿은 TFLite 경로를 기준으로 한 구조 예시입니다.

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

## 6) 주의 사항

- 본 템플릿은 **스켈레톤**입니다. 실제 배포 전 보안(익명 로그인→이메일 전환), 삭제/비식별화, 예외 처리 등을 보완하세요.
- 카메라 스트림/포즈 인식은 기기 성능과 빌드 설정에 따라 FPS가 달라질 수 있습니다.

---

© 2025 HabitFit MVP Template


## 7) MoveNet(TFLite) 실제 구현 포함
- `lib/features/workout/pose_estimator.dart`에 **MoveNetEstimator** 구현 완비
- 입력: CameraImage(YUV/BGRA) → RGB(192x192) 변환 → TFLite 추론 → 17 keypoints
- 출력: 무릎 각도로 상태머신(down/up) → rep 카운트 증가
- **필수**: 모델 파일을 `assets/models/movenet.tflite` 로 교체(예: singlepose lightning 192x192)
- iOS의 경우 BGRA, Android는 YUV420 경로로 처리합니다.
- 성능 팁: 중저가 기기에서는 FPS를 15 이하로 제한하거나, `ResolutionPreset.low`로 시작하세요.


## 8) 스켈레톤 오버레이 + 히스테리시스/스무딩 + Remote Config AB 테스트

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
