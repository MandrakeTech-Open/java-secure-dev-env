#!/usr/bin/env sh
echo "Clean up pid if it exists."
rm -rf /var/run/squid.pid

# Function to consolidate CRL and domain lists
consolidate_files() {
    echo "Consolidating CRL regex lists..."
    CRL_REGEX_FILE="/etc/squid/crl-regex.txt"
    echo "" > "$CRL_REGEX_FILE" # Clear the file if it exists
    for file in /etc/squid/crl-lists.d/*.txt; do
        if [ -f "$file" ]; then
            cat "$file" >> "$CRL_REGEX_FILE"
            echo "" >> "$CRL_REGEX_FILE" # Add a newline for separation
        fi
    done

    echo "Consolidating domain lists..."
    CONSOLIDATED_DOMAINS_FILE="/etc/squid/all-allowed-domains.txt"
    echo "" > "$CONSOLIDATED_DOMAINS_FILE" # Clear the file if it exists
    for file in /etc/squid/domain-lists.d/*.txt; do
        if [ -f "$file" ]; then
            cat "$file" >> "$CONSOLIDATED_DOMAINS_FILE"
            echo "" >> "$CONSOLIDATED_DOMAINS_FILE" # Add a newline for separation
        fi
    done
    echo "File consolidation complete."
}

# Initial consolidation
consolidate_files

# Start file watcher in the background
echo "Starting file watcher for configuration changes..."
inotifywait -m -e modify,create,delete,move /etc/squid/crl-lists.d /etc/squid/domain-lists.d |
while read -r path action file; do
    echo "Detected change in $path/$file ($action). Re-consolidating files and reloading Squid..."
    consolidate_files
    squid -k reconfigure
    echo "Squid reconfigured."
done &

echo "Starting log watcher"
tail -vn 0 -F /var/log/squid/access.log /var/log/squid/cache.log &

echo "Starting Squid"
exec /usr/sbin/squid -NYCd 1
