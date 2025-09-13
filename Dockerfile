FROM bellsoft/liberica-openjdk-debian:latest-cds

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages using Debian package manager
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    git \
    curl \
    unzip \
    openssh-client \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create user and set a simple password for development use
RUN adduser --disabled-password --comment "dev user" --shell /bin/bash dev && \
    echo "dev:dev" | chpasswd

# Create code and ssh directories and set proper ownership/permissions
RUN mkdir -p /code /home/dev/.ssh && \
    chown -R dev:dev /code /home/dev/.ssh

VOLUME ["/code"]

# Entrypoint script: generates host key if missing, copies user keys if provided, and starts sshd
RUN cat > /entrypoint.sh <<'EOF' && chmod +x /entrypoint.sh
#!/usr/bin/env bash
set -e

if [[ -f /home/dev/host/ssh_key_private ]]; then
    echo "Copy private key to ssh folder"
    cp /home/dev/host/ssh_key_private /home/dev/.ssh/id_ed25519
    chown dev:dev /home/dev/.ssh/id_ed25519
    chmod 400 /home/dev/.ssh/id_ed25519
else
    echo "private ssh key not available. git ssh interaction will not work."
fi

echo "wait infinite using tail -f /dev/null"
exec tail -f /dev/null
EOF

ENTRYPOINT [ "/entrypoint.sh" ]
