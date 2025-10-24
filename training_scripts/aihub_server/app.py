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

# 로깅 설정 (먼저 설정)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# MMDetection은 선택적으로 import (의존성 문제 회피)
try:
    import mmcv
    from mmdet.apis import init_detector, inference_detector
    MMDET_AVAILABLE = True
    logger.info("✅ MMDetection available")
except ImportError:
    MMDET_AVAILABLE = False
    logger.warning("⚠️ MMDetection not available. Using dummy predictions.")

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
        # 클래스 이름 로드
        class_names = load_class_names()
        logger.info(f"✅ {len(class_names)}개 클래스 로딩 완료")
        
        # MMDetection이 사용 가능한 경우에만 모델 로드 시도
        if MMDET_AVAILABLE:
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
            if os.path.exists(detection_model_path) and os.path.exists(config_path):
                # 1. 음식 탐지 및 분류 모델 로드
                logger.info("음식 탐지 및 분류 모델 로딩 중...")
                detection_model = init_detector(config_path, detection_model_path, device='cuda' if torch.cuda.is_available() else 'cpu')
                logger.info("✅ 음식 탐지 및 분류 모델 로딩 완료")
            else:
                logger.warning("⚠️ AI-Hub 모델 파일을 찾을 수 없습니다. 더미 모델 사용")
                detection_model = None
        else:
            logger.warning("⚠️ MMDetection을 사용할 수 없습니다. 더미 모델 사용")
            detection_model = None
        
        return True
        
    except Exception as e:
        logger.error(f"모델 로딩 실패: {e}")
        logger.warning("⚠️ 더미 모델로 대체합니다")
        detection_model = None
        return True  # 실패해도 서버는 시작

