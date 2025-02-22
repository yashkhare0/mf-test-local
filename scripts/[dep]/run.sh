#!/bin/bash
# Run the docker container
docker run --gpus all -it \
    -v $(pwd)/config/config.yaml:/opt/ml/code/config.yaml \
    -v $(pwd)/data/models/Mistral-7B-v0.3:/opt/ml/model \
    -v $(pwd)/data/datasets/test-data/train:/opt/ml/input/data/train \
    -v $(pwd)/data/datasets/test-data/eval:/opt/ml/input/data/test \
    -v $(pwd)/data/runs:/opt/ml/output \
    -e SM_MODEL_DIR=/opt/ml/model \
    -e SM_INPUT_DIR=/opt/ml/input/data \
    -e SM_OUTPUT_DIR=/opt/ml/output \
    -e SM_LOG_DIR=/opt/ml/output \
    -e SM_CHANNEL_TRAIN=/opt/ml/input/data/train \
    -e SM_CHANNEL_TEST=/opt/ml/input/data/test \
    -e CUDA_VISIBLE_DEVICES=0 \
    mf-test-local:latest /bin/bash