#!/usr/bin/env sh
echo "Clean up pid if it exists."
rm -rf /var/run/squid.pid

echo "Starting log watcher"
tail -vn 0 -F /var/log/squid/access.log /var/log/squid/cache.log &

echo "Starting Squid"
/usr/sbin/squid -NYCd 3
