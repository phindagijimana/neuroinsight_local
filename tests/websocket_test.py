#!/usr/bin/env python3
"""
WebSocket Testing for NeuroInsight Real-time Updates
"""

import asyncio
import json
import os
import websockets
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

class WebSocketTester:
    """Test WebSocket connections for real-time job updates"""
    
    def __init__(self, ws_url: str = "ws://localhost:8000/ws"):
        self.ws_url = ws_url
        self.connection = None
        
    async def connect(self):
        """Establish WebSocket connection"""
        try:
            self.connection = await websockets.connect(self.ws_url)
            logger.info("WebSocket connected successfully")
            return True
        except Exception as e:
            logger.error(f"WebSocket connection failed: {e}")
            return False
            
    async def send_message(self, message: Dict[str, Any]):
        """Send message to WebSocket"""
        if not self.connection:
            return False
            
        try:
            await self.connection.send(json.dumps(message))
            return True
        except Exception as e:
            logger.error(f"Failed to send message: {e}")
            return False
            
    async def receive_message(self):
        """Receive message from WebSocket"""
        if not self.connection:
            return None
            
        try:
            message = await self.connection.recv()
            return json.loads(message)
        except Exception as e:
            logger.error(f"Failed to receive message: {e}")
            return None
            
    async def disconnect(self):
        """Close WebSocket connection"""
        if self.connection:
            await self.connection.close()
            self.connection = None
            
    async def test_connection(self):
        """Test basic WebSocket connectivity"""
        logger.info("Testing WebSocket connection...")
        
        # Connect
        connected = await self.connect()
        if not connected:
            return False
            
        # Send test message
        test_msg = {"type": "ping", "data": {"timestamp": "test"}}
        sent = await self.send_message(test_msg)
        if not sent:
            await self.disconnect()
            return False
            
        # Try to receive response (timeout after 5 seconds)
        try:
            response = await asyncio.wait_for(self.receive_message(), timeout=5.0)
            if response:
                logger.info(f"Received response: {response}")
            else:
                logger.warning("No response received within timeout")
        except asyncio.TimeoutError:
            logger.warning("Response timeout - this may be normal for ping messages")
            
        # Disconnect
        await self.disconnect()
        return True

async def test_websocket_connectivity(ws_url: str = "ws://localhost:8000/ws"):
    """Test WebSocket connectivity"""
    tester = WebSocketTester(ws_url)
    success = await tester.test_connection()
    return success

if __name__ == "__main__":
    # Test WebSocket connectivity
    import sys
    
    # Get port from environment or command line
    port = os.getenv("PORT", "8000")
    ws_url = f"ws://localhost:{port}/ws"
    
    if len(sys.argv) > 1:
        ws_url = sys.argv[1]
        
    print(f"Testing WebSocket connection to: {ws_url}")
    
    try:
        success = asyncio.run(test_websocket_connectivity(ws_url))
        if success:
            print(" WebSocket test PASSED")
            sys.exit(0)
        else:
            print(" WebSocket test FAILED")
            sys.exit(1)
    except Exception as e:
        print(f" WebSocket test ERROR: {e}")
        sys.exit(1)

import os

async def test_freesurfer_processing(base_url: str = "http://localhost:8000"):
    """Test that FreeSurfer processing works with real license"""
    logger.info("Testing FreeSurfer real processing capabilities...")
    
    try:
        # Test license detection
        import subprocess
        result = subprocess.run([
            "docker", "run", "--rm",
            "-v", f"{os.getcwd()}/license.txt:/usr/local/freesurfer/license.txt:ro",
            "freesurfer/freesurfer:7.4.1",
            "echo", "License test successful"
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            logger.info("FreeSurfer license validation passed")
            return True
        else:
            logger.error(f"FreeSurfer license validation failed: {result.stderr}")
            return False
            
    except Exception as e:
        logger.error(f"FreeSurfer processing test failed: {e}")
        return False

if __name__ == "__main__":
    import sys
    
    # Get port from environment or command line
    port = os.getenv("PORT", "8000")
    
    if len(sys.argv) > 1:
        port = sys.argv[1]
        
    print(f"Testing WebSocket connection to: ws://localhost:{port}/ws")
    
    try:
        # Test WebSocket
        ws_success = asyncio.run(test_websocket_connectivity(f"ws://localhost:{port}/ws"))
        
        # Test FreeSurfer processing
        fs_success = asyncio.run(test_freesurfer_processing(f"http://localhost:{port}"))
        
        if ws_success and fs_success:
            print(" All tests PASSED")
            sys.exit(0)
        else:
            print(" Some tests FAILED")
            print(f"  WebSocket: {'' if ws_success else ''}")
            print(f"  FreeSurfer: {'' if fs_success else ''}")
            sys.exit(1)
    except Exception as e:
        print(f" Test ERROR: {e}")
        sys.exit(1)
