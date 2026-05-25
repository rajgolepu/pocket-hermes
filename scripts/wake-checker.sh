#!/data/data/com.termux/files/usr/bin/bash
# Wake checker - polls Telegram for wake commands when gateway is sleeping
# This is a lightweight script that runs as a no_agent cron job

SLEEP_FLAG="$HOME/.hermes/.gateway_sleep"
LAST_MSG_FILE="$HOME/.hermes/.last_wake_check"

# If no sleep flag, we're not sleeping — exit
if [ ! -f "$SLEEP_FLAG" ]; then
    exit 0
fi

# Get bot token from .env
TOKEN=$(grep "^TELEGRAM_BOT_TOKEN=" "$HOME/.hermes/.env" | cut -d= -f2-)
if [ -z "$TOKEN" ]; then
    echo "Error: Could not read bot token" >> "$HOME/.hermes/logs/wake-checker.log"
    exit 1
fi

# Get the last update ID we've seen
LAST_UPDATE_ID=""
if [ -f "$LAST_MSG_FILE" ]; then
    LAST_UPDATE_ID=$(cat "$LAST_MSG_FILE")
fi

# Fetch new messages from Telegram
RESPONSE=$(curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates?offset=${LAST_UPDATE_ID}&limit=10")

# Parse response and check for wake commands
RESULT=$(echo "$RESPONSE" | python3 -c "
import json, sys, re

try:
    data = json.load(sys.stdin)
except:
    print(':')
    sys.exit(0)

if not data.get('ok') or not data.get('result'):
    print(':')
    sys.exit(0)

updates = data['result']
if not updates:
    print(':')
    sys.exit(0)

# Get the highest update ID
highest = max(u['update_id'] for u in updates)

# Check for wake commands
WAKE_RE = re.compile(r'\bwake\b|\bwakeup\b|/start|come\s*back', re.IGNORECASE)
wake_id = ''

for update in updates:
    msg = update.get('message', {})
    text = msg.get('text', '')
    uid = msg.get('from', {}).get('id', 0)
    
    # Only check messages from the home chat
    # Replace 8750175656 with your actual chat ID
    if uid == 8750175656:
        if WAKE_RE.search(text):
            wake_id = uid

print(f'{highest}:{wake_id}')
")

HIGHEST="${RESULT%%:*}"
WAKE_ID="${RESULT#*:}"

# Update the last seen message ID
if [ -n "$HIGHEST" ]; then
    echo "$HIGHEST" > "$LAST_MSG_FILE"
fi

# If no wake command found, we're done
if [ -z "$WAKE_ID" ]; then
    exit 0
fi

# === WAKE COMMAND FOUND ===
echo "[$(date)] Wake detected (update_id=$WAKE_ID), starting gateway..." >> "$HOME/.hermes/logs/wake-checker.log"

# Remove sleep flag
rm -f "$SLEEP_FLAG"

# Remove stale lock if exists
LOCK_FILE="$HOME/.hermes/gateway.lock"
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(python3 -c "import json; print(json.load(open('$LOCK_FILE'))['pid'])" 2>/dev/null)
    if [ -n "$LOCK_PID" ] && ! kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "[$(date)] Removing stale lock (PID $LOCK_PID)" >> "$HOME/.hermes/logs/wake-checker.log"
        rm -f "$LOCK_FILE"
    fi
fi

# Start the gateway service
sv up "$HOME/.termux/services/hermes-gateway"

# Wait for gateway to start (up to 30 seconds)
for i in $(seq 1 30); do
    if sv status "$HOME/.termux/services/hermes-gateway" 2>/dev/null | grep -q "run:"; then
        # Re-acquire Termux wake lock
        termux-wake-lock 2>/dev/null
        
        # Send notification
        curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
            -d "chat_id=${WAKE_ID}" \
            -d "text=🟢 I'm awake! You can chat with me now." \
            -o /dev/null &
        
        echo "[$(date)] Gateway up, notification sent" >> "$HOME/.hermes/logs/wake-checker.log"
        exit 0
    fi
    sleep 1
done

echo "[$(date)] Gateway failed to start within 30 seconds" >> "$HOME/.hermes/logs/wake-checker.log"
exit 1
