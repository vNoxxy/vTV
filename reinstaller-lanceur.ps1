# Remplace le lanceur installé par une version signée avec une autre clé (une seule fois, pour passer à la
# clé fixe de signature/). Android refuse alors la mise à jour : il faut désinstaller puis réinstaller.
# L'accueil d'origine reprend la main entre les deux, pour que le boîtier ne reste jamais sans accueil.
# Les réglages faits sur le boîtier dans le lanceur (ordre, bibliothèque) sont perdus ; le thème se renvoie.
#
# Usage : powershell -ExecutionPolicy Bypass -File reinstaller-lanceur.ps1 -TvHost 192.168.1.83 -Apk .\app-release.apk
param(
    [Parameter(Mandatory = $true)][string]$Apk,
    [string]$Accueil = 'com.droidlogic.mboxlauncher',
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
$Apk = (Resolve-Path $Apk).Path

# 1. L'accueil d'origine réactivé et remis en accueil : il démarre tout de suite.
$sortie = (& $py -I $tv "pm enable $Accueil; cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME -p $Accueil") -join "`n"
Write-Host $sortie
$composant = ($sortie -split "`n" | Where-Object { $_ -match "^$([regex]::Escape($Accueil))/" } | Select-Object -Last 1)
if (-not $composant) { throw "L'accueil d'origine $Accueil ne répond pas : rien n'a été désinstallé." }
& $py -I $tv "cmd package set-home-activity --user 0 $($composant.Trim()); am start -a android.intent.action.MAIN -c android.intent.category.HOME" | Write-Host

# 2. L'ancien lanceur désinstallé.
& $py -I $tv 'pm uninstall com.gathin.tvhome' | Write-Host

# 3. Le nouveau, installé par le script de cleanyourtv : il vérifie qu'il démarre avant de désactiver
#    l'accueil d'origine.
$dest = Join-Path $repo 'launcher\app\build\outputs\apk\release'
New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item $Apk (Join-Path $dest 'app-release.apk') -Force
$env:SKIP_BUILD = '1'
& powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'launcher\build-and-install.ps1') -TvHost $TvHost -StockLauncher $Accueil
if ($LASTEXITCODE -ne 0) { throw "Installation du lanceur échouée : l'accueil d'origine reste actif." }
Write-Host 'Lanceur réinstallé. Renvoie le thème : cleanyourtv\tools\theme.ps1 -TvHost <ip> themes\premium'
