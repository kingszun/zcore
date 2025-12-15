# Node.js Dependencies for Visualizer

이 디렉토리는 OmniDrive Visualizer의 frontend node_modules를 Docker 이미지에 포함시키기 위한 설정을 담고 있습니다.

## 목적

node module을 설치할 수 없는 환경에서 visualizer를 실행하기 위해, Docker 빌드 시 미리 node_modules를 설치합니다.

## 파일 구조

- `package.json`: Frontend 의존성 정의
- `package-lock.json`: 의존성 버전 lock (자동 생성)

## 사용 방법

1. Dockerfile 빌드 시 자동으로 node_modules 설치
2. 설치된 node_modules는 `/opt/visualizer/frontend/node_modules`에 위치
3. 런타임에 별도 설치 없이 바로 사용 가능

## 업데이트 방법

Frontend의 package.json이 변경되면 다음 명령으로 동기화:

```bash
cp /path/to/visualizer/src/frontend/package.json /workspace/projects/vla/infra/docker/node/
```

그 후 Docker 이미지 재빌드:

```bash
docker build -f /workspace/projects/vla/infra/docker/dockerfile.omnidrive -t omnidrive-dev .
```
