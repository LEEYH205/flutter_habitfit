#!/usr/bin/env python3
"""
현재 TFLite 모델의 예측 패턴을 분석하여 ImageNet vs Food-101 학습 모델인지 판단
"""

import tensorflow as tf
import numpy as np
import pathlib

def analyze_model_predictions():
    print("🔍 TFLite 모델 예측 패턴 분석 시작...")
    
    # 1. TFLite 모델 로드
    model_path = "../assets/models/food_classification.tflite"
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"📊 입력 텐서: {input_details[0]['shape']} ({input_details[0]['dtype']})")
    print(f"📊 출력 텐서: {output_details[0]['shape']} ({output_details[0]['dtype']})")
    
    # 2. 테스트 이미지 생성 (다양한 패턴)
    test_images = []
    
    # 완전히 검은 이미지
    black_image = np.zeros((1, 224, 224, 3), dtype=np.float32)
    test_images.append(("검은 이미지", black_image))
    
    # 완전히 흰 이미지
    white_image = np.ones((1, 224, 224, 3), dtype=np.float32)
    test_images.append(("흰 이미지", white_image))
    
    # 랜덤 노이즈
    random_image = np.random.random((1, 224, 224, 3)).astype(np.float32)
    test_images.append(("랜덤 노이즈", random_image))
    
    # 그라데이션 이미지
    gradient_image = np.zeros((1, 224, 224, 3), dtype=np.float32)
    for i in range(224):
        gradient_image[0, i, :, :] = i / 224.0
    test_images.append(("그라데이션", gradient_image))
    
    # 3. 각 테스트 이미지에 대한 예측 분석
    print("\n🧪 테스트 이미지별 예측 분석:")
    print("=" * 60)
    
    for name, image in test_images:
        # MobileNetV3 전처리 적용
        processed_image = tf.keras.applications.mobilenet_v3.preprocess_input(image)
        
        # 예측 실행
        interpreter.set_tensor(input_details[0]['index'], processed_image)
        interpreter.invoke()
        predictions = interpreter.get_tensor(output_details[0]['index'])[0]
        
        # 상위 5개 예측 결과
        top5_indices = np.argsort(predictions)[-5:][::-1]
        top5_probs = predictions[top5_indices]
        
        print(f"\n📸 {name}:")
        print(f"   최고 확률: {top5_probs[0]:.4f} ({top5_probs[0]*100:.2f}%)")
        print(f"   상위 5개 확률: {[f'{p:.4f}' for p in top5_probs]}")
        print(f"   확률 분산: {np.std(predictions):.6f}")
        print(f"   최대-최소 차이: {np.max(predictions) - np.min(predictions):.6f}")
    
    # 4. ImageNet vs Food-101 학습 모델 판단 기준
    print("\n" + "=" * 60)
    print("🔍 모델 타입 판단 기준:")
    print("=" * 60)
    
    # 검은 이미지 예측 분석
    interpreter.set_tensor(input_details[0]['index'], 
                          tf.keras.applications.mobilenet_v3.preprocess_input(black_image))
    interpreter.invoke()
    black_predictions = interpreter.get_tensor(output_details[0]['index'])[0]
    
    max_prob = np.max(black_predictions)
    std_prob = np.std(black_predictions)
    
    print(f"📊 검은 이미지 최고 확률: {max_prob:.4f} ({max_prob*100:.2f}%)")
    print(f"📊 확률 표준편차: {std_prob:.6f}")
    
    # 판단 기준
    if max_prob > 0.1:  # 10% 이상
        print("❌ ImageNet 사전 훈련 모델로 판단됨")
        print("   → 검은 이미지에 대해 높은 확률로 특정 클래스 예측")
        print("   → Food-101 학습이 제대로 되지 않음")
    elif max_prob < 0.01:  # 1% 미만
        print("✅ Food-101 학습된 모델로 판단됨")
        print("   → 검은 이미지에 대해 낮은 확률로 예측")
        print("   → 적절한 학습이 이루어짐")
    else:
        print("⚠️  중간 상태 - 추가 분석 필요")
    
    # 5. 클래스별 예측 분포 분석
    print(f"\n📈 클래스별 예측 분포:")
    print(f"   평균 확률: {np.mean(black_predictions):.6f}")
    print(f"   중앙값: {np.median(black_predictions):.6f}")
    print(f"   최대값: {np.max(black_predictions):.6f}")
    print(f"   최소값: {np.min(black_predictions):.6f}")
    
    # 6. 균등 분포 vs 집중 분포 판단
    uniform_threshold = 1.0 / len(black_predictions)  # 균등 분포 시 예상 확률
    print(f"\n🎯 균등 분포 기준: {uniform_threshold:.6f}")
    
    if max_prob < uniform_threshold * 2:  # 균등 분포에 가까움
        print("✅ 균등 분포 - Food-101 학습된 모델")
    else:
        print("❌ 집중 분포 - ImageNet 사전 훈련 모델")

if __name__ == "__main__":
    analyze_model_predictions()



