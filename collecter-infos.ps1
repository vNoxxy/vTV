# Lit le boîtier (rien n'est modifié) et rassemble dans infos-boitier.txt ce qu'il faut pour écrire
# sa liste de nettoyage : modèle, système, applis système et installées, lanceur d'origine, audit
# vie privée de cleanyourtv. Une capture de l'accueil est enregistrée dans accueil.png.
#
# Usage (après preparer-pc.ps1) :
#   powershell -ExecutionPolicy Bypass -File collecter-infos.ps1 -TvHost 192.168.1.50
param(
    [string]$TvHost = $env:TV_HOST
)
$ErrorActionPreference = 'Stop'
# Texte UTF-8 sans BOM vers Python : le BOM par défaut corromprait la première commande.
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
if (-not $TvHost) { throw 'Passe -TvHost <ip du boîtier>' }
$env:TV_HOST = $TvHost

$repo = Join-Path $PSScriptRoot 'cleanyourtv'
$py = Join-Path $repo 'tools\venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw 'Lance d''abord preparer-pc.ps1' }
$tv = Join-Path $repo 'tools\tv.py'
$sortie = Join-Path $PSScriptRoot 'infos-boitier.txt'

$commandes = @(
    'echo "== Systeme =="'
    'getprop ro.product.manufacturer; getprop ro.product.model; getprop ro.product.device; getprop ro.board.platform'
    'getprop ro.build.version.release; getprop ro.build.version.sdk; getprop ro.build.fingerprint'
    'echo "== Type (leanback = interface TV) =="'
    'pm list features | grep -i -e leanback -e live_tv'
    'echo "== Memoire et stockage =="'
    'grep -e MemTotal -e MemAvailable /proc/meminfo; df -h /data'
    'echo "== Root =="'
    'id; ls /system/bin/su /system/xbin/su 2>/dev/null'
    'echo "== Accueil actuel =="'
    'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME'
    'echo "== Applis qui repondent a Accueil =="'
    'cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME'
    'echo "== Applis systeme =="'
    'pm list packages -s'
    'echo "== Applis installees =="'
    'pm list packages -3'
    'echo "== Deja desactivees =="'
    'pm list packages -d'
)

Write-Host 'Connexion au boîtier : accepte « Autoriser le débogage USB ? » sur la TV si on te le demande.'
& $py -I $tv --probe | Out-File -Encoding utf8 $sortie
if ($LASTEXITCODE -ne 0) { throw "Connexion impossible à $TvHost (débogage activé ? même box ?)" }
$commandes | & $py -I $tv --batch | Out-File -Encoding utf8 -Append $sortie
'== Audit vie privee (tools\privacy.py) ==' | Out-File -Encoding utf8 -Append $sortie
# Windows PowerShell 5.1 change chaque ligne de stderr en erreur : sous 'Stop', la première
# arrêterait le script. L'audit écrit ses avertissements sur stderr, on les garde dans le fichier.
$ErrorActionPreference = 'Continue'
& $py -I (Join-Path $repo 'tools\privacy.py') 2>&1 | ForEach-Object { "$_" } | Out-File -Encoding utf8 -Append $sortie
$ErrorActionPreference = 'Stop'
& $py -I $tv --screenshot (Join-Path $PSScriptRoot 'accueil.png') HOME --wait 2

Write-Host "Terminé. Envoie-moi $sortie et accueil.png."
