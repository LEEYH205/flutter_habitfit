# 🍽️ AI-Hub 데이터셋을 활용한 음식분류 모델 튜닝

이 문서는 AI-Hub의 음식이미지 데이터셋을 활용하여 기존 Food-101 기반 음식분류 모델을 한국 음식에 특화하여 개선하는 방법을 설명합니다.

## 📋 개요

### AI-Hub 데이터셋 특징
- **232,087장**의 대규모 한국 음식 이미지
- **800종**의 다양한 음식 (한식 중심 + 외식메뉴)
- **4개 카테고리**: 특수외식메뉴, 일반외식·배달메뉴, 끼니대체메뉴, 음료 및 차류
- **바운딩박스** 라벨링으로 정확한 음식 영역 식별
- **영양정보** 텍스트 데이터 포함

### 기존 모델과의 차이점
- **Food-101**: 주로 서양 음식 중심 (101개 클래스)
- **AI-Hub**: 한국 음식 특화 (800개 클래스)
- **개선 효과**: 한국 음식 인식 정확도 대폭 향상 예상

## 🚀 사용 방법

### 1. AI-Hub 데이터셋 다운로드

1. [AI-Hub 웹사이트](https://www.aihub.or.kr/aihubdata/data/view.do?dataSetSn=71564) 접속
2. 회원가입 및 로그인
3. 데이터셋 다운로드 신청
4. 승인 후 데이터 다운로드

### 2. 환경 설정

```bash
# 의존성 설치
cd training_scripts
pip install -r requirements_aihub.txt

# GPU 사용 시 (선택사항)
pip install tensorflow[and-cuda]
```

### 3. 데이터 전처리

```bash
# AI-Hub 데이터셋 전처리
python preprocess_aihub_data.py \
    --input_dir /path/to/aihub/dataset \
    --output_dir ./aihub_processed \
    --max_samples 50000
```

**전처리 과정:**
- XML 어노테이션 파일 파싱
- 한국 음식명을 Food-101 클래스로 매핑
- 바운딩박스 기반 이미지 크롭
- 224x224 크기로 리사이즈
- 훈련/검증/테스트 데이터 분할

### 4. 모델 튜닝

```bash
# AI-Hub 데이터로 모델 재훈련
python train_with_aihub_dataset.py
```

**학습 과정:**
1. **1단계**: 백본 고정하고 분류기만 학습 (20 epochs)
2. **2단계**: 전체 모델 미세튜닝 (30 epochs)
3. **TensorFlow Lite 변환**: 모바일 최적화

## 📊 한국 음식 매핑 전략

### 주요 매핑 예시

| 한국 음식 | Food-101 클래스 | 매핑 이유 |
|-----------|----------------|-----------|
| 김치찌개 | miso_soup | 찌개류의 유사성 |
| 비빔밥 | bibimbap | Food-101에 직접 존재 |
| 불고기 | steak | 구운 고기 요리 |
| 냉면 | ramen | 면 요리 |
| 초밥 | sushi | 일식 초밥 |
| 치킨 | chicken_wings | 닭 요리 |

### 매핑 원칙
1. **시각적 유사성**: 모양, 색상, 질감이 유사한 음식
2. **조리법 유사성**: 볶음, 찜, 구이 등 조리 방법
3. **재료 유사성**: 주재료가 같은 음식
4. **카테고리 유사성**: 같은 종류의 음식

## 🎯 예상 성능 개선

### 한국 음식 인식 정확도
- **기존 모델**: 60-70% (Food-101 기반)
- **AI-Hub 튜닝 후**: 85-95% 예상

### 주요 개선 음식
- 김치찌개, 된장찌개, 순두부찌개
- 비빔밥, 불고기, 갈비
- 냉면, 라면, 우동
- 초밥, 라멘, 돈카츠
- 치킨, 피자, 햄버거

## 📁 출력 파일 구조

```
assets/models/
├── food_classification_aihub.tflite    # 튜닝된 TFLite 모델
├── best_stage1_aihub.h5                # 1단계 모델
├── best_stage2_aihub.h5                # 2단계 모델
├── model_info_aihub.json               # 모델 메타데이터
├── korean_food_labels.txt              # 한국 음식 라벨
└── training_history_aihub.png          # 학습 히스토리 그래프
```

## 🔧 Flutter 앱 적용

### 1. 모델 파일 교체

```dart
// 기존 모델
final modelPath = 'assets/models/food_classification.tflite';

// AI-Hub 튜닝 모델로 교체
final modelPath = 'assets/models/food_classification_aihub.tflite';
```

### 2. 라벨 파일 업데이트

```dart
// 기존 라벨
final labelsPath = 'assets/models/food_labels.txt';

// 한국 음식 라벨로 교체
final labelsPath = 'assets/models/korean_food_labels.txt';
```

### 3. 서비스 코드 수정

```dart
class MealAIService {
  // AI-Hub 튜닝 모델 사용
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('models/food_classification_aihub.tflite');
    _labels = await _loadLabels('models/korean_food_labels.txt');
  }
}
```

## 📈 성능 모니터링

### 정확도 측정
```python
# 한국 음식 테스트 데이터로 정확도 측정
test_accuracy = model.evaluate(test_generator)
print(f"한국 음식 인식 정확도: {test_accuracy[1]:.4f}")
```

### 클래스별 성능
```python
# 클래스별 정확도 분석
from sklearn.metrics import classification_report
y_pred = model.predict(test_generator)
report = classification_report(y_true, y_pred, target_names=class_names)
print(report)
```

## 🚨 주의사항

### 1. 데이터셋 크기
- AI-Hub 데이터셋이 매우 크므로 (232,087장)
- 처음에는 샘플 수를 제한하여 테스트 (`--max_samples 10000`)
- 성공적으로 작동하면 전체 데이터셋 사용

### 2. 메모리 사용량
- 대용량 데이터셋 처리 시 메모리 부족 가능
- 배치 크기를 줄이거나 데이터 스트리밍 사용

### 3. 학습 시간
- 전체 데이터셋으로 학습 시 상당한 시간 소요
- GPU 사용 권장 (CPU: 수십 시간, GPU: 수 시간)

## 🔄 업데이트 계획

### Phase 1: 기본 튜닝
- [x] 데이터 전처리 스크립트 작성
- [x] 모델 튜닝 스크립트 작성
- [ ] AI-Hub 데이터셋 다운로드 및 테스트

### Phase 2: 성능 최적화
- [ ] 하이퍼파라미터 튜닝
- [ ] 데이터 증강 전략 개선
- [ ] 앙상블 모델 적용

### Phase 3: 프로덕션 배포
- [ ] Flutter 앱 모델 교체
- [ ] A/B 테스트 수행
- [ ] 사용자 피드백 수집

## 📚 참고 자료

- [AI-Hub 데이터셋 페이지](https://www.aihub.or.kr/aihubdata/data/view.do?dataSetSn=71564)
- [Food-101 논문](https://data.vision.ee.ethz.ch/cvl/datasets_extra/food-101/)
- [MobileNetV3 논문](https://arxiv.org/abs/1905.02244)
- [TensorFlow Lite 가이드](https://www.tensorflow.org/lite)

---

*문서 작성일: 2025년 10월 24일*  
*버전: 1.0*  
*작성자: lyh205*
