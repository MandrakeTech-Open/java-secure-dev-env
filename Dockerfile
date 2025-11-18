ARG JDK_VERSION=25
FROM bellsoft/liberica-openjdk-alpine:${JDK_VERSION}

# Install required packages using Debian package manager
RUN apk update && \
    apk add --no-cache \
    bash \
    git \
    curl \
    unzip \
    libstdc++ \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
# Create code directory and set proper ownership/permissions
	mkdir /code

VOLUME ["/code"]

CMD ["sleep", "infinity"]
