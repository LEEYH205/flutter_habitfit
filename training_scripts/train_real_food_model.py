#!/usr/bin/env python3
"""
실제 음식 이미지로 MobileNetV3 기반 분류 모델 학습
Food-101 데이터셋 사용 + INT8 양자화 TFLite 변환
"""

import tensorflow as tf
import numpy as np
import os
import json
from tensorflow.keras import layers
from tensorflow.keras.applications import MobileNetV3Large
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint
import tensorflow_datasets as tfds

# 설정
IMAGE_SIZE = 224
BATCH_SIZE = 32
EPOCHS_STAGE1 = 10  # 1단계: 고정된 백본으로 학습
EPOCHS_STAGE2 = 20  # 2단계: 미세튜닝
LEARNING_RATE_STAGE1 = 1e-3
LEARNING_RATE_STAGE2 = 1e-5

def create_datasets(data_dir="../.tensorflow_food101", img_size=224, batch=32, val_split=0.2, seed=1337):
    """실제 데이터셋 생성 (로컬 폴더 또는 Food-101)"""
    AUTOTUNE = tf.data.AUTOTUNE
    
    # 로컬 폴더에 이미지가 있는지 확인
    has_local_images = False
    if os.path.isdir(data_dir):
        # 폴더 내에 이미지 파일이 있는지 확인
        image_extensions = ('.bmp', '.gif', '.jpeg', '.jpg', '.png')
        for root, dirs, files in os.walk(data_dir):
            if any(f.lower().endswith(image_extensions) for f in files):
                has_local_images = True
                break
    
    if has_local_images:
        print(f"📁 로컬 데이터셋 사용: {data_dir}")
        train_ds = tf.keras.utils.image_dataset_from_directory(
            data_dir, 
            validation_split=val_split, 
            subset="training", 
            seed=seed,
            image_size=(img_size, img_size), 
            batch_size=batch
        )
        val_ds = tf.keras.utils.image_dataset_from_directory(
            data_dir, 
            validation_split=val_split, 
            subset="validation", 
            seed=seed,
            image_size=(img_size, img_size), 
            batch_size=batch
        )
        class_names = train_ds.class_names
    else:
        print("🌐 Food-101 데이터셋 다운로드 중...")
        print(f"📁 저장 경로: {data_dir}")
        
        # 데이터셋 다운로드 경로 설정
        tfds_data_dir = data_dir
        
        (train_ds, val_ds), ds_info = tfds.load(
            "food101", 
            split=["train[:90%]", "validation"], 
            as_supervised=True, 
            with_info=True,
            data_dir=tfds_data_dir
        )
        class_names = ds_info.features["label"].names
        
        # 이미지 리사이즈 및 배치 처리
        train_ds = train_ds.map(lambda x, y: (tf.image.resize(x, (img_size, img_size)), y))
        val_ds = val_ds.map(lambda x, y: (tf.image.resize(x, (img_size, img_size)), y))
        train_ds = train_ds.batch(batch)
        val_ds = val_ds.batch(batch)
    
    # 데이터 전처리 및 증강
    normalization = layers.Rescaling(1./255)
    
    augmentation = tf.keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomBrightness(0.1),
        layers.RandomContrast(0.1),
        layers.RandomRotation(0.1),
    ])
    
    # 훈련 데이터: 정규화 + 증강
    train_ds = train_ds.map(
        lambda x, y: (augmentation(normalization(x), training=True), y), 
        num_parallel_calls=AUTOTUNE
    ).prefetch(AUTOTUNE)
    
    # 검증 데이터: 정규화만
    val_ds = val_ds.map(
        lambda x, y: (normalization(x), y), 
        num_parallel_calls=AUTOTUNE
    ).prefetch(AUTOTUNE)
    
    print(f"✅ 데이터셋 준비 완료: {len(class_names)}개 클래스")
    return train_ds, val_ds, class_names

def create_model(num_classes, stage=1):
    """MobileNetV3 기반 모델 생성"""
    print(f"🏗️ 모델 생성 중... (Stage {stage})")
    
    # MobileNetV3Large 백본
    base_model = MobileNetV3Large(
        include_top=False, 
        input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3), 
        weights="imagenet"
    )
    
    if stage == 1:
        # 1단계: 백본 고정
        base_model.trainable = False
        print("🔒 백본 레이어 고정됨")
    else:
        # 2단계: 상위 레이어만 미세튜닝
        base_model.trainable = True
        # 마지막 30개 레이어만 훈련 가능하게 설정
        for layer in base_model.layers[:-30]:
            layer.trainable = False
        print("🔓 상위 30개 레이어 미세튜닝 활성화")
    
    # 분류 헤드
    inputs = tf.keras.Input(shape=(IMAGE_SIZE, IMAGE_SIZE, 3))
    x = base_model(inputs, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.2)(x)
    x = layers.Dense(512, activation='relu')(x)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(num_classes, activation="softmax")(x)
    
    model = tf.keras.Model(inputs, outputs)
    
    # 컴파일
    if stage == 1:
        optimizer = tf.keras.optimizers.Adam(LEARNING_RATE_STAGE1)
    else:
        optimizer = tf.keras.optimizers.Adam(LEARNING_RATE_STAGE2)
    
    model.compile(
        optimizer=optimizer,
        loss=tf.keras.losses.SparseCategoricalCrossentropy(),
        metrics=["accuracy"]
    )
    
    return model

