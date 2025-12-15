#!/bin/bash

# 디버그 모드 활성화
set -x

# 포트 충돌 확인
if netstat -tulpn | grep -q ":8080"; then
    echo "Warning: Port 8080 is already in use. Checking what process is using it..."
    ps -ef | grep $(netstat -tulpn | grep ":8080" | awk '{print $7}' | cut -d'/' -f1)
    echo "Please stop the process using port 8080 before continuing."
    exit 1
fi

# 시스템 리소스 제한 증가
echo "Increasing system limits for better performance..."
ulimit -n 65535 || echo "Failed to increase file descriptor limit"
sysctl -w net.core.somaxconn=4096 || echo "Failed to increase socket connection limit"
sysctl -w net.ipv4.tcp_max_syn_backlog=4096 || echo "Failed to increase TCP backlog limit"


# 메인 Code Server 시작 (기본 인스턴스)
echo "Starting main code-server instance..."
/opt/code-server/bin/code-server --config /opt/code-server/config.yaml &
CODE_SERVER_PID=$!

# 종료 시그널 처리
function cleanup() {
    echo "Shutting down code-server..."
    kill $CODE_SERVER_PID
    exit 0
}

trap cleanup SIGTERM SIGINT

# Code Server 프로세스 모니터링
while true; do
    if ! kill -0 $CODE_SERVER_PID 2>/dev/null; then
        echo "Code Server process died, restarting..."
        /opt/code-server/bin/code-server --config /opt/code-server/config.yaml &
        CODE_SERVER_PID=$!
    fi
    sleep 10
done




