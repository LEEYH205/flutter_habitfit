# ☁️ GCP에서 AI-Hub 음식 분류 서버 배포 가이드

AI-Hub 음식 분류 서버를 Google Cloud Platform에서 운영하기 위한 완벽한 가이드입니다.

---

## 📊 **권장 서버 사양**

### 🎯 **옵션 1: CPU 전용 (저비용, 테스트/개발용)**

#### **Compute Engine 인스턴스**
- **머신 타입**: `e2-standard-4`
  - vCPU: 4개
  - RAM: 16GB
  - 디스크: 50GB SSD
- **예상 비용**: ~$120/월 (서울 리전)
- **추론 속도**: 이미지당 2-5초
- **동시 처리**: 1-2 요청

```bash
# GCP 인스턴스 생성
gcloud compute instances create aihub-food-server \
    --zone=asia-northeast3-a \
    --machine-type=e2-standard-4 \
    --boot-disk-size=50GB \
    --boot-disk-type=pd-ssd \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --tags=http-server,https-server
```

**권장 사용처:**
- ✅ 개발/테스트 환경
- ✅ 하루 1,000건 이하 요청
- ✅ 실시간 응답이 중요하지 않은 경우

---

### 🚀 **옵션 2: GPU 가속 (권장, 프로덕션)**

#### **Compute Engine 인스턴스 + GPU**
- **머신 타입**: `n1-standard-4` + `1 x NVIDIA T4`
  - vCPU: 4개
  - RAM: 15GB
  - GPU: NVIDIA T4 (16GB VRAM)
  - 디스크: 100GB SSD
- **예상 비용**: ~$450/월 (서울 리전)
- **추론 속도**: 이미지당 0.1-0.3초 ⚡
- **동시 처리**: 10-20 요청

```bash
# GCP GPU 인스턴스 생성
gcloud compute instances create aihub-food-server-gpu \
    --zone=asia-northeast3-a \
    --machine-type=n1-standard-4 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --maintenance-policy=TERMINATE \
    --boot-disk-size=100GB \
    --boot-disk-type=pd-ssd \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --metadata=install-nvidia-driver=True \
    --tags=http-server,https-server
```

**권장 사용처:**
- ✅ 프로덕션 환경
- ✅ 하루 10,000건 이상 요청
- ✅ 실시간 음식 분류 필요
- ✅ 앱 서비스 상용화

---

### 💎 **옵션 3: 고성능 GPU (대규모 트래픽)**

#### **Compute Engine 인스턴스 + 고성능 GPU**
- **머신 타입**: `n1-standard-8` + `1 x NVIDIA V100`
  - vCPU: 8개
  - RAM: 30GB
  - GPU: NVIDIA V100 (16GB HBM2)
  - 디스크: 200GB SSD
- **예상 비용**: ~$1,200/월 (서울 리전)
- **추론 속도**: 이미지당 0.05-0.1초 ⚡⚡⚡
- **동시 처리**: 50+ 요청

**권장 사용처:**
- ✅ 대규모 상용 서비스
- ✅ 하루 100,000건 이상 요청
- ✅ 멀티 모델 동시 운영

---

## 🔧 **모델 사양 분석**

### 📦 **AI-Hub 모델 파일 크기**
```
음식 탐지/분류 모델: 536MB (학습모델파일.pth)
중량 예측 모델: ~50MB (예상)
총 용량: ~600MB
```

### 💾 **메모리 요구사항**

#### **모델 로딩 시**
- **모델 파일**: 600MB
- **MMDetection 프레임워크**: 500MB
- **PyTorch 런타임**: 1GB
- **운영체제 + 버퍼**: 2GB
- **총 최소 요구량**: **4GB RAM**

#### **추론 실행 시 (GPU)**
- **GPU VRAM**: 2-3GB
- **시스템 RAM**: 추가 2GB
- **안전 여유분**: 2GB
- **총 권장량**: **8GB+ RAM, 4GB+ VRAM**

---

## 🚀 **GCP 배포 단계별 가이드**

### **1단계: GCP 프로젝트 설정**

```bash
# GCP CLI 설치 및 인증
gcloud init
gcloud auth login

# 프로젝트 생성
gcloud projects create habitfit-ai-server --name="HabitFit AI Server"
gcloud config set project habitfit-ai-server

# 필요한 API 활성화
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
```

---

### **2단계: 방화벽 규칙 설정**

```bash
# HTTP/HTTPS 트래픽 허용
gcloud compute firewall-rules create allow-http \
    --allow=tcp:80,tcp:443,tcp:5001 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server

# SSH 접근 허용
gcloud compute firewall-rules create allow-ssh \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0
```

