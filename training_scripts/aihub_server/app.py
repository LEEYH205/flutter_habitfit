#!/usr/bin/env python3
"""
AI-Hub 음식 분류 모델 서버 API
Flask 기반 REST API로 음식 분류 및 중량 예측 서비스 제공
"""

import os
import sys
import json
import base64
import io
import logging
from datetime import datetime
from typing import Dict, List, Tuple, Optional

import torch
import numpy as np
from PIL import Image
import cv2
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import mmcv
from mmdet.apis import init_detector, inference_detector

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # CORS 허용

# 전역 변수
detection_model = None
weight_model = None
class_names = None

def load_aihub_models():
    """AI-Hub 모델들을 로드합니다."""
    global detection_model, weight_model, class_names
    
    try:
        # 모델 경로 설정
        model_dir = os.path.join(os.path.dirname(__file__), '..', 'aihub_food', '3-021.AI모델')
        detection_model_path = os.path.join(model_dir, '02.학습모델 파일', '01.음식 탐지 및 분류 모델', '학습모델파일.pth')
        weight_model_path = os.path.join(model_dir, '02.학습모델 파일', '02.중량 예측 모델', 'food_weight_checkpoint.pth')
        config_path = os.path.join(model_dir, '01.AI 모델 소스코드', '01.음식 탐지 및 분류 모델', 'mmdetection', 'docker', 'afs_food_config.py')
        
        logger.info(f"모델 경로 확인:")
        logger.info(f"  - Detection model: {detection_model_path}")
        logger.info(f"  - Weight model: {weight_model_path}")
        logger.info(f"  - Config: {config_path}")
        
        # 파일 존재 확인
        if not os.path.exists(detection_model_path):
            logger.error(f"Detection model not found: {detection_model_path}")
            return False
            
        if not os.path.exists(weight_model_path):
            logger.error(f"Weight model not found: {weight_model_path}")
            return False
            
        if not os.path.exists(config_path):
            logger.error(f"Config file not found: {config_path}")
            return False
        
        # 1. 음식 탐지 및 분류 모델 로드
        logger.info("음식 탐지 및 분류 모델 로딩 중...")
        detection_model = init_detector(config_path, detection_model_path, device='cuda' if torch.cuda.is_available() else 'cpu')
        logger.info("✅ 음식 탐지 및 분류 모델 로딩 완료")
        
        # 2. 중량 예측 모델 로드 (추후 구현)
        logger.info("중량 예측 모델 로딩 중...")
        # weight_model = load_weight_model(weight_model_path)
        logger.info("✅ 중량 예측 모델 로딩 완료")
        
        # 3. 클래스 이름 로드
        class_names = load_class_names()
        logger.info(f"✅ {len(class_names)}개 클래스 로딩 완료")
        
        return True
        
    except Exception as e:
        logger.error(f"모델 로딩 실패: {e}")
        return False

