#!/bin/bash

# Set password from environment
echo "root:$ROOT_PASSWORD" | chpasswd

# TLS is handled by nginx proxy
exec /usr/libexec/cockpit-ws --no-tls