def train_model_stage1(train_ds, val_ds, num_classes):
    """1단계: 고정된 백본으로 학습"""
    print("\n🚀 1단계 학습 시작 (고정된 백본)")
    print("=" * 50)
    
    # MPS GPU 사용 설정
    device = '/device:GPU:0' if tf.config.list_physical_devices('GPU') else '/CPU:0'
    print(f"🔧 학습 디바이스: {device}")
    
    with tf.device(device):
        model = create_model(num_classes, stage=1)
        
        # 콜백 설정
        callbacks = [
            EarlyStopping(patience=3, restore_best_weights=True, monitor='val_accuracy'),
            ReduceLROnPlateau(patience=2, factor=0.5, min_lr=1e-7, monitor='val_accuracy'),
            ModelCheckpoint('best_stage1.h5', save_best_only=True, monitor='val_accuracy')
        ]
        
        # 학습
        history = model.fit(
            train_ds,
            epochs=EPOCHS_STAGE1,
            validation_data=val_ds,
            callbacks=callbacks,
            verbose=1
        )
    
    return model, history

def train_model_stage2(model, train_ds, val_ds):
    """2단계: 미세튜닝"""
    print("\n🔧 2단계 학습 시작 (미세튜닝)")
    print("=" * 50)
    
    # MPS GPU 사용 설정
    device = '/device:GPU:0' if tf.config.list_physical_devices('GPU') else '/CPU:0'
    print(f"🔧 학습 디바이스: {device}")
    
    with tf.device(device):
        # 모델을 2단계용으로 재구성
        stage2_model = create_model(model.output_shape[-1], stage=2)
        
        # 1단계 가중치 로드
        stage2_model.set_weights(model.get_weights())
        
        # 콜백 설정
        callbacks = [
            EarlyStopping(patience=5, restore_best_weights=True, monitor='val_accuracy'),
            ReduceLROnPlateau(patience=3, factor=0.5, min_lr=1e-8, monitor='val_accuracy'),
            ModelCheckpoint('best_stage2.h5', save_best_only=True, monitor='val_accuracy')
        ]
        
        # 학습
        history = stage2_model.fit(
            train_ds,
            epochs=EPOCHS_STAGE2,
            validation_data=val_ds,
            callbacks=callbacks,
            verbose=1
        )
    
    return stage2_model, history

def convert_to_tflite_int8(model, train_ds, class_names):
    """INT8 양자화된 TensorFlow Lite 모델로 변환"""
    print("\n🔄 INT8 양자화 TFLite 변환 중...")
    
    # 모델을 SavedModel 형식으로 저장 후 변환
    import tempfile
    import os
    
    with tempfile.TemporaryDirectory() as temp_dir:
        model_path = os.path.join(temp_dir, "model")
        model.save(model_path, save_format='tf')
        
        def representative_dataset():
            """양자화를 위한 대표 데이터셋"""
            for x, _ in train_ds.unbatch().take(200):
                yield [tf.cast(x[None, ...], tf.float32)]
        
        # 변환기 설정
        converter = tf.lite.TFLiteConverter.from_saved_model(model_path)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.representative_dataset = representative_dataset
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.uint8
        converter.inference_output_type = tf.uint8
        
        # 변환 실행
        tflite_model = converter.convert()
    
    # 모델 저장
    model_path = '../assets/models/food_classification.tflite'
    os.makedirs(os.path.dirname(model_path), exist_ok=True)
    
    with open(model_path, 'wb') as f:
        f.write(tflite_model)
    
    model_size_mb = len(tflite_model) / (1024 * 1024)
    print(f"✅ INT8 TFLite 모델 저장됨: {model_path}")
    print(f"📏 모델 크기: {model_size_mb:.2f} MB")
    
    return model_path, model_size_mb

def save_labels_and_metadata(class_names, model_size_mb):
    """라벨 파일 및 메타데이터 저장"""
    
    # 라벨 파일 저장
    labels_path = '../assets/models/food_labels.txt'
    with open(labels_path, 'w', encoding='utf-8') as f:
        for label in class_names:
            f.write(f"{label}\n")
    print(f"✅ 라벨 파일 저장됨: {labels_path}")
    
    # 영양소 데이터베이스 생성
    nutrition_db = {}
    for label in class_names:
        # 기본 영양소 값 (실제로는 더 정확한 데이터 필요)
        nutrition_db[label] = {
            'calories': np.random.randint(100, 600),
            'protein': round(np.random.uniform(5.0, 30.0), 1),
            'carbs': round(np.random.uniform(10.0, 80.0), 1),
            'fat': round(np.random.uniform(2.0, 25.0), 1)
        }
    
    nutrition_path = '../assets/models/nutrition_database.json'
    with open(nutrition_path, 'w', encoding='utf-8') as f:
        json.dump(nutrition_db, f, ensure_ascii=False, indent=2)
    print(f"✅ 영양소 DB 저장됨: {nutrition_path}")
    
    # 모델 정보 저장
    model_info = {
        "name": "Food Classification Model (MobileNetV3)",
        "version": "2.0.0",
        "description": "실제 Food-101 데이터로 학습된 음식 분류 모델",
        "architecture": "MobileNetV3Large",
        "input_shape": [1, IMAGE_SIZE, IMAGE_SIZE, 3],
        "output_shape": [1, len(class_names)],
        "classes": len(class_names),
        "model_size_mb": round(model_size_mb, 2),
        "quantization": "INT8",
        "created_at": "2025-09-10",
        "framework": "TensorFlow Lite",
        "training_data": "Food-101 Dataset"
    }
    
    info_path = '../assets/models/model_info.json'
    with open(info_path, 'w', encoding='utf-8') as f:
        json.dump(model_info, f, ensure_ascii=False, indent=2)
    print(f"✅ 모델 정보 저장됨: {info_path}")

