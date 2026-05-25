#!/data/data/com.termux/files/usr/bin/bash
# Hermes Gateway supervised service
# Managed by runit (termux-services)
# Automatically restarted if killed

# Acquire wake lock to prevent Android from suspending Termux
termux-wake-lock

# Source the Hermes venv
source "$HOME/.hermes/hermes-agent/venv/bin/activate"

# Run gateway in foreground (runit supervises this process)
exec hermes gateway run
