FROM alpine:latest

RUN apk add --no-cache \
    ca-certificates \
    squid

# Create squid user and directories
RUN mkdir -p /var/cache/squid /var/log/squid && \
    chown -R squid:squid /var/cache/squid /var/log/squid

# Initialize squid cache directories
RUN squid -z

EXPOSE 3128

WORKDIR /

RUN cat <<EOF > entrypoint.sh
#!/bin/sh
echo "Clean up pid if it exists."
rm -rf /var/run/squid.pid
echo "Starting log watcher"
tail -vn 0 -F /var/log/squid/access.log /var/log/squid/cache.log &
echo "Starting Squid"
/usr/sbin/squid -NYCd 1
EOF

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
