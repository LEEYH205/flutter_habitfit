#!/usr/bin/env python3
"""
Food-101 H5 모델을 안전하게 TFLite로 변환하는 스크립트
TF 2.15 Apple Silicon 호환성 보장
"""

import os
import tensorflow as tf
import argparse
import pathlib

# TF 2.15 Apple Silicon 충돌 우회 설정
os.environ["TF_USE_LEGACY_KERAS"] = "1"
tf.config.optimizer.set_jit(False)
tf.config.optimizer.set_experimental_options({
    "remapping": False,
    "layout_optimizer": False
})

def convert_h5_to_tflite(h5_path, output_path, fp16=False):
    """H5 모델을 TFLite로 안전하게 변환"""
    print(f"🔄 H5 모델 변환 시작: {h5_path}")
    
    # 1) Keras 모델 로드 (compile=False로 안정성 향상)
    print("📥 H5 모델 로딩 중...")
    model = tf.keras.models.load_model(h5_path, compile=False)
    print(f"✅ 모델 로드 완료: {model.input_shape} → {model.output_shape}")
    
    # 2) SavedModel 임시로 내보내기
    print("💾 SavedModel 형식으로 변환 중...")
    tmp_dir = "tmp_savedmodel"
    if os.path.exists(tmp_dir):
        tf.io.gfile.rmtree(tmp_dir)
    
    tf.saved_model.save(model, tmp_dir)
    print(f"✅ SavedModel 저장됨: {tmp_dir}")
    
    # 3) TFLite 변환
    print("🔄 TFLite 변환 중...")
    converter = tf.lite.TFLiteConverter.from_saved_model(tmp_dir)
    
    # 권장 옵션
    converter.experimental_new_converter = True
    converter._experimental_lower_tensor_list_ops = True
    
    if fp16:
        print("🔧 FP16 양자화 적용")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
    else:
        print("🔧 FP32 모드 (정확도 우선)")
    
    tflite_model = converter.convert()
    
    # 4) TFLite 모델 저장
    output_path = pathlib.Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    model_size_mb = len(tflite_model) / (1024 * 1024)
    print(f"✅ TFLite 모델 저장됨: {output_path}")
    print(f"📏 모델 크기: {model_size_mb:.2f} MB")
    
    # 5) 빠른 점검
    print("🔍 TFLite 모델 검증 중...")
    interpreter = tf.lite.Interpreter(model_path=str(output_path))
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()[0]
    output_details = interpreter.get_output_details()[0]
    
    print(f"✅ TFLite 입력: {input_details['shape']} ({input_details['dtype']})")
    print(f"✅ TFLite 출력: {output_details['shape']} ({output_details['dtype']})")
    
    # 6) 임시 파일 정리
    if os.path.exists(tmp_dir):
        tf.io.gfile.rmtree(tmp_dir)
        print("🧹 임시 파일 정리 완료")
    
    return model_size_mb

def main():
    parser = argparse.ArgumentParser(description="Food-101 H5 모델을 TFLite로 변환")
    parser.add_argument("--h5", required=True, help="입력 H5 모델 경로")
    parser.add_argument("--out", required=True, help="출력 TFLite 모델 경로")
    parser.add_argument("--fp16", action="store_true", help="FP16 양자화 적용")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.h5):
        print(f"❌ H5 파일을 찾을 수 없습니다: {args.h5}")
        return
    
    try:
        model_size = convert_h5_to_tflite(args.h5, args.out, args.fp16)
        print(f"\n🎉 변환 완료!")
        print(f"📁 입력: {args.h5}")
        print(f"📁 출력: {args.out}")
        print(f"📏 크기: {model_size:.2f} MB")
        print(f"🔧 양자화: {'FP16' if args.fp16 else 'FP32'}")
        
    except Exception as e:
        print(f"❌ 변환 실패: {e}")
        raise

if __name__ == "__main__":
    main()
