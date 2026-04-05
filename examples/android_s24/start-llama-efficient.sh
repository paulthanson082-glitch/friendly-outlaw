#!/data/data/com.termux/files/usr/bin/bash

# Power-efficient config for S24 — uses Q3_K_M, fewer threads, smaller context
MODEL="$HOME/models/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-Q3_K_M.gguf"

cd "$HOME/llama.cpp"

./server \
  -m "$MODEL" \
  --host 127.0.0.1 \
  --port 8080 \
  --ctx-size 1024 \
  --threads 4 \
  --n-gpu-layers 0
