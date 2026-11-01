# Lit le boîtier (rien n'est modifié) et rassemble dans diagnostic.txt : d'où vient l'ADB réseau
# ouvert sans autorisation, ce qui occupe le stockage, l'écran de veille et le DNS actuels.
#
# Usage : powershell -ExecutionPolicy Bypass -File diagnostic.ps1 -TvHost 192.168.1.83
param(
    [string]$TvHost = $env:TV_HOST
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
if (-not $TvHost) { throw 'Passe -TvHost <ip du boîtier>' }
$env:TV_HOST = $TvHost

$repo = Join-Path $PSScriptRoot 'cleanyourtv'
$py = Join-Path $repo 'tools\venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw 'Lance d''abord preparer-pc.ps1' }
$sortie = Join-Path $PSScriptRoot 'diagnostic.txt'

$commandes = @(
    'echo "== ADB : proprietes =="'
    'getprop | grep -i -e adb -e usb.config -e usb.state'
    'echo "== ADB : reglages =="'
    'settings get global adb_enabled; settings get global adb_wifi_enabled; settings get global development_settings_enabled'
    'echo "== ADB : scripts de demarrage qui ouvrent le port =="'
    'grep -rn -e adb.tcp -e 5555 /system/etc/init /vendor/etc/init /odm/etc/init /init*.rc /system/build.prop /vendor/build.prop 2>/dev/null'
    'echo "== Stockage : partitions =="'
    'df -h /data'
    'echo "== Stockage : 20 plus gros dossiers d''applis (Ko) =="'
    'du -s /data/data/* /data/app/*/* /data/media/0/Android/data/* 2>/dev/null | sort -n | tail -20'
    'echo "== Stockage : 15 plus gros dossiers de fichiers (Ko) =="'
    'du -s /data/media/0/* 2>/dev/null | sort -n | tail -15'
    'echo "== Ecran de veille =="'
    'settings get secure screensaver_enabled; settings get secure screensaver_components; settings get system screen_off_timeout'
    'echo "== DNS prive =="'
    'settings get global private_dns_mode; settings get global private_dns_specifier'
)

$commandes | & $py -I (Join-Path $repo 'tools\tv.py') --batch | Out-File -Encoding utf8 $sortie
if ($LASTEXITCODE -ne 0) { throw "Connexion impossible à $TvHost" }
Write-Host "Terminé. Envoie-moi $sortie."
