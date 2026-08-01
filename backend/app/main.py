import uuid
import time
import logging
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.logging import setup_logging
from app.core.exceptions import TarangException
from app.api.v1.router import api_router
from app.api.v1.endpoints.ws import router as ws_router

# Setup structured logging
setup_logging()
logger = logging.getLogger("tarang")

# ── NOTE ────────────────────────────────────────────────────────────────────
# Database schema is managed by Alembic migrations.
# Run `alembic upgrade head` before starting the server.
# Never use Base.metadata.create_all() in production.
# ────────────────────────────────────────────────────────────────────────────

# Initialize FastAPI App
app = FastAPI(
    title="Tarang API",
    description="The complete backend API for Tarang - Every Voice Creates a Wave",
    version="1.0.0",
    docs_url="/docs" if settings.ENV != "production" else None,
    redoc_url="/redoc" if settings.ENV != "production" else None,
)

@app.get("/env-check")
def env_check():
    return {
        "env": settings.ENV
    }
# CORS — origins are loaded from the ALLOWED_ORIGINS environment variable.
# Set ALLOWED_ORIGINS=http://localhost:3000 for local dev.
# Set ALLOWED_ORIGINS=https://tarang.app for production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://tarang-satya-ajay-07s-projects.vercel.app",
    ],
    allow_origin_regex=r"https://tarang-.*-satya-ajay-07s-projects\.vercel\.app",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Request tracking and timing middleware
@app.middleware("http")
async def add_process_time_and_request_id(request: Request, call_next):
    request_id = str(uuid.uuid4())
    # Save request_id to local context thread or inject into log filters
    # For simplicity, pass it in headers
    start_time = time.time()
    
    # Store request id on request state
    request.state.request_id = request_id
    
    response = await call_next(request)
    
    process_time = time.time() - start_time
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Process-Time"] = f"{process_time:.4f}s"
    
    # ── Security Headers ─────────────────────────────────────────────────────
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    
    # Content Security Policy (strict settings suitable for an API backend)
    if settings.ENV == "production":
        response.headers["Content-Security-Policy"] = (
            "default-src 'none'; frame-ancestors 'none'; sandbox"
        )
    # HSTS (Strict-Transport-Security) only active in production
    if settings.ENV == "production":
        response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains; preload"
    
    logger.info(
        f"{request.method} {request.url.path} Completed in {process_time:.4f}s with status {response.status_code}"
    )
    return response

# Exception handling middlewares
@app.exception_handler(TarangException)
async def tarang_exception_handler(request: Request, exc: TarangException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": {
                "code": exc.code,
                "message": exc.detail
            }
        }
    )
@app.get("/cors-test")
def cors_test():
    return {
        "origins": settings.allowed_origins_list,
        "raw": settings.ALLOWED_ORIGINS,
    }

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.exception("An unhandled exception occurred")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": "An unexpected error occurred. Please contact support."
            }
        }
    )

# Health Check API
@app.get("/health", tags=["health"])
def health_check():
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "version": "1.0.0"
    }

# Include API Routers
app.include_router(api_router, prefix="/api/v1")

# WebSocket endpoint (mounted separately to support ws:// protocol)
app.include_router(ws_router, prefix="/api/v1")
