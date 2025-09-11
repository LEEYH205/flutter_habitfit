# 음식 분류 모델 학습 스크립트

이 폴더는 HabitFit 앱의 AI 음식 인식 기능을 위한 모델 학습 스크립트들을 포함합니다.

## 📁 파일 구조

```
training_scripts/
├── README.md                           # 이 파일
├── train_mobilenetv3_food101.py       # MobileNetV3 Large 기반 Food-101 모델 학습 (77.5% 정확도)
├── create_tflite_model.py             # TensorFlow Lite 모델 생성 (Flutter 앱용)
├── convert_to_tflite_unused.py        # 사용하지 않는 변환 스크립트
├── requirements.txt                   # Python 의존성 패키지
└── .tensorflow_food101/               # Food-101 데이터셋 (자동 다운로드)
```

## 🚀 사용 방법

### 1. 의존성 설치

```bash
cd training_scripts
pip install -r requirements.txt
```

### 2. Flutter 앱용 TFLite 모델 생성 (권장)

```bash
python create_tflite_model.py
```

이 스크립트는 Flutter 앱에서 바로 사용할 수 있는 TensorFlow Lite 모델을 생성합니다.

### 3. 고성능 모델 학습 (선택사항)

```bash
python train_mobilenetv3_food101.py
```

이 스크립트는 77.5% 정확도의 고성능 모델을 학습하지만, TFLite 변환에서 호환성 문제가 있습니다.

## 📊 데이터셋

- **Food-101**: 101개 음식 클래스, 101,000개 이미지
- **저장 위치**: `../.tensorflow_food101/` (Git에 업로드되지 않음)
- **자동 다운로드**: 첫 실행 시 자동으로 다운로드됩니다.

## 🏗️ 모델 아키텍처

### create_tflite_model.py (권장)
- **백본**: MobileNetV3Large (ImageNet 사전훈련)
- **학습 방식**: Transfer Learning
- **양자화**: FP16 (모바일 최적화)
- **출력**: TensorFlow Lite 모델 (6.74 MB)
- **정확도**: ImageNet 사전훈련 수준

### train_mobilenetv3_food101.py (고성능)
- **백본**: MobileNetV3Large
- **학습 방식**: 2단계 Transfer Learning + Fine-tuning
- **양자화**: FP16
- **출력**: H5 모델 (47.9 MB)
- **정확도**: 77.5% (Food-101 검증셋)

## 📁 출력 파일

### create_tflite_model.py 실행 후:
```
../assets/models/
├── food_classification.tflite    # TFLite 모델 (6.74 MB)
├── food_labels.txt              # 101개 음식 라벨
├── nutrition_database.json      # 영양소 데이터베이스
└── model_info.json             # 모델 메타데이터
```

### train_mobilenetv3_food101.py 실행 후:
```
../assets/models/
├── best_stage1.h5               # 1단계 모델 (31.2 MB)
├── best_stage2.h5               # 2단계 모델 (47.9 MB, 77.5% 정확도)
├── food_labels.txt              # 101개 음식 라벨
├── nutrition_database.json      # 영양소 데이터베이스
└── model_info.json             # 모델 메타데이터
```

## ⚡ 성능 최적화

- **MPS 지원**: M1/M2 Mac에서 GPU 가속
- **메모리 효율**: 통합 메모리 아키텍처 활용
- **배치 처리**: 효율적인 데이터 로딩
- **FP16 양자화**: 모델 크기 50% 감소

## 🔧 설정 변경

### create_tflite_model.py
```python
class_names = [...]  # 음식 클래스 목록
```

### train_mobilenetv3_food101.py
```python
IMAGE_SIZE = 224
BATCH_SIZE = 32
EPOCHS_STAGE1 = 15  # 1단계 학습 에포크
EPOCHS_STAGE2 = 25  # 2단계 미세튜닝 에포크
```

## 📝 주의사항

1. **첫 실행 시**: Food-101 데이터셋 다운로드로 시간이 오래 걸릴 수 있습니다.
2. **디스크 공간**: 데이터셋과 모델 파일로 약 2-3GB의 공간이 필요합니다.
3. **학습 시간**: 
   - `create_tflite_model.py`: 1-2분 (사전훈련 모델 사용)
   - `train_mobilenetv3_food101.py`: 1-2시간 (실제 학습)
4. **Git 무시**: `.tensorflow_food101/` 폴더는 Git에 업로드되지 않습니다.
5. **TFLite 호환성**: `train_mobilenetv3_food101.py`는 TFLite 변환에서 호환성 문제가 있습니다.

## 🎯 권장 사용법

**Flutter 앱 개발용**: `create_tflite_model.py` 사용
- 빠른 실행 (1-2분)
- Flutter 앱에서 바로 사용 가능
- 6.74 MB 작은 크기

**연구/고성능용**: `train_mobilenetv3_food101.py` 사용
- 77.5% 높은 정확도
- H5 형식으로 저장
- TFLite 변환 필요시 별도 작업 필요
