# NVIDIA CUDA 베이스 이미지 (Windows GPU 지원)
FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME=/usr/local/cuda

# 작업 디렉토리 설정
WORKDIR /app

# Python 3.9 및 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    python3.9 \
    python3.9-dev \
    python3-pip \
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
    gcc \
    g++ \
    wget \
    curl \
    git \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Python 심볼릭 링크
RUN ln -sf /usr/bin/python3.9 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# NumPy 먼저 설치 (버전 고정)
RUN pip install --no-cache-dir "numpy<2.0"

# PyTorch 설치 (CUDA 11.3 버전)
RUN pip install --no-cache-dir torch==1.12.1+cu113 torchvision==0.13.1+cu113 \
    --extra-index-url https://download.pytorch.org/whl/cu113

# 나머지 Python 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir flask==2.3.3 flask-cors==4.0.0 \
    opencv-python==4.5.5.64 pillow==10.0.1 \
    requests==2.31.0 python-dotenv==1.0.0 \
    gunicorn==21.2.0 redis==4.6.0

# MMDetection 설치 (CUDA 지원)
# 1. OpenMIM 설치
RUN pip install --no-cache-dir -U openmim

# 2. MMCV-full 설치 (CUDA 11.3 버전)
RUN mim install mmcv-full==1.7.0 -f https://download.openmmlab.com/mmcv/dist/cu113/torch1.12.0/index.html

# 3. MMDetection 설치
RUN pip install --no-cache-dir mmdet==2.25.3

# 4. 설치 확인
RUN python -c "import torch; print('PyTorch:', torch.__version__); print('CUDA available:', torch.cuda.is_available())" && \
    python -c "import mmcv; print('MMCV:', mmcv.__version__)" && \
    python -c "import mmdet; print('MMDet:', mmdet.__version__)" && \
    python -c "from mmcv.ops import RoIPool; print('✅ MMCV ops available')"

# 애플리케이션 코드 복사
COPY app.py .
COPY start_server.sh .

RUN chmod +x start_server.sh

# 포트 노출
EXPOSE 5000

# 환경 변수 설정
ENV PYTHONPATH=/app
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV DOCKER_ENV=true

# 헬스체크 설정 (모델 로딩 시간 고려)
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# 서버 시작
CMD ["python", "app.py"]
