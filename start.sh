#!/bin/bash

# Update packages
apt-get update

# Install necessary packages
apt-get install -y python3 python3-pip curl wget

# Check if repo is already cloned, if not, clone it
if [ ! -d "/app/gemma3" ]; then
  # Create a subdirectory
  mkdir -p /app/gemma3
  
  # Clone the repository
  git clone https://github.com/aashir04m/gemma3.git /app/gemma3
fi

# Navigate to app directory
cd /app/gemma3

# Install Python dependencies
pip3 install --no-cache-dir fastapi uvicorn aiohttp pydantic python-multipart httpx

# Check if Ollama is installed, if not install it
if ! command -v ollama &> /dev/null; then
  echo "Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "Ollama is already installed"
fi

# Make startup script executable
chmod +x start.sh

# Run the startup script
./start.sh
