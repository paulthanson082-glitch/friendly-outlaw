#!/data/data/com.termux/files/usr/bin/bash
# Automated Samsung S24 Setup for Local Reasoning
# Run in Termux: bash setup-android.sh

set -e  # Exit on error

echo "========================================================================"
echo "Samsung S24 - Local Reasoning Setup (llama.cpp + GGUF)"
echo "========================================================================"
echo ""
echo "⚠️  WARNING: This is complex and takes 3-4 hours"
echo "Make sure you have:"
echo "  - 20GB+ free storage"
echo "  - WiFi connection (for model download)"
echo "  - Battery >50% (or plugged in)"
echo "  - Termux installed from F-Droid (NOT Play Store)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled"
    exit 1
fi

echo ""

# Step 1: Check system info
echo "Step 1: Checking system..."
echo "Architecture: $(uname -m)"
echo "Android version: $(getprop ro.build.version.release)"

# Check RAM
TOTAL_RAM=$(free -h | grep Mem | awk '{print $2}')
echo "RAM: $TOTAL_RAM"

# Parse RAM (rough)
RAM_GB=$(free -m | grep Mem | awk '{print $2}')
RAM_GB=$((RAM_GB / 1024))

if [ "$RAM_GB" -lt 8 ]; then
    echo "❌ Error: Need at least 8GB RAM"
    exit 1
fi

echo "✅ System check passed"
echo ""

# Step 2: Update packages
echo "Step 2: Updating Termux packages..."
pkg update -y
pkg upgrade -y
echo "✅ Packages updated"
echo ""

# Step 3: Install base tools
echo "Step 3: Installing base tools..."
pkg install -y \
    git \
    wget \
    curl \
    python \
    nodejs \
    build-essential \
    cmake \
    clang \
    proot

echo "✅ Base tools installed"
echo ""

# Step 4: Setup storage
echo "Step 4: Setting up storage access..."
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage
    echo "✅ Storage setup (grant permission if prompted)"
else
    echo "✅ Storage already setup"
fi
echo ""

# Step 5: Setup swap
echo "Step 5: Setting up swap (helps with RAM)..."
SWAP_FILE="$HOME/swapfile"

if [ ! -f "$SWAP_FILE" ]; then
    echo "Creating 4GB swap file (takes 2-3 minutes)..."
    dd if=/dev/zero of="$SWAP_FILE" bs=1M count=4096 status=progress
    chmod 600 "$SWAP_FILE"
    mkswap "$SWAP_FILE"
    swapon "$SWAP_FILE"

    # Add to startup
    if ! grep -q "swapon" ~/.bashrc; then
        echo "swapon $SWAP_FILE" >> ~/.bashrc
    fi

    echo "✅ Swap created and enabled"
else
    swapon "$SWAP_FILE" 2>/dev/null || echo "Swap already enabled"
    echo "✅ Swap already setup"
fi
echo ""

# Step 6: Clone llama.cpp
echo "Step 6: Downloading llama.cpp..."
if [ ! -d "$HOME/llama.cpp" ]; then
    cd "$HOME"
    git clone https://github.com/ggerganov/llama.cpp.git
    echo "✅ llama.cpp downloaded"
else
    echo "✅ llama.cpp already exists"
fi
echo ""

# Step 7: Compile llama.cpp
echo "Step 7: Compiling llama.cpp (takes 10-15 minutes)..."
cd "$HOME/llama.cpp"

if [ ! -f "main" ] || [ ! -f "server" ]; then
    echo "Starting compilation..."
    make clean
    make -j$(nproc) || {
        echo "⚠️  Full build failed, trying simpler build..."
        make clean
        LLAMA_NO_ACCELERATE=1 make -j2
    }
    echo "✅ Compilation complete"
else
    echo "✅ Already compiled"
fi

# Verify
if [ ! -f "main" ] || [ ! -f "server" ]; then
    echo "❌ Compilation failed"
    exit 1
fi

echo "✅ llama.cpp ready"
echo ""

# Step 8: Install Python packages
echo "Step 8: Installing Python packages..."
pip install --upgrade pip
pip install huggingface-hub[cli]
echo "✅ Python packages installed"
echo ""

# Step 9: Choose model
echo "Step 9: Model selection..."
echo ""
echo "Choose model quantization (based on your RAM):"
echo "  1) Q3_K_M - 11GB  (Recommended for 8GB S24)"
echo "  2) Q4_K_M - 15GB  (Recommended for 12GB S24)"
echo ""

if [ "$RAM_GB" -ge 12 ]; then
    DEFAULT_CHOICE=2
    echo "Your device has ${RAM_GB}GB RAM, recommending Q4_K_M"
else
    DEFAULT_CHOICE=1
    echo "Your device has ${RAM_GB}GB RAM, recommending Q3_K_M"
fi

echo ""
read -p "Enter choice (1-2, default=$DEFAULT_CHOICE): " MODEL_CHOICE
MODEL_CHOICE=${MODEL_CHOICE:-$DEFAULT_CHOICE}

