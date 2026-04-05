#!/data/data/com.termux/files/usr/bin/bash

MODEL="$HOME/models/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-Q4_K_M.gguf"
LLAMACPP="$HOME/llama.cpp"

cd "$LLAMACPP"

./server \
  -m "$MODEL" \
  --host 127.0.0.1 \
  --port 8080 \
  --ctx-size 2048 \
  --threads $(nproc) \
  --n-gpu-layers 0 \
  --log-disable
