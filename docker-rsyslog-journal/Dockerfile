FROM docker.io/rockylinux:8

RUN dnf update -y && \
    dnf install -y rsyslog rsyslog-gnutls && \
    dnf clean all

COPY --chmod=644 rsyslog.conf /etc/rsyslog.conf

COPY --chmod=755 start.sh /usr/bin/start.sh
ENTRYPOINT [ "/usr/bin/start.sh" ]