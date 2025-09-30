FROM caddy:2-alpine

COPY Caddyfile /etc/caddy/Caddyfile

RUN caddy fmt --config /etc/caddy/Caddyfile --overwrite
