# Flutter 앱 통합 가이드

## 🎯 현재 상태

### ✅ 완료된 작업
- AI-Hub 서버 API 구현 (`http://localhost:5001`)
- 800개 한국 음식 클래스 지원
- Flutter `MealAIService` 서버 URL 업데이트 완료
- 웹 테스트 페이지 구현

### 📱 Flutter 앱에서 테스트하기

#### 1. 서버 실행 확인
```bash
cd training_scripts/aihub_server
docker-compose -f docker-compose.yml ps
```

서버가 실행 중이 아니면:
```bash
docker-compose -f docker-compose.yml up -d
```

#### 2. Flutter 앱 실행

##### iOS 시뮬레이터
```bash
flutter run -d "iPhone 15 Pro"
```

##### Android 에뮬레이터
```bash
flutter run -d emulator-5554
```

#### 3. 앱에서 테스트

1. **식사 기록 화면**으로 이동
2. **"사진으로 추가"** 버튼 클릭
3. **카메라 또는 갤러리**에서 음식 사진 선택
4. **AI 분석 결과** 확인

### 🔧 문제 해결

#### localhost 연결 문제

**iOS 시뮬레이터**: `localhost`가 정상 작동
**Android 에뮬레이터**: `10.0.2.2` 사용 필요

`lib/services/meal_ai_service.dart` 수정:
```dart
// Android 에뮬레이터용
static const String _aihubServerUrl = 'http://10.0.2.2:5001';
```

또는 조건부 처리:
```dart
static String get _aihubServerUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:5001';
  }
  return 'http://localhost:5001';
}
```

#### CORS 문제

서버에서 CORS가 이미 활성화되어 있습니다:
```python
from flask_cors import CORS
CORS(app)
```

#### 네트워크 권한 (Android)

`android/app/src/main/AndroidManifest.xml`에 이미 추가되어 있어야 합니다:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

#### 네트워크 보안 설정 (Android)

`android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>
</network-security-config>
```

`AndroidManifest.xml`에 추가:
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

### 📊 API 응답 예시

#### 성공 응답
```json
{
  "success": true,
  "predictions": [
    {
      "food_name": "김치찌개",
      "confidence": 0.92,
      "bbox": [100, 100, 300, 300]
    },
    {
      "food_name": "된장찌개",
      "confidence": 0.85,
      "bbox": [150, 150, 350, 350]
    }
  ],
  "total_detections": 2,
  "note": "Using dummy model (MMDetection not available)"
}
```

#### 실패 응답
```json
{
  "success": false,
  "error": "cannot identify image file",
  "predictions": []
}
```

### 🧪 테스트 방법

#### 1. 웹 테스트 페이지
```bash
open training_scripts/aihub_server/test_web.html
```

#### 2. cURL 테스트
```bash
# 서버 상태
curl http://localhost:5001/health

# 클래스 목록
curl http://localhost:5001/classes

# 음식 분류 (이미지 파일 필요)
curl -X POST http://localhost:5001/predict \
  -F "image=@/path/to/food.jpg"
```

#### 3. Flutter 앱에서 직접 테스트
- 앱 실행 후 식사 기록 화면에서 사진 업로드

### 🎯 다음 단계

#### 실제 AI-Hub 모델 통합 (선택사항)
현재는 더미 모델로 작동하며, 실제 모델 통합은 다음과 같은 방법으로 가능합니다:

1. **GPU 서버 사용**: CUDA 환경에서 MMDetection 빌드
2. **클라우드 API**: Google Cloud Vision, AWS Rekognition
3. **TFLite 변환**: AI-Hub 모델을 TFLite로 변환하여 Flutter에서 직접 사용
4. **사전 빌드 Docker**: OpenMMLab 공식 이미지 활용

#### 프로덕션 배포
1. **서버 호스팅**: AWS, GCP, Azure 등
2. **도메인 설정**: `https://api.yourapp.com`
3. **환경 변수**: 개발/프로덕션 서버 URL 분리
4. **인증**: API 키 또는 JWT 토큰

### 📝 주요 파일

- `lib/services/meal_ai_service.dart` - Flutter AI 서비스
- `training_scripts/aihub_server/app.py` - Flask API 서버
- `training_scripts/aihub_server/docker-compose.yml` - Docker 설정
- `training_scripts/aihub_server/test_web.html` - 웹 테스트 페이지

### 💡 팁

1. **개발 중에는 더미 모델로 충분합니다**
   - UI/UX 테스트
   - 데이터 흐름 확인
   - 에러 핸들링 검증

2. **실제 모델은 프로덕션 단계에서 통합**
   - 성능 최적화 필요
   - 서버 비용 고려
   - 사용자 피드백 수집 후 개선

3. **로컬 TFLite 모델도 병행 사용**
   - 오프라인 지원
   - 빠른 응답 속도
   - 서버 장애 대비

### 🚀 시작하기

```bash
# 1. 서버 시작
cd training_scripts/aihub_server
docker-compose -f docker-compose.yml up -d

# 2. Flutter 앱 실행
cd ../..
flutter run

# 3. 앱에서 음식 사진 업로드 테스트
```

### ✅ 체크리스트

- [x] AI-Hub 서버 API 구현
- [x] 800개 한국 음식 클래스 지원
- [x] Flutter MealAIService 서버 연동
- [x] 웹 테스트 페이지 구현
- [ ] Flutter 앱에서 실제 테스트
- [ ] Android 에뮬레이터 네트워크 설정
- [ ] 에러 핸들링 개선
- [ ] 로딩 UI 추가
- [ ] 실제 AI-Hub 모델 통합 (선택)


