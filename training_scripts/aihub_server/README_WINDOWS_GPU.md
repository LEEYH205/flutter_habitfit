# Windows PC + NVIDIA GPU 설정 가이드

## 🎮 **시스템 요구사항**

### 필수 조건
- ✅ **NVIDIA GPU** (CUDA 지원)
- ✅ **Windows 10/11** (64-bit)
- ✅ **16GB RAM** 이상 권장
- ✅ **10GB 여유 디스크 공간**

### 소프트웨어 요구사항
1. **NVIDIA GPU 드라이버** (최신 버전)
2. **Docker Desktop for Windows**
3. **NVIDIA Container Toolkit**

---

## 📋 **설치 단계**

### 1. NVIDIA GPU 드라이버 설치

1. NVIDIA 공식 사이트에서 최신 드라이버 다운로드:
   - https://www.nvidia.com/Download/index.aspx
2. 설치 후 재부팅
3. 확인:
   ```cmd
   nvidia-smi
   ```

### 2. Docker Desktop 설치

1. Docker Desktop 다운로드:
   - https://www.docker.com/products/docker-desktop/
2. 설치 옵션:
   - ✅ **WSL 2 사용** (권장)
   - ✅ **Hyper-V 활성화**
3. 설치 후 재부팅

### 3. WSL 2 설정 (Docker Desktop 사용 시)

PowerShell (관리자 권한):
```powershell
# WSL 2 활성화
wsl --install

# Ubuntu 설치
wsl --install -d Ubuntu

# 기본 버전을 WSL 2로 설정
wsl --set-default-version 2
```

### 4. NVIDIA Container Toolkit 설치

WSL 2 Ubuntu 터미널에서:
```bash
# Docker GPG 키 추가
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# NVIDIA Container Toolkit 설치
sudo apt-get update
sudo apt-get install -y nvidia-docker2

# Docker 재시작
sudo systemctl restart docker
```

### 5. GPU 지원 확인

```bash
# Docker에서 GPU 테스트
docker run --rm --gpus all nvidia/cuda:11.3.1-base-ubuntu20.04 nvidia-smi
```

성공하면 GPU 정보가 출력됩니다!

---

## 🚀 **AI-Hub 서버 실행**

### 1. 프로젝트 디렉토리로 이동

```bash
cd training_scripts/aihub_server
```

### 2. Docker 이미지 빌드 (첫 실행 시)

```bash
docker-compose build
```

⏱️ **예상 시간**: 10-15분 (CUDA 라이브러리 다운로드 포함)

### 3. 서버 시작

```bash
docker-compose up -d
```

### 4. 로그 확인

```bash
docker-compose logs -f aihub-server
```

다음 메시지가 나올 때까지 대기 (약 2-3분):
```
✅ 음식 탐지 및 분류 모델 로딩 완료
✅ 모든 모델 로딩 완료
🚀 서버 시작: http://localhost:5000
```

### 5. 서버 상태 확인

```bash
curl http://localhost:5001/health
```

응답:
```json
{
  "models_loaded": true,
  "status": "healthy",
  "timestamp": "2025-10-24T..."
}
```

---

## 🧪 **테스트**

### 웹 브라우저 테스트
```
http://localhost:5001
```
또는 `test_web.html` 파일을 브라우저에서 열기

### cURL 테스트

```bash
# 서버 상태
curl http://localhost:5001/health

# 클래스 목록
curl http://localhost:5001/classes

# 음식 분류 (이미지 파일 필요)
curl -X POST http://localhost:5001/predict -F "image=@food.jpg"
```

---

## 🔧 **문제 해결**

### GPU가 인식되지 않을 때

1. **NVIDIA 드라이버 확인**:
   ```cmd
   nvidia-smi
   ```

2. **Docker GPU 지원 확인**:
   ```bash
   docker run --rm --gpus all nvidia/cuda:11.3.1-base-ubuntu20.04 nvidia-smi
   ```

