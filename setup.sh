#!/bin/bash
# setup.sh - Initialize the development environment

set -e

echo "Setting up Docker Compose development environment..."

# Create directory structure
mkdir -p caddy database/init dev proxy

# Check if SSH key exists
ssh_key_type=ed25519
ssh_pub_key_filename="${HOME}/.ssh/id_${ssh_key_type}.pub"

if [ ! -f "${ssh_pub_key_filename}" ]; then
    echo "Warning: No SSH public key found at ${ssh_pub_key_filename}"
    echo "Please generate an SSH key pair first:"
    echo "  ssh-keygen -C 'your_email@example.com' -t ${ssh_key_type} ${ssh_pub_key_filename}"
    exit 1
fi

# Create the configuration files (these would be created by the artifacts above)
echo "Configuration files should be created from the artifacts above"

echo "Building and starting services..."
docker compose up --build -d

echo "Waiting for services to be ready..."
sleep 10

echo "Checking service status..."
docker compose ps

echo ""
echo "Setup complete! Your development environment is ready."
echo ""
echo "Services:"
echo "  - Ingress (Caddy): https://www.localhost"
echo "  - Dev container SSH: ssh dev@localhost -p 2222"
echo "  - Database: PostgreSQL on internal network"
echo "  - Egress: Squid on http://egress:3128 on internal network"
echo ""
echo "To connect to the dev container:"
echo "  ssh dev@localhost -p 2222"
echo ""
echo "To view logs:"
echo "  docker compose logs -f [service_name]"
echo ""
echo "To stop:"
echo "  docker compose down"
