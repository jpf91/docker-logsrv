## Building containers

To build the `journal-remote` container:

```bash
cd docker-journal-remote
docker build . -t ghcr.io/jpf91/journal-remote:latest
```

To build the `rsyslog-journal` container:

```bash
cd docker-rsyslog-journal
docker build . -t ghcr.io/jpf91/rsyslog-journal:latest
```

To build the `cockpit-journal` container:

```bash
cd docker-cockpit-journal
docker build . -t ghcr.io/jpf91/cockpit-journal:latest
```

## Generating certificates

```bash
cd data/certs

# Setup the CA key
openssl ecparam -name prime256v1 -genkey -noout -out ca.key
openssl req -new -x509 -sha256 -key ca.key -out ca.crt
openssl x509 -in ca.crt -noout -text

# Setup the log server key
openssl ecparam -name prime256v1 -genkey -noout -out logsrv.key
openssl req -new -sha256 -key logsrv.key -out logsrv.csr
openssl x509 -req -in logsrv.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out logsrv.crt -sha256

# For each client:
openssl ecparam -name prime256v1 -genkey -noout -out client-hostname.key
openssl req -new -sha256 -key client-hostname.key -out client-hostname.csr
openssl x509 -req -in client-hostname.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client-hostname.crt -sha256
```

## Adjusting the cockpit remote origin

If you're using a procy in front of cockpit, you'll probably have to change the cockpit configuration
to allow this external origin.

Create the configuration `data/cockpit.conf` with this content:

```ini
[WebService]
Origins = https://logs.example.com
```

Then add the volume mount to the `cockpit` entry in `docker-compose.yml`:

```
- "./data/cockpit.conf:/etc/cockpit/cockpit.conf:Z"
```

## Running


The images use privileged ports, so to run them using podman, you'll have to use the root mode system socket:

```bash
sudo -i
export DOCKER_HOST=unix:///var/run/podman/podman.sock
```

To run everything using podman or docker:

```bash
docker-compose up
```

## Testing

### Sending data to the journal
```
curl http://127.0.0.1:19532/upload \
   -H 'Content-Type: application/vnd.fdo.journal'  \
   --data-binary $'__REALTIME_TIMESTAMP=1654518724000000\n_HOSTNAME=test-host\nMESSAGE=Test message\n\n' -v
```

The Timestamp should be a unix timestamp in microseconds (Use `date +%s` and append `000000`).

### Syslog TCP

```bash
logger -n 127.0.0.1 -P 514 --tcp "Test message"
```

### Syslog UDP

```bash
logger -n 127.0.0.1 -P 514 "Test message"
```

## Related Links

Some more information about rsyslog and journald logging:

* https://www.freedesktop.org/software/systemd/man/systemd-journal-remote.service.html
* https://docs.fedoraproject.org/en-US/Fedora/22/html/System_Administrators_Guide/s1-interaction_of_rsyslog_and_journal.html
* https://rsyslog.readthedocs.io/en/latest/configuration/modules/omjournal.html
* https://www.digitalocean.com/community/tutorials/how-to-centralize-logs-with-journald-on-debian-10