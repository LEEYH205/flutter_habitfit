#!/usr/bin/env python3
"""
가중치만 추출해서 모델을 재구성하고 TFLite로 변환하는 스크립트
"""

import os
import sys
import h5py
import numpy as np
import tensorflow as tf
from pathlib import Path

# TF 2.15 Apple Silicon 충돌 우회 설정
os.environ["TF_USE_LEGACY_KERAS"] = "1"
os.environ["TF_DISABLE_MLIR_OPTIMIZATIONS"] = "1"
tf.config.optimizer.set_jit(False)
tf.config.optimizer.set_experimental_options({
    "remapping": False,
    "layout_optimizer": False,
    "constant_folding": False
})

def create_mobilenetv3_model():
    """MobileNetV3 Large 아키텍처를 생성"""
    print("🏗️ MobileNetV3 Large 모델 아키텍처 생성 중...")
    
    # MobileNetV3 Large 백본
    base_model = tf.keras.applications.MobileNetV3Large(
        input_shape=(224, 224, 3),
        include_top=False,
        weights='imagenet'
    )
    
    # 분류 헤드 추가
    model = tf.keras.Sequential([
        base_model,
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(101, activation='softmax', name='predictions')
    ])
    
    return model

def extract_weights_from_h5(h5_path):
    """H5 파일에서 가중치만 추출"""
    print(f"📥 H5 파일에서 가중치 추출 중: {h5_path}")
    
    weights = {}
    
    try:
        with h5py.File(h5_path, 'r') as f:
            def extract_weights_recursive(group, prefix=""):
                for key in group.keys():
                    full_key = f"{prefix}/{key}" if prefix else key
                    
                    if isinstance(group[key], h5py.Group):
                        extract_weights_recursive(group[key], full_key)
                    else:
                        # 가중치 배열 추출
                        weights[full_key] = np.array(group[key])
                        print(f"  ✅ {full_key}: {weights[full_key].shape}")
            
            extract_weights_recursive(f)
            
    except Exception as e:
        print(f"❌ H5 파일 읽기 실패: {e}")
        return None
    
    return weights

def load_weights_to_model(model, weights):
    """추출된 가중치를 모델에 로드"""
    print("🔄 가중치를 모델에 로드 중...")
    
    try:
        # 모델의 레이어 이름과 가중치 매칭
        model_weights = {}
        
        for layer in model.layers:
            if hasattr(layer, 'weights') and layer.weights:
                layer_name = layer.name
                print(f"  📋 {layer_name}: {len(layer.weights)} 가중치")
                
                # 해당 레이어의 가중치 찾기
                layer_weights = []
                for weight in layer.weights:
                    weight_name = weight.name
                    # H5에서 가중치 찾기
                    found = False
                    for h5_key, h5_weight in weights.items():
                        if weight_name in h5_key or layer_name in h5_key:
                            layer_weights.append(h5_weight)
                            found = True
                            break
                    
                    if not found:
                        print(f"    ⚠️ {weight_name} 가중치를 찾을 수 없음")
                        layer_weights.append(weight.numpy())
                
                if layer_weights:
                    model_weights[layer_name] = layer_weights
        
        # 가중치 로드
        for layer in model.layers:
            if layer.name in model_weights:
                try:
                    layer.set_weights(model_weights[layer.name])
                    print(f"  ✅ {layer.name} 가중치 로드 완료")
                except Exception as e:
                    print(f"  ❌ {layer.name} 가중치 로드 실패: {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ 가중치 로드 실패: {e}")
        return False

def convert_to_tflite(model, output_path, fp16=True):
    """모델을 TFLite로 변환"""
    print(f"🔄 TFLite 변환 중: {output_path}")
    
    try:
        # TFLite 변환기 생성
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # 최적화 설정
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        
        if fp16:
            converter.target_spec.supported_types = [tf.float16]
            print("  📦 FP16 양자화 적용")
        
        # 변환 실행
        tflite_model = converter.convert()
        
        # 파일 저장
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        print(f"✅ TFLite 모델 저장 완료: {output_path}")
        print(f"  📊 모델 크기: {len(tflite_model) / (1024*1024):.2f} MB")
        
        return True
        
    except Exception as e:
        print(f"❌ TFLite 변환 실패: {e}")
        return False

def main():
    print("🚀 가중치 추출 및 모델 재구성 시작...")
    
    # 경로 설정
    h5_path = Path("../assets/models/best_stage2.h5")
    output_path = Path("../assets/models/food_classification_trained.tflite")
    
    # 1. 모델 아키텍처 생성
    model = create_mobilenetv3_model()
    print(f"✅ 모델 아키텍처 생성 완료: {model.count_params():,} 파라미터")
    
    # 2. H5에서 가중치 추출
    weights = extract_weights_from_h5(h5_path)
    if weights is None:
        print("❌ 가중치 추출 실패")
        return False
    
    print(f"✅ 가중치 추출 완료: {len(weights)} 개")
    
    # 3. 가중치를 모델에 로드
    if not load_weights_to_model(model, weights):
        print("❌ 가중치 로드 실패")
        return False
    
    # 4. TFLite 변환
    if not convert_to_tflite(model, output_path, fp16=True):
        print("❌ TFLite 변환 실패")
        return False
    
    print("🎉 모든 작업 완료!")
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)




