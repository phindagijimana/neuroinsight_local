"""
Main FastAPI application for NeuroInsight.

This module initializes and configures the FastAPI application,
including middleware, routes, and lifecycle events.
"""

import asyncio
import threading
import time
from contextlib import asynccontextmanager

from pathlib import Path

from fastapi import FastAPI, APIRouter, Request, HTTPException, Query, Depends, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

from backend.api import cleanup_router, jobs_router, metrics_router, reports_router, upload_router, visualizations_router
from backend.core import get_settings, init_db, setup_logging
from backend.core.logging import get_logger
from backend.core.database import get_db

# Clear any cached settings and initialize fresh
from backend.core.config import get_settings
get_settings.cache_clear()  # Clear LRU cache

# Initialize settings (will be reloaded at runtime for environment variables)
settings = get_settings()
setup_logging(settings.log_level, settings.environment)
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan context manager.

    Handles startup and shutdown events.
    """
    global settings, logger

    # Reload settings at runtime (environment variables should now be set)
    settings = get_settings()
    setup_logging(settings.log_level, settings.environment)
    logger = get_logger(__name__)

    # Startup
    logger.info(
        "application_starting",
        app_name=settings.app_name,
        version=settings.app_version,
        environment=settings.environment,
    )

    # Initialize database
    try:
        init_db()
        logger.info("database_initialized")
    except Exception as e:
        logger.error("database_initialization_failed", error=str(e))
        logger.warning("continuing_without_database_initialization")
        # Don't raise - let the app start even if DB init fails


    # Special route for working version
    @app.get("/working")
    async def working_page():
        frontend_dir = Path(__file__).parent.parent / "frontend"
        working_file = frontend_dir / "index.html"
        if working_file.exists():
            return FileResponse(str(working_file), media_type="text/html")
        return JSONResponse({"error": "Working file not found"}, status_code=404)

    # Mount static files (JS libraries, etc.)
    static_dir = Path(__file__).parent.parent / "static"
    if static_dir.exists():
        app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")
        logger.info("static_files_enabled", path=str(static_dir))

    # Mount static files for web frontend from dist directory
    frontend_dir = Path(__file__).parent.parent / "frontend" / "dist"
    if frontend_dir.exists():
        index_file = frontend_dir / "index.html"
        if index_file.exists():
            logger.info("serving_index_html_from", path=str(index_file))
        app.mount("/", StaticFiles(directory=str(frontend_dir), html=True), name="frontend")
        logger.info("frontend_static_files_enabled", path=str(frontend_dir))
    else:
        logger.warning("frontend_directory_not_found", path=str(frontend_dir))

    yield


    logger.info("application_shutting_down")


# Create FastAPI application
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Neuroimaging pipeline for hippocampal asymmetry analysis",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# Direct API endpoints (must be defined immediately after app creation)
@app.get("/api/test-endpoint")
def test_endpoint():
    return {"message": "Test endpoint works"}

@app.post("/api/test-delete", status_code=204)
def delete_job(
    job_id: str = Query(..., description="Job ID"),
    db: Session = Depends(get_db),
):
    """
    Delete a job and its associated data.

    For RUNNING or PENDING jobs:
    - Cancels Celery task and terminates FreeSurfer processes
    - Marks job as CANCELLED before deletion
    - Waits briefly for graceful termination

    For COMPLETED or FAILED jobs:
    - Immediately deletes files and database records

    Args:
        job_id: Job identifier
        db: Database session dependency

    Raises:
        HTTPException: If job not found
    """
    from backend.services.job_service import JobService
    deleted = JobService.delete_job(db, job_id)

    if not deleted:
        raise HTTPException(status_code=404, detail="Job not found")

# Configure CORS
# If cors_origins_list contains "*", use allow_origin_regex to match all origins
cors_origins = settings.cors_origins_list
if cors_origins == ["*"]:
    # Allow all origins when "*" is specified
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r".*",  # Match any origin
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    # Use specific origins
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


# Health check endpoint - supports both GET and HEAD methods for wait-on compatibility
@app.api_route("/health", methods=["GET", "HEAD"], tags=["health"])
async def health_check():
    """
    Health check endpoint.

    Returns application status and version information.
    Supports both GET and HEAD methods for compatibility with health check libraries.
    """
    current_settings = get_settings()
    return {
        "status": "healthy",
        "app_name": current_settings.app_name,
        "version": current_settings.app_version,
        "environment": current_settings.environment,
    }


# Root endpoint - serves the React frontend
@app.get("/", tags=["root"])
async def root():
    """
    Root endpoint - serves the React frontend for web deployment.
    """
    # Serve the React frontend directly
    from pathlib import Path
    frontend_path = Path(__file__).parent.parent / "frontend" / "dist" / "index.html"
    if frontend_path.exists():
        with open(frontend_path, "r", encoding="utf-8") as f:
            content = f.read()
        from fastapi.responses import HTMLResponse
        return HTMLResponse(
            content=content,
            status_code=200,
            headers={
                "Cache-Control": "no-cache, no-store, must-revalidate",
                "Pragma": "no-cache",
                "Expires": "0"
            }
        )
    else:
        return {"error": "Frontend not found", "path": str(frontend_path)}


# Exception handlers
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """
    Global exception handler.
    
    Catches unhandled exceptions and returns a standardized error response.
    """
    logger.error(
        "unhandled_exception",
        path=request.url.path,
        method=request.method,
        error=str(exc),
        exc_info=True,
    )
    
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "error": str(exc) if settings.environment == "development" else None,
        },
    )


# Include routers
app.include_router(upload_router, prefix="/api")
app.include_router(jobs_router, prefix="/api")
app.include_router(metrics_router, prefix="/api")
app.include_router(reports_router, prefix="/api")
app.include_router(visualizations_router, prefix="/api")
app.include_router(cleanup_router, prefix="/api")  # Admin cleanup endpoints

# WebSocket endpoint for real-time job updates
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            # Send periodic job status updates
            data = await websocket.receive_text()
            await websocket.send_text(f"Message received: {data}")
    except WebSocketDisconnect:
        pass

# Static file mounting will be done in lifespan after settings are initialized


if __name__ == "__main__":
    import uvicorn
    import os

    port = int(os.getenv("PORT", settings.api_port))
    should_reload = settings.environment == "development"

    logger.info(
        "starting_uvicorn",
        host=settings.api_host,
        port=port,
        reload=should_reload
    )

    uvicorn.run(
        "backend.main:app",
        host=settings.api_host,
        port=port,
        reload=should_reload,
        log_level=settings.log_level.lower(),
    )