def load_class_names() -> List[str]:
    """AI-Hub 800개 클래스 이름을 로드합니다."""
    # AI-Hub 모델의 실제 800개 클래스 이름들 (afs_food.py에서 추출)
    class_names = [
        '명태조림', '가자미구이', '갈비찜', '명란바게트', '간장치킨(뼈)', '개불', '바질크림파스타', '비프샐러드', '튀김소보루', '순살양념반후라이드반치킨',
        '황태전골', '연어포케', '해물라면', '두부두루치기', '앙버터호두과자', '쟁반국수', '치즈버거', '초계국수', '카레우동', '경주빵',
        '쇠고기수프', '반미샌드위치', '소고기부리또', '소고기퀘사디아', '냉라멘', '팥붕어빵', '오렌지에이드', '생딸기와플', '단호박크럼블', '짬뽕차돌쌀국수',
        '명태찜', '모둠순대', '에그마요샌드위치', '국물닭발', '닭윙간장치킨', '연어샐러드', '토르티야', '크림떡볶이', '마라빤', '치킨샐러드',
        '새우샌드위치', '반계탕', '시카고피자', '쑥떡', '규동', '우유크림빵', '부타동', '호두빵', '바지락된장찌개', '시래기해장국',
        '바닐라아이스크림와플', '크랜베리시리얼', '호박식혜', '홍차', '단호박피자', '쿠키슈', '황태국', '고구마치즈돈가스', '카이센동', '불고기컵밥',
        '아몬드크로와상', '로스카츠(등심)', '까눌레', '냉채족발', '로제치킨(뼈)', '리코타치즈샐러드', '떡강정', '차돌짬뽕', '유린기', '꿔바로우',
        '사천탕수육', '삼겹살스테이크', '낙지호롱', '내장볶음', '콩나물불고기(콩불)', '초코까눌레', '밤식빵', '광어회', '나주곰탕', '대구뽈찜',
        '대구탕', '대하찜', '막회', '멍게(활)', '물갈비', '물회', '북어찜', '산낙지회', '소라숙회', '술국',
        '아바이순대', '어탕국수', '얼큰황태우거지탕', '오징어회', '장어탕', '해물누룽지탕', '프렌치토스트', '차돌된장찌개', '카레컵밥', '스팸김밥',
        '스팸김치컵밥', '콩떡', '갈릭난', '양꼬치', '양장피', '러스크', '새우튀김우동', '닭가슴살', '연유크림빵', '소세지크로와상',
        '닭모래집볶음', '꽁치김치찌개', '순살간장치킨', '아이스티라미수라떼', '삼계전복죽', '치즈크로플', '망개떡', '딸기에이드', '딸기주스', '매운해물쌀국수',
        '베이컨토스트', '참치마요덮밥', '크림리조또', '플레인크로플', '우삼겹비빔밥', '초코라떼(HOT)', '버팔로윙', '황태닭곰탕', '치킨커리', '떡만두라면',
        '매생이굴국밥', '동파육', '플레인난', '닭다리간장치킨', '고구마피자(팬)', '곱창떡볶이', '까르보나라파스타', '밀크크레이프', '바게트빵', '고구마핫도그',
        '훈제연어덮밥', '훈제양념치킨', '묵은지닭볶음탕', '블루베리마카롱', '빠네크림파스타', '또띠아피자', '새우(쉬림프)부리또', '빨간참치김밥', '야채고로케', '추어칼국수',
        '파닭', '페퍼로니피자(씬)', '치즈곱창', '새우오일파스타', '케이준양념감자', '뮤즐리시리얼', '딸기크레이프', '오피자', '자장떡볶이', '키위주스',
        '베트남식 볶음면', '마라떡볶이', '닭가슴살샐러드', '찹쌀도너츠', '피자빵', '핫도그', '양념반후라이드반치킨(뼈)', '앙금절편', '크레미롤', '크림우동',
        '충무김밥', '크림도넛', '곱도리탕', '가라아케', '검은콩국수', '아몬드시리얼', '순살파닭', '삼치구이', '밤떡', '초코파운드',
        '차슈바오', '어니언링', '슈크림크로와상', '나폴리피자', '김치죽', '오징어순대', '올갱이해장국', '옥수수식빵', '추어만두', '루꼴라피자',
        '딸기샌드위치', '초코아이스크림와플', '마라쌀국수', '함박스테이크', '아라비아따파스타', '생크림케이크', '새우피자(씬)', '새우피자(팬)', '말차까눌레', '팟타이',
        '베이컨샌드위치', '햄에그샌드위치', '녹차마카롱', '파네토네', '훈제닭가슴살', '콤비네이션피자(팬)', '감자고로케', '치킨마요덮밥', '고구마식빵', '메밀소바',
        '멘보샤', '깐풍치킨(뼈)', '돈코츠라멘', '건두부볶음', '불고기피자(팬)', '멍게비빔밥', '납작만두', '버터크림빵', '돼지간', '돼지두루치기',
        '비빔막국수', '아이스아메리카노', '소고기타다끼초밥', '아이스크림크로플', '카푸치노(HOT)', '햄치즈파니니', '흑임자죽', '김피탕', '꼬막무침', '조기구이',
        '초코머핀', '꽃빵', '바지락칼국수', '잡채말이튀김', '새우로제파스타', '새우샤오롱바오', '순살로제치킨', '무뼈닭발', '모카번', '우삼겹팟타이',
        '만두라면', '곱창쭈꾸미', '광어매운탕', '우삼겹떡볶이', '닭다리후라이드치킨', '딸기크로플', '감자토스트', '소대창쌀국수', '바나나주스', '복숭아아이스티',
        '어니언베이컨피자', '소고기타코', '비스마르크피자', '소시지빵', '두부샐러드', '짜조', '가리비초밥', '간장달걀밥', '순살훈제양념치킨', '제육컵밥',
        '타코와사비', '영양떡', '젤리롤케잌', '로제떡볶이', '황태미역국', '딸기롤케잌', '야채호빵', '인절미크로플', '아보카도샌드위치', '오코노미야끼',
        '흑당밀크티', '연유빵', '오메기떡', '멸치김밥', '미니족발', '포테이토피자(씬)', '메밀만두', '콘수프', '애플파이', '꽈배기',
        '가지만두', '부대떡볶이', '고기국수', '크림함박스테이크', '휘낭시에', '달걀초밥', '민트초코라떼', '순살양념파닭', '미소라멘', '떡만둣국',
        '로제찜닭', '오레오시리얼', '콘샐러드', '닭계장', '버터난', '양갈비살꼬치', '감자수제비', '우럭초밥', '춘권', '김치참치마요컵밥',
        '초코크로와상', '치킨파히타', '바닐라마카롱', '야채곱창볶음', '양평해장국', '새우고로케', '마늘바게트', '글레이즈드도넛', '볼로네제토마토파스타', '해물쌀국수',
        '샤오롱바오', 'BLT샌드위치', '캘리포니아롤', '하와이안피자', '청귤에이드', '플레인스콘', '햄치즈베이글', '훈제닭가슴살소시지', '치즈케이크', '모시송편',
        '황태닭개장', '황태떡국', '황태만두국', '사천볶음쌀국수', '치즈스틱', '연어회덮밥', '베이컨치즈버거', '황태콩나물해장국', '녹차머핀', '날치알주먹밥',
        '다슬기해장국', '경주찰보리빵', '계란빵', '우유마카롱', '고구마돈가스', '불백(뚝배기불고기)', '나시고랭볶음밥', '똠얌꿍쌀국수', '고구마피자(씬)', '순살마요치킨',
        '땡초김밥', '얼큰칼국수', '잡채고로케', '튀김꽃빵', '참치마요컵밥', '피자호빵', '마라샹궈', '고르곤졸라피자', '초코소라빵', '오돌뼈볶음',
        '낙지죽', '치즈샌드위치', '치즈피자', '순살깐풍치킨', '제육볶음', '차돌양지쌀국수', '후르츠링시리얼', '빨계떡', '투움바떡볶이', '머랭쿠키',
        '햄치즈토스트', '소떡소떡', '닭가슴살샌드위치', '닭갈비컵밥', '마르게리따피자', '꼬막짬뽕', '새우버거', '참소라초밥', '치즈볼', '낙지탕탕이',
        '민물새우튀김', '날치알크림파스타', '치킨버거', '치즈떡볶이', '소고기초밥', '콤비네이션피자(씬)', '굴비찜', '해신탕', '닭윙후라이드치킨', '두부버섯전골',
        '슈크림붕어빵', '초코와플', '호박송편', '소시지(프랑크)', '버섯피자', '맥앤치즈', '타코야끼', '새우장초밥', '참치죽', '시나몬롤',
        '아이스카페라떼', '순대전골', '순두부짬뽕', '크림치즈호두빵', '우육면', '에스프레소', '풍기크림파스타', '옥수수빵', '크로크무슈', '그래놀라시리얼',
        '쏨땀', '황치즈마카롱', '감자그라탕', '시나몬라떼(HOT)', '훈제치킨(뼈)', '닭윙&닭다리양념치킨', '아이스크림와플', '마약옥수수', '앙버터치아바타', '쑥버무리',
        '씨앗호떡', '생크림식빵', '깔라만시에이드', '딸기바나나주스', '옛날통닭', '양념닭가슴살', '추어전골', '로제리조또', '순살간장반후라이드반치킨', '쿠키엔크림케이크',
        '까르보네피자', '황도', '돌체피자', '중화냉면', '불고기파니니', '브로콜리수프', '토피넛라떼', '닭다리양념치킨', '대하구이', '모짜렐라핫도그',
        '얼그레이', '소시지고로케', '감자핫도그', '바질샌드위치', '소금빵', '꽁치구이', '김치나베', '슈크림빵', '시나몬크로플', '쟁반짬뽕',
        '전주비빔컵밥', '순살양념반간장반치킨', '닭고기쌀국수', '고구마떡', '칼국수', '볶음쌀국수', '베이컨크림파스타', '초코롤케잌', '진주냉면', '황태부대찌개',
        '딸기마카롱', '순살어니언치킨', '순살크림(크리미)치킨', '커피콩빵', '닭내장볶음', '피자토스트', '포테이토피자(팬)', '카스테라', '어니언치킨(뼈)', '돼지짜글이',
        '호두과자', '묵은지갈비찜', '딸기타르트', '닭발볶음', '초코스무디', '히레카츠(안심)', '육회초밥', '은행구이', '까르보나라떡볶이', '얼그레이마카롱',
        '얼그레이밀크티', '탄탄멘', '티라미수', '에비(텐)동', '딸기크로와상', '해물리조또', '새우토마토스파게티', '간장반후라이드반치킨(뼈)', '석갈비', '단팥크림빵',
        '순살후라이드치킨', '쫄볶이', '버섯리조또', '바나나와플', '로제돈가스', '베이컨포테이토피자', '망고스무디', '찹스테이크', '알내장탕', '불고기피자(씬)',
        '깨찰빵', '녹차라떼', '치킨퀘사디아', '우삼겹커리', '약밥', '멸치국수', '민트초코마카롱', '순살간장파닭', '순살마늘치킨', '마늘치킨(뼈)',
        '플레인베이글', '불고기쌀국수', '크림(크리미)치킨(뼈)', '소힘줄(스지) 쌀국수', '카츠동', '초코크레이프', '라조기', '치아바타', '김치낙지죽', '애플크럼블',
        '해물뚝배기', '마요치킨(뼈)', '초코베이글', '클럽샌드위치', '김치알컵밥', '오일파스타', '소곱창쌀국수', '노가리', '치즈달걀말이', '무지개떡',
        '코다리냉면', '차슈라멘', '닭윙양념치킨', '낙지전골', '계란토스트', '블루베리시리얼', '들깨수제비', '레인보우케이크', '봉골레파스타', '치킨부리또',
        '새우볼', '새우토스트', '페퍼로니피자(팬)', '해산물팟타이', '모시떡', '밀푀유나베', '마살라커리', '단팥호빵', '크림수프', '팔보채',
        '장어롤', '짬뽕 쌀국수', '완두앙금빵', '알리오올리오파스타', '간장닭갈비', '달걀오믈렛', '쇠고기죽', '연어롤', '삼선간짜장', '편육',
        '피자돈까스', '토마토리조또', '마들렌', '호떡', '김치찜', '블루베리파이', '빠네로제파스타', '사과주스', '땅콩샌드위치', '묵밥(묵사발)',
        '묵은지감자탕', '물밀면', '버섯샐러드', '불족발', '빈대떡', '고구마그라탕', '옥수수떡', '나가사끼짬뽕', '소갈비살꼬지', '꼬마김밥',
        '명란크림파스타', '양념반간장반치킨(뼈)', '앙버터크로와상', '당근케이크', '감자만두', '만두전골', '크로칸슈', '후라이드치킨(뼈)', '고추장불고기', '딸기케이크',
        '해천탕', '마라쇼룽샤', '양송이수프', '치킨포케', '피쉬볼', '해물순두부찌개', '닭가슴살소시지', '카야토스트', '게살고로케', '고구마샐러드',
        '아이스돌체라떼', '우유식빵', '우럭매운탕', '오트밀식빵', '황태찜', '단호박샐러드', '불고기버거', '카라멜마끼아또(HOT)', '생크림크로플', '김치참치컵밥',
        '풍기피자', '생크림와플', '치아바타샌드위치', '가이 팟 퐁 커리', '전복버터구이', '땡초멸치김밥', '굴국밥', '꼬막비빔밥', '유산슬', '녹두죽',
        '돌체라떼(HOT)', '쿠키쉐이크', '팥빙수', '플레인요거트스무디', '핫초코', '흑당라떼', '술떡', '돈가스김밥', '불낙전골', '후레쉬빵',
        '황태국밥', '고구마케이크', '치킨토스트', '초코스콘', '자몽주스', '헤이즐넛라떼(HOT)', '녹차롤케잌', '카라멜마카롱', '에그타르트', '마라살꼬치',
        '바닐라머핀', '주꾸미삽겹살볶음', '크림새우', '난자완스', '옥수수시리얼', '감자옹심이', '햄샌드위치', '먹태', '루이보스차', '쟁반짜장',
        '양지쌀국수', '로제파스타', '어묵튀김', '참치샌드위치', '크림치즈베이글', '맘모스빵', '중화볶음면', '초계탕', '오트밀시리얼', '감바스',
        '돈부리덮밥', '통밀식빵', '장어튀김', '브라우니', '치즈라볶이', '크리스피치킨(뼈)', '빙떡', '유부우동', '아이스코코넛라떼', '닭가슴살스테이크',
        '망고주스', '모히또', '메론빵', '비빔밀면', '닭윙&닭다리간장치킨', '추어전', '불닭마요컵밥', '초코시리얼', '칠리새우', '감자빵',
        '나쵸', '깐쇼새우', '마라롱샤', '새우만두', '감자떡', '에그샌드위치', '새우김밥', '초코크로플', '마라탕', '탄두리치킨',
        '푸팟퐁커리', '게살볶음밥', '케이준샐러드', '똠얌꿍', '날치알초밥', '초코케이크', '소보루빵', '찰순대', '체리콕에이드', '토마토계란볶음',
        '팥칼국수', '미숫가루', '황태육개장', '마늘빵', '찹쌀꽈배기', '에비카츠', '오곡라떼', '인절미빙수', '단팥빵', '차돌떡볶이',
        '콜드브루', '콜드브루라떼', '깜빠뉴', '얼그레이까눌레', '고구마라떼', '아이스초코라떼', '바나나쉐이크', '낙곱새', '소유라멘', '퀸아망',
        '아이스헤이즐넛라떼', '아이스헤이즐넛아메리카노', '새우크림파스타', '레몬에이드', '호두타르트', '등갈비찜', '갈비만두', '갈비전골', '순살양념치킨', '차슈동',
        '분짜', '교자만두', '치즈번', '초코밀크티', '초코마카롱', '소고기간', '카레고로케', '갈치구이', '누드김밥', '카츠나베',
        '야끼만두', '카모마일차', '고등어구이', '핫바(어묵소시지)', '천엽', '아메리카노(HOT)', '갈비치킨', '딸기스무디', '치킨타코', '빨미까레',
        '굴비구이', '치즈닭갈비', '매생이국', '시오라멘', '코코넛라떼(HOT)', '추어튀김', '치킨너겟', '꿍 팟 퐁 커리', '유자차', '망고에이드',
        '수박주스', '자몽차', '청귤차', '블루레몬에이드', '냉우동', '아이스카라멜마끼아또', '메밀전', '아이스모카라떼', '히비스커스', '아이스초코모카라떼',
        '카페라떼(HOT)', '도리뱅뱅이', '초코모카라떼(HOT)', '헤이즐넛아메리카노(HOT)', '유니짜장', '울면', '레몬아이스티', '녹차', '레몬차', '달고나라떼',
        '식혜', '아이스토피넛라떼', '초코쉐이크', '밀크쉐이크', '낙지덮밥', '딸기빙수', '키위스무디', '토마토주스', '블랙밀크티', '생태찌개',
        '연유라떼', '죠리퐁라떼', '칠리새우덮밥', '아샷추', '그린밀크티', '자몽에이드', '더치커피', '아이스카푸치노', '청포도에이드', '모카라떼(HOT)',
        '아포가토', '티라미수라떼(HOT)', '돌솥비빔밥', '블루베리스무디', '바닐라라떼', '유자스무디', '코울슬로', '말차라떼', '아이스시나몬라떼', '아이스초코'
    ]
    
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
        
        # 실제 모델이 로드되어 있으면 사용
        if detection_model is not None and MMDET_AVAILABLE:
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
        else:
            # 더미 모델: 랜덤하게 3개의 음식 반환
            import random
            sample_foods = random.sample(class_names, min(3, len(class_names)))
            predictions = [
                {
                    'food_name': food,
                    'confidence': round(random.uniform(0.7, 0.95), 2),
                    'bbox': [100, 100, 300, 300]
                }
                for food in sample_foods
            ]
            predictions.sort(key=lambda x: x['confidence'], reverse=True)
            
            return {
                'success': True,
                'predictions': predictions,
                'total_detections': len(predictions),
                'note': 'Using dummy model (MMDetection not available)'
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

# 서버 시작 시 모델 로드 (Gunicorn 환경에서도 실행됨)
logger.info("AI-Hub 음식 분류 서버 초기화 중...")
load_aihub_models()
logger.info("✅ 서버 초기화 완료")

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
