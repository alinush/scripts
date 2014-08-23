#!/usr/bin/env python

"""
Starts a python http server in the current working directory.
Autoindexes files.
"""

import argparse
import BaseHTTPServer
from SimpleHTTPServer import SimpleHTTPRequestHandler

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Simple HTTP Server in current directory')

    parser.add_argument('--port', dest='port', type=int, default=8000,
        help='default 8000')

    parser.add_argument('--addr', dest='addr', type=str, default='127.0.0.1',
        help='default 127.0.0.1')

    args = parser.parse_args()

    httpRequestHandler = SimpleHTTPRequestHandler
    httpRequestHandler.protocol_version = "HTTP/1.1"
    bindAddress = (args.addr, args.port)
    httpServer = BaseHTTPServer.HTTPServer


    httpd = BaseHTTPServer.HTTPServer(bindAddress, httpRequestHandler)

    sa = httpd.socket.getsockname()

    print "Serving HTTP on", sa[0], "port", sa[1], "..."

    httpd.serve_forever()
