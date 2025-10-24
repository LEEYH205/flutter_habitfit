#!/usr/bin/env python3
"""
AI-Hub 800종 한국 음식 분류 모델
기존 101종 모델 대신 800종으로 세분화된 한국 음식 전용 모델
"""

import os
import tensorflow as tf
import numpy as np
import json
import pathlib
import cv2
from datetime import datetime
from tensorflow.keras import layers
from tensorflow.keras.applications import MobileNetV3Large, EfficientNetB3
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint, LearningRateScheduler
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt

# TF 2.15 Apple Silicon 충돌 우회 설정
os.environ["TF_USE_LEGACY_KERAS"] = "1"
os.environ["TF_DISABLE_MLIR_OPTIMIZATIONS"] = "1"
tf.config.optimizer.set_jit(False)
tf.config.optimizer.set_experimental_options({
    "remapping": False,
    "layout_optimizer": False,
    "constant_folding": False
})

# 설정
IMAGE_SIZE = 224
BATCH_SIZE = 16  # 800클래스로 인해 메모리 사용량 증가로 배치 크기 감소
EPOCHS_STAGE1 = 25  # 더 많은 클래스로 인해 학습 시간 증가
EPOCHS_STAGE2 = 35
LEARNING_RATE_STAGE1 = 1e-3
LEARNING_RATE_STAGE2 = 1e-5

def setup_gpu():
    """GPU 설정 및 최적화"""
    try:
        gpus = tf.config.experimental.list_physical_devices('GPU')
        if gpus:
            for gpu in gpus:
                tf.config.experimental.set_memory_growth(gpu, True)
            print(f"✅ GPU 사용 가능: {len(gpus)}개")
            return True
        else:
            print("⚠️ GPU를 사용할 수 없습니다. CPU로 학습합니다.")
            return False
    except Exception as e:
        print(f"⚠️ GPU 설정 실패: {e}")
        return False

def get_aihub_800_classes():
    """
    AI-Hub 800종 한국 음식 클래스 정의
    실제 AI-Hub 데이터셋의 클래스 구조에 맞게 조정 필요
    """
    korean_food_classes = {
        # 한식 메인 (200종)
        '한식_메인': [
            '김치찌개', '된장찌개', '순두부찌개', '부대찌개', '청국장찌개',
            '비빔밥', '불고기', '갈비', '삼겹살', '제육볶음', '닭볶음탕',
            '냉면', '라면', '우동', '김밥', '떡볶이', '잡채', '김치전',
            '파전', '해물파전', '된장국', '미역국', '콩나물국', '육개장',
            '설렁탕', '곰탕', '감자탕', '닭갈비', '닭볶음탕', '오징어볶음',
            '낙지볶음', '고등어조림', '갈치조림', '삼치구이', '고등어구이',
            '갈치구이', '삼치구이', '조기구이', '꽁치구이', '멸치볶음',
            '멸치조림', '멸치국수', '멸치국', '멸치무침', '멸치김치',
            '멸치볶음', '멸치조림', '멸치국수', '멸치국', '멸치무침',
            # ... 더 많은 한식 메인 (총 200종)
        ],
        
        # 중식 (150종)
        '중식': [
            '짜장면', '짬뽕', '탕수육', '깐풍기', '마파두부', '양장피',
            '팔보채', '볶음밥', '짬뽕밥', '유산슬', '깐쇼새우', '라조기',
            '고추잡채', '칠리새우', '깐풍기', '마파두부', '양장피',
            '팔보채', '볶음밥', '짬뽕밥', '유산슬', '깐쇼새우', '라조기',
            # ... 더 많은 중식 (총 150종)
        ],
        
        # 일식 (150종)
        '일식': [
            '초밥', '라멘', '우동', '돈카츠', '가라아게', '텐동', '오니기리',
            '사시미', '회', '스시', '우나기', '야키니쿠', '샤부샤부',
            '스키야키', '오코노미야키', '타코야키', '오뎅', '라멘',
            '우동', '소바', '덴푸라', '야키토리', '사시미', '회',
            # ... 더 많은 일식 (총 150종)
        ],
        
        # 양식 (100종)
        '양식': [
            '스테이크', '파스타', '피자', '햄버거', '샐러드', '샌드위치',
            '리조또', '라자냐', '스파게티', '마카로니', '치즈케이크',
            '브라우니', '아이스크림', '도넛', '와플', '팬케이크',
            # ... 더 많은 양식 (총 100종)
        ],
        
        # 분식/간식 (100종)
        '분식_간식': [
            '치킨', '닭강정', '떡볶이', '순대', '튀김', '만두', '김치',
            '도시락', '삼각김밥', '주먹밥', '핫도그', '샌드위치',
            '토스트', '샐러드', '스무디', '주스', '커피', '라떼',
            # ... 더 많은 분식/간식 (총 100종)
        ],
        
        # 디저트 (50종)
        '디저트': [
            '팥빙수', '아이스크림', '케이크', '도넛', '와플', '팬케이크',
            '마카롱', '쿠키', '브라우니', '치즈케이크', '티라미수',
            '크레페', '프로피터롤', '에클레어', '캐러멜', '초콜릿',
            # ... 더 많은 디저트 (총 50종)
        ],
        
        # 음료 (50종)
        '음료': [
            '커피', '라떼', '아메리카노', '카페모카', '카푸치노', '에스프레소',
            '차', '녹차', '홍차', '우롱차', '보이차', '허브차',
            '주스', '오렌지주스', '사과주스', '포도주스', '토마토주스',
            '스무디', '프로틴스무디', '과일스무디', '요거트스무디',
            # ... 더 많은 음료 (총 50종)
        ]
    }
    
    # 모든 클래스를 하나의 리스트로 통합
    all_classes = []
    for category, foods in korean_food_classes.items():
        all_classes.extend(foods)
    
    return all_classes, korean_food_classes

