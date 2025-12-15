#!/bin/bash
# EuroSAT10 데이터셋 다운로드 및 설정 스크립트
#
# Dropbox 폴더에는 eurosat10.zip, eurosat20.zip, eurosat40.zip, eurosat80.zip이 포함됨
# 이 스크립트는 eurosat10.zip만 추출하여 설정

set -e

# 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RAW_DATA_DIR="/workspace/data/datasets/raw"
EUROSAT_DIR="$RAW_DATA_DIR/eurosat10"

echo "=== EuroSAT10 데이터셋 설정 ==="
echo "Project: $PROJECT_DIR"
echo "Raw data: $RAW_DATA_DIR"

# 1. raw 디렉토리 생성
mkdir -p "$RAW_DATA_DIR"

# 2. 이미 존재하는지 확인
if [ -d "$EUROSAT_DIR" ]; then
    echo "eurosat10 디렉토리가 이미 존재합니다: $EUROSAT_DIR"
else
    echo "Dropbox에서 EuroSAT 데이터셋 다운로드 중..."

    # Dropbox 폴더 직접 다운로드 링크 (dl=1)
    # 폴더 전체를 zip으로 다운로드하면 내부에 개별 zip 파일들이 포함됨
    DROPBOX_URL="https://www.dropbox.com/scl/fo/1mhwsunssr6g2v1wio0vq/AEI2cx3aZ2vWvFmSLDfUHtQ?rlkey=kbxo4uae43tnzvk6k7x5hk28u&st=8tkh3oyl&dl=1"
    FOLDER_ZIP="$RAW_DATA_DIR/eurosat_folder.zip"

    # 다운로드
    wget -O "$FOLDER_ZIP" "$DROPBOX_URL" || curl -L -o "$FOLDER_ZIP" "$DROPBOX_URL"

    # Dropbox 폴더 zip에서 eurosat10.zip 추출
    echo "eurosat10.zip 추출 중..."
    unzip -o "$FOLDER_ZIP" eurosat10.zip -d "$RAW_DATA_DIR"

    # eurosat10.zip 압축 해제
    echo "eurosat10 데이터셋 압축 해제 중..."
    unzip -o "$RAW_DATA_DIR/eurosat10.zip" -d "$RAW_DATA_DIR"

    # 정리
    rm -rf "$RAW_DATA_DIR/__MACOSX"
    rm -f "$FOLDER_ZIP"
    rm -f "$RAW_DATA_DIR/eurosat10.zip"

    echo "다운로드 완료: $EUROSAT_DIR"
fi

# 3. 심볼릭 링크 생성
DATA_LINK="$PROJECT_DIR/data"

if [ -L "$DATA_LINK" ]; then
    echo "심볼릭 링크가 이미 존재합니다: $DATA_LINK"
elif [ -d "$DATA_LINK" ]; then
    echo "경고: $DATA_LINK 가 디렉토리입니다. 수동으로 확인하세요."
    exit 1
else
    echo "심볼릭 링크 생성: $DATA_LINK -> $RAW_DATA_DIR"
    ln -s "$RAW_DATA_DIR" "$DATA_LINK"
fi

# 4. 확인
echo ""
echo "=== 설정 완료 ==="
echo "데이터 위치: $EUROSAT_DIR"
echo "심볼릭 링크: $(readlink -f "$DATA_LINK")"
echo ""
echo "데이터셋 구조:"
ls -la "$EUROSAT_DIR"
