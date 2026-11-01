# Envoie au boîtier les commandes d'un fichier (une par ligne, sur la même connexion) et enregistre
# la réponse dans un .txt du même nom à la racine du dépôt.
#
# Usage : powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost 192.168.1.83 commandes\diagnostic.txt
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Fichier,
    [string]$TvHost = $env:TV_HOST
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
if (-not $TvHost) { throw 'Passe -TvHost <ip du boîtier>' }
$env:TV_HOST = $TvHost

$repo = Join-Path $PSScriptRoot 'cleanyourtv'
$py = Join-Path $repo 'tools\venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw 'Lance d''abord preparer-pc.ps1' }
$commandes = Get-Content $Fichier | Where-Object { $_ -and $_ -notmatch '^\s*#' }
$sortie = Join-Path $PSScriptRoot ([IO.Path]::GetFileNameWithoutExtension($Fichier) + '.txt')

$commandes | & $py -I (Join-Path $repo 'tools\tv.py') --batch | Out-File -Encoding utf8 $sortie
if ($LASTEXITCODE -ne 0) { throw "Connexion impossible à $TvHost" }
Write-Host "Terminé. Réponse dans $sortie."