def create_800_class_model(num_classes=800, input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3)):
    """
    800클래스용 최적화된 모델 생성
    """
    print("🏗️ 800클래스 모델 구성 중...")
    
    # EfficientNetB3 사용 (더 많은 클래스에 적합)
    base_model = EfficientNetB3(
        input_shape=input_shape,
        include_top=False,
        weights='imagenet',
        drop_connect_rate=0.2
    )
    
    # 800클래스용 최적화된 모델 구성
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=input_shape),
        tf.keras.layers.Lambda(lambda x: tf.keras.applications.efficientnet.preprocess_input(x)),
        base_model,
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.3),  # 더 강한 드롭아웃
        tf.keras.layers.Dense(2048, activation='relu'),  # 더 큰 Dense 레이어
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.4),
        tf.keras.layers.Dense(1024, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(512, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(num_classes, activation='softmax')
    ])
    
    return model, base_model

def create_data_pipeline_800_classes(images, labels, class_names, batch_size=16):
    """
    800클래스용 데이터 파이프라인
    """
    print("🔄 800클래스 데이터 파이프라인 생성 중...")
    
    # 클래스 인덱스 매핑
    class_to_idx = {name: idx for idx, name in enumerate(class_names)}
    
    # 라벨을 인덱스로 변환
    label_indices = [class_to_idx[label] for label in labels]
    label_indices = tf.keras.utils.to_categorical(label_indices, len(class_names))
    
    # 훈련/검증 분할 (800클래스로 인해 더 많은 검증 데이터 필요)
    X_train, X_val, y_train, y_val = train_test_split(
        images, label_indices, test_size=0.25, random_state=42, 
        stratify=label_indices.argmax(axis=1)
    )
    
    print(f"📊 훈련 데이터: {len(X_train)}개")
    print(f"📊 검증 데이터: {len(X_val)}개")
    
    # 800클래스용 강화된 데이터 증강
    train_datagen = tf.keras.preprocessing.image.ImageDataGenerator(
        rotation_range=30,
        width_shift_range=0.3,
        height_shift_range=0.3,
        horizontal_flip=True,
        vertical_flip=True,
        zoom_range=0.3,
        brightness_range=[0.7, 1.3],
        shear_range=0.2,
        channel_shift_range=0.2
    )
    
    val_datagen = tf.keras.preprocessing.image.ImageDataGenerator()
    
    train_generator = train_datagen.flow(
        X_train, y_train, batch_size=batch_size, shuffle=True
    )
    
    val_generator = val_datagen.flow(
        X_val, y_val, batch_size=batch_size, shuffle=False
    )
    
    return train_generator, val_generator, class_names

def train_800_class_model_stage1(model, train_generator, val_generator, output_dir):
    """
    800클래스 1단계 학습
    """
    print("🎯 800클래스 1단계 학습 시작...")
    
    # 백본 고정
    for layer in model.layers[2].layers:
        layer.trainable = False
    
    # 800클래스용 최적화된 컴파일
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE_STAGE1),
        loss='categorical_crossentropy',
        metrics=['accuracy', 'top_3_accuracy', 'top_5_accuracy']
    )
    
    # 800클래스용 콜백 설정
    callbacks = [
        EarlyStopping(patience=8, restore_best_weights=True),
        ReduceLROnPlateau(factor=0.5, patience=5, min_lr=1e-7),
        ModelCheckpoint(
            filepath=output_dir / "best_stage1_800classes.h5",
            save_best_only=True,
            monitor='val_accuracy'
        )
    ]
    
    # 학습
    history = model.fit(
        train_generator,
        epochs=EPOCHS_STAGE1,
        validation_data=val_generator,
        callbacks=callbacks,
        verbose=1
    )
    
    return model, history

def train_800_class_model_stage2(model, train_generator, val_generator, output_dir):
    """
    800클래스 2단계 학습
    """
    print("🎯 800클래스 2단계 학습 시작...")
    
    # 백본 해제
    for layer in model.layers[2].layers:
        layer.trainable = True
    
    # 낮은 학습률로 재컴파일
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE_STAGE2),
        loss='categorical_crossentropy',
        metrics=['accuracy', 'top_3_accuracy', 'top_5_accuracy']
    )
    
    # 콜백 설정
    callbacks = [
        EarlyStopping(patience=12, restore_best_weights=True),
        ReduceLROnPlateau(factor=0.3, patience=7, min_lr=1e-8),
        ModelCheckpoint(
            filepath=output_dir / "best_stage2_800classes.h5",
            save_best_only=True,
            monitor='val_accuracy'
        )
    ]
    
    # 학습
    history = model.fit(
        train_generator,
        epochs=EPOCHS_STAGE2,
        validation_data=val_generator,
        callbacks=callbacks,
        verbose=1
    )
    
    return model, history