---

### **3단계: VM 인스턴스 생성 (GPU 버전 권장)**

```bash
# GPU 인스턴스 생성
gcloud compute instances create aihub-food-server \
    --zone=asia-northeast3-a \
    --machine-type=n1-standard-4 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --maintenance-policy=TERMINATE \
    --boot-disk-size=100GB \
    --boot-disk-type=pd-ssd \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --metadata=install-nvidia-driver=True \
    --tags=http-server,https-server
```

---

### **4단계: 서버 초기 설정**

```bash
# SSH 접속
gcloud compute ssh aihub-food-server --zone=asia-northeast3-a

# Docker 설치
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Docker 권한 설정
sudo usermod -aG docker $USER
newgrp docker
```

---

### **5단계: NVIDIA Container Toolkit 설치 (GPU 전용)**

```bash
# NVIDIA 드라이버 확인
nvidia-smi

# NVIDIA Container Toolkit 설치
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

# GPU 테스트
docker run --rm --gpus all nvidia/cuda:11.3.1-base-ubuntu20.04 nvidia-smi
```

---

### **6단계: 프로젝트 배포**

```bash
# Git 설치
sudo apt-get install -y git

# 프로젝트 클론
git clone https://github.com/LEEYH205/flutter_habitfit.git
cd flutter_habitfit/training_scripts/aihub_server

# AI-Hub 모델 파일 업로드 (로컬에서 GCP로)
# 방법 1: gcloud SCP
gcloud compute scp --recurse \
    ../aihub_food \
    aihub-food-server:~/flutter_habitfit/training_scripts/ \
    --zone=asia-northeast3-a

# 방법 2: Google Cloud Storage 사용 (권장)
# 로컬에서 실행:
gsutil mb gs://habitfit-ai-models
gsutil -m cp -r ../aihub_food gs://habitfit-ai-models/

# GCP VM에서 실행:
gsutil -m cp -r gs://habitfit-ai-models/aihub_food ../
```

---

### **7단계: Docker 서버 실행**

```bash
# Docker Compose로 서버 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f aihub-server

# 서버 상태 확인
curl http://localhost:5001/health
```

---

### **8단계: 외부 IP 확인 및 테스트**

```bash
# 외부 IP 확인
gcloud compute instances describe aihub-food-server \
    --zone=asia-northeast3-a \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# 예시: 34.64.123.45

# 외부에서 서버 테스트
curl http://34.64.123.45:5001/health

# Flutter 앱에서 사용할 URL
# http://34.64.123.45:5001
```

---

## 🔐 **보안 설정 (필수)**

### **1. 고정 IP 할당**

```bash
# 고정 IP 예약
gcloud compute addresses create aihub-server-ip --region=asia-northeast3

# 인스턴스에 고정 IP 할당
gcloud compute instances add-access-config aihub-food-server \
    --access-config-name="External NAT" \
    --address=aihub-server-ip \
    --zone=asia-northeast3-a
```

### **2. HTTPS 설정 (Let's Encrypt)**

```bash
# Nginx 설치
sudo apt-get install -y nginx certbot python3-certbot-nginx

# 도메인 설정 (예: api.habitfit.com)
sudo nano /etc/nginx/sites-available/aihub-server

# 내용:
server {
    listen 80;
    server_name api.habitfit.com;

    location / {
        proxy_pass http://localhost:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Nginx 활성화
sudo ln -s /etc/nginx/sites-available/aihub-server /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# SSL 인증서 발급
sudo certbot --nginx -d api.habitfit.com
```

### **3. API 키 인증 (선택사항)**

`app.py`에 인증 미들웨어 추가:

```python
from functools import wraps
from flask import request, jsonify

API_KEY = "your-secret-api-key-here"

def require_api_key(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if request.headers.get('X-API-Key') != API_KEY:
            return jsonify({'error': 'Invalid API key'}), 401
        return f(*args, **kwargs)
    return decorated_function

@app.route('/predict', methods=['POST'])
@require_api_key
def predict():
    # 기존 코드...
```

---

## 📊 **모니터링 및 최적화**

### **Cloud Monitoring 설정**

```bash
# Stackdriver 에이전트 설치
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# 메트릭 확인
gcloud monitoring dashboards create --config-from-file=dashboard.json
```

### **자동 확장 (Auto-scaling)**

