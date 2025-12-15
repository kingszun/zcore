# Visualizer Node Module 사용 가이드

## 개요

이 설정은 node module을 설치할 수 없는 환경에서 visualizer를 실행하기 위한 것입니다.
Docker 이미지 빌드 시 node_modules를 미리 설치하여 런타임에 npm install 없이 바로 사용할 수 있습니다.

## 빌드 방법

### 1. Docker 이미지 빌드

```bash
cd /workspace/projects/vla

# x86 아키텍처로 빌드 (M2 Mac에서도 가능)
docker buildx build \
  --platform linux/amd64 \
  -f infra/docker/dockerfile.omnidrive \
  -t omnidrive-dev:latest \
  .
```

### 2. 빌드 확인

```bash
# 이미지 확인
docker images | grep omnidrive-dev

# Node.js 버전 확인
docker run --rm omnidrive-dev:latest node --version
docker run --rm omnidrive-dev:latest npm --version
```

## 실행 방법

### 1. Docker 컨테이너 시작

```bash
docker run -it --rm \
  --gpus all \
  -p 8888:8888 \
  -p 6006:6006 \
  -p 5000:5000 \
  -p 9003:9003 \
  -p 8000:8000 \
  -v /path/to/your/project:/workspace \
  omnidrive-dev:latest \
  bash
```

### 2. Visualizer 시작

컨테이너 내부에서:

```bash
# 방법 1: 자동 startup script 사용 (권장)
visualizer-start.sh /workspace/projects/github/omnidrive/projects/omnidrive_uavla

# 방법 2: 수동 실행
# Backend 시작
cd /workspace/projects/github/omnidrive/projects/omnidrive_uavla/visualizer/src
python -m uvicorn backend.app:app --host 0.0.0.0 --port 8000 --reload &

# Node modules 연결
cd frontend
ln -sf /opt/visualizer/frontend/node_modules ./node_modules

# Frontend 시작
npm run dev -- --host 0.0.0.0 --port 9003
```

### 3. 접속

브라우저에서:
- Frontend: http://localhost:9003
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## 구조

```
Docker Image
├── /opt/visualizer/frontend/
│   ├── package.json
│   └── node_modules/          # 미리 설치된 node modules
│
└── /workspace/                 # 마운트된 프로젝트
    └── projects/
        └── github/omnidrive/projects/omnidrive_uavla/
            └── visualizer/
                └── src/
                    ├── backend/
                    └── frontend/
                        └── node_modules -> /opt/visualizer/frontend/node_modules (symlink)
```

## 작동 원리

1. Docker 빌드 시:
   - Node.js LTS 설치
   - package.json을 /opt/visualizer/frontend/로 복사
   - npm install 실행하여 node_modules 생성

2. 런타임 시:
   - visualizer-start.sh가 symbolic link 생성
   - 프로젝트의 frontend/node_modules → /opt/visualizer/frontend/node_modules
   - npm install 없이 바로 npm run dev 실행 가능

## 장점

1. 빠른 시작: npm install 시간 절약 (약 2-5분)
2. 네트워크 불필요: npm registry 접근 불필요
3. 일관성: 모든 환경에서 동일한 node_modules 사용
4. 캐싱: Docker layer cache로 재빌드 시간 단축

## 업데이트 방법

package.json이 변경되면:

```bash
# 1. package.json 복사
cp /path/to/visualizer/src/frontend/package.json /workspace/projects/vla/infra/docker/node/

# 2. Docker 이미지 재빌드
cd /workspace/projects/vla
docker buildx build \
  --platform linux/amd64 \
  -f infra/docker/dockerfile.omnidrive \
  -t omnidrive-dev:latest \
  --no-cache \
  .
```

## 트러블슈팅

### node_modules 링크 실패

```bash
# 수동으로 링크 생성
cd /workspace/projects/github/omnidrive/projects/omnidrive_uavla/visualizer/src/frontend
rm -rf node_modules
ln -sf /opt/visualizer/frontend/node_modules ./node_modules
```

### npm 명령어 실패

```bash
# Node.js 환경 확인
which node
node --version
npm --version

# 환경변수 확인
echo $VISUALIZER_FRONTEND_PATH
```

### 포트 충돌

```bash
# 포트 사용 확인
netstat -tuln | grep 9003
netstat -tuln | grep 8000

# 프로세스 종료
kill <PID>
```

## 참고사항

- Node.js 버전: LTS (v20.x)
- npm 버전: Node.js LTS에 포함된 버전
- 설치 위치: /opt/visualizer/frontend/node_modules
- 환경변수:
  - VISUALIZER_PORT=9003
  - VISUALIZER_FRONTEND_PATH=/opt/visualizer/frontend