def convert_800_class_to_tflite(model, class_names, output_dir):
    """
    800클래스 모델을 TensorFlow Lite로 변환
    """
    print("🔄 800클래스 TFLite 변환 중...")
    
    # TFLite 변환 (800클래스용 최적화)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    
    # 800클래스용 추가 최적화
    converter.representative_dataset = None
    
    tflite_model = converter.convert()
    
    # 파일 저장
    tflite_path = output_dir / "korean_food_800classes.tflite"
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)
    
    # 모델 크기 계산
    model_size_mb = len(tflite_model) / (1024 * 1024)
    print(f"✅ 800클래스 TFLite 모델 저장됨: {tflite_path}")
    print(f"📏 모델 크기: {model_size_mb:.2f} MB")
    
    return tflite_path, model_size_mb

def save_800_class_metadata(class_names, korean_categories, model_size_mb, output_dir):
    """
    800클래스 모델 메타데이터 저장
    """
    metadata = {
        "model_name": "korean_food_800classes",
        "version": "1.0",
        "created_at": datetime.now().isoformat(),
        "dataset": "AI-Hub Korean Food Dataset (800 classes)",
        "architecture": "EfficientNetB3",
        "input_size": [IMAGE_SIZE, IMAGE_SIZE, 3],
        "num_classes": len(class_names),
        "class_names": class_names,
        "korean_categories": korean_categories,
        "model_size_mb": model_size_mb,
        "training_stages": 2,
        "stage1_epochs": EPOCHS_STAGE1,
        "stage2_epochs": EPOCHS_STAGE2,
        "optimization": "FP16 quantization",
        "batch_size": BATCH_SIZE,
        "description": "800종 한국 음식 분류 모델 - AI-Hub 데이터셋 기반"
    }
    
    info_path = output_dir / "model_info_800classes.json"
    with open(info_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)
    
    print(f"✅ 800클래스 모델 정보 저장됨: {info_path}")

def main():
    """메인 실행 함수"""
    print("🍽️ AI-Hub 800종 한국 음식 분류 모델 학습 시작!")
    print("=" * 60)
    
    # GPU 설정
    gpu_available = setup_gpu()
    
    # 출력 디렉토리 설정
    output_dir = pathlib.Path("../assets/models")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        # 1. 800클래스 정의
        print("\n📊 800종 한국 음식 클래스 정의 중...")
        class_names, korean_categories = get_aihub_800_classes()
        print(f"✅ 총 {len(class_names)}개 클래스 정의 완료")
        
        # 2. AI-Hub 데이터셋 로딩 (실제 구현 필요)
        print("\n📊 AI-Hub 데이터셋 로딩 중...")
        data_dir = input("AI-Hub 데이터셋 경로를 입력하세요: ").strip()
        
        if not data_dir:
            print("❌ 데이터셋 경로가 필요합니다.")
            return
        
        # 실제 데이터 로딩 구현 필요
        # images, labels = load_aihub_800_classes_dataset(data_dir, class_names)
        
        # 임시 데이터 생성 (실제 구현 시 제거)
        print("⚠️ 임시 데이터 생성 중... (실제 구현 필요)")
        n_samples = 1000
        images = np.random.random((n_samples, IMAGE_SIZE, IMAGE_SIZE, 3)).astype(np.float32)
        labels = np.random.choice(class_names, n_samples)
        
        # 3. 데이터 파이프라인 생성
        train_generator, val_generator, class_names = create_data_pipeline_800_classes(
            images, labels, class_names, BATCH_SIZE
        )
        
        # 4. 800클래스 모델 생성
        model, base_model = create_800_class_model(len(class_names))
        
        # 5. 1단계 학습
        model_stage1, history1 = train_800_class_model_stage1(
            model, train_generator, val_generator, output_dir
        )
        
        # 6. 2단계 학습
        model_stage2, history2 = train_800_class_model_stage2(
            model_stage1, train_generator, val_generator, output_dir
        )
        
        # 7. TensorFlow Lite 변환
        tflite_path, model_size = convert_800_class_to_tflite(
            model_stage2, class_names, output_dir
        )
        
        # 8. 메타데이터 저장
        save_800_class_metadata(class_names, korean_categories, model_size, output_dir)
        
        # 9. 최종 결과 출력
        print(f"\n🎯 800클래스 모델 학습 완료!")
        print(f"📁 모델 파일: {tflite_path}")
        print(f"📏 모델 크기: {model_size:.2f} MB")
        print(f"📊 클래스 수: {len(class_names)}개")
        print(f"🎯 최고 검증 정확도: {max(history2.history['val_accuracy']):.4f}")
        
        print("\n✅ AI-Hub 800종 모델 학습 완료!")
        
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
