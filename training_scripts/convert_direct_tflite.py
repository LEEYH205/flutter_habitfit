#!/usr/bin/env python3
"""
완성된 best_stage2.h5 모델을 직접 TFLite로 변환
Keras 3 호환성 문제 우회
"""

import os
import tensorflow as tf
import pathlib

# TF 2.15 Apple Silicon 충돌 우회 설정
os.environ["TF_USE_LEGACY_KERAS"] = "1"
os.environ["TF_DISABLE_MLIR_OPTIMIZATIONS"] = "1"
tf.config.optimizer.set_jit(False)
tf.config.optimizer.set_experimental_options({
    "remapping": False,
    "layout_optimizer": False,
    "constant_folding": False
})

def convert_h5_to_tflite_direct():
    """H5 모델을 직접 TFLite로 변환"""
    print("🔄 H5 모델 직접 TFLite 변환 시작...")
    
    h5_path = "../assets/models/best_stage2.h5"
    output_path = "../assets/models/food_classification.tflite"
    
    if not os.path.exists(h5_path):
        print(f"❌ H5 파일을 찾을 수 없습니다: {h5_path}")
        return False
    
    try:
        # 1) H5 모델 로드 (custom_objects로 호환성 문제 해결)
        print("📥 H5 모델 로딩 중...")
        model = tf.keras.models.load_model(h5_path, compile=False)
        print(f"✅ 모델 로드 완료: {model.input_shape} → {model.output_shape}")
        
        # 2) 직접 TFLite 변환 (SavedModel 우회)
        print("🔄 TFLite 변환 중...")
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # FP16 양자화 설정
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
        
        # 변환 실행
        tflite_model = converter.convert()
        
        # 3) TFLite 모델 저장
        output_path = pathlib.Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        model_size_mb = len(tflite_model) / (1024 * 1024)
        print(f"✅ TFLite 모델 저장됨: {output_path}")
        print(f"📏 모델 크기: {model_size_mb:.2f} MB")
        
        # 4) 검증
        print("🔍 TFLite 모델 검증 중...")
        interpreter = tf.lite.Interpreter(model_path=str(output_path))
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()[0]
        output_details = interpreter.get_output_details()[0]
        
        print(f"✅ TFLite 입력: {input_details['shape']} ({input_details['dtype']})")
        print(f"✅ TFLite 출력: {output_details['shape']} ({output_details['dtype']})")
        
        print(f"\n🎉 변환 완료!")
        print(f"📁 입력: {h5_path}")
        print(f"📁 출력: {output_path}")
        print(f"📏 크기: {model_size_mb:.2f} MB")
        print(f"🔧 양자화: FP16")
        
        return True
        
    except Exception as e:
        print(f"❌ 변환 실패: {e}")
        return False

if __name__ == "__main__":
    convert_h5_to_tflite_direct()



