#!/bin/bash

# ╔════════════════════════════════════════════════════════════════╗
# ║                    Jules Quick Launch Script                   ║
# ║         Personal Assistant Chatbot for Writers                 ║
# ╚════════════════════════════════════════════════════════════════╝

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           Jules - Your AI Writing Assistant                ║"
echo "║         Ready to help with your creative writing           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check for API key
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "⚠️  ANTHROPIC_API_KEY not set!"
    echo ""
    echo "To use Jules, you need an Anthropic API key."
    echo ""
    echo "Option 1: Set in this session"
    echo "  export ANTHROPIC_API_KEY=\"sk-ant-YOUR_KEY_HERE\""
    echo "  bash launch-jules.sh"
    echo ""
    echo "Option 2: Set in your shell profile"
    echo "  echo 'export ANTHROPIC_API_KEY=\"sk-ant-YOUR_KEY_HERE\"' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    echo ""
    echo "Option 3: Set via .env file (create .env in project root)"
    echo "  ANTHROPIC_API_KEY=sk-ant-YOUR_KEY_HERE"
    echo ""
    read -p "Enter your API key now (or press Ctrl+C to cancel): " api_key

    if [ -n "$api_key" ]; then
        export ANTHROPIC_API_KEY="$api_key"
        echo "✓ API key set for this session"
    else
        echo "Cancelled. Jules needs an API key to run."
        exit 1
    fi
fi

echo "✓ API key found"
echo ""

# Ask about dangerous mode
read -p "Enable dangerous mode? (skip permissions) [y/N]: " dangerous_mode

if [[ "$dangerous_mode" =~ ^[Yy]$ ]]; then
    echo "⚠️  Enabling dangerous mode..."
    export DANGEROUS_MODE=true
    export SKIP_GIT_HOOKS=true
    export SKIP_FILE_CHECKS=true
    git config core.hooksPath "" 2>/dev/null || true
    echo "✓ Dangerous mode enabled"
    echo ""
fi

# Run the app
echo "🚀 Starting Jules..."
echo ""
echo "Quick Menu:"
echo "  17 = Chat with Jules (AI Assistant)"
echo "  18 = Toggle Adult Mode (curse words & mature content)"
echo ""
echo "Type your choice and press Enter"
echo ""

swift run WritersAppCLI

# Cleanup
if [[ "$dangerous_mode" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Disabling dangerous mode..."
    unset DANGEROUS_MODE
    unset SKIP_GIT_HOOKS
    unset SKIP_FILE_CHECKS
    git config core.hooksPath ".git/hooks" 2>/dev/null || true
    echo "✓ Dangerous mode disabled"
fi

echo ""
echo "Thanks for using Jules! Happy writing! 📝✨"
echo ""
