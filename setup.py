from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Optional

from huggingface_hub import snapshot_download
import pandas as pd
import logging
from pydantic import BaseModel
import os
# Enhanced logging configuration

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger("SET_UP")


class SetupArgs(BaseModel):
    hf_model_id: str
    hf_data_parquet_url: str
    test_split: Optional[float] = 0.05

def _load_args(config_path: Path) -> SetupArgs:
    logger.info(f"Loading configuration from {config_path}")
    import yaml
    try:
        with open(config_path, "r") as f:
            config = yaml.safe_load(f)
        logger.debug(f"Loaded config: {config}")
        return SetupArgs(**config)
    except Exception as e:
        logger.error(f"Failed to load config from {config_path}: {str(e)}")
        raise

def _download_model(model_id: str):
    logger.info(f"Starting model download for {model_id}")
    model_name = model_id.split("/")[-1]
    models_path = Path("data/models", model_name)
    
    if not models_path.exists():
        logger.info(f"Creating directory: {models_path}")
        models_path.mkdir(parents=True, exist_ok=True)
        try:
            logger.info("Downloading model files...")
            snapshot_download(
                repo_id=model_id, 
                allow_patterns=["params.json", "consolidated.safetensors", "tokenizer.model.v3"], 
                local_dir=models_path,
                token=os.getenv("HF_TOKEN")
            )
            logger.info(f"Successfully downloaded model to {models_path}")
        except Exception as e:
            logger.error(f"Failed to download model: {str(e)}")
            raise
    else:
        logger.info(f"Model {model_id} already exists in {models_path}")

def _download_dataset(data_parquet_url: str, test_split: float = 0.05):
    logger.info(f"Starting dataset download from {data_parquet_url}")
    dataset_name = data_parquet_url.split("/datasets/")[1].split("/")[1]
    dataset_path = Path("data/datasets", dataset_name)
    train_path = dataset_path / "train" 
    eval_path = dataset_path / "test"
    
    if train_path.exists() and eval_path.exists():
        logger.info(f"Dataset {dataset_name} already exists in {dataset_path}")
        return

    try:
        logger.info("Creating directory structure...")
        train_path.mkdir(parents=True, exist_ok=True)
        eval_path.mkdir(parents=True, exist_ok=True)
        logger.info("Reading parquet file...")
        df = pd.read_parquet(data_parquet_url)
        logger.info(f"Dataset loaded with {len(df)} rows")
        logger.info(f"Splitting dataset with test_split={test_split}")
        df_train = df.sample(frac=1-test_split, random_state=200)
        df_eval = df.drop(df_train.index)
        logger.debug(f"Train set size: {len(df_train)}, Eval set size: {len(df_eval)}")
        logger.info("Saving train set...")
        df_train.to_json(train_path / "train.jsonl", orient="records", lines=True)
        logger.info("Saving eval set...")
        df_eval.to_json(eval_path / "test.jsonl", orient="records", lines=True)
        logger.info("Dataset processing completed successfully")
    except Exception as e:
        logger.error(f"Failed to process dataset: {str(e)}")
        raise

def setup():
    logger.info("Starting setup process")
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=str, default="config/setup.yaml")

    parsed_args = parser.parse_args()
    logger.info(f"Using config file: {parsed_args.config}")
    
    try:
        args = _load_args(Path(parsed_args.config))
        with ThreadPoolExecutor(max_workers=2) as executor:
            model_future = executor.submit(_download_model, args.hf_model_id)
            dataset_future = executor.submit(_download_dataset, args.hf_data_parquet_url, args.test_split)
            futures = [model_future, dataset_future]
            for future in futures:
                try:
                    future.result()
                except Exception as e:
                    logger.error(f"Task failed: {str(e)}")
                    raise
        logger.info("Setup completed successfully")
    except Exception as e:
        logger.error(f"Setup failed: {str(e)}")
        raise

if __name__ == "__main__":
    setup()



