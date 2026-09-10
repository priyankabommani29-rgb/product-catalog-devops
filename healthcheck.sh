#!/bin/bash

URL=$1
MAX_ATTEMPTS=10
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  if [ "$STATUS" -eq 200 ]; then
    echo "Health check passed: $URL"
    exit 0
  fi
  echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: not ready yet (status $STATUS)..."
  ATTEMPT=$((ATTEMPT + 1))
  sleep 2
done

echo "Health check FAILED after $MAX_ATTEMPTS attempts: $URL"
exit 1