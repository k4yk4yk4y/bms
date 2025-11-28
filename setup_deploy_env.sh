#!/bin/bash

# Kamal Deployment Environment Setup Script
# Run this script to set up the required environment variables for deployment

echo "=== Kamal Deployment Environment Setup ==="
echo ""

# Check if environment variables are already set
if [ -n "$KAMAL_REGISTRY_PASSWORD" ]; then
    echo "✓ KAMAL_REGISTRY_PASSWORD is already set"
else
    echo "❌ KAMAL_REGISTRY_PASSWORD is not set"
    echo ""
    echo "Please enter your Docker Hub password or access token for user 'k4yk4yk4y':"
    echo "(You can create an access token at: https://hub.docker.com/settings/security)"
    read -s -p "Docker Hub Password/Token: " DOCKER_PASSWORD
    export KAMAL_REGISTRY_PASSWORD="$DOCKER_PASSWORD"
    echo ""
    echo "✓ KAMAL_REGISTRY_PASSWORD has been set for this session"
fi

echo ""

if [ -n "$POSTGRES_PASSWORD" ]; then
    echo "✓ POSTGRES_PASSWORD is already set"
else
    echo "❌ POSTGRES_PASSWORD is not set"
    echo ""
    echo "Please enter your PostgreSQL password:"
    read -s -p "PostgreSQL Password: " PG_PASSWORD
    export POSTGRES_PASSWORD="$PG_PASSWORD"
    echo ""
    echo "✓ POSTGRES_PASSWORD has been set for this session"
fi

echo ""
echo "=== Environment Variables Status ==="
echo "KAMAL_REGISTRY_PASSWORD: ${KAMAL_REGISTRY_PASSWORD:+SET}"
echo "POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:+SET}"
echo ""

# Save to a temporary file for this session
echo "export KAMAL_REGISTRY_PASSWORD='$KAMAL_REGISTRY_PASSWORD'" > /tmp/kamal_env
echo "export POSTGRES_PASSWORD='$POSTGRES_PASSWORD'" >> /tmp/kamal_env

echo "Environment variables have been set for this session."
echo "To load them in future sessions, run: source /tmp/kamal_env"
echo ""
echo "=== Next Steps ==="
echo "1. Make sure your SSH key is added to the server (165.22.206.225)"
echo "2. Test SSH connection: ssh root@165.22.206.225"
echo "3. Run: bin/kamal deploy"
