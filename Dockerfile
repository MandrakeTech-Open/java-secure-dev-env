FROM bellsoft/liberica-openjdk-debian:latest-cds

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages using Debian package manager
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    git \
    curl \
    unzip \
    openssh-server \
    openssh-client \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Ensure sshd runtime directories exist
RUN mkdir -p /run/sshd /var/run/sshd

# Create user and set a simple password for development use
RUN adduser --disabled-password --comment "dev user" --shell /bin/bash dev && \
    echo "dev:dev" | chpasswd

# Create code and ssh directories and set proper ownership/permissions
RUN mkdir -p /code /home/dev/.ssh && \
    chown -R dev:dev /code /home/dev/.ssh && \
    chmod 700 /home/dev/.ssh

# Configure SSH daemon (additional configuration file)
RUN mkdir -p /etc/ssh/sshd_config.d

COPY sshd-config/* /etc/ssh/sshd_config.d

# Generate host keys if necessary
RUN ssh-keygen -A

EXPOSE 22

VOLUME ["/code"]

# Entrypoint script: generates host key if missing, copies user keys if provided, and starts sshd
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
