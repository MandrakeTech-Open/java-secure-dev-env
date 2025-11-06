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

COPY crl-lists.d/ /etc/squid/crl-lists.d/

# Concatenate all CRL regex files into a single file for Squid
RUN cat /etc/squid/crl-lists.d/*.txt > /etc/squid/crl-regex.txt

COPY domain-lists.d/ /etc/squid/domain-lists.d/

# Concatenate all allowed domain files into a single file for Squid
RUN cat /etc/squid/domain-lists.d/*.txt > /etc/squid/all-allowed-domains.txt

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
