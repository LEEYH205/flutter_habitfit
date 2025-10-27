#!/bin/bash

echo "🚀 AI-Hub 서버 (간단 버전) 시작 중..."

# 기존 컨테이너 정리
echo "🧹 기존 컨테이너 정리 중..."
docker-compose -f docker-compose.simple.yml down

# Docker 이미지 빌드
echo "🔨 Docker 이미지 빌드 중..."
docker-compose -f docker-compose.simple.yml build

# 컨테이너 시작
echo "▶️ 컨테이너 시작 중..."
docker-compose -f docker-compose.simple.yml up -d

# 서버 상태 확인
echo "⏳ 서버 시작 대기 중..."
sleep 10

echo "🔍 서버 상태 확인 중..."
curl -f http://localhost:5001/health || echo "❌ 서버가 아직 시작되지 않았습니다."

echo ""
echo "✅ AI-Hub 서버 (간단 버전) 시작 완료!"
echo "🌐 서버 URL: http://localhost:5001"
echo "📊 헬스체크: http://localhost:5001/health"
echo "📝 API 문서: http://localhost:5001/"
echo ""
echo "📋 유용한 명령어:"
echo "  - 로그 확인: docker-compose -f docker-compose.simple.yml logs -f"
echo "  - 서버 중지: docker-compose -f docker-compose.simple.yml down"
echo "  - 컨테이너 상태: docker-compose -f docker-compose.simple.yml ps"

