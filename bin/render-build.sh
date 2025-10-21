#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean

# Create default admin users (will use environment variables if set, otherwise defaults)
echo "Creating default admin users..."
bundle exec rails admin:create_defaults