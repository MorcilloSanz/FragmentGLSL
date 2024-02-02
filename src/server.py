"""
https://docs.python.org/es/3/library/http.server.html
Simple http server in python
"""

import http.server
import socketserver

PORT = 9000

Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print("serving at port", PORT)
    httpd.serve_forever()