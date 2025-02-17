# Docker Build

## Tutorial

### 1. Set-Up Environment

#### 1.1 Create Virtual Environment

```bash
python -m venv .venv --prompt "mistral-finetune-test-local"
```

#### 1.2 Activate Virtual Environment

```bash
source .venv/bin/activate
```

#### 1.3 Install Dependencies

```bash
pip install -r requirements.txt
```

#### 1.4 Add huggingface token to environment variable through `.env` file

```bash
HF_TOKEN=<your-huggingface-token>
```

### 2. Setup Project

#### 2.1 Update the `setup.py` file

```bash
hf_model_id: "mistralai/Mistral-7B-v0.3"
hf_data_parquet_url: "https://huggingface.co/datasets/Locutusque/function-calling-chatml/resolve/main/data/train-00000-of-00001-f0b56c6983b4a78f.parquet"
test_split: 0.05
```

#### 2.2 Run the setup script

```bash
python setup.py
```

This should download the model and dataset, and save them in the `data/models` and `data/datasets` folders respectively.

### 3. Build Docker Image

#### 3.1. Login to ECR

```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 954976316440.dkr.ecr.ap-south-1.amazonaws.com
```

#### 3.2 Build the Docker Image

Replace the `954976316440.dkr.ecr.ap-south-1.amazonaws.com` with your own ECR repository URI.

```bash
docker build -t mf-test-local:latest .
```

#### 3.3 Run the Docker Container with the following script

```bash
./scripts/run.sh
```

### 4. Train the Model

The run command should start off bash command.

#### 4.1 Run the Training Script

Edit the `config/config.yaml` file to change the the final folder in the `run_dir`.

```bash
torchrun --nproc-per-node 1 -m mistral_finetune.train config/config.yaml
```

This should start the training process.

#### 4.2 Validate the Data

```bash
python -m mistral_finetune.utils.validate_data --train_yaml config/config.yaml --created-corrected
```

## Reformat Data Glaive

```bash
python -m mistral_finetune.utils.reformat_data_glaive ../input/data/test/eval.jsonl
```

```bash
python -m mistral_finetune.utils.reformat_data_glaive ../input/data/train/train.jsonl
```

## Reformat Data

```bash
python -m mistral_finetune.utils.reformat_data /opt/ml/input/data/train/train.jsonl
```

```bash
python -m mistral_finetune.utils.reformat_data /opt/ml/input/data/train/train.jsonl
```

```bash
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True,max_split_size_mb:512
```
