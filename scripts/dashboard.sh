#!/data/data/com.termux/files/usr/bin/bash
# Dashboard management script

DASHBOARD_DIR="$HOME/.hermes/dashboard"
SCRIPTS_DIR="$(dirname "$0")"

case "${1:-help}" in
    build)
        python3 "$SCRIPTS_DIR/dashboard-build.py"
        ;;
    start)
        python3 -u "$SCRIPTS_DIR/dashboard-serve.py"
        ;;
    status)
        if pgrep -f "dashboard-serve.py" > /dev/null; then
            echo "✅ Dashboard server is running"
            echo "   URL: http://localhost:8080"
        else
            echo "❌ Dashboard server is not running"
        fi
        ;;
    kill)
        pkill -f "dashboard-serve.py" 2>/dev/null && echo "✅ Server stopped" || echo "❌ Server not running"
        ;;
    rebuild)
        python3 "$SCRIPTS_DIR/dashboard-build.py" && python3 -u "$SCRIPTS_DIR/dashboard-serve.py"
        ;;
    *)
        echo "Usage: dashboard {build|start|status|kill|rebuild}"
        ;;
esac
