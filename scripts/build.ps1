# Empacota a Lambda (código + dependências) em dist/function.zip (Windows)
$ErrorActionPreference = "Stop"

$root  = Split-Path -Parent $PSScriptRoot
$build = Join-Path $root "build"
$dist  = Join-Path $root "dist"

Remove-Item -Recurse -Force $build, $dist -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $build, $dist | Out-Null

Write-Host "==> Instalando dependências"
python -m pip install -r (Join-Path $root "requirements.txt") -t $build --quiet

Write-Host "==> Copiando código-fonte"
Copy-Item -Recurse (Join-Path $root "src\auth_fn") (Join-Path $build "auth_fn")

Write-Host "==> Gerando dist\function.zip"
Get-ChildItem -Recurse -Directory -Filter "__pycache__" $build | Remove-Item -Recurse -Force
Compress-Archive -Path (Join-Path $build "*") -DestinationPath (Join-Path $dist "function.zip") -Force

Write-Host "OK -> $dist\function.zip"
