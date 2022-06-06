FROM registry.fedoraproject.org/fedora:36

RUN dnf update -y && \
    dnf install -y util-linux-core sed cockpit-ws cockpit-bridge cockpit-system systemd && \
    dnf clean all

# Disable pam_loginuid.so as it somehow causes root logins to fail.
# Problem seems similar to this: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=726661
RUN sed -e '/pam_loginuid/d' -i /etc/pam.d/cockpit

# Hack: Force cockpit to always set --merge for journalctl
RUN mv /usr/bin/journalctl /usr/bin/journalctl.real
COPY --chmod=755 journalctl /usr/bin/journalctl

# Original image does this for the host pam file, but seems to work fine so far for us
#RUN sed -e '/pam_selinux/d' -e '/pam_sepermit/d' -i /etc/pam.d/cockpit

COPY --chmod=755 start.sh /usr/bin/start.sh
ENTRYPOINT [ "/usr/bin/start.sh" ]