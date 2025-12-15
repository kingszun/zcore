# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# ===================================================
# 출력 형식 (Output Format)
# ===================================================

절대 사용 금지:
- 이모지 전면 금지
- 볼드 형식 금지 (markdown ** 사용 금지)


# ===================================================
# Language Configuration
# ===================================================

Primary Language: Korean (한국어)
Context: Korean developer working with international codebases

Communication Style:
- Communication using Korean
- Use Korean for explanations, descriptions, and discussions
- Use English naturally for technical terms, code, commands, and file paths where appropriate
- Code comments, variable names, function names: Keep in English (standard practice)
- Natural code-switching is encouraged when English terms are more precise or commonly used
- Example: "이 함수는 async/await 패턴을 사용해서 API call을 처리합니다"

## 프로젝트 개요

ZCore (Zero-Shot Coreset Selection)는 라벨이나 학습 없이 데이터 subset을 선택하는 연구 구현체입니다. Foundation model embedding을 사용하여 embedding 분포 내 coverage와 redundancy를 기반으로 각 샘플의 중요도를 측정합니다.

## 명령어

### Zero-Shot Coreset Selection
```bash
python zeroshot_coreset_selection.py --dataset eurosat10 --data_dir ./data --results_dir ./results --embedding clip resnet18 --num_workers 10
```

### Coreset 모델 학습
```bash
python train_coreset_model.py --prune_rate 0.7 --dataset eurosat10 --data_dir ./data --score_file ./results/eurosat10/zcore-eurosat10-clip-resnet18-1000Ks-2sd-ri-1000nn-4ex-0/score.npy
```

### 반복 실험 결과 처리
```bash
python process_repeat_trials.py --base_score_dir ./results/example/eurosat10/zcore-eurosat10-clip-resnet18-1000Ks-2sd-ri-1000nn-4ex
```

### FiftyOne으로 이미지 폴더 시각화
```bash
python visualize_image_folder.py --image_dir ./path/to/images --embedding clip
```

## 아키텍처

### Entry Points
- `zeroshot_coreset_selection.py` - ZCore 중요도 score 생성, `score.npy`로 저장
- `train_coreset_model.py` - score 기반으로 pruning된 coreset으로 모델 학습
- `process_repeat_trials.py` - 여러 trial 실험 결과 집계
- `visualize_image_folder.py` / `visualize_model_certainty.py` - FiftyOne 기반 시각화

### Core Modules

`core/coreset/`:
- `zcore.py` - 병렬 subspace sampling으로 coverage/redundancy scoring하는 ZCore 알고리즘
- `model_embed.py` - FiftyOne 기반 embedding 생성 (CLIP ViT-L-14, ResNet18, DINOv2)
- `utils.py` - 실험 naming 규칙, 결과 수집, 로깅 유틸리티

`core/train/`:
- `train.py` - SGD optimizer와 cosine annealing scheduler를 사용하는 학습 루프
- `pruned_dataset.py` - CIFAR, ImageNet, EuroSAT용 score 기반 pruning 데이터셋 로딩
- `model.py`, `resnet.py` - ResNet 모델 구현

### 데이터 흐름
1. FiftyOne 모델로 embedding 생성 (`data_dir/preprocess/dataset/`에 캐시)
2. ZCore가 iterative subspace sampling으로 각 샘플 scoring
3. Score를 numpy array로 results 디렉토리에 저장
4. 학습 시 score 로드, top-k 샘플만 남기고 pruning, classifier 학습

## 지원 설정

Datasets: `cifar10`, `cifar100`, `imagenet`, `eurosat10`, `eurosat20`, `eurosat40`, `eurosat80`

Embeddings: `clip` (ViT-L-14), `resnet18`, `dinov2` - 여러 개 조합 가능 (concatenate)

ZCore Parameters:
- `--n_sample`: subspace sample 수 (default: 1M)
- `--sample_dim`: subspace 차원 (default: 2)
- `--rand_init`: coverage score random 초기화 여부
- `--redund_nn`: redundancy용 neighbor 수 (default: 1000)
- `--redund_exp`: distance penalty 지수 (default: 4)

## Dependencies

주요: `fiftyone`, `torch`, `torchvision`, `numpy`

embedding 생성에 FiftyOne 필요 (`pip install fiftyone`).
