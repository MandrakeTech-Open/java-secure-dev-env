FROM bellsoft/liberica-openjdk-alpine:latest-cds

RUN apk add --no-cache bash git curl unzip openssh-server openssh-client

# Create user and setup SSH as root
RUN adduser -g "dev user" -D -s /bin/bash dev && \
    # change the password and unlock ssh && \
    echo "dev:dev" | chpasswd

RUN mkdir -p /home/dev/.ssh /code && \
    chown -R dev:dev /home/dev/.ssh /code && \
    chmod 700 /home/dev/.ssh && \
    ssh-keygen -A

# Configure SSH daemon
RUN mkdir -p /etc/ssh/sshd_config.d && \
    cat <<EOF > /etc/ssh/sshd_config.d/user-dev-enable.conf
# PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ListenAddress 0.0.0.0
ListenAddress ::
HostKey /etc/ssh/ssh_host_ed25519_key
AllowUsers dev
EOF

EXPOSE 22

VOLUME ["/code"]

RUN touch /entrypoint.sh && \
    chmod +x /entrypoint.sh && \
    cat <<'EOF' > /entrypoint.sh
#!/usr/bin/env bash
# fail on error
set -e

if [[ ! -f /etc/ssh/ssh_host_ed25519_key ]]; then
    echo "Generating host key"
    ssh-keygen -t ed25519 -C "default key" -N "" -f "/etc/ssh/ssh_host_ed25519_key"
fi

if [[ -f /home/dev/host/ssh_key_public ]]; then
    echo "Copy public key to authorized_keys"
    cp /home/dev/host/ssh_key_public /home/dev/.ssh/authorized_keys
    chown dev:dev /home/dev/.ssh/authorized_keys
    chmod 400 /home/dev/.ssh/authorized_keys
fi

if [[ -f /home/dev/host/ssh_key_private ]]; then
    echo "Copy private key to ssh folder"
    # cp /home/dev/host/ssh_key_public /home/dev/.ssh/id_ed25519.pub
    cp /home/dev/host/ssh_key_private /home/dev/.ssh/id_ed25519
    chown dev:dev /home/dev/.ssh/id_ed25519
    chmod 400 /home/dev/.ssh/id_ed25519
fi

# if [[ ! -f /home/dev/.ssh/id_ed25519 ]] ; then
#     echo "No private key found. Generating one."
#     ssh-keygen -t ed25519 -C "secure-dev-key" -N "" -f "/home/dev/.ssh/id_ed25519"
# fi

if [[ ! -f /home/dev/.ssh/authorized_keys ]]; then
    echo "No authorized key file found. Cannot enable sshd. Running tail."
    exec tail -f /dev/null
else
    echo "Starting sshd server"
    exec /usr/sbin/sshd -De
fi

echo "Done"
EOF

ENTRYPOINT [ "/entrypoint.sh" ]
