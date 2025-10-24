#!/bin/bash

echo "🧪 AI-Hub 음식 분류 API 테스트"
echo "================================"
echo ""

# 서버 상태 확인
echo "1️⃣ 서버 상태 확인..."
curl -s http://localhost:5001/health | jq '.'
echo ""

# 클래스 개수 확인
echo "2️⃣ 클래스 개수 확인..."
curl -s http://localhost:5001/classes | jq '{total_classes, sample: .classes[0:5]}'
echo ""

# 테스트 이미지 생성 (Python 사용)
echo "3️⃣ 테스트 이미지 생성..."
python3 << 'EOF'
from PIL import Image, ImageDraw, ImageFont
import random

# 랜덤 음식 이미지 생성
img = Image.new('RGB', (640, 480), color=(240, 240, 240))
draw = ImageDraw.Draw(img)

# 원형 "음식" 그리기
for _ in range(5):
    x = random.randint(50, 590)
    y = random.randint(50, 430)
    r = random.randint(30, 80)
    color = (random.randint(100, 255), random.randint(100, 255), random.randint(100, 255))
    draw.ellipse([x-r, y-r, x+r, y+r], fill=color, outline=(50, 50, 50), width=2)

# 텍스트 추가
try:
    draw.text((320, 240), "Test Food Image", fill=(100, 100, 100), anchor="mm")
except:
    pass

img.save('/tmp/test_food_image.jpg')
print('✅ 테스트 이미지 생성 완료: /tmp/test_food_image.jpg')
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "4️⃣ 음식 분류 API 테스트..."
    curl -s -X POST http://localhost:5001/predict \
        -F "image=@/tmp/test_food_image.jpg" | jq '.'
    echo ""
    
    echo "5️⃣ 중량 예측 API 테스트..."
    curl -s -X POST http://localhost:5001/predict_weight \
        -H "Content-Type: application/json" \
        -d '{"food_name":"김치찌개"}' | jq '.'
    echo ""
else
    echo "❌ Python이 설치되어 있지 않거나 PIL 모듈이 없습니다."
    echo "   pip install pillow 로 설치해주세요."
fi

echo "✅ 테스트 완료!"
echo ""
echo "💡 웹 테스트 페이지: file://$(pwd)/test_web.html"

