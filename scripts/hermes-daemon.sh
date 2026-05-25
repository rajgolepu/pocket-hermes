#!/data/data/com.termux/files/usr/bin/bash
# Hermes Gateway Daemon for Termux
# Manages the runit-supervised gateway service

SERVICE_DIR="$HOME/.termux/services/hermes-gateway"

cmd_start() {
    if [ -f "$SERVICE_DIR/run" ]; then
        if sv status "$SERVICE_DIR" 2>/dev/null | grep -q "run:"; then
            echo "✓ Gateway is already running (supervised by runsv)"
            sv status "$SERVICE_DIR"
        else
            echo "Starting supervised gateway service..."
            sv start "$SERVICE_DIR"
            sleep 3
            sv status "$SERVICE_DIR"
        fi
    else
        echo "✗ Service not found at $SERVICE_DIR"
        exit 1
    fi
}

cmd_stop() {
    if [ -f "$SERVICE_DIR/run" ]; then
        sv stop "$SERVICE_DIR"
        sleep 2
        echo "✓ Gateway stopped"
    fi
    termux-wake-unlock 2>/dev/null || true
}

cmd_restart() {
    if [ -f "$SERVICE_DIR/run" ]; then
        sv restart "$SERVICE_DIR"
        sleep 3
        sv status "$SERVICE_DIR"
    fi
}

cmd_status() {
    echo "── Hermes Gateway (Termux) ──"
    if [ -f "$SERVICE_DIR/run" ]; then
        sv status "$SERVICE_DIR" 2>/dev/null || echo "down"
    else
        echo "✗ Service not configured"
    fi
    echo ""
    echo "  Commands: hermes-daemon {start|stop|restart|status|logs}"
}

cmd_logs() {
    tail -n 50 "$HOME/.hermes/logs/gateway-daemon.log" 2>/dev/null || echo "No log file found"
}

case "${1:-status}" in
    start)   cmd_start ;;
    stop)    cmd_stop ;;
    restart) cmd_restart ;;
    status)  cmd_status ;;
    logs)    cmd_logs ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