def main():
    """메인 실행 함수"""
    print("🍽️ 실제 음식 분류 모델 학습 시작!")
    print("=" * 60)
    
    # MPS/GPU 설정
    try:
        # MPS (Metal Performance Shaders) 설정 (M1/M2 Mac)
        if tf.config.list_physical_devices('GPU'):
            print("✅ MPS GPU 사용 가능")
            # MPS 메모리 증가 설정
            gpus = tf.config.experimental.list_physical_devices('GPU')
            for gpu in gpus:
                tf.config.experimental.set_memory_growth(gpu, True)
        else:
            print("⚠️ MPS GPU를 사용할 수 없습니다. CPU로 학습합니다.")
    except Exception as e:
        print(f"⚠️ GPU 설정 실패: {e}. CPU로 학습합니다.")
    
    # 사용 가능한 디바이스 확인
    print(f"🔧 사용 가능한 디바이스: {tf.config.list_physical_devices()}")
    
    # MPS 사용 여부 확인
    try:
        # M1/M2 Mac에서는 '/device:GPU:0' 사용
        with tf.device('/device:GPU:0'):
            test_tensor = tf.constant([1.0, 2.0, 3.0])
            print("✅ MPS GPU 테스트 성공")
    except Exception as e:
        print(f"⚠️ MPS GPU 테스트 실패: {e}. CPU로 진행합니다.")
    
    try:
        # 1. 데이터셋 준비
        print("\n📊 데이터셋 준비 중...")
        train_ds, val_ds, class_names = create_datasets(
            data_dir="../.tensorflow_food101", 
            img_size=IMAGE_SIZE, 
            batch=BATCH_SIZE
        )
        
        # 학습된 모델이 있는지 확인
        stage1_model_path = 'best_stage1.h5'
        stage2_model_path = 'best_stage2.h5'
        
        if os.path.exists(stage1_model_path) and os.path.exists(stage2_model_path):
            print("📁 기존 학습된 모델을 불러옵니다...")
            model_stage1 = tf.keras.models.load_model(stage1_model_path)
            model_stage2 = tf.keras.models.load_model(stage2_model_path)
            model_final = model_stage2
            print("✅ 모델 로드 완료!")
            print(f"📊 1단계 모델: {stage1_model_path} ({os.path.getsize(stage1_model_path)/1024/1024:.1f}MB)")
            print(f"📊 2단계 모델: {stage2_model_path} ({os.path.getsize(stage2_model_path)/1024/1024:.1f}MB)")
        else:
            print("🚀 새로운 모델 학습을 시작합니다...")
            # 2. 1단계 학습 (고정된 백본)
            model_stage1, history1 = train_model_stage1(train_ds, val_ds, len(class_names))
            
            # 1단계 모델 저장
            model_stage1.save(stage1_model_path)
            print(f"✅ 1단계 모델 저장됨: {stage1_model_path}")
            
            # 3. 2단계 학습 (미세튜닝)
            model_stage2, history2 = train_model_stage2(model_stage1, train_ds, val_ds)
            
            # 2단계 모델 저장
            model_stage2.save(stage2_model_path)
            print(f"✅ 2단계 모델 저장됨: {stage2_model_path}")
            
            # 최종 모델
            model_final = model_stage2
        
        # 4. INT8 TFLite 변환
        model_path, model_size = convert_to_tflite_int8(model_final, train_ds, class_names)
        
        # 5. 메타데이터 저장
        save_labels_and_metadata(class_names, model_size)
        
        # 6. 최종 결과 출력
        final_accuracy = max(history2.history['val_accuracy'])
        print(f"\n🎯 최종 검증 정확도: {final_accuracy:.4f}")
        print(f"📁 모델 파일: {model_path}")
        print(f"📏 모델 크기: {model_size:.2f} MB")
        print(f"🏷️ 클래스 수: {len(class_names)}개")
        
        print("\n✅ 실제 음식 분류 모델 학습 완료!")
        
    except Exception as e:
        print(f"❌ 학습 중 오류 발생: {e}")
        raise

if __name__ == "__main__":
    main()
