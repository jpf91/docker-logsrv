FROM docker.io/rockylinux:8

RUN dnf update -y && \
    dnf install -y systemd-journal-remote && \
    dnf clean all

# No need to modify /etc/systemd/journal-remote.conf
COPY --chmod=644 journald.conf /etc/systemd/journald.conf

# Default log location must exist for split-host mode
RUN mkdir /var/log/journal/remote

# Get some logs from journal-remote
ENV SYSTEMD_LOG_LEVEL notice
# TLS is handled by nginx proxy, so we don't have to worry about certificate updates
ENTRYPOINT [ "/usr/lib/systemd/systemd-journal-remote", "--listen-http=19532" ]