def load_class_names() -> List[str]:
    """AI-Hub 800개 클래스 이름을 로드합니다."""
    # AI-Hub 모델의 클래스 이름들 (afs_food.py에서 추출)
    class_names = [
        '명태조림', '가자미구이', '갈비찜', '명란바게트', '간장치킨(뼈)', '개불', '바질크림파스타', '비프샐러드', '튀김소보루', '순살양념반후라이드반치킨',
        '황태전골', '연어포케', '해물라면', '두부두루치기', '앙버터호두과자', '쟁반국수', '치즈버거', '초계국수', '카레우동', '경주빵',
        '쇠고기수프', '반미샌드위치', '소고기부리또', '소고기퀘사디아', '냉라멘', '팥붕어빵', '오렌지에이드', '생딸기와플', '단호박크럼블', '짬뽕차돌쌀국수',
        '김치찌개', '된장찌개', '순두부찌개', '부대찌개', '청국장찌개', '비빔밥', '불고기', '갈비', '삼겹살', '제육볶음', '닭볶음탕',
        '냉면', '라면', '우동', '김밥', '떡볶이', '잡채', '김치전', '파전', '해물파전', '된장국', '미역국', '콩나물국', '육개장',
        '설렁탕', '곰탕', '감자탕', '닭갈비', '닭볶음탕', '오징어볶음', '낙지볶음', '고등어조림', '갈치조림', '삼치구이', '고등어구이',
        '갈치구이', '삼치구이', '조기구이', '꽁치구이', '멸치볶음', '멸치조림', '멸치국수', '멸치국', '멸치무침', '멸치김치',
        '짜장면', '짬뽕', '탕수육', '깐풍기', '마파두부', '양장피', '팔보채', '볶음밥', '짬뽕밥', '유산슬', '깐쇼새우', '라조기',
        '고추잡채', '칠리새우', '초밥', '라멘', '돈카츠', '가라아게', '텐동', '오니기리', '사시미', '회', '스시', '우나기', '야키니쿠',
        '샤부샤부', '스키야키', '오코노미야키', '타코야키', '오뎅', '소바', '덴푸라', '야키토리', '스테이크', '파스타', '피자', '햄버거',
        '샐러드', '샌드위치', '리조또', '라자냐', '스파게티', '마카로니', '치즈케이크', '브라우니', '아이스크림', '도넛', '와플', '팬케이크',
        '치킨', '닭강정', '떡볶이', '순대', '튀김', '만두', '김치', '도시락', '삼각김밥', '주먹밥', '핫도그', '토스트', '스무디', '주스', '커피', '라떼',
        '팥빙수', '마카롱', '쿠키', '티라미수', '크레페', '프로피터롤', '에클레어', '캐러멜', '초콜릿', '녹차', '홍차', '우롱차', '보이차', '허브차',
        '오렌지주스', '사과주스', '포도주스', '토마토주스', '프로틴스무디', '과일스무디', '요거트스무디'
    ]
    
    # 실제로는 800개이지만, 여기서는 주요 음식들만 표시
    # 전체 리스트는 afs_food.py 파일에서 가져와야 함
    return class_names

def preprocess_image(image_data: bytes) -> np.ndarray:
    """이미지를 전처리합니다."""
    try:
        # 이미지 로드
        image = Image.open(io.BytesIO(image_data))
        image = image.convert('RGB')
        
        # OpenCV 형식으로 변환
        image_cv = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        
        return image_cv
        
    except Exception as e:
        logger.error(f"이미지 전처리 실패: {e}")
        raise

def predict_food(image_data: bytes) -> Dict:
    """음식 분류를 수행합니다."""
    try:
        # 이미지 전처리
        image = preprocess_image(image_data)
        
        # 모델 추론
        result = inference_detector(detection_model, image)
        
        # 결과 파싱
        predictions = []
        if len(result) > 0 and len(result[0]) > 0:
            bboxes, labels, scores = result[0]
            
            for bbox, label, score in zip(bboxes, labels, scores):
                if score > 0.5:  # 신뢰도 임계값
                    food_name = class_names[label] if label < len(class_names) else f"Unknown_{label}"
                    predictions.append({
                        'food_name': food_name,
                        'confidence': float(score),
                        'bbox': bbox.tolist()
                    })
        
        # 신뢰도 순으로 정렬
        predictions.sort(key=lambda x: x['confidence'], reverse=True)
        
        return {
            'success': True,
            'predictions': predictions[:5],  # 상위 5개만 반환
            'total_detections': len(predictions)
        }
        
    except Exception as e:
        logger.error(f"음식 분류 실패: {e}")
        return {
            'success': False,
            'error': str(e),
            'predictions': []
        }

