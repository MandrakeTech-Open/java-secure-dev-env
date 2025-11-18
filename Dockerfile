FROM bellsoft/liberica-openjdk-debian:latest-cds

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages using Debian package manager
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    git \
    curl \
    unzip \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create user and set a simple password for development use
RUN adduser --disabled-password --comment "dev user" --shell /bin/bash dev

# Create code directory and set proper ownership/permissions
RUN mkdir -p /code && \
    chown -R dev:dev /code

VOLUME ["/code"]

# Entrypoint script: starts the Java application
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
