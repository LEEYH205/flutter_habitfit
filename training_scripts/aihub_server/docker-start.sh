#!/bin/bash

# AI-Hub 서버 Docker 시작 스크립트

echo "🐳 AI-Hub 음식 분류 서버 Docker 시작"
echo "=================================="

# AI-Hub 모델 파일 존재 확인
AIHUB_PATH="../aihub_food"
if [ ! -d "$AIHUB_PATH" ]; then
    echo "❌ AI-Hub 모델 파일이 없습니다: $AIHUB_PATH"
    echo "💡 AI-Hub 데이터셋을 다운로드하고 올바른 경로에 배치해주세요."
    exit 1
fi

echo "✅ AI-Hub 모델 파일 확인됨: $AIHUB_PATH"

# Docker 및 Docker Compose 설치 확인
if ! command -v docker &> /dev/null; then
    echo "❌ Docker가 설치되지 않았습니다."
    echo "💡 Docker를 설치해주세요: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose가 설치되지 않았습니다."
    echo "💡 Docker Compose를 설치해주세요: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker 및 Docker Compose 확인됨"

# 로그 디렉토리 생성
mkdir -p logs

# Docker 이미지 빌드
echo "🔨 Docker 이미지 빌드 중..."
docker-compose build

if [ $? -ne 0 ]; then
    echo "❌ Docker 이미지 빌드 실패"
    exit 1
fi

echo "✅ Docker 이미지 빌드 완료"

# 컨테이너 시작
echo "🚀 컨테이너 시작 중..."
docker-compose up -d

if [ $? -ne 0 ]; then
    echo "❌ 컨테이너 시작 실패"
    exit 1
fi

echo "✅ 컨테이너 시작 완료"

# 서버 상태 확인
echo "🔍 서버 상태 확인 중..."
sleep 10

# 헬스체크
for i in {1..30}; do
    if curl -f http://localhost:5000/health &> /dev/null; then
        echo "✅ 서버가 정상적으로 실행 중입니다!"
        echo ""
        echo "🌐 서버 주소:"
        echo "   - API 서버: http://localhost:5000"
        echo "   - Nginx 프록시: http://localhost:80"
        echo ""
        echo "📖 API 문서: http://localhost:5000"
        echo "🔍 헬스체크: http://localhost:5000/health"
        echo ""
        echo "📋 유용한 명령어:"
        echo "   - 로그 확인: docker-compose logs -f"
        echo "   - 컨테이너 중지: docker-compose down"
        echo "   - 컨테이너 재시작: docker-compose restart"
        echo ""
        break
    else
        echo "⏳ 서버 시작 대기 중... ($i/30)"
        sleep 2
    fi
done

if [ $i -eq 30 ]; then
    echo "❌ 서버 시작 시간 초과"
    echo "📋 로그 확인: docker-compose logs"
    exit 1
fi
