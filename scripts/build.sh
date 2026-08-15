#!/usr/bin/env bash
# Empacota a Lambda (código + dependências) em dist/function.zip
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
DIST="$ROOT/dist"

rm -rf "$BUILD" "$DIST"
mkdir -p "$BUILD" "$DIST"

echo "==> Instalando dependências"
python -m pip install -r "$ROOT/requirements.txt" -t "$BUILD" --quiet

echo "==> Copiando código-fonte"
cp -r "$ROOT/src/auth_fn" "$BUILD/auth_fn"

echo "==> Gerando dist/function.zip"
( cd "$BUILD" && find . -name '__pycache__' -type d -prune -exec rm -rf {} + \
  && zip -r "$DIST/function.zip" . -x '*.pyc' >/dev/null )

echo "OK -> $DIST/function.zip"
