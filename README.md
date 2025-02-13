# Docker Build

```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 954976316440.dkr.ecr.ap-south-1.amazonaws.com
```

```bash
docker build -t mf-test-local:v0.1 .
```

```bash
chmod +x run.sh
```

```bash
./run.sh
```

```bash
torchrun --nproc-per-node 1 --master_port $RANDOM  mistral-finetune/train.py config_local.yaml
```