3. **Docker Desktop 설정**:
   - Settings → Resources → WSL Integration
   - Ubuntu 활성화 확인

### 메모리 부족 오류

`docker-compose.yml` 수정:
```yaml
deploy:
  resources:
    limits:
      memory: 8G
    reservations:
      memory: 4G
```

### 모델 로딩 타임아웃

`app.py`의 Gunicorn timeout 증가:
```python
sys.argv = ['gunicorn', '--bind', '0.0.0.0:5000', '--workers', '1', '--timeout', '900', '--preload', 'app:app']
```

---

## ⚡ **성능 최적화**

### GPU 메모리 최적화

`app.py`에 추가:
```python
import torch
torch.cuda.empty_cache()  # 추론 후 메모리 정리
```

### 배치 처리

여러 이미지를 동시에 처리하려면 `app.py`의 `predict_food` 함수 수정

### Worker 수 조정

GPU가 여러 개라면 `app.py`:
```python
sys.argv = ['gunicorn', '--bind', '0.0.0.0:5000', '--workers', '2', '--timeout', '600', '--preload', 'app:app']
```

---

## 📊 **성능 벤치마크**

### 예상 성능 (NVIDIA RTX 3060 기준)

- **모델 로딩 시간**: 약 30초
- **추론 시간**: 
  - 이미지당 약 100-200ms (GPU)
  - 이미지당 약 2-3초 (CPU)
- **메모리 사용량**:
  - GPU VRAM: 약 3-4GB
  - RAM: 약 4-6GB

---

## 🎯 **Flutter 앱 연동**

### Android 에뮬레이터

`lib/services/meal_ai_service.dart`:
```dart
static const String _aihubServerUrl = 'http://10.0.2.2:5001';
```

### 실제 Android 기기

Windows PC의 IP 주소 확인:
```cmd
ipconfig
```

Flutter 앱:
```dart
static const String _aihubServerUrl = 'http://192.168.x.x:5001';
```

### iOS 시뮬레이터 (Mac에서만)

```dart
static const String _aihubServerUrl = 'http://localhost:5001';
```

---

## 🛑 **서버 중지**

```bash
docker-compose down
```

---

## 📝 **주요 명령어 요약**

```bash
# 서버 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f aihub-server

# 서버 재시작
docker-compose restart aihub-server

# 서버 중지
docker-compose down

# 이미지 재빌드
docker-compose build --no-cache

# GPU 상태 확인
nvidia-smi

# Docker GPU 테스트
docker run --rm --gpus all nvidia/cuda:11.3.1-base-ubuntu20.04 nvidia-smi
```

---

## ✅ **체크리스트**

설치 전:
- [ ] NVIDIA GPU 드라이버 설치
- [ ] Docker Desktop 설치
- [ ] WSL 2 설정
- [ ] NVIDIA Container Toolkit 설치
- [ ] GPU 인식 확인 (`nvidia-smi`)

서버 실행:
- [ ] `docker-compose build` 성공
- [ ] `docker-compose up -d` 성공
- [ ] 로그에서 "모델 로딩 완료" 확인
- [ ] `curl http://localhost:5001/health` 응답 확인
- [ ] 웹 테스트 페이지에서 이미지 업로드 테스트

---

## 🆘 **지원**

문제가 발생하면:
1. 로그 확인: `docker-compose logs aihub-server`
2. GPU 상태 확인: `nvidia-smi`
3. Docker 상태 확인: `docker ps`
4. 이슈 리포트: GitHub Issues

---

## 🎉 **성공 확인**

서버가 정상 작동하면:
```
✅ PyTorch: 1.12.1+cu113
✅ CUDA available: True
✅ MMCV ops available
✅ 음식 탐지 및 분류 모델 로딩 완료
✅ 800개 클래스 로딩 완료
🚀 서버 시작: http://localhost:5000
```

**축하합니다! Windows PC에서 AI-Hub 800개 한국 음식 분류 모델이 GPU로 실행 중입니다!** 🎊

