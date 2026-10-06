$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

$place = "place/buildapiramid.rbxl"
$backup = "place/buildapiramid_FACTORY_BACKUP.rbxl"

if (-not (Test-Path $place)) {
    throw "Fichier introuvable: $place"
}

Write-Host "Sauvegarde complete du projet Roblox..." -ForegroundColor Cyan

git add -A

# Double securite: ne jamais versionner le backup factory.
git reset -- $backup 2>$null | Out-Null

$staged = git diff --cached --name-only
if (-not $staged) {
    Write-Host "Aucun changement a sauvegarder." -ForegroundColor Yellow
    exit 0
}

$stamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "save: project snapshot $stamp"

Write-Host "Envoi sur GitHub..." -ForegroundColor Cyan
git push

Write-Host ""
Write-Host "Sauvegarde terminee: scripts + map active sont sur GitHub." -ForegroundColor Green
