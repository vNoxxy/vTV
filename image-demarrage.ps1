# Envoie une image à l'add-on Startup & Branding, comme son push-image.sh (bash seulement) : par
# tools\b64push.py puis par le fournisseur de contenu de l'appli, que seul le shell ADB peut écrire.
# Ensuite, sur le boîtier : Startup & Branding > Custom Image > Picture.
#
# Usage : powershell -ExecutionPolicy Bypass -File image-demarrage.ps1 -TvHost 192.168.1.83 [visuels\demarrage.png]
param(
    [Parameter(Position = 0)][string]$Image,
    [string]$TvHost = $env:TV_HOST
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
if (-not $TvHost) { throw 'Passe -TvHost <ip du boîtier>' }
$env:TV_HOST = $TvHost

$repo = Join-Path $PSScriptRoot 'cleanyourtv'
$py = Join-Path $repo 'tools\venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw 'Lance d''abord preparer-pc.ps1' }
$tv = Join-Path $repo 'tools\tv.py'
# $PSScriptRoot est vide dans les valeurs par défaut de param() sous Windows PowerShell 5.1.
if (-not $Image) { $Image = Join-Path $PSScriptRoot 'visuels\demarrage.png' }
$Image = (Resolve-Path $Image).Path
$nom = [IO.Path]::GetFileName($Image) -replace '[^A-Za-z0-9._-]', '_'
if ($nom -notmatch '\.(png|jpe?g|webp)$') { throw 'PNG, JPEG ou WebP seulement' }

$pkg = 'io.github.maxhayim.startupbranding'
if (-not ((& $py -I $tv "pm path $pkg; true") -match 'package:')) { throw 'Startup & Branding n''est pas installé : lance installer-addons.ps1' }
$tmp = '/data/local/tmp/startup-branding-picture'
& $py -I (Join-Path $repo 'tools\b64push.py') $Image $tmp
if ($LASTEXITCODE -ne 0) { throw "Envoi de $nom échoué" }
& $py -I $tv "content write --uri content://$pkg.pictures/$nom < $tmp; rm -f $tmp" | Out-Null
Write-Host "Envoyé : $nom. Sur le boîtier : Startup & Branding > Custom Image > Picture."
