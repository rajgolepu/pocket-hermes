#!/data/data/com.termux/files/usr/bin/bash
# Hermes Gateway - Termux:Boot startup script
# Starts runsvdir which supervises the gateway service

BOOT_LOG="$HOME/.hermes/logs/boot.log"
SLEEP_FLAG="$HOME/.hermes/.gateway_sleep"
GATEWAY_SERVICE="$HOME/.termux/services/hermes-gateway"
CHAT_ID="YOUR_CHAT_ID_HERE"  # Replace with your Telegram chat ID

echo "=== $(date): Boot script started ===" >> "$BOOT_LOG"

# Check if gateway is in sleep mode
if [ -f "$SLEEP_FLAG" ]; then
    echo "$(date): Sleep flag found, gateway will stay down" >> "$BOOT_LOG"
    echo "=== $(date): Boot complete (sleep mode) ===" >> "$BOOT_LOG"
    exit 0
fi

# Acquire wake lock so Android doesn't suspend Termux
if command -v termux-wake-lock &>/dev/null; then
    termux-wake-lock
    echo "$(date): wake lock acquired" >> "$BOOT_LOG"
fi

# Wait for Termux to fully initialize
sleep 10

# Check if runsvdir is already running
if pgrep -f "runsvdir.*termux/services" > /dev/null 2>&1; then
    echo "$(date): runsvdir already running, checking service..." >> "$BOOT_LOG"
else
    # Start runsvdir — it will auto-start our gateway service
    echo "$(date): Starting runsvdir..." >> "$BOOT_LOG"
    runsvdir "$HOME/.termux/services" &>/dev/null &
    sleep 5
    echo "$(date): runsvdir started (PID: $!)" >> "$BOOT_LOG"
fi

# Wait for gateway to come up
sleep 15

# Verify gateway service is up
if sv status "$GATEWAY_SERVICE" 2>/dev/null | grep -q "run:"; then
    echo "$(date): Gateway service is RUNNING" >> "$BOOT_LOG"

    # Send Telegram notification: "I'm ready"
    TOKEN=$(grep "^TELEGRAM_BOT_TOKEN=" "$HOME/.hermes/.env" | cut -d= -f2-)
    if [ -n "$TOKEN" ]; then
        MESSAGE="🟢 Hermes is ready! I'm back online after the restart.
Say \"sleep\" to put me to sleep, or just chat normally."
        curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
            -d "chat_id=${CHAT_ID}" \
            -d "text=${MESSAGE}" \
            -d "parse_mode=Markdown" \
            -o /dev/null &
        echo "$(date): Telegram notification sent" >> "$BOOT_LOG"
    else
        echo "$(date): Could not read bot token" >> "$BOOT_LOG"
    fi
else
    echo "$(date): Gateway service status: $(sv status $GATEWAY_SERVICE 2>&1)" >> "$BOOT_LOG"
fi

echo "=== $(date): Boot complete ===" >> "$BOOT_LOG"
