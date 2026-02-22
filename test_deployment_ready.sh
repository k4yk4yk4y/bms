#!/bin/bash

echo "=== Kamal Deployment Readiness Check ==="
echo ""

# Check environment variables
echo "1. Environment Variables:"
if [ -n "$KAMAL_REGISTRY_PASSWORD" ]; then
    echo "   ✅ KAMAL_REGISTRY_PASSWORD is set"
else
    echo "   ❌ KAMAL_REGISTRY_PASSWORD is not set"
fi

if [ -n "$POSTGRES_PASSWORD" ]; then
    echo "   ✅ POSTGRES_PASSWORD is set"
else
    echo "   ❌ POSTGRES_PASSWORD is not set"
fi

echo ""

# Check SSH connection
echo "2. SSH Connection:"
if ssh -o ConnectTimeout=5 -o BatchMode=yes root@165.22.206.225 echo "SSH OK" 2>/dev/null; then
    echo "   ✅ SSH connection to 165.22.206.225 successful"
else
    echo "   ❌ SSH connection failed - need to add SSH key to server"
fi

echo ""

# Check Kamal config
echo "3. Kamal Configuration:"
if bin/kamal config >/dev/null 2>&1; then
    echo "   ✅ Kamal configuration is valid"
else
    echo "   ❌ Kamal configuration has issues"
fi

echo ""

# Summary
echo "=== Summary ==="
if [ -n "$KAMAL_REGISTRY_PASSWORD" ] && [ -n "$POSTGRES_PASSWORD" ] && ssh -o ConnectTimeout=5 -o BatchMode=yes root@165.22.206.225 echo "SSH OK" >/dev/null 2>&1; then
    echo "🎉 Ready to deploy! Run: bin/kamal deploy"
else
    echo "⚠️  Setup incomplete. Please:"
    if [ -z "$KAMAL_REGISTRY_PASSWORD" ] || [ -z "$POSTGRES_PASSWORD" ]; then
        echo "   - Set environment variables: source ./set_env.sh"
    fi
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes root@165.22.206.225 echo "SSH OK" >/dev/null 2>&1; then
        echo "   - Add SSH key to server (see DEPLOYMENT_SETUP.md)"
    fi
fi
