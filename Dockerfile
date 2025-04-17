# Use CUDA base image with sufficient capabilities for Gemma 3 27B
FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    wget \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Copy application files
COPY main.py /app/
COPY requirements.txt /app/
COPY start.sh /app/

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Make startup script executable
RUN chmod +x /app/start.sh

# Set up port for FastAPI
EXPOSE 8000

# Set up port for Ollama
EXPOSE 11434

# Start the services
CMD ["/app/start.sh"]