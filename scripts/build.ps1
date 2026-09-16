# Faz o build local da imagem da Lambda usando o Dockerfile do projeto (Windows)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

if (-not $env:IMAGE_TAG -or [string]::IsNullOrWhiteSpace($env:IMAGE_TAG)) {
    $env:IMAGE_TAG = "autocenter-lambda-auth:local"
}

Write-Host "==> Build da imagem Lambda: $env:IMAGE_TAG"
docker build --platform linux/amd64 -t $env:IMAGE_TAG $root

Write-Host "OK -> $env:IMAGE_TAG"
