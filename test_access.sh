#!/bin/bash
echo "🧪 NEUROINSIGHT ACCESSIBILITY TEST"
echo "=================================="
echo ""

echo "1. 🐳 Container Status:"
docker ps --filter "name=neuroinsight-api" --format "   {{.Names}}: {{.Status}}"

echo ""
echo "2. 🌐 Port 8002 Status:"
if ss -tlnp | grep -q :8002; then
    echo "   ✅ Port 8002 is listening"
else
    echo "   ❌ Port 8002 is not listening"
fi

echo ""
echo "3. 🏥 Health Check:"
HEALTH=$(curl -s --max-time 3 http://localhost:8002/health)
if [ $? -eq 0 ] && echo "$HEALTH" | grep -q "healthy"; then
    echo "   ✅ Health check passed: $HEALTH"
else
    echo "   ❌ Health check failed"
fi

echo ""
echo "4. 🌐 Web Interface:"
WEB=$(curl -s --max-time 3 http://localhost:8002/ | grep -c "<title>")
if [ "$WEB" -gt 0 ]; then
    echo "   ✅ Web interface accessible"
else
    echo "   ❌ Web interface not accessible"
fi

echo ""
echo "🎯 ACCESS INSTRUCTIONS:"
echo "   🌐 Open browser to: http://localhost:8002"
echo "   🌍 Remote access: http://18.216.8.38:8002"
echo ""
echo "🔧 IF STILL NOT WORKING:"
echo "   • Clear browser cache (Ctrl+Shift+R)"
echo "   • Try incognito/private browsing mode"
echo "   • Disable browser extensions temporarily"
echo "   • Check if VPN/proxy is interfering"
echo "   • Try from a different browser"
echo "   • Verify you're on the correct server/machine"
