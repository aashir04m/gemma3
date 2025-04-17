from fastapi import FastAPI, Request, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import aiohttp
import os
import httpx
import json
import time
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="RunPod Ollama API")

# Add CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add this near the top with other app setup code
app.mount("/static", StaticFiles(directory="."), name="static")

# Request body model for chat
class ChatRequest(BaseModel):
    model: str = "gemma3:27b"  # Default to Gemma 3 27B
    messages: list
    stream: bool = False
    temperature: float = 0.7
    top_p: float = 0.9
    top_k: int = 40
    max_tokens: int = 2048

# Model pull request
class PullModelRequest(BaseModel):
    name: str
    insecure: bool = False

# RunPod health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "OK"}

@app.get("/")
async def serve_ui():
    return FileResponse("static/gemma_UI_with_formated.html")

# RunPod serverless compatible handler
@app.post("/")
async def runpod_handler(request: Request):
    body = await request.json()
    input_data = body.get("input", {})
    
    # Check if this is a chat request
    if "messages" in input_data and "model" in input_data:
        chat_request = ChatRequest(**input_data)
        return await handle_chat(chat_request)
    
    # Default response if request type not recognized
    return {"error": "Unrecognized request type"}

# Ollama chat endpoint
@app.post("/api/chat")
async def chat(request: ChatRequest):
    return await handle_chat(request)

async def handle_chat(request: ChatRequest):
    ollama_host = os.environ.get("OLLAMA_HOST", "localhost")
    ollama_url = f"http://{ollama_host}:11434/api/chat"
    req_json = request.dict()
    
    if request.stream:
        async def stream_ollama():
            async with aiohttp.ClientSession() as session:
                async with session.post(ollama_url, json=req_json) as resp:
                    if resp.status != 200:
                        error_text = await resp.text()
                        yield json.dumps({"error": error_text}).encode()
                    else:
                        async for line in resp.content:
                            yield line

        return StreamingResponse(stream_ollama(), media_type="application/x-ndjson")
    else:
        async with httpx.AsyncClient() as client:
            response = await client.post(ollama_url, json=req_json, timeout=None)
            return JSONResponse(content=response.json())

# Endpoint to pull models
@app.post("/api/pull")
async def pull_model(request: PullModelRequest, background_tasks: BackgroundTasks):
    background_tasks.add_task(download_model, request.name, request.insecure)
    return {"status": "Model download started", "model": request.name}

# Function to download model in background
async def download_model(model_name: str, insecure: bool = False):
    logger.info(f"Starting download of model: {model_name}")
    ollama_host = os.environ.get("OLLAMA_HOST", "localhost")
    ollama_url = f"http://{ollama_host}:11434/api/pull"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                ollama_url, 
                json={"name": model_name, "insecure": insecure},
                timeout=None
            )
            logger.info(f"Model download response: {response.status_code}")
        except Exception as e:
            logger.error(f"Error downloading model: {str(e)}")

# List available models
@app.get("/api/models")
async def list_models():
    ollama_host = os.environ.get("OLLAMA_HOST", "localhost")
    ollama_url = f"http://{ollama_host}:11434/api/tags"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(ollama_url)
            return response.json()
        except Exception as e:
            return {"error": str(e)}

# Startup event
@app.on_event("startup")
async def startup_event():
    logger.info("Starting FastAPI application")
    # Wait for Ollama to be ready
    ollama_ready = False
    max_retries = 10
    retry_count = 0
    
    while not ollama_ready and retry_count < max_retries:
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get("http://localhost:11434/api/tags")
                if response.status_code == 200:
                    ollama_ready = True
                    logger.info("Ollama is ready")
                else:
                    logger.info(f"Ollama not ready yet, status: {response.status_code}")
        except Exception as e:
            logger.info(f"Waiting for Ollama to start: {str(e)}")
        
        if not ollama_ready:
            retry_count += 1
            time.sleep(5)
    
    if not ollama_ready:
        logger.warning("Ollama service not ready after maximum retries")
