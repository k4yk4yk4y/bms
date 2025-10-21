#!/usr/bin/env bash
# Script to create admin user on Render

echo "=== Creating Admin Users ==="

# Create main admin user
if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then
  echo "Creating main admin user: $ADMIN_EMAIL"
  bundle exec rails admin:create_custom[$ADMIN_EMAIL,$ADMIN_PASSWORD,Admin,User]
else
  echo "ADMIN_EMAIL and ADMIN_PASSWORD environment variables not set"
  echo "Creating default admin user: admin@bms.com"
  bundle exec rails admin:create
fi

# Create AdminUser for ActiveAdmin
if [ -n "$ADMIN_USER_EMAIL" ] && [ -n "$ADMIN_USER_PASSWORD" ]; then
  echo "Creating AdminUser for ActiveAdmin: $ADMIN_USER_EMAIL"
  bundle exec rails admin_user:create_custom[$ADMIN_USER_EMAIL,$ADMIN_USER_PASSWORD]
else
  echo "ADMIN_USER_EMAIL and ADMIN_USER_PASSWORD environment variables not set"
  echo "Creating default AdminUser: admin@example.com"
  bundle exec rails admin_user:create
fi

echo "=== Admin users creation completed ==="
