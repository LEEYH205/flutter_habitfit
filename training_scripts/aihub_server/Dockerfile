# AI-Hub 음식 분류 서버 Dockerfile
FROM python:3.9

# 작업 디렉토리 설정
WORKDIR /app

# 시스템 패키지 업데이트 및 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
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
    libopenblas-dev \
    python3-dev \
    gcc \
    g++ \
    wget \
    curl \
    git \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# PyTorch 설치 (최신 버전 사용 - ARM64 호환)
RUN pip install --no-cache-dir torch torchvision

# NumPy 먼저 설치 (버전 고정)
RUN pip install --no-cache-dir "numpy<2.0"

# 나머지 Python 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir flask==2.3.3 flask-cors==4.0.0 \
    opencv-python==4.5.5.64 pillow==10.0.1 \
    requests==2.31.0 python-dotenv==1.0.0 \
    gunicorn==21.2.0 redis==4.6.0

# MMDetection 설치 시도 (실패해도 계속 진행)
# MMCV-full을 소스에서 빌드 (C++ 확장 포함)
RUN pip install --no-cache-dir -U openmim || true
RUN MMCV_WITH_OPS=1 pip install --no-cache-dir "mmcv-full>=1.3.17,<=1.7.0" -f https://download.openmmlab.com/mmcv/dist/cpu/torch2.8.0/index.html || \
    pip install --no-cache-dir "mmcv>=1.3.17,<=1.7.0" || true
RUN pip install --no-cache-dir mmdet==2.25.3 || true

# PyTorch 설치 확인
RUN python -c "import torch; print('✅ PyTorch version:', torch.__version__)"

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
ENV DOCKER_ENV=true

# 헬스체크 추가
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# 서버 시작
CMD ["python", "app.py"]
