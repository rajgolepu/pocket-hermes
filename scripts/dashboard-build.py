#!/usr/bin/env python3
"""Generate static HTML dashboard from cron data."""

import json
import os
from datetime import datetime
from pathlib import Path

HOME = Path.home()
CRON_DIR = HOME / ".hermes" / "cron"
DASHBOARD_DIR = HOME / ".hermes" / "dashboard"
OUTPUT_FILE = DASHBOARD_DIR / "index.html"

def load_cron_jobs():
    """Load all cron jobs."""
    jobs = []
    if CRON_DIR.exists():
        for f in CRON_DIR.iterdir():
            if f.suffix == '.json':
                try:
                    data = json.loads(f.read_text())
                    jobs.append(data)
                except:
                    pass
    return jobs

def generate_html(jobs):
    """Generate dashboard HTML."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    jobs_html = ""
    for job in jobs:
        name = job.get('name', 'Unknown')
        schedule = job.get('schedule', 'N/A')
        enabled = job.get('enabled', True)
        status = "✅ Active" if enabled else "⏸️ Paused"
        jobs_html += f"""
        <tr>
            <td>{name}</td>
            <td>{schedule}</td>
            <td>{status}</td>
        </tr>
        """
    
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hermes Dashboard</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #0a0a0a; 
            color: #e0e0e0; 
            padding: 20px;
        }}
        .container {{ max-width: 800px; margin: 0 auto; }}
        h1 {{ color: #00ff88; margin-bottom: 20px; }}
        .card {{ 
            background: #1a1a1a; 
            border: 1px solid #333; 
            border-radius: 8px; 
            padding: 20px; 
            margin-bottom: 20px; 
        }}
        .card h2 {{ color: #00ff88; margin-bottom: 15px; }}
        table {{ width: 100%; border-collapse: collapse; }}
        th, td {{ 
            padding: 10px; 
            text-align: left; 
            border-bottom: 1px solid #333; 
        }}
        th {{ color: #00ff88; }}
        .kill-btn {{ 
            background: #ff4444; 
            color: white; 
            border: none; 
            padding: 10px 20px; 
            border-radius: 4px; 
            cursor: pointer;
            font-size: 16px;
        }}
        .kill-btn:hover {{ background: #ff6666; }}
        .footer {{ 
            text-align: center; 
            color: #666; 
            margin-top: 40px; 
            font-size: 14px; 
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🧠 Hermes Dashboard</h1>
        
        <div class="card">
            <h2>⏰ Scheduled Jobs</h2>
            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Schedule</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    {jobs_html}
                </tbody>
            </table>
        </div>
        
        <div class="card">
            <h2>📊 System Info</h2>
            <p>Last updated: {now}</p>
        </div>
        
        <div style="text-align: center; margin-top: 30px;">
            <button class="kill-btn" onclick="fetch('/kill').then(() => alert('Server shutting down...'))">
                🗡 Kill Server
            </button>
        </div>
        
        <div class="footer">
            Pocket Hermes — An AI assistant that fits in your pocket
        </div>
    </div>
</body>
</html>"""
    return html

def main():
    DASHBOARD_DIR.mkdir(exist_ok=True)
    jobs = load_cron_jobs()
    html = generate_html(jobs)
    OUTPUT_FILE.write_text(html)
    print(f"Dashboard generated: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
