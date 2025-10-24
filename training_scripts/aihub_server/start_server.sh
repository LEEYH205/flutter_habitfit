#!/bin/bash

# AI-Hub 음식 분류 서버 시작 스크립트

echo "🍽️ AI-Hub 음식 분류 서버 시작 중..."

# 가상환경 확인 및 생성
if [ ! -d "aihub_env" ]; then
    echo "📦 가상환경 생성 중..."
    python3 -m venv aihub_env
fi

# 가상환경 활성화
echo "🔧 가상환경 활성화 중..."
source aihub_env/bin/activate

# 의존성 설치
echo "📥 의존성 설치 중..."
pip install -r requirements.txt

# 서버 시작
echo "🚀 서버 시작 중..."
echo "📍 서버 주소: http://localhost:5000"
echo "📖 API 문서: http://localhost:5000"
echo ""
echo "종료하려면 Ctrl+C를 누르세요"
echo ""

python app.py
