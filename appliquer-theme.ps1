# Envoie un thème au lanceur : d'abord les photos de fond par appli (art/<paquet>.jpg, que seul le lanceur
# patché par vTV accepte), puis le thème lui-même par tools\theme.ps1 de cleanyourtv, qui redémarre l'accueil.
# Les photos viennent du dossier art\ du thème s'il en a un, sinon de themes\art\, partagé par les boîtiers.
#
# Usage : powershell -ExecutionPolicy Bypass -File appliquer-theme.ps1 -TvHost 192.168.1.83 boitiers\h96-max-v11\theme
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Theme,
    [string]$TvHost = $env:TV_HOST
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
if (-not $TvHost) { throw 'Passe -TvHost <ip du boîtier>' }
$env:TV_HOST = $TvHost
$Theme = (Resolve-Path $Theme).Path

$repo = Join-Path $PSScriptRoot 'cleanyourtv'
$py = Join-Path $repo 'tools\venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw 'Lance d''abord preparer-pc.ps1' }
$tv = Join-Path $repo 'tools\tv.py'

$art = Join-Path $Theme 'art'
if (-not (Test-Path $art)) { $art = Join-Path $PSScriptRoot 'themes\art' }
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
