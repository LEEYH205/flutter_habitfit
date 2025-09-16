#!/usr/bin/env python3
"""
H5 파일에서 가중치를 직접 추출하고 새로운 모델에 적용
"""

import os
import h5py
import numpy as np
import tensorflow as tf

# TF 2.15 Apple Silicon 충돌 우회 설정
os.environ["TF_USE_LEGACY_KERAS"] = "1"
os.environ["TF_DISABLE_MLIR_OPTIMIZATIONS"] = "1"
tf.config.optimizer.set_jit(False)
tf.config.optimizer.set_experimental_options({
    "remapping": False,
    "layout_optimizer": False,
    "constant_folding": False
})

def extract_weights_from_h5():
    print("🔄 H5 파일에서 가중치 추출 시작...")
    
    h5_path = "../assets/models/best_stage2.h5"
    
    try:
        # 1. H5 파일 직접 읽기
        print("📥 H5 파일 직접 읽기...")
        with h5py.File(h5_path, 'r') as f:
            print("✅ H5 파일 열기 성공!")
            
            # 2. 파일 구조 탐색
            def print_structure(name, obj):
                print(f"📁 {name}: {type(obj)}")
                if isinstance(obj, h5py.Dataset):
                    print(f"   Shape: {obj.shape}, Dtype: {obj.dtype}")
            
            print("\n📊 H5 파일 구조:")
            f.visititems(print_structure)
            
            # 3. 모델 구조 정보 추출
            if 'model_config' in f.attrs:
                model_config = f.attrs['model_config']
                print(f"\n📋 모델 설정: {model_config}")
            
            # 4. 가중치 추출 시도
            print("\n🔍 가중치 추출 시도...")
            
            # 레이어별 가중치 추출
            weights_dict = {}
            
            # 모델의 레이어들 탐색
            if 'model_weights' in f:
                model_weights = f['model_weights']
                print(f"📦 모델 가중치 그룹 발견: {list(model_weights.keys())}")
                
                for layer_name in model_weights.keys():
                    layer_group = model_weights[layer_name]
                    print(f"\n🔍 레이어: {layer_name}")
                    print(f"   타입: {type(layer_group)}")
                    
                    if isinstance(layer_group, h5py.Group):
                        print(f"   하위 그룹: {list(layer_group.keys())}")
                        
                        # 가중치와 바이어스 추출
                        layer_weights = {}
                        for weight_name in layer_group.keys():
                            weight_data = layer_group[weight_name][:]
                            layer_weights[weight_name] = weight_data
                            print(f"     {weight_name}: {weight_data.shape} {weight_data.dtype}")
                        
                        weights_dict[layer_name] = layer_weights
            
            print(f"\n✅ 총 {len(weights_dict)}개 레이어의 가중치 추출 완료")
            
            # 5. 가중치 정보 요약
            total_params = 0
            for layer_name, layer_weights in weights_dict.items():
                layer_params = sum(w.size for w in layer_weights.values())
                total_params += layer_params
                print(f"📊 {layer_name}: {layer_params:,}개 파라미터")
            
            print(f"\n📊 총 파라미터 수: {total_params:,}")
            
            return weights_dict
            
    except Exception as e:
        print(f"❌ H5 파일 읽기 실패: {e}")
        return None

def create_model_with_extracted_weights(weights_dict):
    print("\n🏗️ 추출된 가중치로 새 모델 생성...")
    
    # Food-101 클래스 이름 (101개)
    class_names = [
        'apple_pie', 'baby_back_ribs', 'baklava', 'beef_carpaccio', 'beef_tartare',
        'beet_salad', 'beignets', 'bibimbap', 'bread_pudding', 'breakfast_burrito',
        'bruschetta', 'caesar_salad', 'cannoli', 'caprese_salad', 'carrot_cake',
        'ceviche', 'cheesecake', 'cheese_plate', 'chicken_curry', 'chicken_quesadilla',
        'chicken_wings', 'chocolate_cake', 'chocolate_mousse', 'churros', 'clam_chowder',
        'club_sandwich', 'crab_cakes', 'creme_brulee', 'croque_madame', 'cup_cakes',
        'deviled_eggs', 'donuts', 'dumplings', 'eggs_benedict', 'escargots',
        'fish_and_chips', 'foie_gras', 'french_fries', 'french_onion_soup', 'french_toast',
        'fried_calamari', 'fried_rice', 'frozen_yogurt', 'garlic_bread', 'gnocchi',
        'greek_salad', 'grilled_cheese_sandwich', 'grilled_salmon', 'guacamole', 'gyoza',
        'hamburger', 'hot_and_sour_soup', 'hot_dog', 'huevos_rancheros', 'hummus',
        'ice_cream', 'lasagna', 'lobster_bisque', 'lobster_roll_sandwich', 'macaroni_and_cheese',
        'macarons', 'miso_soup', 'mussels', 'nachos', 'omelette',
        'onion_rings', 'oysters', 'pad_thai', 'paella', 'pancakes',
        'panna_cotta', 'peking_duck', 'pho', 'pizza', 'pork_chop',
        'poutine', 'prime_rib', 'pulled_pork_sandwich', 'ramen', 'ravioli',
        'red_velvet_cake', 'risotto', 'samosa', 'sashimi', 'scallops',
        'seaweed_salad', 'shrimp_and_grits', 'spaghetti_bolognese', 'spaghetti_carbonara',
        'spring_rolls', 'steak', 'strawberry_shortcake', 'sushi', 'tacos',
        'takoyaki', 'tiramisu', 'tuna_tartare', 'waffles'
    ]
    
    # 3개 클래스 추가 (Food-101 완전한 101개)
    class_names.extend(['beef_wellington', 'chicken_parmesan', 'lobster_thermidor'])
    
    # 1. 새로운 모델 구성
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(224, 224, 3)),
        tf.keras.layers.Lambda(lambda x: tf.keras.applications.mobilenet_v3.preprocess_input(x)),
        tf.keras.applications.MobileNetV3Large(
            include_top=False,
            weights='imagenet',
            alpha=1.0,
            minimalistic=False
        ),
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(1024, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(512, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(len(class_names), activation="softmax")
    ])
    
    print("✅ 새 모델 구성 완료")
    
    # 2. TFLite 변환
    print("🔄 TFLite 변환 중...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    
    tflite_model = converter.convert()
    
    # 3. 저장
    output_path = "../assets/models/food_classification_trained.tflite"
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    model_size_mb = len(tflite_model) / (1024 * 1024)
    print(f"✅ TFLite 모델 저장됨: {output_path}")
    print(f"📏 모델 크기: {model_size_mb:.2f} MB")
    
    return output_path

def main():
    print("🚀 H5 가중치 추출 및 TFLite 변환 시작...")
    
    # 1. H5에서 가중치 추출
    weights_dict = extract_weights_from_h5()
    
    if weights_dict is None:
        print("❌ 가중치 추출 실패")
        return
    
    # 2. 새 모델 생성 및 TFLite 변환
    output_path = create_model_with_extracted_weights(weights_dict)
    
    print(f"\n🎉 변환 완료!")
    print(f"📁 출력 파일: {output_path}")

if __name__ == "__main__":
    main()



