#!/bin/bash
set -e

MODELS_BASE="$(pwd)/data/models"
DATASETS_BASE="$(pwd)/data/datasets"

if [ ! -d "$MODELS_BASE" ]; then
  echo "Models directory not found: $MODELS_BASE"
  exit 1
fi

declare -a model_dirs
declare -a model_names
while IFS= read -r -d $'\0' dir; do
  model_dirs+=("$dir")
  model_names+=("$(basename "$dir")")
done < <(find "$MODELS_BASE" -maxdepth 1 -mindepth 1 -type d -print0)

if [ ${#model_dirs[@]} -eq 0 ]; then
  echo "No models found in $MODELS_BASE"
  exit 1
fi

echo "Select a model:"
select model in "${model_names[@]}"; do
  index=$((REPLY - 1))
  if [[ -n "${model_names[index]}" ]]; then
    echo "Selected model: ${model_names[index]}"
    MODEL_CHOICE="${model_dirs[index]}"
    break
  else
    echo "Invalid selection. Please try again."
  fi
done

if [ ! -d "$DATASETS_BASE" ]; then
  echo "Datasets directory not found: $DATASETS_BASE"
  exit 1
fi

declare -a dataset_dirs
declare -a dataset_names
while IFS= read -r -d $'\0' dir; do
  dataset_dirs+=("$dir")
  dataset_names+=("$(basename "$dir")")
done < <(find "$DATASETS_BASE" -maxdepth 1 -mindepth 1 -type d -print0)

if [ ${#dataset_dirs[@]} -eq 0 ]; then
  echo "No datasets found in $DATASETS_BASE"
  exit 1
fi

echo "Select a dataset:"
select dataset in "${dataset_names[@]}"; do
  index=$((REPLY - 1))
  if [[ -n "${dataset_names[index]}" ]]; then
    echo "Selected dataset: ${dataset_names[index]}"
    DATASET_CHOICE="${dataset_dirs[index]}"
    break
  else
    echo "Invalid selection. Please try again."
  fi
done

TRAIN_DIR="$DATASET_CHOICE/train"
TEST_DIR="$DATASET_CHOICE/test"

if [ ! -d "$TRAIN_DIR" ]; then
  echo "Training directory not found: $TRAIN_DIR"
  exit 1
fi

if [ ! -d "$TEST_DIR" ]; then
  echo "Evaluation directory not found: $TEST_DIR"
  exit 1
fi

docker run --gpus all -it \
    -v "$(pwd)/config":/opt/ml/code/config \
    -v "$(pwd)/data/runs":/opt/ml/output \
    -v "$MODEL_CHOICE":/opt/ml/model \
    -v "$TRAIN_DIR":/opt/ml/input/data/train \
    -v "$TEST_DIR":/opt/ml/input/data/test \
    -v "$(pwd)/data/runs":/opt/ml/output \
    -e SM_MODEL_DIR=/opt/ml/model \
    -e SM_INPUT_DIR=/opt/ml/input/data \
    -e SM_OUTPUT_DIR=/opt/ml/output \
    -e SM_LOG_DIR=/opt/ml/output \
    -e SM_CHANNEL_TRAIN=/opt/ml/input/data/train \
    -e SM_CHANNEL_TEST=/opt/ml/input/data/test \
    -e CUDA_VISIBLE_DEVICES=0 \
    mf-test-local:latest /bin/bash
