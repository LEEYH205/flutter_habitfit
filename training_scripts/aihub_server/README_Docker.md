# 🐳 AI-Hub 음식 분류 서버 Docker 가이드

AI-Hub 음식 분류 서버를 Docker로 쉽게 배포하고 실행하는 가이드입니다.

## 🚀 빠른 시작

### 1. Docker 설치 확인
```bash
# Docker 설치 확인
docker --version
docker-compose --version
```

### 2. 서버 시작
```bash
# 자동 시작 스크립트 사용 (권장)
./docker-start.sh

# 또는 수동으로 시작
docker-compose up -d
```

### 3. 서버 상태 확인
```bash
# 헬스체크
curl http://localhost:5000/health

# 로그 확인
docker-compose logs -f
```

## 📁 Docker 파일 구조

```
aihub_server/
├── Dockerfile              # Docker 이미지 빌드 설정
├── docker-compose.yml      # 다중 컨테이너 오케스트레이션
├── nginx.conf              # Nginx 리버스 프록시 설정
├── .dockerignore           # Docker 빌드 시 제외 파일
├── docker-start.sh         # 자동 시작 스크립트
└── README_Docker.md        # 이 파일
```

## 🔧 Docker Compose 서비스

### 1. aihub-server (메인 서비스)
- **포트**: 5000
- **기능**: AI-Hub 모델 서빙
- **볼륨**: AI-Hub 모델 파일 마운트

### 2. redis (캐싱 서비스)
- **포트**: 6379
- **기능**: 결과 캐싱 (선택사항)

### 3. nginx (리버스 프록시)
- **포트**: 80
- **기능**: 로드 밸런싱, CORS 처리

## 📊 사용법

### 기본 명령어
```bash
# 서버 시작
docker-compose up -d

# 서버 중지
docker-compose down

# 서버 재시작
docker-compose restart

# 로그 확인
docker-compose logs -f

# 특정 서비스 로그만 확인
docker-compose logs -f aihub-server
```

### 이미지 관리
```bash
# 이미지 빌드
docker-compose build

# 이미지 강제 재빌드
docker-compose build --no-cache

# 이미지 삭제
docker-compose down --rmi all
```

### 볼륨 관리
```bash
# 볼륨 확인
docker volume ls

# 볼륨 삭제
docker-compose down -v
```

## 🌐 API 접근

### 직접 접근
- **API 서버**: http://localhost:5000
- **Nginx 프록시**: http://localhost:80

### API 테스트
```bash
# 헬스체크
curl http://localhost:5000/health

# 음식 분류
curl -X POST -F "image=@food_image.jpg" http://localhost:5000/predict

# 클래스 목록
curl http://localhost:5000/classes
```

## 🔧 설정 변경

### 포트 변경
`docker-compose.yml`에서 포트 매핑 수정:
```yaml
ports:
  - "8080:5000"  # 호스트:컨테이너
```

### 환경 변수 설정
```yaml
environment:
  - FLASK_ENV=development
  - CUDA_VISIBLE_DEVICES=0  # GPU 사용
```

### 볼륨 마운트 추가
```yaml
volumes:
  - ./custom_models:/app/models
  - ./config:/app/config
```

## 🐛 문제 해결

### 1. 포트 충돌
```bash
# 포트 사용 중인 프로세스 확인
lsof -i :5000

# 다른 포트 사용
docker-compose up -d --scale aihub-server=0
docker-compose up -d -p 8080:5000
```

### 2. 메모리 부족
```bash
# Docker 메모리 제한 설정
docker-compose up -d --memory=4g
```

### 3. 모델 파일 없음
```bash
# AI-Hub 모델 파일 경로 확인
ls -la ../aihub_food/

# 올바른 경로에 모델 파일 배치
```

### 4. 권한 문제
```bash
# 실행 권한 부여
chmod +x docker-start.sh
chmod +x start_server.sh
```

## 📈 성능 최적화

### 1. GPU 사용 (NVIDIA Docker)
```yaml
# docker-compose.yml에 추가
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

### 2. 멀티 스테이지 빌드
```dockerfile
# 더 작은 이미지 크기
FROM python:3.9-slim as builder
# ... 빌드 단계

FROM python:3.9-slim
# ... 최종 단계
```

### 3. 캐싱 최적화
```yaml
# Redis 캐싱 활성화
environment:
  - REDIS_URL=redis://redis:6379
  - ENABLE_CACHE=true
```

## 🔒 보안 설정

### 1. 네트워크 격리
```yaml
networks:
  aihub-network:
    driver: bridge
    internal: true  # 외부 접근 차단
```

### 2. 환경 변수 보안
```bash
# .env 파일 생성
echo "SECRET_KEY=your-secret-key" > .env
echo "API_KEY=your-api-key" >> .env
```

### 3. SSL/TLS 설정
```yaml
# nginx.conf에 SSL 설정 추가
server {
    listen 443 ssl;
    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;
}
```

## 📊 모니터링

### 1. 헬스체크
```bash
# 컨테이너 상태 확인
docker-compose ps

# 헬스체크 상태
docker inspect aihub-food-classifier | grep Health
```

### 2. 리소스 사용량
```bash
# CPU/메모리 사용량
docker stats

# 특정 컨테이너만
docker stats aihub-food-classifier
```

### 3. 로그 모니터링
```bash
# 실시간 로그
docker-compose logs -f --tail=100

# 에러 로그만
docker-compose logs --since=1h | grep ERROR
```

## 🚀 프로덕션 배포

### 1. 환경 분리
```bash
# 프로덕션 설정
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 2. 로드 밸런싱
```yaml
# docker-compose.prod.yml
services:
  aihub-server:
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

### 3. 백업 및 복구
```bash
# 볼륨 백업
docker run --rm -v aihub_logs:/data -v $(pwd):/backup alpine tar czf /backup/logs-backup.tar.gz -C /data .

# 복구
docker run --rm -v aihub_logs:/data -v $(pwd):/backup alpine tar xzf /backup/logs-backup.tar.gz -C /data
```

## 📝 유용한 명령어 모음

```bash
# 전체 시스템 정리
docker system prune -a

# 특정 이미지 삭제
docker rmi aihub-server_aihub-server

# 컨테이너 내부 접속
docker exec -it aihub-food-classifier bash

# 볼륨 확인
docker volume inspect aihub-server_logs

# 네트워크 확인
docker network ls
docker network inspect aihub-server_aihub-network
```
