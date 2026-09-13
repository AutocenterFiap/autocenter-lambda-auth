#!/usr/bin/env bash
# Faz o build local da imagem da Lambda usando o Dockerfile do projeto.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_TAG="${IMAGE_TAG:-${1:-autocenter-lambda-auth:local}}"

echo "==> Build da imagem Lambda: $IMAGE_TAG"
docker build --platform linux/amd64 -t "$IMAGE_TAG" "$ROOT"
echo "OK -> $IMAGE_TAG"
