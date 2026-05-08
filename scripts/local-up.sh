#!/usr/bin/env bash
set -euo pipefail

docker compose up --force-recreate --remove-orphans --detach

echo "Waiting for containers..."
sleep 20

docker ps

echo "App: http://localhost:8080"
echo "Grafana: http://localhost:8080/grafana"
echo "Jaeger: http://localhost:8080/jaeger/ui"