```bash
# 관리형 인스턴스 그룹 생성
gcloud compute instance-templates create aihub-template \
    --machine-type=n1-standard-4 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --image-family=ubuntu-2004-lts

gcloud compute instance-groups managed create aihub-group \
    --base-instance-name=aihub-server \
    --template=aihub-template \
    --size=1 \
    --zone=asia-northeast3-a

# Auto-scaling 정책 설정
gcloud compute instance-groups managed set-autoscaling aihub-group \
    --max-num-replicas=5 \
    --min-num-replicas=1 \
    --target-cpu-utilization=0.75 \
    --zone=asia-northeast3-a
```

---

## 💰 **비용 최적화 팁**

### **1. 프리미엄 스토리지 사용 제한**
```bash
# 모델 파일은 Standard Storage에 저장
gsutil mb -c STANDARD -l asia-northeast3 gs://habitfit-models
```

### **2. Preemptible VM 사용 (개발/테스트)**
```bash
# 최대 80% 저렴 (최대 24시간 실행)
gcloud compute instances create aihub-test \
    --preemptible \
    --machine-type=n1-standard-4 \
    --zone=asia-northeast3-a
```

### **3. 스케줄 기반 시작/종료**
```bash
# Cloud Scheduler로 야간 자동 종료
gcloud scheduler jobs create http stop-server \
    --schedule="0 0 * * *" \
    --uri="https://compute.googleapis.com/compute/v1/projects/PROJECT/zones/ZONE/instances/INSTANCE/stop" \
    --http-method=POST
```

---

## 📈 **성능 벤치마크**

| 사양 | 추론 속도 | 동시 요청 | 월 비용 | 권장 용도 |
|------|----------|---------|---------|----------|
| **e2-standard-4 (CPU)** | 2-5초 | 1-2 | $120 | 개발/테스트 |
| **n1-standard-4 + T4** | 0.1-0.3초 | 10-20 | $450 | 프로덕션 |
| **n1-standard-8 + V100** | 0.05-0.1초 | 50+ | $1,200 | 대규모 서비스 |

---

## 🎯 **Flutter 앱 연동**

GCP 서버 배포 후 Flutter 앱 설정:

```dart
// lib/services/meal_ai_service.dart
class MealAIService {
  // GCP 서버 URL (고정 IP 또는 도메인)
  static const String _aihubServerUrl = 'https://api.habitfit.com';
  // 또는 IP 직접 사용: 'http://34.64.123.45:5001'
  
  static const bool _useAihubServer = true;
  
  // API 키 인증 (선택사항)
  static const String _apiKey = 'your-api-key-here';
  
  Future<List<FoodPrediction>> classifyFood(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_aihubServerUrl/predict'),
    );
    
    // API 키 헤더 추가
    request.headers['X-API-Key'] = _apiKey;
    
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
    ));
    
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final result = json.decode(responseData);
    
    return (result['predictions'] as List)
        .map((p) => FoodPrediction.fromJson(p))
        .toList();
  }
}
```

---

## 🚨 **트러블슈팅**

### **문제 1: GPU가 인식되지 않음**
```bash
# NVIDIA 드라이버 재설치
sudo apt-get purge nvidia-*
sudo apt-get install -y nvidia-driver-470
sudo reboot

# 재확인
nvidia-smi
```

### **문제 2: 메모리 부족 오류**
```bash
# Swap 메모리 추가
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 영구 설정
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### **문제 3: Docker 컨테이너 재시작 반복**
```bash
# 로그 확인
docker-compose logs -f aihub-server

# 메모리 할당 증가
# docker-compose.yml 수정:
deploy:
  resources:
    limits:
      memory: 8G
```

---

## 📞 **지원 및 문의**

- **GCP 문서**: https://cloud.google.com/compute/docs
- **프로젝트 이슈**: https://github.com/LEEYH205/flutter_habitfit/issues

---

## ✅ **배포 체크리스트**

- [ ] GCP 프로젝트 생성
- [ ] VM 인스턴스 생성 (GPU 포함)
- [ ] 방화벽 규칙 설정
- [ ] Docker 및 Docker Compose 설치
- [ ] NVIDIA 드라이버 및 Container Toolkit 설치 (GPU)
- [ ] AI-Hub 모델 파일 업로드
- [ ] Docker 서버 실행 및 테스트
- [ ] 고정 IP 할당
- [ ] HTTPS/SSL 인증서 설정
- [ ] Flutter 앱 서버 URL 업데이트
- [ ] API 키 인증 설정 (선택)
- [ ] 모니터링 및 알림 설정

---

**🎉 이제 GCP에서 AI-Hub 음식 분류 서버가 프로덕션 환경에서 안정적으로 운영됩니다!**