case $MODEL_CHOICE in
    1)
        MODEL_FILE="Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-Q3_K_M.gguf"
        echo "Selected: Q3_K_M (11GB)"
        ;;
    2)
        MODEL_FILE="Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-Q4_K_M.gguf"
        echo "Selected: Q4_K_M (15GB)"
        ;;
    *)
        echo "Invalid choice, using default"
        MODEL_FILE="Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-Q3_K_M.gguf"
        ;;
esac

echo ""

# Step 10: Download model
echo "Step 10: Downloading model..."
mkdir -p "$HOME/models"
cd "$HOME/models"

if [ -f "$MODEL_FILE" ]; then
    echo "✅ Model already downloaded"
else
    echo "Downloading $MODEL_FILE (~11-15GB, takes 10-20 minutes)..."
    echo "This can be resumed if interrupted"

    huggingface-cli download \
        bartowski/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-GGUF \
        "$MODEL_FILE" \
        --local-dir . \
        --local-dir-use-symlinks False

    echo "✅ Model downloaded"
fi

MODEL_PATH="$HOME/models/$MODEL_FILE"
echo "Model location: $MODEL_PATH"
echo ""

# Step 11: Create startup script
echo "Step 11: Creating startup script..."
cat > "$HOME/start-llama-server.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash

MODEL="$MODEL_PATH"
LLAMACPP="$HOME/llama.cpp"

echo "Starting llama.cpp server..."
echo "Model: \$MODEL"
echo ""

cd "\$LLAMACPP"

# Determine context size based on RAM
if [ "$RAM_GB" -ge 12 ]; then
    CTX_SIZE=2048
else
    CTX_SIZE=1024
fi

./server \\
    -m "\$MODEL" \\
    --host 127.0.0.1 \\
    --port 8080 \\
    --ctx-size \$CTX_SIZE \\
    --threads \$(nproc) \\
    --n-gpu-layers 0

echo ""
echo "Server stopped"
EOF

chmod +x "$HOME/start-llama-server.sh"
echo "✅ Startup script created: $HOME/start-llama-server.sh"
echo ""

# Step 12: Setup Node.js project
echo "Step 12: Setting up Node.js project..."
mkdir -p "$HOME/qwen-android-integration"
cd "$HOME/qwen-android-integration"

if [ ! -f "package.json" ]; then
    npm init -y
    npm install axios
    npm install -D typescript ts-node @types/node
    echo "✅ Node.js project created"
else
    echo "✅ Node.js project already exists"
fi

# Create tsconfig
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node"
  }
}
EOF

echo "✅ TypeScript configured"
echo ""

# Step 13: Quick test
echo "Step 13: Running quick test..."
echo ""
echo "Starting llama.cpp server in background..."

cd "$HOME/llama.cpp"
./server \
    -m "$MODEL_PATH" \
    --host 127.0.0.1 \
    --port 8080 \
    --ctx-size 512 \
    --threads $(nproc) &

SERVER_PID=$!
echo "Server PID: $SERVER_PID"

# Wait for server to start
echo "Waiting for server to start (30s)..."
sleep 30

# Test generation
echo ""
echo "Testing generation..."
./main \
    -m "$MODEL_PATH" \
    -p "What is 2+2?" \
    -n 50 \
    --ctx-size 512

# Stop server
echo ""
echo "Stopping test server..."
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null || true

echo ""
echo "✅ Quick test complete"
echo ""

# Summary
echo "========================================================================"
echo "Setup Complete!"
echo "========================================================================"
echo ""
echo "System:"
echo "  Device: Samsung S24"
echo "  RAM: ${RAM_GB}GB"
echo "  Model: $MODEL_FILE"
echo ""
echo "Installed:"
echo "  ✅ Termux environment"
echo "  ✅ llama.cpp (compiled)"
echo "  ✅ Qwen Opus model"
echo "  ✅ Node.js + TypeScript"
echo "  ✅ Startup scripts"
echo ""
echo "Project directory:"
echo "  $HOME/qwen-android-integration"
echo ""
echo "Next steps:"
echo ""
echo "1. Start the server:"
echo "   \$HOME/start-llama-server.sh"
echo ""
echo "2. In another Termux session, copy integration files:"
echo "   cd $HOME/qwen-android-integration"
echo "   # Copy LocalReasoningProvider.ts, SmartRouter.ts, etc."
echo ""
echo "3. Test TypeScript integration:"
echo "   npx ts-node test.ts"
echo ""
echo "4. Integrate into WritersApp Android"
echo ""
echo "Performance expectations:"
echo "  - First load: 45-60s"
echo "  - Generation: 5-10s per response"
echo "  - Battery: ~2-3 hours continuous use"
echo ""
echo "Tips:"
echo "  - Use WiFi when possible"
echo "  - Keep device plugged in for heavy use"
echo "  - Monitor temperature (Settings → Battery → Temperature)"
echo "  - Close other apps to free RAM"
echo ""
echo "Support:"
echo "  - Check server: curl http://127.0.0.1:8080/health"
echo "  - Monitor memory: free -h"
echo "  - Check processes: ps aux | grep server"
echo ""
echo "Ready to start the server? Run:"
echo "  \$HOME/start-llama-server.sh"
echo ""
echo "========================================================================"
