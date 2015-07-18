FROM debian

##### install ssh without private keys
RUN    apt-get update \
    && apt-get install -y ssh

RUN    mkdir /var/run/sshd \
    && sed s/101/0/ /usr/sbin/policy-rc.d \
    && rm -f /etc/ssh/*_key*

COPY sshd_config /etc/ssh/sshd_config
COPY ssh-init    /ssh-init
COPY LoginSleep  /usr/local/bin/LoginSleep

ENTRYPOINT ["/ssh-init"]
CMD ["sshd"]

EXPOSE 22
