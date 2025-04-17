#!/bin/bash

# Start Ollama in the background
echo "Starting Ollama server..."
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to initialize
echo "Waiting for Ollama to become available..."
MAX_RETRIES=30
COUNT=0
while ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
    sleep 2
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "Ollama failed to start after $MAX_RETRIES attempts."
        exit 1
    fi
    echo "Waiting for Ollama to become available... Attempt $COUNT/$MAX_RETRIES"
done
echo "Ollama is running!"

# Check if Gemma 3 27B model is already downloaded
if ! ollama list | grep -q "gemma3:27b"; then
    echo "Downloading Gemma 3 27B model..."
    ollama pull gemma3:27b
    echo "Gemma 3 27B model downloaded successfully!"
else
    echo "Gemma 3 27B model is already available."
fi

# Start FastAPI application
echo "Starting FastAPI application..."
exec uvicorn main:app --host 0.0.0.0 --port 8000 --log-level info

# Note: We use 'exec' so uvicorn becomes the main process
# This means if uvicorn exits, the container exits
# The OLLAMA_PID cleanup is not needed because 'exec' replaces the shell process
