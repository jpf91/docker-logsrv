#!/bin/bash

# Set password from environment
if [ -n "$ROOT_PASSWORD" ]; then
    echo "root:$ROOT_PASSWORD" | chpasswd
fi

# TLS is handled by nginx proxy
exec /usr/libexec/cockpit-ws --no-tls