# Envoie un thème au lanceur : d'abord ses photos de fond par appli (art/<paquet>.jpg, que seul le lanceur
# patché par vTV accepte), puis le thème lui-même par tools\theme.ps1 de cleanyourtv, qui redémarre l'accueil.
#
# Usage : powershell -ExecutionPolicy Bypass -File appliquer-theme.ps1 -TvHost 192.168.1.83 [themes\premium]
param(
    [Parameter(Position = 0)][string]$Theme,
    [string]$TvHost = $env:TV_HOST
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
if (-not $TvHost) { throw 'Passe -TvHost <ip du boîtier>' }
$env:TV_HOST = $TvHost
# $PSScriptRoot est vide dans les valeurs par défaut de param() sous Windows PowerShell 5.1.
if (-not $Theme) { $Theme = Join-Path $PSScriptRoot 'themes\premium' }
$Theme = (Resolve-Path $Theme).Path

$repo = Join-Path $PSScriptRoot 'cleanyourtv'
$py = Join-Path $repo 'tools\venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw 'Lance d''abord preparer-pc.ps1' }
$tv = Join-Path $repo 'tools\tv.py'

$art = Join-Path $Theme 'art'
if (Test-Path $art) {
    foreach ($photo in Get-ChildItem $art -Filter *.jpg) {
        $tmp = '/data/local/tmp/vtv-art.jpg'
        & $py -I (Join-Path $repo 'tools\b64push.py') $photo.FullName $tmp | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Envoi de $($photo.Name) échoué" }
        $sortie = (& $py -I $tv "content write --uri content://com.gathin.tvhome.theme/art/$($photo.Name) < $tmp && echo ok; rm -f $tmp") -join "`n"
        if ($sortie -notmatch 'ok') { throw "Le lanceur refuse art/$($photo.Name) : installe d'abord le lanceur patché (reinstaller-lanceur.ps1). $sortie" }
        Write-Host "Fond : $($photo.Name)"
    }
}

& powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'tools\theme.ps1') -TvHost $TvHost $Theme
if ($LASTEXITCODE -ne 0) { throw 'Envoi du thème échoué' }
