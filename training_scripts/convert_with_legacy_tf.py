#!/usr/bin/env python3
"""
TensorFlow 2.15 이전 버전으로 best_stage2.h5 모델을 TFLite로 변환
"""

import os
import sys

# TensorFlow 2.15 이전 버전 사용을 위한 환경 설정
os.environ["TF_USE_LEGACY_KERAS"] = "1"
os.environ["TF_DISABLE_MLIR_OPTIMIZATIONS"] = "1"

# TensorFlow 2.15 이전 버전으로 임포트 시도
try:
    import tensorflow as tf
    print(f"✅ TensorFlow 버전: {tf.__version__}")
    
    # Keras 2.x 호환성 설정
    tf.config.optimizer.set_jit(False)
    tf.config.optimizer.set_experimental_options({
        "remapping": False,
        "layout_optimizer": False,
        "constant_folding": False
    })
    
    def convert_h5_to_tflite_legacy():
        print("🔄 Legacy TensorFlow로 H5 → TFLite 변환 시작...")
        
        h5_path = "../assets/models/best_stage2.h5"
        output_path = "../assets/models/food_classification_trained.tflite"
        
        try:
            # 1. H5 모델 로드 (compile=False)
            print("📥 H5 모델 로딩 중...")
            model = tf.keras.models.load_model(h5_path, compile=False)
            print("✅ H5 모델 로드 성공!")
            
            # 2. 모델 구조 확인
            print(f"📊 모델 입력: {model.input_shape}")
            print(f"📊 모델 출력: {model.output_shape}")
            print(f"📊 총 레이어 수: {len(model.layers)}")
            
            # 3. TFLite 변환
            print("🔄 TFLite 변환 중...")
            converter = tf.lite.TFLiteConverter.from_keras_model(model)
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.target_spec.supported_types = [tf.float16]
            
            tflite_model = converter.convert()
            
            # 4. 저장
            with open(output_path, 'wb') as f:
                f.write(tflite_model)
            
            model_size_mb = len(tflite_model) / (1024 * 1024)
            print(f"✅ TFLite 모델 저장됨: {output_path}")
            print(f"📏 모델 크기: {model_size_mb:.2f} MB")
            
            return True
            
        except Exception as e:
            print(f"❌ 변환 실패: {e}")
            return False
    
    if __name__ == "__main__":
        success = convert_h5_to_tflite_legacy()
        if success:
            print("🎉 변환 성공!")
        else:
            print("💥 변환 실패!")

except ImportError as e:
    print(f"❌ TensorFlow 임포트 실패: {e}")
    print("💡 TensorFlow 2.15 이전 버전이 필요합니다.")

#!/usr/bin/env python3
"""
Convert a Keras 2.x H5 model (best_stage2.h5) to TFLite, using TF 2.15 (tf.keras legacy).
This script is robust to:
 - Missing softmax at the last layer (it will attach one).
 - Accidental wrong working directory (prints absolute paths and checks existence).
Usage:
  python convert_with_legacy_tf.py \
      --h5 ../assets/models/best_stage2.h5 \
      --out ../assets/models/food_classification_trained.tflite \
      --labels ../assets/models/food_labels.txt \
      --fp16
"""

import os
import sys
import argparse
import json

# Force legacy tf.keras on TF 2.16+ if present (requires tf-keras installed),
# and also works fine on TF 2.15.
os.environ.setdefault("TF_USE_LEGACY_KERAS", "1")

def echo_env(tf):
    import h5py
    print("🧪 Python:", sys.version.split()[0])
    print("🧪 TensorFlow:", tf.__version__)
    # Try to show if using legacy tf.keras shim
    using_legacy = os.environ.get("TF_USE_LEGACY_KERAS") == "1"
    print("🧪 TF_USE_LEGACY_KERAS:", using_legacy)
    print("🧪 h5py:", h5py.__version__)

def build_parser():
    p = argparse.ArgumentParser()
    p.add_argument("--h5", required=True, help="Path to best_stage2.h5 (full model or weights-only not supported here)")
    p.add_argument("--out", required=True, help="Path to save tflite")
    p.add_argument("--labels", required=False, help="Optional labels.txt to verify output dimension")
    p.add_argument("--fp16", action="store_true", help="Apply FP16 quantization")
    return p

def maybe_wrap_softmax(model, tf):
    last = model.layers[-1]
    has_softmax = getattr(last, "activation", None) is tf.keras.activations.softmax
    if not has_softmax:
        x = tf.keras.layers.Softmax(name="pred_softmax")(model.output)
        model = tf.keras.Model(model.input, x, name=model.name + "_softmax")
        print("ℹ️  Attached Softmax to the last layer.")
    else:
        print("ℹ️  Model already ends with Softmax.")
    return model

def main():
    parser = build_parser()
    args = parser.parse_args()

    # Resolve and show absolute paths for clarity
    h5_path = os.path.abspath(args.h5)
    out_path = os.path.abspath(args.out)
    labels_path = os.path.abspath(args.labels) if args.labels else None

    print("📄 H5 path :", h5_path)
    print("💾 Out path:", out_path)
    if labels_path:
        print("🏷️ Labels :", labels_path)

    if not os.path.exists(h5_path):
        print(f"❌ H5 파일을 찾을 수 없습니다: {h5_path}")
        sys.exit(2)

    # Import TF after env var is set
    import tensorflow as tf
    echo_env(tf)

    # Try to load full model (compile=False to avoid optimizer restore)
    print("📥 Loading H5 model (compile=False)...")
    try:
        model = tf.keras.models.load_model(h5_path, compile=False)
    except Exception as e:
        print("❌ 모델 로드 실패:", repr(e))
        print("👉 해결 가이드:")
        print("   1) 현재 가상환경이 TF 2.15 + Keras 2.15 인지 확인")
        print("      - python -c 'import tensorflow as tf; print(tf.__version__)'  # 2.15.0 이어야 함")
        print("   2) 모델이 '가중치만'인 경우 이 스크립트로는 로드할 수 없습니다.")
        print("      - 동일한 아키텍처를 코드로 생성 후 model.load_weights(h5)를 사용하세요.")
        sys.exit(3)

    print("✅ Model loaded.")
    print("   Input :", model.input_shape)
    print("   Output:", model.output_shape)
    print("   Layers:", len(model.layers))

    # Ensure softmax at the end (so TFLite outputs probabilities)
    model = maybe_wrap_softmax(model, tf)

    # Optional labels check
    if labels_path and os.path.exists(labels_path):
        with open(labels_path) as f:
            labels = [ln.strip() for ln in f if ln.strip()]
        n_labels = len(labels)
        out_dim = int(model.outputs[0].shape[-1])
        if n_labels != out_dim:
            print(f"⚠️ 라벨 수({n_labels})와 모델 출력 차원({out_dim})이 다릅니다.")
        else:
            print(f"✅ 라벨 수와 출력 차원 일치: {n_labels}")

    # Convert
    print("🔄 Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    if args.fp16:
        converter.target_spec.supported_types = [tf.float16]
        print("ℹ️  FP16 quantization ON")

    try:
        tflite_bytes = converter.convert()
    except Exception as e:
        print("❌ TFLite 변환 실패:", repr(e))
        print("👉 해결 팁: keras==2.15.*, tensorflow(-macos)==2.15.*, h5py<=3.10 로 맞추세요.")
        sys.exit(4)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as f:
        f.write(tflite_bytes)

    print(f"🎉 Saved: {out_path}  ({len(tflite_bytes)/(1024*1024):.2f} MB)")
    print("✅ Done.")

if __name__ == "__main__":
    main()