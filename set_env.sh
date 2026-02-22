#!/bin/bash

# Quick environment setup for Kamal deployment
# Usage: 
#   ./set_env.sh "your_docker_hub_password" "your_postgres_password"
# OR set them manually:
#   export KAMAL_REGISTRY_PASSWORD="your_docker_hub_password"
#   export POSTGRES_PASSWORD="your_postgres_password"

if [ $# -eq 2 ]; then
    export KAMAL_REGISTRY_PASSWORD="$1"
    export POSTGRES_PASSWORD="$2"
    echo "✅ Environment variables set!"
    echo "KAMAL_REGISTRY_PASSWORD: SET"
    echo "POSTGRES_PASSWORD: SET"
else
    echo "Usage: $0 <docker_hub_password> <postgres_password>"
    echo ""
    echo "Or set manually:"
    echo "export KAMAL_REGISTRY_PASSWORD='your_docker_hub_password'"
    echo "export POSTGRES_PASSWORD='your_postgres_password'"
    echo ""
    echo "Current status:"
    echo "KAMAL_REGISTRY_PASSWORD: ${KAMAL_REGISTRY_PASSWORD:-NOT SET}"
    echo "POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-NOT SET}"
fi
