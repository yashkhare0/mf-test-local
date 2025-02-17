import json
import re
from pathlib import Path
from typing import Union

def extract_line_numbers(error_log: str) -> list[int]:
    """
    Extract line numbers from error log text.
    
    Args:
        error_log: String containing error messages
    
    Returns:
        List of line numbers found in the error messages
    """
    pattern = r"The data in line (\d+) of dataset"
    return [int(match) for match in re.findall(pattern, error_log)]

def remove_lines_from_jsonl(
    jsonl_file: Union[str, Path],
    error_log: str
) -> tuple[int, int]:
    """
    Remove lines specified in error log from a JSONL file.
    Updates the file in place.
    
    Args:
        jsonl_file: Path to JSONL file to modify
        error_log: String containing error messages
    
    Returns:
        tuple: (number of lines processed, number of lines removed)
    """
    lines_to_remove = {line_num - 1 for line_num in extract_line_numbers(error_log)}
    jsonl_path = Path(jsonl_file)
    temp_path = jsonl_path.with_suffix('.jsonl.temp')
    lines_processed = 0
    lines_removed = 0
    try:
        with jsonl_path.open('r', encoding='utf-8') as infile, \
             temp_path.open('w', encoding='utf-8') as outfile:
            for i, line in enumerate(infile):
                try:
                    json.loads(line.strip())
                    if i not in lines_to_remove:
                        outfile.write(line)
                    else:
                        lines_removed += 1
                    lines_processed += 1
                except json.JSONDecodeError:
                    continue
        temp_path.replace(jsonl_path)
    finally:
        if temp_path.exists():
            temp_path.unlink()
            
    return lines_processed, lines_removed

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Clean JSONL file based on error log")
    parser.add_argument("--data_type", type=str, default="train", help="Path to the JSONL file to clean")
    args = parser.parse_args()

    error_log = """
 The data in line 1704 of dataset /opt/ml/input/data/test/test.jsonl is incorrectly formatted.Assistant message must have either content or tool_calls, but not both.
   """
    
    processed, removed = remove_lines_from_jsonl(
        jsonl_file=f"data/datasets/function-calling-chatml/{args.data_type}/{args.data_type}.jsonl",
        error_log=error_log
    )
    
    print(f"Processed {processed} lines")
    print(f"Removed {removed} lines")