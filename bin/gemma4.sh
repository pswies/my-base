#!/bin/bash

set -euo pipefail

MODEL_REPO="OBLITERATUS/gemma-4-E4B-it-OBLITERATED"
MODEL_FILE="gemma-4-E4B-it-OBLITERATED-Q5_K_M.gguf"
MODEL_DIR="$HOME/.cache/llm-models"
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"
PROMPT="Say hello and introduce yourself in one sentence."

# ── 1. Dependencies ────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v llama-cli &>/dev/null; then
  echo "Installing llama.cpp..."
  brew install llama.cpp
fi

if ! command -v hf &>/dev/null; then
  echo "Installing Hugging Face CLI..."
  brew install hf
fi

# ── 2. Download model ──────────────────────────────────────────────────────────
mkdir -p "$MODEL_DIR"

if [ ! -f "$MODEL_PATH" ]; then
  echo "Downloading $MODEL_FILE..."
  hf download "$MODEL_REPO" "$MODEL_FILE" --local-dir "$MODEL_DIR"
else
  echo "Model already cached at $MODEL_PATH"
fi

# ── 3. Run ─────────────────────────────────────────────────────────────────────
echo -e "\n--- Response ---"
llama-cli \
  --model "$MODEL_PATH" \
  --n-gpu-layers 999 \
  --ctx-size 8192 \
  --temp 0.2 \
  --log-disable \
  --no-display-prompt
