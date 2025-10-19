#!/bin/bash
# Taiga Stack - Secret Generation Helper
# Run this script to generate secure random values for Taiga deployment

echo "==================================================="
echo "  Taiga Stack - Secret Generation"
echo "==================================================="
echo ""

echo "📝 Copy these values to your Portainer environment variables:"
echo ""

echo "# PostgreSQL Password"
echo "POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)"
echo ""

echo "# Taiga Secret Key (64 char hex)"
echo "SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))' 2>/dev/null || openssl rand -hex 32)"
echo ""

echo "# RabbitMQ Password"
echo "RABBITMQ_PASS=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)"
echo ""

echo "# RabbitMQ Erlang Cookie"
echo "RABBITMQ_ERLANG_COOKIE=$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)"
echo ""

echo "==================================================="
echo "⚠️  Keep these values secure!"
echo "==================================================="
