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
ENTRYPOINT [ "/usr/lib/systemd/systemd-journal-remote", \
    "--listen-https=19532", "--key=/etc/journal-remote.key", "--cert=/etc/journal-remote.crt", "--trust=/etc/journal-remote.ca.crt" ]