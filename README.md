# docker-logsrv

## Running the log server

### Generating certificates

```bash
cd data/cert

# Setup the CA key
openssl ecparam -name prime256v1 -genkey -noout -out ca.key
openssl req -new -x509 -sha256 -key ca.key -out ca.crt
openssl x509 -in ca.crt -noout -text

# Setup the log server key
openssl ecparam -name prime256v1 -genkey -noout -out logsrv.key
openssl req -new -sha256 -key logsrv.key -out logsrv.csr
openssl x509 -req -in logsrv.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out logsrv.crt -sha256
```

Note: Do not set the same CN for the CA certificate and for your logsrv certificate, otherwise rsyslog will think
it's self-signed and complain! For the CA just use a CN such as `Foo LTD Log CA`.

## Configuring cockpit

If you're using a proxy in front of cockpit, you'll probably have to change the cockpit configuration
to allow an external origin.

Create the configuration `data/cockpit.conf` with this content:

```ini
[WebService]
Origins = https://logs.example.com
```
You may also want to add `LoginTo = false` to remote the remote connect option from the login page.

Then add the volume mount to the `cockpit` entry in `docker-compose.yml`:

```
- "./data/cockpit.conf:/etc/cockpit/cockpit.conf:Z"
```

### Running

To run everything:

```bash
docker-compose up
```

## Setting up clients

First, create a client certificate in the `data/cert` folder:

```bash
export CLIENT_HOSTNAME=foo.example.com
openssl ecparam -name prime256v1 -genkey -noout -out $CLIENT_HOSTNAME.key
openssl req -new -sha256 -key $CLIENT_HOSTNAME.key -out $CLIENT_HOSTNAME.csr
openssl x509 -req -in $CLIENT_HOSTNAME.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out $CLIENT_HOSTNAME.crt -sha256
```

Copy the files to the remote host:
* `$CLIENT_HOSTNAME.key` => `/etc/ssl/certs/journal-upload.key`
* `$CLIENT_HOSTNAME.crt` => `/etc/ssl/certs/journal-upload.crt`
* `ca.crt` => `/etc/ssl/certs/journal-upload-ca.crt`

### Using journal-remote

Install package:
```bash
 dnf install systemd-journal-remote
 ```

Create a user for the `systemd-journald-upload` service, so that it can access the cert files:
```bash
adduser --system --home-dir /run/systemd --no-create-home --shell /usr/sbin/nologin --user-group systemd-journal-upload
```

Adjust the permissions, to make sure only root and journald user can read the certs:
```bash
chmod 640 /etc/ssl/certs/journal-upload.key
chown root:systemd-journal-upload /etc/ssl/certs/journal-upload.key
chmod 640 /etc/ssl/certs/journal-upload.crt
chown root:systemd-journal-upload /etc/ssl/certs/journal-upload.crt
chmod 640 /etc/ssl/certs/journal-upload-ca.crt
chown root:systemd-journal-upload /etc/ssl/certs/journal-upload-ca.crt
```

Configure `/etc/systemd/journal-upload.conf`:
```ini
[Upload]
URL=https://logsrv.example.com:19532
ServerKeyFile=/etc/ssl/certs/journal-upload.key
ServerCertificateFile=/etc/ssl/certs/journal-upload.crt
TrustedCertificateFile=/etc/ssl/certs/journal-upload-ca.crt
```

And start the upload daemon:
```bash
 systemctl enable --now systemd-journal-upload
```

### Using rsyslogd

Install package:
```bash
 dnf install rsyslog rsyslog-gnutls
 ```

Adjust the permissions, to make sure only root can read the certs:
```bash
chmod 640 /etc/ssl/certs/journal-upload.key
chown root:root /etc/ssl/certs/journal-upload.key
chmod 640 /etc/ssl/certs/journal-upload.crt
chown root:root /etc/ssl/certs/journal-upload.crt
chmod 640 /etc/ssl/certs/journal-upload-ca.crt
chown root:root /etc/ssl/certs/journal-upload-ca.crt
```

Configure `/etc/rsyslog.conf`:
```ini
# Our CA for logs.example.com
$DefaultNetStreamDriverCAFile /etc/ssl/certs/journal-upload-ca.crt
$DefaultNetstreamDriverCertFile /etc/ssl/certs/journal-upload.crt
$DefaultNetstreamDriverKeyFile /etc/ssl/certs/journal-upload.key
$DefaultNetStreamDriver gtls
$ActionSendStreamDriverMode 1
$ActionSendStreamDriverAuthMode anon

*.*     @@(o)logs.example.com:6514
```

And start the upload daemon:
```bash
 systemctl enable --now rsyslog
```

## Development setup

### Building containers locally

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

### Sending test data to the journal

This sends some test data directly to the journal, using TLS and certificates:

```
curl https://127.0.0.1:19532/upload \
   -H 'Content-Type: application/vnd.fdo.journal'  \
   --data-binary $'__REALTIME_TIMESTAMP=1654518724000000\n_HOSTNAME=test-host\nMESSAGE=Test message\n\n' --insecure --key /path/to/hostname.key --cert /path/to/hostname.crt -v
```

The Timestamp should be a unix timestamp in microseconds (Use `date +%s` and append `000000`). For the client certs `hostname.key` / `hostname.crt` you can either use client certs as explained above or you can just use the `logsrv` key.

### Unencrypted Syslog TCP

```bash
logger -n 127.0.0.1 -P 514 --tcp "Test message TCP"
```

### Syslog UDP

```bash
logger -n 127.0.0.1 -P 514 "Test message UDP"
```

## Related Links

Some more information about rsyslog and journald logging:

* https://www.freedesktop.org/software/systemd/man/systemd-journal-remote.service.html
* https://docs.fedoraproject.org/en-US/Fedora/22/html/System_Administrators_Guide/s1-interaction_of_rsyslog_and_journal.html
* https://rsyslog.readthedocs.io/en/latest/configuration/modules/omjournal.html
* https://www.digitalocean.com/community/tutorials/how-to-centralize-logs-with-journald-on-debian-10
