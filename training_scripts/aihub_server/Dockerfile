# AI-Hub 음식 분류 서버 Dockerfile
FROM python:3.9-slim

# 작업 디렉토리 설정
WORKDIR /app

# 시스템 패키지 업데이트 및 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libatlas-base-dev \
    python3-dev \
    gcc \
    g++ \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Python 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# PyTorch CPU 버전 설치 (GPU 버전은 필요시 별도 설치)
RUN pip install torch==1.12.1+cpu torchvision==0.13.1+cpu -f https://download.pytorch.org/whl/torch_stable.html

# MMDetection 설치
RUN pip install mmcv-full==1.7.1 -f https://download.openmmlab.com/mmcv/dist/cpu/torch1.12.0/index.html
RUN pip install mmdet==2.25.3

# 애플리케이션 코드 복사
COPY app.py .
COPY start_server.sh .

# 실행 권한 부여
RUN chmod +x start_server.sh

# 포트 노출
EXPOSE 5000

# 환경 변수 설정
ENV PYTHONPATH=/app
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# 헬스체크 추가
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# 서버 시작
CMD ["python", "app.py"]
