#!/bin/bash

# Start Ollama in the background
ollama serve &
OLLAMA_PID=$!

echo "Starting Ollama server with PID: $OLLAMA_PID"

# Wait for Ollama to start
echo "Waiting for Ollama to start..."
until curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
    echo "Waiting for Ollama to become available..."
    sleep 2
done
echo "Ollama is running!"

# Pull the Gemma 3 27B model (hardcoded)
echo "Downloading Gemma 3 27B model..."
ollama pull gemma3:27b

# Start FastAPI application
echo "Starting FastAPI application..."
uvicorn main:app --host 0.0.0.0 --port 8000 --log-level info

# If FastAPI exits, kill Ollama
kill $OLLAMA_PID