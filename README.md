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