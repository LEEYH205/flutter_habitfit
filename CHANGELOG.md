ㄹ# Changelog

All notable changes to habitfit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Firebase App Distribution을 통한 테스트 배포 시스템

### Changed
- 앱 이름을 RoutineX에서 habitfit으로 변경
- 새로운 불꽃 + 도트 디자인의 앱 아이콘 적용

### Fixed
- iOS Info.plist 파일의 XML 파싱 오류 수정
- Import 경로를 package:routinex에서 package:habitfit_mvp로 수정

## [0.1.0] - 2025-09-04

### Added
- 🎯 **AI 기반 실시간 운동 인식**
  - TensorFlow Lite MoveNet 모델을 활용한 포즈 추정
  - 스쿼트, 푸시업 실시간 카운팅
  - 17개 키포인트 기반 정확한 자세 분석
  - 무릎/팔꿈치 각도 계산으로 운동 깊이 측정

- 🏥 **HealthKit 완전 연동**
  - iOS 건강앱과의 데이터 동기화
  - Apple Watch 운동 데이터 자동 수집
  - 달리기, 걷기, 자전거 등 다양한 운동 타입 지원
  - 심박수, 거리, 칼로리, 속도 등 상세 메트릭 수집

- 🏃‍♂️ **고급 러닝 분석 시스템**
  - 5개 탭 구조의 종합적인 달리기 분석 (요약, 트렌딩, 심박수, 페이스, 패턴)
  - fl_chart 기반 데이터 시각화
  - AI 기반 개인화된 코칭 시스템
  - 요일별, 시간대별 운동 패턴 분석

- 🔔 **스마트 알림 시스템**
  - 로컬 알림 기반 운동 완료, 목표 달성 알림
  - 습관 체크 리마인더
  - 사용자 정의 알림 시간 설정
  - Firebase Cloud Messaging 연동

- 📱 **사용자 인증 시스템**
  - Google Sign-In 연동
  - 이메일/비밀번호 인증
  - Firebase Authentication 기반 사용자 관리
  - UID 기반 데이터 분리 및 보안

- 📊 **습관 및 피트니스 추적**
  - 일일 습관 체크 및 연속 달성 기록
  - 식사 기록 및 칼로리 추적
  - AI 기반 실시간 운동 세션 관리
  - Firestore 실시간 데이터베이스 연동

- 🎨 **통일된 UI/UX 디자인**
  - Material Design 3 기반 최신 디자인
  - 모든 탭의 일관된 상단 디자인
  - 다크/라이트 테마 지원
  - 반응형 레이아웃

### Technical Details
- **Frontend**: Flutter 3.35.1 + Dart 3.9.0
- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore, Messaging, Remote Config)
- **AI/ML**: TensorFlow Lite (MoveNet Lightning 모델)
- **Health Integration**: iOS HealthKit 네이티브 연동
- **Data Visualization**: fl_chart
- **Local Notifications**: flutter_local_notifications

### Performance
- 실시간 30fps AI 추론 성능 (iPhone에서 안정적 동작)
- 최적화된 메모리 관리 및 배터리 효율성
- Firebase 실시간 데이터 동기화

### Known Issues
- Android 빌드 시 Health 패키지 호환성 문제
- 일부 고급 HealthKit 기능은 iOS에서만 완전 지원
- FCM 푸시 알림은 실제 기기에서만 정상 작동

### Testing
- iPhone 물리 기기에서 AI 추론 성능 검증 완료
- HealthKit 데이터 수집 및 파싱 정확성 검증 완료
- 사용자 인증 플로우 및 데이터 보안 검증 완료
- UI/UX 전반적인 사용성 테스트 완료

---

## Release Notes for Firebase App Distribution

### v0.1.0 - habitfit 첫 테스트 버전

🎉 **habitfit 첫 테스트 버전을 출시합니다!**

이 버전은 AI 기반 운동 인식과 HealthKit 연동을 통한 종합적인 피트니스 앱입니다.

#### ✨ 주요 기능
- **AI 운동 인식**: 실시간 스쿼트/푸시업 카운팅
- **HealthKit 연동**: Apple Watch 데이터 자동 수집
- **습관 추적**: 달력 기반 습관 관리
- **식사 기록**: 사진 기반 칼로리 추적
- **사용자 인증**: Google Sign-In, 이메일 인증

#### 🔧 기술 스택
- Flutter + Riverpod 상태 관리
- TensorFlow Lite MoveNet 모델
- Firebase (Auth, Firestore, Messaging)
- HealthKit 네이티브 연동

#### 📱 지원 플랫폼
- iOS (iPhone, iPad)
- HealthKit 권한 필요

#### ⚠️ 알려진 이슈
- Android 빌드 문제 (Health 패키지 호환성)
- 일부 기능은 iOS에서만 완전 지원

#### 🧪 테스트 포인트
- 운동 인식 정확도
- HealthKit 데이터 수집
- 사용자 인증 플로우
- UI/UX 전반적인 사용성

#### 📋 테스트 방법
1. 앱 설치 후 Google Sign-In 또는 이메일로 회원가입
2. HealthKit 권한 허용
3. 운동 탭에서 스쿼트/푸시업 테스트
4. 리포트 탭에서 HealthKit 데이터 확인
5. 습관 및 식사 기록 기능 테스트

#### 🐛 버그 리포트
테스트 중 발견된 버그나 개선사항은 개발팀에 알려주세요.

---

*이 릴리즈 노트는 Firebase App Distribution 업로드 시 사용됩니다.*
