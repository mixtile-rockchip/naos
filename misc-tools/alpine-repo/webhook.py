#!/usr/bin/env python3

from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import hmac

SECRET_TOKEN = "AKIA2RCKRCDLOGUZQINR"

class WebhookHandler(BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'
    
    def do_GET(self):
        try:
            print(f"Received request from {self.client_address[0]}")
            
            self.close_connection = True

            if not self._verify_token():
                self._send_response(401, "Invalid token")
                return

            if self.path == "/webhook/reboot":
                result = subprocess.run(["echo", "reboot command received"],
                                      capture_output=True, text=True, timeout=5)
            elif self.path == "/webhook/update/index":
                result = subprocess.run([
                    "docker", "exec", "-w", "/data/alpine/x86_64", "alpine-repo",
                    "sh", "-c", "apk index -o APKINDEX.tar.gz *.apk"
                ], capture_output=True, text=True, timeout=30)
            elif self.path == "/webhook/status":
                result = subprocess.run(["uptime"], capture_output=True, text=True, timeout=5)
            else:
                self._send_response(404, "Command not found")
                return

            self._send_response(200, f"Command executed:\n{result.stdout}")

        except Exception as e:
            self._send_response(500, f"Error: {str(e)}")

    def _verify_token(self):
        token = self.headers.get('X-Webhook-Token', '')
        return hmac.compare_digest(token, SECRET_TOKEN)

    def _send_response(self, code, message):
        self.send_response(code)
        self.send_header('Content-type', 'text/plain')
        self.send_header('Connection', 'close')
        self.send_header('Content-Length', str(len(message.encode())))
        self.end_headers()
        self.wfile.write(message.encode())
        self.wfile.flush()

    def log_message(self, format, *args):
        print(f"Webhook: {self.client_address[0]} - {format % args}")

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), WebhookHandler)
    print("Webhook server running on port 8080...")
    server.serve_forever()

