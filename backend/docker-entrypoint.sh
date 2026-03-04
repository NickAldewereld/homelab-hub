#!/bin/sh
set -e

# Wait for PostgreSQL if DATABASE_URL points to one
if echo "$DATABASE_URL" | grep -q "postgresql"; then
  echo "Waiting for PostgreSQL..."
  # Extract host:port from DATABASE_URL
  PG_HOST=$(echo "$DATABASE_URL" | sed -n 's|.*@\([^:/]*\).*|\1|p')
  PG_PORT=$(echo "$DATABASE_URL" | sed -n 's|.*@[^:]*:\([0-9]*\).*|\1|p')
  PG_PORT=${PG_PORT:-5432}

  for i in $(seq 1 30); do
    if nc -z "$PG_HOST" "$PG_PORT" 2>/dev/null; then
      echo "PostgreSQL is ready."
      break
    fi
    echo "Waiting for PostgreSQL ($i/30)..."
    sleep 1
  done
fi

echo "Running database migrations..."
alembic upgrade head

echo "Starting application..."
exec gunicorn --bind 0.0.0.0:8000 --workers 1 --timeout 120 wsgi:app
