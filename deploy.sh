#!/bin/bash

set -e

echo "Starting deployment..."

echo "Pulling latest code..."
git pull

CURRENT_COMMIT=$(git rev-parse HEAD)

if git rev-parse HEAD~1 >/dev/null 2>&1; then
  PREVIOUS_COMMIT=$(git rev-parse HEAD~1)
else
  PREVIOUS_COMMIT=""
  echo "No previous commit found — this is the first deployment. Rollback will not be available if this deploy fails."
fi

echo "Current commit: $CURRENT_COMMIT"

echo "Building backend image..."
docker build -t product-catalog-backend:$CURRENT_COMMIT ./backend

echo "Starting backend..."
docker compose stop backend
docker compose rm -f backend
docker compose up -d backend

if bash healthcheck.sh http://localhost/api/health; then
    echo "Backend healthy."

else
    echo "Backend failed health check."
    if [ -n "$PREVIOUS_COMMIT" ]; then
        echo "Rolling back to previous commit: $PREVIOUS_COMMIT"
        docker build -t product-catalog-backend:$PREVIOUS_COMMIT ./backend
        docker compose stop backend
        docker compose rm -f backend
        docker run -d \
          --name product-catalog-devops-backend-1 \
          --network product-catalog-devops_backend-network \
          --network-alias backend \
          --env-file .env \
          product-catalog-backend:$PREVIOUS_COMMIT
        echo "Rollback complete."
    else
        echo "No previous commit available — cannot roll back automatically."
    fi
    exit 1
fi

echo "Rebuilding backend2..."
docker compose stop backend2
docker compose rm -f backend2
docker compose up -d backend2

if bash healthcheck.sh http://localhost/api/health; then
    echo "Backend2 healthy."
else
    echo "Backend2 failed health check."
    exit 1
fi

echo "Rebuilding frontend and nginx..."
docker compose up -d --build frontend nginx

echo "Deployment complete."
docker compose ps

echo "Done."