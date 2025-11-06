#!/usr/bin/env bash
echo "Clean up pid if it exists."
rm -rf /var/run/squid.pid

echo "Consolidating domain lists..."
# Create a temporary file for consolidated domains
CONSOLIDATED_DOMAINS_FILE="/etc/squid/all-allowed-domains.txt"
> "$CONSOLIDATED_DOMAINS_FILE" # Clear the file if it exists

# Loop through all files in the domain-lists.d directory and concatenate them
for file in /etc/squid/domain-lists.d/*; do
    if [ -f "$file" ]; then
        cat "$file" >> "$CONSOLIDATED_DOMAINS_FILE"
        echo "" >> "$CONSOLIDATED_DOMAINS_FILE" # Add a newline for separation
    fi
done

echo "Starting log watcher"
tail -vn 0 -F /var/log/squid/access.log /var/log/squid/cache.log &

echo "Starting Squid"
/usr/sbin/squid -NYCd 3