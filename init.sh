#!/bin/bash

# Update and install dependencies
apt-get update
apt-get install -y git python3 python3-pip curl

# Clone repository
git clone https://github.com/aashir04m/gemma3.git /workspace/gemma3

# Setup the application
cd /workspace/gemma3
pip3 install -r requirements.txt

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Make start script executable and run it
chmod +x start.sh
./start.sh
