#!/bin/bash

CERT_FILE="/etc/rsyslog.cert.pem"

# Get latest change time of vertificate file
function get_cert_time {
    if [ -f "$CERT_FILE" ]; then
        CERT_TIME=$(date -r "$CERT_FILE" +%s)
    else
        CERT_TIME=0
    fi
}

# See if certificate file changed and send kill to rsyslog if it did
function monitor_cert {
    get_cert_time
    ORIG_TIME=$CERT_TIME
    while true
    do
        sleep 10
        get_cert_time
        if [ "$ORIG_TIME" -ne "$CERT_TIME" ]; then
            echo "Certificate changed, killing rsyslogd"
            pkill rsyslog
            return
        fi
    done
}

while true
do
    # Start monitor in background
    monitor_cert &

    # And rsyslog in front
    get_cert_time
    "/usr/sbin/rsyslogd" "-n"
    EXIT_CODE=$?

    ORIG_TIME=$CERT_TIME
    get_cert_time

    # If there was no cert change, exit
    if [ "$ORIG_TIME" -eq "$CERT_TIME" ]; then
        exit $EXIT_CODE
    fi

    echo "Restarting rsyslog because of certificate change"
done