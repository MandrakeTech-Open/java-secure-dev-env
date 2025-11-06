#!/usr/bin/env sh
echo "Clean up pid if it exists."
rm -rf /var/run/squid.pid

echo "Consolidating CRL regex lists..."
CRL_REGEX_FILE="/etc/squid/crl-regex.txt"
> "$CRL_REGEX_FILE" # Clear the file if it exists
for file in /etc/squid/crl-lists.d/*.txt; do
    if [ -f "$file" ]; then
        cat "$file" >> "$CRL_REGEX_FILE"
        echo "" >> "$CRL_REGEX_FILE" # Add a newline for separation
    fi
done

echo "Consolidating domain lists..."
CONSOLIDATED_DOMAINS_FILE="/etc/squid/all-allowed-domains.txt"
> "$CONSOLIDATED_DOMAINS_FILE" # Clear the file if it exists
for file in /etc/squid/domain-lists.d/*.txt; do
    if [ -f "$file" ]; then
        cat "$file" >> "$CONSOLIDATED_DOMAINS_FILE"
        echo "" >> "$CONSOLIDATED_DOMAINS_FILE" # Add a newline for separation
    fi
done

echo "Starting log watcher"
tail -vn 0 -F /var/log/squid/access.log /var/log/squid/cache.log &

echo "Starting Squid"
/usr/sbin/squid -NYCd 1
