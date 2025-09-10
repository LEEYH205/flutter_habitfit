# 음식 분류 모델 학습 스크립트

이 폴더는 HabitFit 앱의 AI 음식 인식 기능을 위한 모델 학습 스크립트들을 포함합니다.

## 📁 파일 구조

```
training_scripts/
├── README.md                    # 이 파일
├── train_food_model.py         # 더미 데이터로 테스트용 모델 학습
├── train_real_food_model.py    # 실제 Food-101 데이터셋으로 모델 학습
└── requirements.txt            # Python 의존성 패키지
```

## 🚀 사용 방법

### 1. 의존성 설치

```bash
cd training_scripts
pip install -r requirements.txt
```

### 2. 실제 모델 학습 (권장)

```bash
python train_real_food_model.py
```

### 3. 테스트용 모델 학습

```bash
python train_food_model.py
```

## 📊 데이터셋

- **Food-101**: 101개 음식 클래스, 101,000개 이미지
- **저장 위치**: `../.tensorflow_food101/` (Git에 업로드되지 않음)
- **자동 다운로드**: 첫 실행 시 자동으로 다운로드됩니다.

## 🏗️ 모델 아키텍처

- **백본**: MobileNetV3Large
- **학습 방식**: Transfer Learning + Fine-tuning
- **양자화**: INT8 (모바일 최적화)
- **출력**: TensorFlow Lite 모델

## 📁 출력 파일

학습 완료 후 다음 파일들이 생성됩니다:

```
../assets/models/
├── food_classification.tflite    # 학습된 모델
├── food_labels.txt              # 음식 라벨 목록
├── nutrition_database.json      # 영양소 데이터베이스
└── model_info.json             # 모델 메타데이터
```

## ⚡ 성능 최적화

- **MPS 지원**: M1/M2 Mac에서 GPU 가속
- **메모리 효율**: 통합 메모리 아키텍처 활용
- **배치 처리**: 효율적인 데이터 로딩

## 🔧 설정 변경

주요 설정값들을 스크립트 상단에서 수정할 수 있습니다:

```python
IMAGE_SIZE = 224
BATCH_SIZE = 32
EPOCHS_STAGE1 = 10  # 1단계 학습 에포크
EPOCHS_STAGE2 = 20  # 2단계 미세튜닝 에포크
```

## 📝 주의사항

1. **첫 실행 시**: Food-101 데이터셋 다운로드로 시간이 오래 걸릴 수 있습니다.
2. **디스크 공간**: 데이터셋과 모델 파일로 약 2-3GB의 공간이 필요합니다.
3. **학습 시간**: M1/M2 Mac에서 약 1-2시간 소요됩니다.
4. **Git 무시**: `.tensorflow_food101/` 폴더는 Git에 업로드되지 않습니다.
