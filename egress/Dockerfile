FROM alpine:latest

RUN apk add --no-cache \
	bash \
    ca-certificates \
    squid \
    curl

# Create squid user and directories
RUN mkdir -p /var/cache/squid /var/log/squid && \
    chown -R squid:squid /var/cache/squid /var/log/squid

# Initialize squid cache directories
RUN squid -z

EXPOSE 3128

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
