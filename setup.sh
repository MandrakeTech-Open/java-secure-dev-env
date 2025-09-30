#!/usr/bin/env bash
# setup.sh - Initialize the development environment

docker_compose_cmd="docker compose"

echo "Setting up Docker Compose development environment..."

if [[ ! -d ./secrets ]]; then
    # Create directory structure
    mkdir secrets
fi

# Check if SSH key exists
ssh_key_prefix=id
ssh_key_type=ed25519
ssh_pub_key_filename="${HOME}/.ssh/${ssh_key_prefix}_${ssh_key_type}.pub"

if [ ! -f "${ssh_pub_key_filename}" ]; then
    echo "Warning: No SSH public key found at ${ssh_pub_key_filename}"
    echo "Please generate an SSH key pair first:"
    echo "  ssh-keygen -C 'comment-to-identify-key' -t ${ssh_key_type} ${ssh_pub_key_filename}"
    exit 1
fi

# Create the configuration files (these would be created by the artifacts above)
echo "Configuration files should be created from the artifacts above"

echo "Building and starting services..."
${docker_compose_cmd} -f docker-compose.yml up -d

echo "Waiting for services to be ready..."
sleep 10

echo "Checking service status..."
${docker_compose_cmd} ps

echo ""
echo "Setup complete! Your development environment is ready."
echo ""
echo "Services:"
echo "  - Ingress: https://www.localhost:8443"
echo "  - Dev container SSH: ssh dev@localhost -p 2222"
echo "  - Database: PostgreSQL on internal network"
echo "  - egress: Squid on http://egress:3128 on internal network"
echo ""
echo "To connect to the dev container:"
echo "  ssh dev@localhost -p 2222"
echo ""
echo "To view logs:"
echo "  ${docker_compose_cmd} logs -f [service_name]"
echo ""
echo "To stop:"
echo "  ${docker_compose_cmd} down"
