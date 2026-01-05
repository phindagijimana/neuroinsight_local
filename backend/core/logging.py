"""
Structured logging configuration using structlog.

This module sets up JSON-formatted structured logging for production
environments and human-readable logging for development.
"""

import logging
import sys
from typing import Any, Dict

import structlog


def setup_logging(log_level: str = "INFO", environment: str = "development") -> None:
    """
    Configure structured logging for the application.
    
    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        environment: Application environment (development, production)
    """
    # Configure standard logging
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=getattr(logging, log_level.upper()),
    )
    
    # Shared processors for all environments
    shared_processors = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]
    
    # Environment-specific processors
    if environment == "production":
        # JSON logging for production
        processors = shared_processors + [
            structlog.processors.dict_tracebacks,
            structlog.processors.JSONRenderer(),
        ]
    else:
        # Pretty console logging for development
        processors = shared_processors + [
            structlog.dev.ConsoleRenderer(colors=True),
        ]
    
    # Configure structlog
    structlog.configure(
        processors=processors,
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )


def get_logger(name: str) -> Any:
    """
    Get a structured logger instance.
    
    Args:
        name: Logger name (typically __name__)
    
    Returns:
        Structured logger instance
    """
    return structlog.get_logger(name)

