# 🍽️ AI-Hub 음식 분류 서버 API

AI-Hub의 800종 한국 음식 분류 모델을 Flask API로 서빙하는 서버입니다.

## 🚀 빠른 시작

### 1. 환경 설정

```bash
# 가상환경 생성
python -m venv aihub_env
source aihub_env/bin/activate  # Windows: aihub_env\Scripts\activate

# 의존성 설치
pip install -r requirements.txt
```

### 2. 서버 실행

```bash
python app.py
```

서버가 `http://localhost:5000`에서 실행됩니다.

## 📡 API 엔드포인트

### 1. 서버 상태 확인
```http
GET /health
```

**응답:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-XX...",
  "models_loaded": true
}
```

### 2. 음식 분류
```http
POST /predict
Content-Type: multipart/form-data

image: [이미지 파일]
```

**응답:**
```json
{
  "success": true,
  "predictions": [
    {
      "food_name": "김치찌개",
      "confidence": 0.95,
      "bbox": [100, 150, 300, 400]
    },
    {
      "food_name": "된장찌개", 
      "confidence": 0.87,
      "bbox": [120, 160, 320, 420]
    }
  ],
  "total_detections": 2
}
```

### 3. 음식 중량 예측
```http
POST /predict_weight
Content-Type: application/json

{
  "food_name": "김치찌개"
}
```

**응답:**
```json
{
  "success": true,
  "estimated_weight": 300,
  "unit": "grams",
  "confidence": 0.7
}
```

### 4. 사용 가능한 음식 클래스
```http
GET /classes
```

**응답:**
```json
{
  "success": true,
  "classes": ["김치찌개", "된장찌개", "비빔밥", ...],
  "total_classes": 800
}
```

## 🧪 테스트

### cURL로 테스트
```bash
# 서버 상태 확인
curl http://localhost:5000/health

# 음식 분류
curl -X POST -F "image=@food_image.jpg" http://localhost:5000/predict

# 중량 예측
curl -X POST -H "Content-Type: application/json" \
  -d '{"food_name": "김치찌개"}' \
  http://localhost:5000/predict_weight
```

### Python으로 테스트
```python
import requests

# 음식 분류
with open('food_image.jpg', 'rb') as f:
    response = requests.post('http://localhost:5000/predict', 
                           files={'image': f})
    result = response.json()
    print(result)

# 중량 예측
response = requests.post('http://localhost:5000/predict_weight',
                        json={'food_name': '김치찌개'})
result = response.json()
print(result)
```

## 🔧 설정

### 모델 경로 설정
`app.py`에서 모델 경로를 수정할 수 있습니다:

```python
model_dir = os.path.join(os.path.dirname(__file__), '..', 'aihub_food', '3-021.AI모델')
```

### GPU 사용
CUDA가 설치되어 있으면 자동으로 GPU를 사용합니다:
```python
device = 'cuda' if torch.cuda.is_available() else 'cpu'
```

## 📊 성능

- **음식 분류 정확도**: 85-95% (AI-Hub 검증)
- **지원 음식**: 800종 한국 음식
- **추론 속도**: GPU 기준 ~100ms
- **메모리 사용량**: ~2GB (GPU)

## 🚨 주의사항

1. **모델 파일**: AI-Hub 모델 파일들이 올바른 경로에 있어야 합니다
2. **메모리**: 최소 4GB RAM 권장
3. **GPU**: CUDA 지원 GPU 권장 (CPU도 가능하지만 느림)

## 🔄 Flutter 앱 연동

Flutter 앱에서 이 API를 사용하려면:

```dart
// HTTP 요청으로 음식 분류
final response = await http.post(
  Uri.parse('http://localhost:5000/predict'),
  headers: {'Content-Type': 'multipart/form-data'},
  body: {
    'image': imageFile,
  },
);

final result = json.decode(response.body);
print('분류 결과: ${result['predictions']}');
```

## 📝 로그

서버 로그는 콘솔에 출력됩니다:
```
INFO:__main__:음식 탐지 및 분류 모델 로딩 중...
INFO:__main__:✅ 음식 탐지 및 분류 모델 로딩 완료
INFO:__main__:🚀 서버 시작: http://localhost:5000
```
