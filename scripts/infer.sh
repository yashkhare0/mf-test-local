#!/bin/bash

select_directory() {
    local path=$1
    local prompt=$2
    local filter=$3
    local selected=""
    
    # If filter is set to "checkpoints", only show directories containing a checkpoints folder
    if [ "$filter" = "checkpoints" ]; then
        dirs=()
        for d in "$path"/*/; do
            if [ -d "${d}checkpoints" ]; then
                dirs+=("$d")
            fi
        done
    else
        dirs=($(ls -d "$path"/*/ 2>/dev/null))
    fi
    
    if [ ${#dirs[@]} -eq 0 ]; then
        echo "No directories found in $path"
        exit 1
    fi
    
    PS3="$prompt "
    select dir in "${dirs[@]}"; do
        if [ -n "$dir" ]; then
            selected="${dir%/}"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
    echo "$selected"
}

select_lora_file() {
    local run_dir=$1
    local selected=""
    
    checkpoints=($(ls -d "$run_dir/checkpoints"/*/ 2>/dev/null))
    
    if [ ${#checkpoints[@]} -eq 0 ]; then
        echo "No checkpoints found in $run_dir/checkpoints"
        exit 1
    fi
    
    PS3="Select checkpoint: "
    select checkpoint in "${checkpoints[@]}"; do
        if [ -n "$checkpoint" ]; then
            checkpoint="${checkpoint%/}"
            lora_path="$checkpoint/consolidated/lora.safetensors"
            if [ -f "$lora_path" ]; then
                selected="$checkpoint"  # Return just the checkpoint path
                break
            else
                echo "LORA file not found at expected path: $lora_path"
                exit 1
            fi
        else
            echo "Invalid selection. Please try again."
        fi
    done
    echo "$selected"
}

# Store selections in variables
echo "Selecting base model..."
BASE_MODEL=$(select_directory "data/models" "Select base model:")

echo -e "\nSelecting run directory..."
RUN_DIR=$(select_directory "data/runs" "Select run directory:" "checkpoints")

echo -e "\nSelecting checkpoint..."
CHECKPOINT_PATH=$(select_lora_file "$RUN_DIR")

# Get the run folder name (removing 'data/runs/' prefix)
RUN_FOLDER=$(echo "$RUN_DIR" | sed 's|data/runs/||')

# Get the checkpoint folder name
CHECKPOINT_FOLDER=$(basename "$CHECKPOINT_PATH")

# Construct Docker paths
DOCKER_MODEL_PATH="/opt/ml/model"
DOCKER_LORA_PATH="/opt/ml/output/${RUN_FOLDER}/checkpoints/${CHECKPOINT_FOLDER}/consolidated/lora.safetensors"

# Print configuration
echo -e "\nConfiguration:"
echo "Base model: $BASE_MODEL"
echo "Run folder: $RUN_FOLDER"
echo "Checkpoint: $CHECKPOINT_FOLDER"

# Print the command in simple format
echo -e "\nCommand to run in the docker container:"
echo "mistral-chat $DOCKER_MODEL_PATH --max_tokens 256 --temperature 1.0 --instruct --lora_path $DOCKER_LORA_PATH" 