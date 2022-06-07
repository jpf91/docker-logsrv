FROM docker.io/rockylinux:8

RUN dnf update -y && \
    dnf install -y rsyslog rsyslog-gnutls && \
    dnf clean all

COPY --chmod=644 rsyslog.conf /etc/rsyslog.conf

ENTRYPOINT [ "/usr/sbin/rsyslogd", "-n" ]