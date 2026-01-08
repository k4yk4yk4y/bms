#!/bin/bash
# PostgreSQL Setup Script for BMS Rails Application
# Run this script to install and configure PostgreSQL for local development

set -e

echo "=== PostgreSQL Setup for BMS ==="
echo ""

# Check if PostgreSQL is installed and running
if ! command -v psql &> /dev/null; then
    echo "⚠ PostgreSQL client (psql) is not installed."
    echo "Please install PostgreSQL:"
    echo "   sudo apt update"
    echo "   sudo apt install -y postgresql postgresql-contrib"
    echo ""
    exit 1
fi

if ! pg_isready -h localhost &> /dev/null; then
    echo "⚠ PostgreSQL server is not running."
    echo "Please start PostgreSQL:"
    echo "   sudo systemctl start postgresql"
    echo "   sudo systemctl enable postgresql"
    echo ""
    exit 1
fi

echo "✓ PostgreSQL is installed and running!"
echo ""

# Check if the current user exists as a PostgreSQL role
# Try to connect using peer authentication first (local socket)
if psql -U "$USER" -d postgres -c "SELECT 1;" &> /dev/null; then
    echo "✓ PostgreSQL role '$USER' exists and can connect!"
elif sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname = '$USER'" | grep -q 1 2>/dev/null; then
    echo "✓ PostgreSQL role '$USER' exists!"
else
    echo "⚠ PostgreSQL role '$USER' does not exist."
    echo ""
    echo "Please create the PostgreSQL role by running:"
    echo "   sudo -u postgres createuser -s $USER"
    echo ""
    echo "Or connect as postgres user and create it:"
    echo "   sudo -u postgres psql -c \"CREATE ROLE $USER WITH SUPERUSER LOGIN;\""
    echo ""
    exit 1
fi

echo ""
echo "Setting up Rails database..."
cd "$(dirname "$0")"

# Try to create database with Rails
if bin/rails db:create 2>&1; then
    echo "✓ Database created successfully!"
else
    echo "⚠ Rails db:create failed, trying manual creation with UTF-8 encoding..."
    # Create database manually with explicit UTF-8 encoding to avoid locale issues
    if psql -d postgres -c "CREATE DATABASE bms_development WITH ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE template0;" 2>&1; then
        echo "✓ Development database created manually!"
    fi
    if psql -d postgres -c "CREATE DATABASE bms_test WITH ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE template0;" 2>&1; then
        echo "✓ Test database created manually!"
    fi
fi

# Run migrations
if bin/rails db:migrate 2>&1; then
    echo "✓ Migrations completed successfully!"
else
    echo "⚠ Migrations had issues."
    exit 1
fi

echo ""
echo "✓ Database setup complete!"
echo ""
echo "You can now start the Rails server with:"
echo "   bin/rails server"
echo "   # or"
echo "   bin/dev"
