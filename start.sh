#!/bin/bash

# Update and install dependencies
apt-get update
apt-get install -y python3 python3-pip git curl wget

# Clone the repository
git clone https://github.com/aashir04m/gemma3.git /app

# Navigate to app directory
cd /app

# Install Python dependencies
pip3 install --no-cache-dir -r requirements.txt

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Make startup script executable
chmod +x start.sh

# Run the startup script
./start.sh
