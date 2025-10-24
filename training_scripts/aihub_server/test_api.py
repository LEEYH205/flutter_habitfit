#!/usr/bin/env python3
"""
AI-Hub 서버 API 테스트 스크립트
"""

import requests
import json
import os
from PIL import Image
import numpy as np

# 서버 URL
SERVER_URL = 'http://localhost:5000'

def test_health():
    """서버 상태 확인"""
    print("🔍 서버 상태 확인...")
    try:
        response = requests.get(f'{SERVER_URL}/health')
        if response.status_code == 200:
            result = response.json()
            print(f"✅ 서버 상태: {result['status']}")
            print(f"📊 모델 로드됨: {result['models_loaded']}")
            return True
        else:
            print(f"❌ 서버 응답 오류: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 서버 연결 실패: {e}")
        return False

def test_classes():
    """사용 가능한 클래스 목록 확인"""
    print("\n🏷️ 사용 가능한 클래스 목록 확인...")
    try:
        response = requests.get(f'{SERVER_URL}/classes')
        if response.status_code == 200:
            result = response.json()
            if result['success']:
                print(f"✅ 총 {result['total_classes']}개 클래스")
                print(f"📋 예시: {result['classes'][:10]}")
                return result['classes']
            else:
                print("❌ 클래스 목록 가져오기 실패")
                return []
        else:
            print(f"❌ 서버 응답 오류: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ 클래스 목록 요청 실패: {e}")
        return []

def create_test_image():
    """테스트용 이미지 생성"""
    print("\n🖼️ 테스트용 이미지 생성...")
    
    # 간단한 테스트 이미지 생성 (224x224 RGB)
    image_array = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
    image = Image.fromarray(image_array)
    
    # 임시 파일로 저장
    test_image_path = 'test_image.jpg'
    image.save(test_image_path)
    print(f"✅ 테스트 이미지 생성: {test_image_path}")
    
    return test_image_path

def test_predict(image_path):
    """음식 분류 테스트"""
    print(f"\n🍽️ 음식 분류 테스트: {image_path}")
    try:
        with open(image_path, 'rb') as f:
            files = {'image': f}
            response = requests.post(f'{SERVER_URL}/predict', files=files)
        
        if response.status_code == 200:
            result = response.json()
            if result['success']:
                print(f"✅ 분류 성공!")
                print(f"📊 총 탐지: {result['total_detections']}개")
                
                for i, prediction in enumerate(result['predictions'][:3]):
                    print(f"  {i+1}. {prediction['food_name']} (신뢰도: {prediction['confidence']:.3f})")
                
                return result['predictions']
            else:
                print(f"❌ 분류 실패: {result.get('error', 'Unknown error')}")
                return []
        else:
            print(f"❌ 서버 응답 오류: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ 분류 요청 실패: {e}")
        return []

def test_weight_prediction(food_name):
    """중량 예측 테스트"""
    print(f"\n⚖️ 중량 예측 테스트: {food_name}")
    try:
        data = {'food_name': food_name}
        response = requests.post(
            f'{SERVER_URL}/predict_weight',
            json=data,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            result = response.json()
            if result['success']:
                print(f"✅ 중량 예측 성공!")
                print(f"📊 예상 중량: {result['estimated_weight']} {result['unit']}")
                print(f"📊 신뢰도: {result['confidence']:.3f}")
                return result
            else:
                print(f"❌ 중량 예측 실패: {result.get('error', 'Unknown error')}")
                return None
        else:
            print(f"❌ 서버 응답 오류: {response.status_code}")
            return None
    except Exception as e:
        print(f"❌ 중량 예측 요청 실패: {e}")
        return None

def cleanup():
    """테스트 파일 정리"""
    test_files = ['test_image.jpg']
    for file in test_files:
        if os.path.exists(file):
            os.remove(file)
            print(f"🗑️ 테스트 파일 삭제: {file}")

def main():
    """메인 테스트 함수"""
    print("🧪 AI-Hub 서버 API 테스트 시작")
    print("=" * 50)
    
    # 1. 서버 상태 확인
    if not test_health():
        print("\n❌ 서버가 실행되지 않았습니다.")
        print("💡 서버를 시작하려면: python app.py")
        return
    
    # 2. 클래스 목록 확인
    classes = test_classes()
    
    # 3. 테스트 이미지 생성
    test_image_path = create_test_image()
    
    # 4. 음식 분류 테스트
    predictions = test_predict(test_image_path)
    
    # 5. 중량 예측 테스트
    if predictions:
        food_name = predictions[0]['food_name']
        test_weight_prediction(food_name)
    
    # 6. 정리
    cleanup()
    
    print("\n" + "=" * 50)
    print("✅ 테스트 완료!")

if __name__ == '__main__':
    main()