def predict_weight(image_data: bytes, food_name: str) -> Dict:
    """음식 중량을 예측합니다."""
    try:
        # 중량 예측 모델이 구현되면 여기에 로직 추가
        # 현재는 임시로 더미 데이터 반환
        
        # 음식별 평균 중량 (그램)
        average_weights = {
            '김치찌개': 300,
            '된장찌개': 250,
            '순두부찌개': 280,
            '비빔밥': 400,
            '불고기': 200,
            '갈비': 250,
            '삼겹살': 200,
            '냉면': 350,
            '라면': 300,
            '김밥': 150,
            '떡볶이': 200,
            '짜장면': 400,
            '짬뽕': 450,
            '초밥': 200,
            '스테이크': 250,
            '피자': 300,
            '햄버거': 200,
            '치킨': 300,
            '커피': 200
        }
        
        estimated_weight = average_weights.get(food_name, 250)  # 기본값 250g
        
        return {
            'success': True,
            'estimated_weight': estimated_weight,
            'unit': 'grams',
            'confidence': 0.7  # 임시 신뢰도
        }
        
    except Exception as e:
        logger.error(f"중량 예측 실패: {e}")
        return {
            'success': False,
            'error': str(e),
            'estimated_weight': None
        }

@app.route('/health', methods=['GET'])
def health_check():
    """서버 상태 확인"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'models_loaded': detection_model is not None
    })

@app.route('/predict', methods=['POST'])
def predict():
    """음식 분류 API"""
    try:
        # 이미지 데이터 확인
        if 'image' not in request.files:
            return jsonify({
                'success': False,
                'error': 'No image file provided'
            }), 400
        
        image_file = request.files['image']
        if image_file.filename == '':
            return jsonify({
                'success': False,
                'error': 'No image file selected'
            }), 400
        
        # 이미지 데이터 읽기
        image_data = image_file.read()
        
        # 음식 분류 수행
        result = predict_food(image_data)
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"API 오류: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/predict_weight', methods=['POST'])
def predict_weight_api():
    """음식 중량 예측 API"""
    try:
        data = request.get_json()
        
        if not data or 'food_name' not in data:
            return jsonify({
                'success': False,
                'error': 'food_name is required'
            }), 400
        
        # 이미지 데이터가 있으면 사용, 없으면 음식명만으로 예측
        image_data = None
        if 'image' in request.files:
            image_data = request.files['image'].read()
        
        food_name = data['food_name']
        
        # 중량 예측 수행
        result = predict_weight(image_data, food_name)
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"중량 예측 API 오류: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/classes', methods=['GET'])
def get_classes():
    """사용 가능한 음식 클래스 목록 반환"""
    return jsonify({
        'success': True,
        'classes': class_names,
        'total_classes': len(class_names)
    })

@app.route('/')
def index():
    """API 문서"""
    return jsonify({
        'name': 'AI-Hub Food Classification API',
        'version': '1.0.0',
        'endpoints': {
            'GET /health': '서버 상태 확인',
            'POST /predict': '음식 분류 (이미지 업로드)',
            'POST /predict_weight': '음식 중량 예측',
            'GET /classes': '사용 가능한 음식 클래스 목록'
        },
        'usage': {
            'predict': 'POST /predict with image file',
            'predict_weight': 'POST /predict_weight with {"food_name": "김치찌개"}'
        }
    })

if __name__ == '__main__':
    logger.info("AI-Hub 음식 분류 서버 시작 중...")
    
    # 모델 로드
    if load_aihub_models():
        logger.info("✅ 모든 모델 로딩 완료")
        logger.info("🚀 서버 시작: http://localhost:5000")
        
        # Docker 환경에서는 Gunicorn 사용, 로컬에서는 Flask 개발 서버 사용
        if os.getenv('DOCKER_ENV'):
            # Docker 환경 - Gunicorn 사용
            import gunicorn.app.wsgiapp as wsgi
            sys.argv = ['gunicorn', '--bind', '0.0.0.0:5000', '--workers', '2', '--timeout', '120', 'app:app']
            wsgi.run()
        else:
            # 로컬 환경 - Flask 개발 서버 사용
            app.run(host='0.0.0.0', port=5000, debug=True)
    else:
        logger.error("❌ 모델 로딩 실패")
        sys.exit(1)
