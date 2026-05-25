#!/usr/bin/env python3
"""Lightweight HTTP server for the dashboard."""

import http.server
import socketserver
import os
import threading

PORT = 8080
DIRECTORY = os.path.expanduser("~/.hermes/dashboard")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def do_GET(self):
        if self.path == '/kill':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'Server shutting down...')
            # Shutdown after sending response
            threading.Thread(target=self.server.shutdown).start()
            return
        return super().do_GET()
    
    def log_message(self, format, *args):
        """Suppress default logging."""
        pass

def main():
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Dashboard running at http://localhost:{PORT}")
        print("Press Ctrl+C or click 'Kill Server' to stop")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped")

if __name__ == "__main__":
    main()
