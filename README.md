# 🧠 Pocket Hermes

### An AI Assistant That Fits in Your Pocket

> Turn your old Android phone into a 24/7 AI assistant — no cloud costs, no monthly subscriptions, no always-on servers. Just Termux, Hermes Agent, and some clever engineering.

**⚠️ This project is a work in progress. You can make wonders with this setup.**

---

## 🤖 Quick Setup with Hermes

**Already have Hermes Agent installed?** Just give it this repo link and say:

> "Set up Pocket Hermes from https://github.com/rajgolepu/pocket-hermes"

Hermes will automatically:
1. Download all scripts from the `scripts/` folder
2. Configure the background service
3. Set up the boot script
4. Create the wake checker cron job
5. Build and serve the dashboard

**You just need to:**
- Get your Telegram bot token from [@BotFather](https://t.me/BotFather)
- Get your Opengateway API key (see below)
- Set Android permissions (battery unrestricted, open Termux:Boot once)

Everything else is automated.

---

## 📖 The Story

It started with a simple question: *What if I could talk to an AI assistant anytime, from anywhere, without opening an app or paying for cloud servers?*

I had a **vivo I2214** lying around — a mid-range Android phone with a Dimensity 8100 chip and 7.6GB of RAM. Not flagship, but not a potato either. I'd been hearing about **Hermes Agent**, an open-source AI agent framework that runs locally and connects to messaging platforms like Telegram. The idea was wild: run a full AI agent on your phone, message it from Telegram like texting a friend, and have it automate things for you.

So I installed Termux, installed Hermes, and said "hi."

What happened next surprised me.

---

## 🏗️ The Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Android Phone                     │
│                  (Any mid-range+)                    │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │              Termux:Boot                     │    │
│  │     (auto-start on phone restart)            │    │
│  └──────────────────┬──────────────────────────┘    │
│                     │                                │
│  ┌──────────────────▼──────────────────────────┐    │
│  │              runsvdir                        │    │
│  │        (process supervisor)                  │    │
│  └──────────────────┬──────────────────────────┘    │
│                     │                                │
│  ┌──────────────────▼──────────────────────────┐    │
│  │         Hermes Gateway Service               │    │
│  │   (Telegram polling, cron, agent loop)       │    │
│  └──────────────────┬──────────────────────────┘    │
│                     │                                │
│  ┌──────────────────▼──────────────────────────┐    │
│  │              Cron Jobs                       │    │
│  │  • Battery monitor (6h)                      │    │
│  │  • AI briefing (daily 7AM)                   │    │
│  │  • Wake checker (2min)                       │    │
│  │  • Dashboard rebuild (daily 7:05AM)          │    │
│  └─────────────────────────────────────────────┘    │
│                                                      │
│  termux-wake-lock (prevents deep sleep)              │
└─────────────────────────────────────────────────────┘
           │
           │ Telegram API (polling)
           ▼
    ┌──────────────┐
    │   Telegram    │
    │  (your phone) │
    └──────────────┘
           │
           │ OpenAI-compatible API
           ▼
    ┌──────────────────────────────────┐
    │  Opengateway (gitlawb.com)       │
    │  Free & Unlimited AI inference   │
    │  Sponsored by Xiaomi MiMo        │
    └──────────────────────────────────┘
```

---

## 🚀 Manual Setup

If you prefer to set up manually (or want to understand each step):

### Prerequisites

1. **Android phone** (any mid-range device from the last 3-4 years)
2. **Termux** installed from [F-Droid](https://f-droid.org/packages/com.termux/) (NOT Play Store)
3. **Termux:API** from F-Droid (for wake lock)
4. **Termux:Boot** from F-Droid (for auto-start on reboot)
5. **Hermes Agent** installed (see below)
6. **Telegram bot token** from [@BotFather](https://t.me/BotFather)

### Step 1: Install Hermes Agent

```bash
# Install Python and dependencies
pkg install python git -y

# Clone Hermes Agent
git clone https://github.com/NousResearch/hermes-agent.git
cd hermes-agent

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install Hermes
pip install -e .

# Verify installation
hermes --version
```

### Step 2: Configure Telegram Gateway

```bash
# Set up your Telegram bot
hermes config set telegram.bot_token YOUR_BOT_TOKEN_HERE

# Set your Telegram chat ID (send /start to @userinfobot to get it)
hermes config set telegram.home_chat_id YOUR_CHAT_ID_HERE
```

### Step 3: Get a Free AI Model (Opengateway)

We use **Opengateway by gitlawb** — a free, unlimited AI inference gateway sponsored by Xiaomi MiMo.

**How to get your API key:**

1. Go to [gitlawb.com/opengateway/dashboard](https://gitlawb.com/opengateway/dashboard)
2. Sign in with your X (Twitter) account
3. Generate a new API key
4. Copy the key (it starts with `ogw_live_`)

**Configure Hermes to use Opengateway via custom provider:**

```bash
hermes config set model.default mimo-v2.5-pro
hermes config set model.provider custom
hermes config set model.base_url https://opengateway.gitlawb.com/v1
hermes config set model.api_mode chat_completions
hermes config set model.api_key YOUR_OGw_API_KEY_HERE
```

**Your config.yaml should look like this:**

```yaml
model:
  default: mimo-v2.5-pro
  provider: custom
  base_url: https://opengateway.gitlawb.com/v1
  api_mode: chat_completions
  api_key: ogw_live_your_key_here
```

**Alternative Free AI Providers:**

You can use any OpenAI-compatible API with Hermes. Just swap the `base_url` and `api_key` in your config. Some options: Google Gemini, Groq, Mistral, DeepSeek, OpenRouter, Together.ai, Fireworks, Replicate, Perplexity, Cohere.

### Step 4: Set Up Background Service

Install required packages and copy the scripts:

```bash
# Install required packages
pkg install termux-services -y

# Create directories
mkdir -p ~/.termux/services/hermes-gateway
mkdir -p ~/.termux/boot
mkdir -p ~/.hermes/scripts

# Copy scripts from this repo
cp scripts/hermes-gateway-run.sh ~/.termux/services/hermes-gateway/run
cp scripts/boot-hermes-gateway.sh ~/.termux/boot/hermes-gateway
cp scripts/hermes-daemon.sh ~/.hermes/hermes-daemon.sh
cp scripts/wake-checker.sh ~/.hermes/scripts/wake-checker.sh
cp scripts/dashboard-build.py ~/.hermes/scripts/dashboard-build.py
cp scripts/dashboard-serve.py ~/.hermes/scripts/dashboard-serve.py
cp scripts/dashboard.sh ~/.hermes/scripts/dashboard.sh

# Make all scripts executable
chmod +x ~/.termux/services/hermes-gateway/run
chmod +x ~/.termux/boot/hermes-gateway
chmod +x ~/.hermes/hermes-daemon.sh
chmod +x ~/.hermes/scripts/*.sh
chmod +x ~/.hermes/scripts/*.py

# Add aliases to bashrc
mkdir -p ~/.bashrc.d
echo 'alias hermes-daemon="bash ~/.hermes/hermes-daemon.sh"' >> ~/.bashrc.d/hermes-daemon
echo 'alias dashboard="bash ~/.hermes/scripts/dashboard.sh"' >> ~/.bashrc.d/hermes-daemon
echo '[ -f ~/.bashrc.d/hermes-daemon ] && . ~/.bashrc.d/hermes-daemon' >> ~/.bashrc
```

**Edit the boot script** — replace `YOUR_CHAT_ID_HERE` with your actual Telegram chat ID:

```bash
nano ~/.termux/boot/hermes-gateway
```

### Step 5: Set Android Permissions

1. **Settings → Apps → Termux → Battery → Unrestricted**
2. **Lock Termux in recent apps** (recents → long-press Termux card → lock icon)
3. **Open Termux:Boot at least once** after installing (Android requires this for boot receivers)

### Step 6: Start Everything

```bash
# Start runsvdir (the service supervisor)
runsvdir "$HOME/.termux/services" &>/dev/null &

# Check if the gateway is running
hermes-daemon status
```

### Step 7: Test

1. Close Termux entirely (swipe away from recent apps)
2. Send a message to your Telegram bot
3. If the agent responds, you're done! 🎉

---

## 📁 Scripts Reference

All scripts are in the [`scripts/`](scripts/) folder:

| Script | Purpose |
|--------|---------|
| [`hermes-gateway-run.sh`](scripts/hermes-gateway-run.sh) | Runit service script — runs the gateway with wake lock |
| [`boot-hermes-gateway.sh`](scripts/boot-hermes-gateway.sh) | Termux:Boot script — auto-starts on phone restart |
| [`hermes-daemon.sh`](scripts/hermes-daemon.sh) | Management script — start/stop/restart/status/logs |
| [`wake-checker.sh`](scripts/wake-checker.sh) | Wake checker — polls Telegram for wake commands |
| [`dashboard-build.py`](scripts/dashboard-build.py) | Dashboard generator — creates static HTML |
| [`dashboard-serve.py`](scripts/dashboard-serve.py) | Dashboard server — lightweight HTTP server |
| [`dashboard.sh`](scripts/dashboard.sh) | Dashboard management — build/start/status/kill/rebuild |

---

## 🌙 Sleep/Wake System

The gateway has a built-in sleep/wake system to save battery when you don't need it.

### How it works:

```
┌─────────────────────────────────────────────────────┐
│                    Sleep/Wake Flow                   │
│                                                      │
│  User: "sleep"                                       │
│    │                                                 │
│    ▼                                                 │
│  ┌─────────────────────────────────────────────┐    │
│  │  1. Create sleep flag file                  │    │
│  │  2. Stop gateway service                    │    │
│  │  3. Wake checker stays alive (lightweight)  │    │
│  └─────────────────────────────────────────────┘    │
│                                                      │
│  User: "wake up" (on Telegram)                       │
│    │                                                 │
│    ▼                                                 │
│  ┌─────────────────────────────────────────────┐    │
│  │  1. Wake checker polls every 2 minutes      │    │
│  │  2. Detects "wake" / "wake up" / "/start"   │    │
│  │  3. Removes sleep flag                      │    │
│  │  4. Starts gateway service                  │    │
│  │  5. Sends "🟢 I'm awake!" to Telegram      │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

### Wake keywords:
- `wake`
- `wake up`
- `wakeup`
- `come back`
- `/start`

---

## 📊 The Dashboard

The dashboard is a **proof of concept** — a simple static HTML page generated from your cron data. It's designed for testing, but this is just the beginning.

### What you can build:

The dashboard is just a starting point. With this setup, you can build:

- **Real-time monitoring dashboards** — live battery, CPU, memory stats
- **News aggregators** — RSS feeds, AI news, tech updates
- **Job boards** — auto-fetched listings from RemoteOK, HN, LinkedIn
- **Social media managers** — post scheduling, analytics
- **Personal CRM** — contact management, reminders
- **Code playgrounds** — run and test code from your phone
- **IoT controllers** — smart home automation
- **AI-powered tools** — custom chatbots, content generators

The possibilities are endless. The dashboard is just a starting point — go build something crazy.

### How it works:

```
┌─────────────────────────────────────────────────────┐
│                  Dashboard Flow                      │
│                                                      │
│  Daily @ 7:00 AM:                                    │
│    └── AI Free Tier Briefing (cron job)              │
│                                                      │
│  Daily @ 7:05 AM:                                    │
│    └── Dashboard auto-rebuilds (silent)              │
│                                                      │
│  You ask "open dashboard":                           │
│    └── Agent starts server, sends link               │
│                                                      │
│  You click "🗡 Kill Server":                         │
│    └── Server shuts down, zero battery drain         │
└─────────────────────────────────────────────────────┘
```

### Management commands:

```bash
dashboard build          # Generate fresh HTML from latest data
dashboard start          # Start server at http://localhost:8080
dashboard status         # Shows if server is running + URL
dashboard kill           # Stops the server immediately
dashboard rebuild        # Build + start in one shot
```

---

## 🔋 Battery Impact

The big question: *Does this kill my battery?*

**No.** Here are the actual numbers:

| Component | RAM | CPU (idle) | Battery Impact |
|-----------|-----|------------|----------------|
| Gateway | ~60MB | ~0% | Minimal |
| Wake checker | ~3MB | ~0% (runs every 2min) | Negligible |
| Runit supervisor | ~1MB | ~0% | None |
| **Total** | **~64MB** | **~0%** | **~2-3%/day extra** |

---

## ⚠️ Pitfalls to Avoid

- **Don't use Play Store Termux** — it's outdated. Use F-Droid.
- **Don't forget to open Termux:Boot once** — Android blocks boot receivers until the app is launched manually.
- **OEM battery optimization is your enemy** — Chinese OEMs (vivo, Xiaomi, Oppo) are aggressive. Set battery to "Unrestricted" or the agent will die silently.
- **The gateway lock file can go stale** — if the phone crashes, `~/.hermes/gateway.lock` might block restarts. Both the daemon script and wake checker auto-clean stale locks now.

---

## 📱 Device Compatibility

This setup has been tested on:

- **vivo I2214** (Dimensity 8100, 7.6GB RAM) — ✅ Working
- Any Android phone with Termux support should work

**Minimum requirements:**
- Android 7.0+
- 2GB RAM
- 1GB free storage
- Termux from F-Droid

---

## 🛠️ Management Commands

```bash
# Gateway management
hermes-daemon start      # Start the gateway
hermes-daemon stop       # Stop it
hermes-daemon restart    # Restart it
hermes-daemon status     # Check if it's running
hermes-daemon logs       # View recent logs

# From Telegram (chat with your bot)
"sleep"                  # Put the gateway to sleep
"wake up"                # Wake it up (within 2 minutes)
"open the dashboard"     # Start the server, get the link
"update the dashboard"   # Rebuild with fresh data
"kill the dashboard"     # Stop the server
```

---

## 📊 Final Stats

| Metric | Value |
|--------|-------|
| **Setup time** | ~2 hours (manual) / ~10 min (with Hermes) |
| **Monthly cost** | $0 |
| **Battery impact** | ~2-3%/day |
| **RAM usage** | ~64MB |
| **Boot time** | ~80 seconds |
| **Wake response** | ~2 minutes |

---

## 🙏 Credits

- **[Hermes Agent](https://github.com/NousResearch/hermes-agent)** — The open-source AI agent framework
- **[Opengateway by gitlawb](https://gitlawb.com/opengateway)** — Free, unlimited AI inference sponsored by Xiaomi MiMo
- **[Termux](https://termux.dev)** — Android terminal emulator
- **[Termux:Boot](https://github.com/termux/termux-boot)** — Auto-start on boot
- **[runit](http://smarden.org/runit/)** — Process supervision

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📬 Contact

- **GitHub:** [@rajgolepu](https://github.com/rajgolepu)

---

**Built with ❤️ on a vivo I2214 running Termux.**

*An AI assistant that fits in your pocket.*
